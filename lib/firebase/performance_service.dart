import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// 自訂 Trace 名稱統一管理。名稱只能使用固定代碼，
/// 不可包含站牌名稱、路線名稱、完整 URL 或任何使用者資料。
class AppTraces {
  AppTraces._();

  static const appStartup = 'app_startup';
  static const homeLoad = 'home_load';
  static const busEtaApi = 'bus_eta_api';
  static const busScheduleApi = 'bus_schedule_api';
  static const busRouteLoad = 'bus_route_load';
  static const routeSearch = 'route_search';
  static const pageLoadPrefix = 'page_load_';
}

/// 可安全停止的 Trace；Firebase 不可用時為 no-op。
class AppTraceHandle {
  AppTraceHandle._(this._trace, this._name);

  final Trace? _trace;
  final String _name;
  final Stopwatch _stopwatch = Stopwatch()..start();
  bool _stopped = false;

  String get name => _name;
  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  void setMetric(String name, int value) {
    try {
      _trace?.setMetric(name, value);
    } catch (_) {}
  }

  void putAttribute(String name, String value) {
    try {
      // Firebase 限制：屬性值最長 100 字元。
      _trace?.putAttribute(
          name, value.length > 100 ? value.substring(0, 100) : value);
    } catch (_) {}
  }

  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    _stopwatch.stop();
    try {
      await _trace?.stop();
    } catch (_) {}
  }
}

/// 台灣通 Firebase 效能監控服務。
class AppPerformance {
  AppPerformance._();

  static bool get _available {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 開始一個 Trace。Firebase 尚未初始化（或測試環境）時回傳 no-op handle。
  static AppTraceHandle startTrace(String traceName) {
    Trace? trace;
    if (_available) {
      try {
        trace = FirebasePerformance.instance.newTrace(traceName);
        unawaited(trace.start().catchError((_) {}));
      } catch (e) {
        if (kDebugMode) debugPrint('[AppPerformance] trace start failed: $e');
        trace = null;
      }
    }
    return AppTraceHandle._(trace, traceName);
  }

  /// 測量指定非同步工作執行的時間。
  ///
  /// QA B13：先前 Trace 啟動失敗會讓 [action] 不被執行，業務邏輯一起失敗；
  /// 現在監控失敗只會降級，不影響 [action]。
  static Future<T> measure<T>({
    required String traceName,
    required Future<T> Function() action,
    Map<String, String> attributes = const {},
  }) async {
    final handle = startTrace(traceName);
    attributes.forEach(handle.putAttribute);
    var success = false;
    try {
      final result = await action();
      success = true;
      return result;
    } finally {
      handle.putAttribute('result', success ? 'success' : 'error');
      unawaited(handle.stop());
    }
  }
}
