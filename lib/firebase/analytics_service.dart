
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

/// 台灣通 Firebase Analytics 統計服務。
///
/// 只記錄功能代碼與操作結果，不記錄站牌名稱、電子郵件、
/// 使用者姓名或其他可識別個人的資訊。
class AppAnalytics {
  AppAnalytics._();

  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

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

  // ---------------------------------------------------------------------------
  // Beta 測試追蹤事件（名稱與參數統一定義於 [AnalyticsEvents]）
  // 原則：不記錄個人身分、精確位置、完整 URL、Token；城市只記錄 TDX 代碼。
  // ---------------------------------------------------------------------------

  static Future<void> logAppOpen() =>
      _log(() => _analytics.logAppOpen());

  static Future<void> logCityChanged({
    required String city,
    required String source,
  }) =>
      _event(AnalyticsEvents.cityChanged, {'city': city, 'source': source});

  static Future<void> logBusRouteSearch({
    required String city,
    required int resultCount,
  }) =>
      _event(AnalyticsEvents.busRouteSearch, {
        'city': city,
        'result_bucket': _bucket(resultCount),
      });

  static Future<void> logBusStopView({required String city}) =>
      _event(AnalyticsEvents.busStopView, {'city': city});

  static Future<void> logBusScheduleView({
    required String city,
    required bool supported,
  }) =>
      _event(AnalyticsEvents.busScheduleView, {
        'city': city,
        'supported': supported ? 1 : 0,
      });

  static Future<void> logTransitRouteSearch({required String mode}) =>
      _event(AnalyticsEvents.transitRouteSearch, {'mode': mode});

  static Future<void> logNavigationStart({required String mode}) =>
      _event(AnalyticsEvents.navigationStart, {'mode': mode});

  static Future<void> logThemeChanged({required String mode}) =>
      _event(AnalyticsEvents.themeChanged, {'mode': mode});

  /// [api] 為固定代碼（例如 `bus_daily_timetable`），不可傳入 URL。
  static Future<void> logApiError({
    required String api,
    required String category,
  }) =>
      _event(AnalyticsEvents.apiError, {'api': api, 'category': category});

  static Future<void> logFeatureError({
    required String feature,
    required String category,
  }) =>
      _event(AnalyticsEvents.appFeatureError,
          {'feature': feature, 'category': category});

  static Future<void> _event(String name, Map<String, Object> parameters) {
    return _log(() => _analytics.logEvent(
          name: name,
          parameters: {
            for (final entry in parameters.entries)
              entry.key: entry.value is String
                  ? _clip(entry.value as String)
                  : entry.value,
          },
        ));
  }

  /// Firebase 限制參數值最長 100 字元。
  static String _clip(String value) =>
      value.length > 100 ? value.substring(0, 100) : value;

  /// 結果數以區間記錄，避免高基數維度。
  static String _bucket(int count) {
    if (count <= 0) return '0';
    if (count <= 5) return '1-5';
    if (count <= 20) return '6-20';
    return '20+';
  }

  /// 統計失敗不應影響 App 原本的功能。
  static Future<void> _log(
      Future<void> Function() action,
      ) async {
    try {
      // Firebase 未初始化（初始化失敗或測試環境）時直接略過。
      if (Firebase.apps.isEmpty) return;
      await action();
    } catch (error) {
      // 正式環境可接入受控的除錯紀錄。
      // 不要將個人資訊或完整查詢內容寫入日誌。
    }
  }
}

/// Analytics 事件名稱統一管理（snake_case，<= 40 字元）。
class AnalyticsEvents {
  AnalyticsEvents._();

  static const cityChanged = 'city_changed';
  static const busRouteSearch = 'bus_route_search';
  static const busStopView = 'bus_stop_view';
  static const busScheduleView = 'bus_schedule_view';
  static const transitRouteSearch = 'transit_route_search';
  static const navigationStart = 'navigation_start';
  static const themeChanged = 'theme_changed';
  static const apiError = 'api_error';
  static const appFeatureError = 'app_feature_error';

  static const all = [
    cityChanged,
    busRouteSearch,
    busStopView,
    busScheduleView,
    transitRouteSearch,
    navigationStart,
    themeChanged,
    apiError,
    appFeatureError,
  ];
}
