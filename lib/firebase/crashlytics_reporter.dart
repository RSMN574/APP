import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../core/error/app_error_handler.dart';

/// 以 Firebase Crashlytics 實作 [ErrorReporter]。
class CrashlyticsErrorReporter implements ErrorReporter {
  CrashlyticsErrorReporter([FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  /// Debug build 預設不收集，避免開發期間的錯誤污染正式數據；
  /// 需要在 Debug 驗證時以 `--dart-define=CRASHLYTICS_DEBUG=true` 開啟。
  static const bool _collectInDebug =
      bool.fromEnvironment('CRASHLYTICS_DEBUG', defaultValue: false);

  static bool get collectionEnabled => !kDebugMode || _collectInDebug;

  Future<void> configure({
    required String appVersion,
    required String buildNumber,
  }) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(collectionEnabled);
    await _crashlytics.setCustomKey('app_version', appVersion);
    await _crashlytics.setCustomKey('build_number', buildNumber);
    await _crashlytics.setCustomKey(
      'build_mode',
      kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
    );
  }

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) {
    return _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
      printDetails: kDebugMode,
    );
  }

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    required bool fatal,
  }) {
    return fatal
        ? _crashlytics.recordFlutterFatalError(details)
        : _crashlytics.recordFlutterError(details);
  }

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);
}
