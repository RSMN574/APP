import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 錯誤分類：API、Repository、Provider 與 UI 共用同一套分類，
/// 讓 Crashlytics / Analytics 能以固定維度統計。
enum AppErrorCategory {
  network,
  timeout,
  auth,
  server,
  notFound,
  rateLimited,
  parse,
  cancelled,
  unsupported,
  unknown,
}

/// 錯誤回報後端。正式環境為 Crashlytics，測試時可替換成假實作。
abstract class ErrorReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details,
      {required bool fatal});

  Future<void> log(String message);

  Future<void> setCustomKey(String key, Object value);
}

/// 尚未初始化 Firebase（或單元測試）時使用：不送出任何資料。
class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {required bool fatal, String? reason}) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details,
      {required bool fatal}) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// App 統一錯誤處理服務。
///
/// - 捕捉 Flutter framework、PlatformDispatcher、Zone 與 Isolate 未處理錯誤
/// - 非致命錯誤分類、去重後上報
/// - 管理 custom keys（版本、城市、功能模組）與 breadcrumb
/// - 所有字串在送出前去除 Token、URL 查詢字串與 Email 等敏感資訊
class AppErrorHandler {
  AppErrorHandler._();

  static ErrorReporter _reporter = const NoopErrorReporter();
  static final Map<String, DateTime> _recent = {};
  static final List<String> _breadcrumbs = [];

  /// 相同錯誤在此時間內只回報一次。
  static Duration dedupeWindow = const Duration(minutes: 1);
  static const int _maxBreadcrumbs = 30;
  static const int _maxDedupeEntries = 200;

  /// 目前回報器（測試用）。
  static ErrorReporter get reporter => _reporter;

