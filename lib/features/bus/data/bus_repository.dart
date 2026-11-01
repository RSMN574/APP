import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';

import '../../../database/sql/app_database.dart';
import '../model/bus_route_model.dart';
import '../model/bus_stop_info_result.dart';
import '../services/bus_arrival_service.dart';
import '../services/bus_realtime_service.dart';
import '../services/bus_route_service.dart';
import '../services/bus_search_service.dart';
import '../services/bus_shape_service.dart';
import '../services/bus_station_service.dart';
import '../services/bus_stop_info_service.dart';

/// 公車資料 Repository
///
/// Bus 模組統一資料入口，整合：
/// - SQLite：本地路線快取（BusRouteDb / AppDatabase）
/// - [BusRouteService]：MySQL / 後端路線資料
/// - [BusRealtimeService]：TDX A1 即時車輛位置、歷史動態
/// - [BusArrivalService]：TDX A2 預估到站時間
/// - [BusShapeService]：路線形狀
/// - [BusStationService]：站牌資料
///
/// 不依賴 BuildContext、Widget 或 Provider。
/// Provider 只能呼叫本類別，不得直接存取 Service 或 Database。
class BusRepository {
  const BusRepository({
    BusRouteService routeService = const BusRouteService(),
    BusRealtimeService realtimeService = const BusRealtimeService(),
    BusArrivalService arrivalService = const BusArrivalService(),
    BusShapeService shapeService = const BusShapeService(),
    BusStationService stationService = const BusStationService(),
    BusStopInfoService stopInfoService = const BusStopInfoService(),
  })  : _routes = routeService,
        _realtime = realtimeService,
        _arrivals = arrivalService,
        _shapes = shapeService,
        _stations = stationService,
        _stopInfo = stopInfoService;

  final BusRouteService _routes;
  final BusRealtimeService _realtime;
  final BusArrivalService _arrivals;
  final BusShapeService _shapes;
  final BusStationService _stations;
  final BusStopInfoService _stopInfo;

  static const List<String> allCities = [
    'Taichung',
    'Taipei',
    'NewTaipei',
    'Taoyuan',
    'Tainan',
    'Kaohsiung',
    'Keelung',
    'Hsinchu',
    'InterCity',
  ];

  /// 是否為公車模組支援的城市 id。
  static bool isSupportedCity(String cityId) =>
      BusRouteService.allowedCityIds.contains(cityId);

  // ============================================================
  // Route：路線資料
  // ============================================================

  /// 取得指定縣市路線。
  ///
  /// 本地快取優先：SQLite 有資料就直接使用，沒有才向遠端取得。
  Future<List<BusRoute>> fetchRoutes(String city) async {
    try {
      await _logLocalRouteStats();

      final localRoutes = await _fetchLocalRoutes(city);

      if (localRoutes.isNotEmpty) {
        return localRoutes;
      }

      return await _routes.fetchRoutes(city);
    } catch (error, stackTrace) {
      _log('fetchRoutes($city)', error, stackTrace);

      // 本地資料庫發生錯誤時，嘗試遠端資料來源。
      try {
        return await _routes.fetchRoutes(city);
      } catch (remoteError, remoteStackTrace) {
        _log(
          'fetchRoutes remote fallback ($city)',
          remoteError,
          remoteStackTrace,
        );
        rethrow;
      }
    }
  }

  /// 取得 SQLite 路線資料。
  Future<List<BusRoute>> _fetchLocalRoutes(String city) async {
    if (city != 'all') {
      return BusRouteDb.instance.getByCity(city);
    }

    final results = await Future.wait(
      allCities.map((c) => BusRouteDb.instance.getByCity(c)),
    );

    final seen = <String>{};

    return results
        .expand((routes) => routes)
        .where((route) => seen.add('${route.city}|${route.routeID}'))
        .toList();
  }

  /// Debug 模式下輸出各縣市本地路線筆數。
  Future<void> _logLocalRouteStats() async {
    if (!kDebugMode) return;
    try {
      final db = await AppDatabase.instance.database;
      final stats = await db.rawQuery(
        'SELECT city, COUNT(*) AS n FROM bus_route GROUP BY city',
      );
      debugPrint('[db] city stats: $stats');
    } catch (error) {
      debugPrint('[BusRepository] route stats failed: $error');
    }
  }

