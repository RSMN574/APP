import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/app_error_handler.dart';
import '../../../l10n/app_localizations.dart';
import '../services/bus_direction_resolver.dart';
import '../services/bus_route_stops_builder.dart';

enum BusRouteLoadStatus { loading, loaded, error }

/// 公車路線頁的資料來源（抽象出來方便測試；正式環境由 BusProvider 提供）。
abstract interface class BusRouteDataSource {
  Future<List<Map<String, dynamic>>> fetchRouteStops({
    required String city,
    required String routeId,
  });

  Future<List<dynamic>> fetchEstimatedArrivals({
    required String routeName,
    required String city,
    required String routeID,
  });
}

/// 公車路線頁（BusTime）的 ViewModel（QA 架構審查 B1）。
///
/// 負責：載入站序與預估到站、方向判定、組合站序列表、即時資料自動更新倒數。
/// 頁面只負責渲染、地圖 Marker 與捲動。
class BusRouteViewModel extends ChangeNotifier {
  BusRouteViewModel({
    required BusRouteDataSource dataSource,
    required this.city,
    required this.routeId,
    required this.tdxRouteName,
    required this.hasSubRoutes,
    required this.tabCount,
    this.preferredDirection,
    this.highlightStops,
    this.autoReloadSeconds = 40,
    DateTime Function()? clock,
  })  : _dataSource = dataSource,
        _now = clock ?? DateTime.now,
        remainingSeconds = ValueNotifier(autoReloadSeconds),
        directions = hasSubRoutes ? [1, 0] : [preferredDirection ?? 1];

  final BusRouteDataSource _dataSource;
  final DateTime Function() _now;
  final String city;
  final String routeId;
  final String tdxRouteName;
  final bool hasSubRoutes;
  final int tabCount;
  final int? preferredDirection;
  final List<dynamic>? highlightStops;
  final int autoReloadSeconds;

  /// 倒數秒數（只有倒數 Widget 監聽，避免整頁每秒重建）。
  final ValueNotifier<int> remainingSeconds;

  /// 是否有即時資料並正在自動更新。
  final ValueNotifier<bool> autoReloadOn = ValueNotifier(false);

  /// 自動更新到期時呼叫（頁面在此重新載入並更新地圖）。
  Future<void> Function()? onAutoReload;

  BusRouteLoadStatus _status = BusRouteLoadStatus.loading;
  Object? _error;
  List<int> directions;
  List<List<Map<String, dynamic>>> _stops = const [[], []];
  int? _initialTabIndex;
  bool _initialTabResolved = false;
  int _requestId = 0;
  Timer? _timer;
  bool _disposed = false;

  BusRouteLoadStatus get status => _status;
  Object? get error => _error;
  bool get hasData => _stops.any((s) => s.isNotEmpty);
  List<Map<String, dynamic>> stopsForTab(int tabIndex) =>
      tabIndex < _stops.length ? _stops[tabIndex] : const [];

  /// 第一次載入時依「使用者點選的方向」決定要切到哪個 Tab；只會回傳一次。
  int? takeInitialTabIndex() {
    final value = _initialTabIndex;
    _initialTabIndex = null;
    return value;
  }

  int directionForTab(int tabIndex) =>
      directions[tabIndex.clamp(0, directions.length - 1)];

  /// 載入資料。失敗時若已有資料則保留舊資料（[status] 維持 loaded）並重新拋出，
  /// 讓頁面顯示提示；沒有資料時進入 error 狀態。
  Future<void> load({
    required AppLocalizations l10n,
    required bool isEnglish,
  }) async {
    final requestId = ++_requestId;
    try {
      final routeStops =
          await _dataSource.fetchRouteStops(city: city, routeId: routeId);
      final arrivals = await _dataSource.fetchEstimatedArrivals(
        routeName: tdxRouteName,
        city: city,
        routeID: routeId,
      );
      if (_disposed || requestId != _requestId) return;

      final resolution = BusDirectionResolver.resolve(
        hasSubRoutes: hasSubRoutes,
        tabCount: tabCount,
        routeStopsData: routeStops,
        preferredDirection: preferredDirection,
      );
      directions = resolution.directions;
      if (!_initialTabResolved) {
        _initialTabResolved = true;
        final target = resolution.preferredTabIndex;
        if (target != null && target < tabCount) _initialTabIndex = target;
      }

      final now = _now();
      List<Map<String, dynamic>> build(int direction) =>
          BusRouteStopsBuilder.build(
            direction: direction,
            busTimeData: arrivals,
            routeStopsData: routeStops,
            l10n: l10n,
            isEnglish: isEnglish,
            now: now,
            highlightStops: highlightStops,
            highlightDirection: preferredDirection,
          );
      _stops = [
        build(directions[0]),
        directions.length > 1 ? build(directions[1]) : const [],
      ];
      _status = BusRouteLoadStatus.loaded;
      _error = null;

      final live =
          _stops.any((list) => list.any((s) => s['hasLiveData'] == true));
      autoReloadOn.value = live;
      live ? _restartCountdown() : _stopCountdown();
      _notify();
    } catch (e, st) {
      if (_disposed || requestId != _requestId) return;
      unawaited(AppErrorHandler.recordNonFatal(e, st, feature: 'bus_route'));
      if (hasData) {
        rethrow;
      }
      _status = BusRouteLoadStatus.error;
      _error = e;
      _notify();
    }
  }

  /// 使用者下拉更新後重新開始倒數。
  void restartCountdownIfLive() {
    if (autoReloadOn.value) _restartCountdown();
  }

  void _restartCountdown() {
    _timer?.cancel();
    remainingSeconds.value = autoReloadSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (remainingSeconds.value > 1) {
        remainingSeconds.value -= 1;
      } else {
        remainingSeconds.value = autoReloadSeconds;
        final reload = onAutoReload;
        if (reload != null) unawaited(reload());
      }
    });
  }

  void _stopCountdown() {
    _timer?.cancel();
    _timer = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _timer?.cancel();
    remainingSeconds.dispose();
    autoReloadOn.dispose();
    super.dispose();
  }
}
