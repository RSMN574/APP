
import 'package:firebase_analytics/firebase_analytics.dart';

/// 台灣通 Firebase Analytics 統計服務。
///
/// 只記錄功能代碼與操作結果，不記錄站牌名稱、電子郵件、
/// 使用者姓名或其他可識別個人的資訊。
class AppAnalytics {
  AppAnalytics._();

  static final FirebaseAnalytics _analytics =
      FirebaseAnalytics.instance;

  /// 記錄交通功能開啟。
  static Future<void> logFeatureOpened(String feature) {
    return _log(() => _analytics.logEvent(
      name: 'transport_feature_opened',
      parameters: {'feature': feature},
    ));
  }

  /// 記錄交通查詢結果。
  static Future<void> logQueryResult({
    required String feature,
    required bool success,
    String? errorType,
  }) {
    return _log(() => _analytics.logEvent(
      name: 'transport_query_result',
      parameters: {
        'feature': feature,
        'success': success ? 1 : 0,
        if (!success && errorType != null)
          'error_type': errorType,
      },
    ));
  }

  /// 記錄公車到站提醒操作。
  /// action 建議使用 created、removed、enabled、disabled。
  static Future<void> logReminderAction({
    required String action,
  }) {
    return _log(() => _analytics.logEvent(
      name: 'bus_reminder_action',
      parameters: {'action': action},
    ));
  }

  /// 記錄路線規劃功能使用。
  static Future<void> logRoutePlanningUsed({
    required String transportType,
  }) {
    return _log(() => _analytics.logEvent(
      name: 'route_planning_used',
      parameters: {'transport_type': transportType},
    ));
  }

  /// 記錄收藏操作。
  static Future<void> logFavoriteAction({
    required String feature,
    required bool added,
  }) {
    return _log(() => _analytics.logEvent(
      name: 'favorite_action',
      parameters: {
        'feature': feature,
        'action': added ? 'add' : 'remove',
      },
    ));
  }

  /// 統計失敗不應影響 App 原本的功能。
  static Future<void> _log(
      Future<void> Function() action,
      ) async {
    try {
      await action();
    } catch (error) {
      // 正式環境可接入受控的除錯紀錄。
      // 不要將個人資訊或完整查詢內容寫入日誌。
    }
  }
}