  /// 取得遠端原始路線資料（不轉型），給仍使用 Map 結構的頁面使用。
  Future<dynamic> fetchRawRoutes(String city) => _routes.fetchRawRoutes(city);

  /// 依 RouteID 取得單一路線。
  Future<BusRoute> fetchRouteById({
    required String city,
    required String routeId,
  }) {
    return _routes.fetchRouteById(city: city, routeId: routeId);
  }

  /// 取得路線的站序資料。
  Future<List<Map<String, dynamic>>> fetchRouteStops({
    required String city,
    required String routeId,
  }) {
    return _routes.fetchRouteStops(city: city, routeId: routeId);
  }

  /// 取得單一路線詳細資料（給 BusTime 導航用）。
  Future<Map<String, dynamic>?> fetchRouteDetail({
    required String cityId,
    required String routeName,
    required String jsonField,
  }) {
    return _routes.fetchRouteDetail(
      cityId: cityId,
      routeName: routeName,
      jsonField: jsonField,
    );
  }

  /// 取得縣市的路線名稱與 RouteID（路線規劃選單用）。
  Future<List<Map<String, dynamic>>> fetchRouteNames(String city) {
    return _routes.fetchRouteNames(city);
  }

  /// 取得路線基本資訊與站序（路線規劃用）。
  Future<Map<String, dynamic>> fetchRouteWithStops({
    required String routeName,
    required String city,
  }) {
    return _routes.fetchRouteWithStops(routeName: routeName, city: city);
  }

  /// 取得台灣好行路線詳細資料。
  Future<List<dynamic>> fetchTaiwanTripRouteDetail(String routeName) {
    return _routes.fetchTaiwanTripRouteDetail(routeName);
  }

  // ============================================================
  // Search：搜尋
  // ============================================================

  /// 路線搜尋：SQLite + 記憶體合併、去重、精確符合優先。
  Future<List<BusRoute>> searchRoutes({
    required String city,
    required String keyword,
    required String languageCode,
    required List<BusRoute> memoryRoutes,
  }) async {
    if (keyword.isEmpty) return const [];

    final fromDb = await BusRouteDb.instance.searchByName(
      city: city,
      keyword: keyword,
      languageCode: languageCode,
    );

    return BusSearchService.mergeRoutes(
      fromDb: fromDb,
      memoryRoutes: memoryRoutes,
      keyword: keyword,
      languageCode: languageCode,
    );
  }

  /// 站牌名稱搜尋。
  Future<List<String>> searchStops({
    required String cityId,
    required String keyword,
    required String languageCode,
  }) {
    return _stations.searchStopNames(
      cityId: cityId,
      keyword: keyword,
      languageCode: languageCode,
    );
  }

  /// 台灣好行站牌名稱搜尋。
  Future<List<String>> searchTaiwanTripStops(String keyword) {
    return _stations.searchTaiwanTripStopNames(keyword);
  }

  // ============================================================
  // Station：站牌資訊
  // ============================================================

  /// 載入站牌（站位）資訊與途經路線的預估到站時間。
  Future<BusStopInfoResult> loadStopInfo({
    required String stopName,
    required String city,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    return _stopInfo.load(
      stopName: stopName,
      city: city,
      l10n: l10n,
      now: now,
    );
  }

  // ============================================================
  // TDX A2：預估到站時間
  // ============================================================

  Future<List<dynamic>> fetchEstimatedArrivals({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return _arrivals.fetchEstimatedArrivals(
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
    return _realtime.fetchPositions(
      routeName: routeName,
      city: city,
      routeID: routeID,
    );
  }

  /// 歷史公車動態。
  Future<List<Map<String, dynamic>>> fetchHistory({
    required String city,
    required String routeId,
    required int count,
  }) {
    return _realtime.fetchHistory(
      city: city,
      routeId: routeId,
      count: count,
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
    return _shapes.fetchShape(
      city: city,
      routeName: routeName,
      routeID: routeID,
    );
  }

  // ============================================================
  // Debug
  // ============================================================

  void _log(
    String method,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    debugPrint('[BusRepository] $method failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
