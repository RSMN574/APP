
import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';

import '../../../firebase/analytics_service.dart';
import '../data/bus_repository.dart';
import '../model/bus_route_model.dart';
import '../model/bus_stop_info_result.dart';

class BusProvider extends ChangeNotifier {
  BusProvider({
    BusRepository? repository,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _repository = repository ?? const BusRepository(),
        _cacheTtl = cacheTtl;

  final BusRepository _repository;
  final Duration _cacheTtl;

  final Map<String, _CachedRoutes> _routeCache = {};
  final Map<String, Future<List<BusRoute>>> _pendingRequests = {};

  List<BusRoute> _routes = const [];
  Object? _error;
  String? _city;

  int _cacheGeneration = 0;
  bool _disposed = false;

  List<BusRoute> get routes => _routes;
  Object? get error => _error;
  String? get city => _city;

  bool get isLoading =>
      _city != null && _pendingRequests.containsKey(_city);

  // ============================================================
  // Routes
  // ============================================================

  Future<List<BusRoute>> loadRoutes(
      String city, {
        bool force = false,
      }) {
    if (_disposed) {
      return Future.error(
        StateError('BusProvider has been disposed'),
      );
    }

    _city = city;
    _error = null;

    final cached = _routeCache[city];

    if (!force &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      _routes = cached.routes;
      _notifyListeners();
      return Future.value(_routes);
    }

    // 相同城市合併重複請求。
    final pending = _pendingRequests[city];

    if (pending != null) {
      _notifyListeners();
      return pending;
    }

    final generation = _cacheGeneration;

    late final Future<List<BusRoute>> request;

    request = _loadRoutes(city, generation).whenComplete(() {
      if (identical(_pendingRequests[city], request)) {
        _pendingRequests.remove(city);
      }

      _notifyListeners();
    });

    _pendingRequests[city] = request;

    _notifyListeners();

    return request;
  }

  Future<List<BusRoute>> _loadRoutes(
      String city,
      int generation,
      ) async {
    try {
      final result = await _repository.fetchRoutes(city);

      _logAnalytics(
        success: true,
      );

      final routes = List<BusRoute>.unmodifiable(result);

      if (!_disposed && generation == _cacheGeneration) {
        _routeCache[city] = _CachedRoutes(
          routes,
          DateTime.now(),
        );

        if (_city == city) {
          _routes = routes;
          _error = null;
        }
      }

      return routes;
    } catch (error) {
      _logAnalytics(
        success: false,
        errorType: error.runtimeType.toString(),
      );

      if (!_disposed &&
          generation == _cacheGeneration &&
          _city == city) {
        _error = error;
        _routes = const [];
      }

      rethrow;
    }
  }

  // ============================================================
  // TDX A2：預估到站時間
  // ============================================================

  Future<List<dynamic>> fetchEstimatedArrivals({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return _repository.fetchEstimatedArrivals(
      routeName: routeName,
      city: city,
      routeID: routeID,
    );
  }

  // ============================================================
  // TDX A1：即時車輛位置
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchRealtimePositions({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return _repository.fetchRealtimePositions(
      routeName: routeName,
      city: city,
      routeID: routeID,
    );
  }

  // ============================================================
  // TDX：路線形狀
  // ============================================================

  Future<List<dynamic>> fetchRouteShape({
    required String city,
    required String routeName,
    required String routeID,
  }) {
    return _repository.fetchRouteShape(
      city: city,
      routeName: routeName,
      routeID: routeID,
    );
  }

  // ============================================================
  // 歷史動態
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchHistory({
    required String city,
    required String routeId,
    required int count,
  }) {
    return _repository.fetchHistory(
      city: city,
      routeId: routeId,
      count: count,
    );
  }

  // ============================================================
  // 路線詳細資料 / 站序
  // ============================================================

  Future<BusRoute> fetchRouteById({
    required String city,
    required String routeId,
  }) {
    return _repository.fetchRouteById(city: city, routeId: routeId);
  }

  Future<List<Map<String, dynamic>>> fetchRouteStops({
    required String city,
    required String routeId,
  }) {
    return _repository.fetchRouteStops(city: city, routeId: routeId);
  }

  Future<Map<String, dynamic>?> fetchRouteDetail({
    required String cityId,
    required String routeName,
    required String jsonField,
  }) {
    return _repository.fetchRouteDetail(
      cityId: cityId,
      routeName: routeName,
      jsonField: jsonField,
    );
  }

  Future<dynamic> fetchRawRoutes(String city) {
    return _repository.fetchRawRoutes(city);
  }

  Future<List<Map<String, dynamic>>> fetchRouteNames(String city) {
    return _repository.fetchRouteNames(city);
  }

  Future<Map<String, dynamic>> fetchRouteWithStops({
    required String routeName,
    required String city,
  }) {
    return _repository.fetchRouteWithStops(routeName: routeName, city: city);
  }

  Future<List<dynamic>> fetchTaiwanTripRouteDetail(String routeName) {
    return _repository.fetchTaiwanTripRouteDetail(routeName);
  }

  // ============================================================
  // 搜尋
  // ============================================================

  Future<List<BusRoute>> searchRoutes({
    required String city,
    required String keyword,
    required String languageCode,
    required List<BusRoute> memoryRoutes,
  }) {
    return _repository.searchRoutes(
      city: city,
      keyword: keyword,
      languageCode: languageCode,
      memoryRoutes: memoryRoutes,
    );
  }

  Future<List<String>> searchStops({
    required String cityId,
    required String keyword,
    required String languageCode,
  }) {
    return _repository.searchStops(
      cityId: cityId,
      keyword: keyword,
      languageCode: languageCode,
    );
  }

  Future<List<String>> searchTaiwanTripStops(String keyword) {
    return _repository.searchTaiwanTripStops(keyword);
  }

  // ============================================================
  // 站牌資訊
  // ============================================================

  Future<BusStopInfoResult> loadStopInfo({
    required String stopName,
    required String city,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    return _repository.loadStopInfo(
      stopName: stopName,
      city: city,
      l10n: l10n,
      now: now,
    );
  }

  // ============================================================
  // Cache
  // ============================================================

  void clearCache() {
    _cacheGeneration++;

    _routeCache.clear();
    _pendingRequests.clear();

    _routes = const [];
    _error = null;

    _notifyListeners();
  }

  // ============================================================
  // Analytics
  // ============================================================

  Future<void> _logAnalytics({
    required bool success,
    String? errorType,
  }) async {
    try {
      await AppAnalytics.logQueryResult(
        feature: 'bus_routes',
        success: success,
        errorType: errorType,
      );
    } catch (error) {
      debugPrint('[BusProvider] Analytics failed: $error');
    }
  }

  // ============================================================
  // Lifecycle
  // ============================================================

  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    _pendingRequests.clear();
    _routeCache.clear();

    super.dispose();
  }
}

class _CachedRoutes {
  const _CachedRoutes(
      this.routes,
      this.cachedAt,
      );

  final List<BusRoute> routes;
  final DateTime cachedAt;
}