  /// 最近的 breadcrumb（Debug 畫面與測試使用）。
  static List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);

  /// 設定回報後端。Firebase 初始化完成後呼叫。
  static void attachReporter(ErrorReporter reporter) {
    _reporter = reporter;
  }

  /// 測試用：重設所有狀態。
  @visibleForTesting
  static void reset() {
    _reporter = const NoopErrorReporter();
    _recent.clear();
    _breadcrumbs.clear();
    dedupeWindow = const Duration(minutes: 1);
  }

  /// 安裝全域錯誤攔截。應在 `runApp` 之前、盡可能早呼叫。
  static void installGlobalHandlers() {
    FlutterError.onError = handleFlutterError;

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(recordError(error, stack, fatal: true, reason: 'platform'));
      return true;
    };

    if (!kIsWeb) {
      Isolate.current.addErrorListener(RawReceivePort((dynamic pair) {
        if (pair is List && pair.length == 2) {
          final error = pair.first ?? 'Unknown isolate error';
          final stackText = pair.last?.toString();
          unawaited(recordError(
            error,
            stackText == null ? null : StackTrace.fromString(stackText),
            fatal: true,
            reason: 'isolate',
          ));
        }
      }).sendPort);
    }
  }

  /// Flutter framework 錯誤：版面溢位等渲染問題視為非致命。
  static void handleFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final fatal = isFatalFlutterError(details);
    if (_isDuplicate(_signature(details.exception, details.stack, 'flutter'))) {
      return;
    }
    unawaited(_safe(() => _reporter.recordFlutterError(details, fatal: fatal)));
  }

  /// 渲染、版面與圖片載入錯誤不會讓 App 停止運作，不應算成閃退。
  static bool isFatalFlutterError(FlutterErrorDetails details) {
    final library = details.library ?? '';
    const nonFatalLibraries = {
      'rendering library',
      'image resource service',
      'painting library',
      'widgets library',
      'gesture',
      'services library',
    };
    if (nonFatalLibraries.contains(library)) return false;
    return !details.silent;
  }

  /// 記錄非致命錯誤（API、Repository、Provider 使用）。
  static Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? feature,
    String? reason,
  }) {
    return recordError(error, stack,
        fatal: false, feature: feature, reason: reason);
  }

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? feature,
    String? reason,
  }) async {
    final category = classify(error);
    if (!fatal && category == AppErrorCategory.cancelled) return;

    final signature = _signature(error, stack, feature ?? reason ?? '');
    if (_isDuplicate(signature)) return;

    if (kDebugMode) {
      debugPrint('[AppErrorHandler] ${fatal ? 'FATAL' : 'non-fatal'} '
          '${category.name} ${feature ?? ''}: ${sanitize(error.toString())}');
    }

    await _safe(() async {
      await _reporter.setCustomKey('error_category', category.name);
      if (feature != null) {
        await _reporter.setCustomKey('feature', sanitize(feature));
      }
      await _reporter.recordError(
        _SanitizedError(error),
        stack,
        fatal: fatal,
        reason: reason == null ? null : sanitize(reason),
      );
    });
  }

  /// 新增 breadcrumb，協助在 Crashlytics 中還原錯誤發生前的操作。
  static void breadcrumb(String message) {
    final clean = sanitize(message);
    _breadcrumbs.add('${DateTime.now().toIso8601String()} $clean');
    if (_breadcrumbs.length > _maxBreadcrumbs) _breadcrumbs.removeAt(0);
    unawaited(_safe(() => _reporter.log(clean)));
  }

  /// 設定非敏感的診斷資訊（版本、城市、功能模組）。
  static Future<void> setContext({
    String? appVersion,
    String? buildNumber,
    String? city,
    String? feature,
  }) {
    return _safe(() async {
      if (appVersion != null) {
        await _reporter.setCustomKey('app_version', appVersion);
      }
      if (buildNumber != null) {
        await _reporter.setCustomKey('build_number', buildNumber);
      }
      if (city != null) await _reporter.setCustomKey('city', city);
      if (feature != null) await _reporter.setCustomKey('feature', feature);
    });
  }

  /// 依例外型別與 HTTP 狀態分類。
  static AppErrorCategory classify(Object error) {
    if (error is _SanitizedError) return classify(error.original);
    if (error is TimeoutException) return AppErrorCategory.timeout;
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return AppErrorCategory.network;
    }
    if (error is FormatException || error is TypeError) {
      return AppErrorCategory.parse;
    }
    if (error is UnsupportedError) return AppErrorCategory.unsupported;

    final text = error.toString();
    if (text.contains('cancelled') || text.contains('canceled')) {
      return AppErrorCategory.cancelled;
    }
    final status = _statusCode(text);
    if (status != null) {
      if (status == 401 || status == 403) return AppErrorCategory.auth;
      if (status == 404) return AppErrorCategory.notFound;
      if (status == 429) return AppErrorCategory.rateLimited;
      if (status >= 500) return AppErrorCategory.server;
    }
    if (text.contains('token is unavailable')) return AppErrorCategory.auth;
    return AppErrorCategory.unknown;
  }

  static int? _statusCode(String text) {
    final match =
        RegExp(r'(?:HTTP|status|error:?)\s*(\d{3})\b', caseSensitive: false)
            .firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// 去除可能的敏感資訊：Bearer token、JWT、URL 查詢字串、Email。
  static String sanitize(String input) {
    var text = input;
    text = text.replaceAll(
        RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
        'Bearer <redacted>');
    text = text.replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'), '<jwt>');
    text = text.replaceAllMapped(
        RegExp(r'(https?://[^\s?#]+)\?[^\s#]*'), (m) => '${m[1]}?<query>');
    text = text.replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<email>');
    text = text.replaceAll(
        RegExp(r'(password|secret|api[_-]?key|token)\s*[=:]\s*\S+',
            caseSensitive: false),
        r'$1=<redacted>');
    if (text.length > 1000) text = '${text.substring(0, 1000)}…';
    return text;
  }

  static String _signature(Object error, StackTrace? stack, String scope) {
    final firstFrame = stack
            ?.toString()
            .split('\n')
            .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '') ??
        '';
    final message = sanitize(error.toString());
    final shortMessage =
        message.length > 160 ? message.substring(0, 160) : message;
    return '${error.runtimeType}|$scope|$shortMessage|$firstFrame';
  }

  static bool _isDuplicate(String signature) {
    final now = DateTime.now();
    final last = _recent[signature];
    if (last != null && now.difference(last) < dedupeWindow) return true;
    _recent[signature] = now;
    if (_recent.length > _maxDedupeEntries) {
      _recent.removeWhere((_, time) => now.difference(time) >= dedupeWindow);
      if (_recent.length > _maxDedupeEntries) {
        _recent.remove(_recent.keys.first);
      }
    }
    return false;
  }

  /// 回報流程本身失敗時不能再丟出例外，避免遞迴錯誤。
  static Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (kDebugMode) debugPrint('[AppErrorHandler] reporter failed: $e');
    }
  }
}

/// 送出前去除敏感資訊的包裝；Crashlytics 以 toString() 作為訊息。
class _SanitizedError implements Exception {
  _SanitizedError(this.original);

  final Object original;

  @override
  String toString() =>
      '${original.runtimeType}: ${AppErrorHandler.sanitize(original.toString())}';
}
