
import 'package:firebase_performance/firebase_performance.dart';

/// 台灣通 Firebase 效能監控服務。
///
/// traceName 請使用固定的功能代碼，
/// 不要傳入站牌名稱、路線名稱或完整 URL。
class AppPerformance {
  AppPerformance._();

  static final FirebasePerformance _performance =
      FirebasePerformance.instance;

  /// 測量指定非同步工作執行的時間。
  static Future<T> measure<T>({
    required String traceName,
    required Future<T> Function() action,
  }) async {
    final trace = _performance.newTrace(traceName);

    await trace.start();

    try {
      return await action();
    } finally {
      await trace.stop();
    }
  }
}
