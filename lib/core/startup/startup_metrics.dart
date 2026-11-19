import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../firebase/performance_service.dart';

/// 啟動效能量測。
///
/// 量測點（皆以 Dart `main()` 開始為 0）：
/// - `first_frame`：Flutter 第一個畫面繪製完成（Splash）
/// - `home_visible`：首頁（TaiwanPass）第一次 build 完成
/// - `home_interactive`：首頁主要資料（城市/定位）可互動
///
/// 結果以單行 `[startup] ...` 輸出到 logcat（`adb logcat -s flutter`），
/// 並同步建立 Firebase Performance 自訂 Trace（`app_startup`）。
class StartupMetrics {
  StartupMetrics._();

  static final Stopwatch _sinceMain = Stopwatch();
  static final Map<String, int> _marks = {};
  static final Map<String, int> _durations = {};
  static AppTraceHandle? _trace;

  static Map<String, int> get marks => Map.unmodifiable(_marks);
  static Map<String, int> get durations => Map.unmodifiable(_durations);

  static void markMainStart() {
    if (_sinceMain.isRunning) return;
    _sinceMain.start();
  }

  /// Firebase 初始化完成後才能建立 Trace；各量測點以 metric 記錄
  /// （數值仍以 main() 開始為 0）。
  static void attachPerformanceTrace() {
    if (_trace != null || _marks.containsKey('home_interactive')) return;
    _trace = AppPerformance.startTrace(AppTraces.appStartup);
  }

  static void markFirstFrame() => _mark('first_frame');

  static void markHomeVisible() => _mark('home_visible');

  static void markHomeInteractive() {
    if (_marks.containsKey('home_interactive')) return;
    _mark('home_interactive');
    final trace = _trace;
    _trace = null;
    if (trace != null) {
      for (final entry in {..._marks, ..._durations}.entries) {
        trace.setMetric('${entry.key}_ms', entry.value);
      }
      unawaited(trace.stop());
    }
  }

  /// 量測一段啟動工作的耗時（毫秒）。
  static Future<T> measure<T>(String name, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      return await action();
    } finally {
      _durations[name] = sw.elapsedMilliseconds;
      _log('[startup] $name took ${sw.elapsedMilliseconds}ms');
    }
  }

  static void _mark(String name) {
    if (_marks.containsKey(name) || !_sinceMain.isRunning) return;
    final ms = _sinceMain.elapsedMilliseconds;
    _marks[name] = ms;
    developer.Timeline.instantSync('startup_$name');
    _log('[startup] $name=${ms}ms');
  }

  static void _log(String message) {
    // print（非 debugPrint）在 profile/release 也會寫到 logcat，供效能量測。
    // ignore: avoid_print
    print(message);
  }

  @visibleForTesting
  static void reset() {
    _sinceMain
      ..stop()
      ..reset();
    _marks.clear();
    _durations.clear();
    _trace = null;
  }
}
