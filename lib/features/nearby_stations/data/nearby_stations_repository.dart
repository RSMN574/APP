import '../../../database/sql/favorite_feature.dart';
import '../../../models/mrt_station.dart';
import '../../bus/model/bus_route_model.dart';
import '../../bus/model/bus_station_model.dart';
import '../models/nearby_station_result.dart';
import '../services/nearby_station_filter_service.dart';
import '../services/nearby_station_service.dart';

/// 附近站點的唯一資料入口。
///
/// 整合 [NearbyStationService]（資料來源）、[NearbyStationFilterService]
/// （座標驗證 / 去重 / 正規化）與收藏（SQLite）。
///
/// 不依賴 BuildContext、Widget 或 Provider；定位座標由呼叫端傳入
/// （定位由 App 層的 LocationProvider 負責）。
class NearbyStationsRepository {
  const NearbyStationsRepository({
    NearbyStationService stationService = const NearbyStationService(),
    NearbyStationFilterService filterService =
        const NearbyStationFilterService(),
  })  : _stations = stationService,
        _filter = filterService;

  final NearbyStationService _stations;
  final NearbyStationFilterService _filter;

  /// 座標是否可用於查詢附近站點。
  static bool isValidLocation(double? latitude, double? longitude) =>
      NearbyStationFilterService.isValidCoordinate(latitude, longitude);

  // ── 附近站點 ─────────────────────────────────────────

  /// 附近公車站牌（已排除無效座標並去重）。
  Future<List<BusStationInfo>> fetchNearbyBusStations({
    required double latitude,
    required double longitude,
  }) async {
    if (!isValidLocation(latitude, longitude)) return const [];
    final stations = await _stations.fetchNearbyBusStations(
      latitude,
      longitude,
    );

    return _filter.cleanBusStations(stations);
  }

  /// 附近捷運站（原始模型，供列表卡片使用）。
  Future<List<MRTStation>> fetchNearbyMetroStations({
    required double latitude,
    required double longitude,
  }) async {
    if (!isValidLocation(latitude, longitude)) return const [];
    return _stations.fetchNearbyMetroStations(latitude, longitude);
  }

  /// 附近臺鐵站（原始資料列，供列表卡片使用）。
  Future<List<dynamic>> fetchNearbyTrainStations({
    required double latitude,
    required double longitude,
  }) async {
    if (!isValidLocation(latitude, longitude)) return const [];
    return _stations.fetchNearbyTrainStations(latitude, longitude);
  }

  /// 依交通類型取得整理完成的附近站點（地圖 Marker 用）。
  Future<List<NearbyStationResult>> fetchNearbyStations({
    required double latitude,
    required double longitude,
    NearbyStationType type = NearbyStationType.bus,
  }) async {
    switch (type) {
      case NearbyStationType.bus:
        return _filter.busResults(await fetchNearbyBusStations(
          latitude: latitude,
          longitude: longitude,
        ));
      case NearbyStationType.metro:
        final stations = await fetchNearbyMetroStations(
          latitude: latitude,
          longitude: longitude,
        );
        return _filter.metroResults(
          stations.map((s) => s.toJson()).toList(),
        );
      case NearbyStationType.train:
        return _filter.trainResults(await fetchNearbyTrainStations(
          latitude: latitude,
          longitude: longitude,
        ));
    }
  }

  /// 將已取得的捷運站 / 臺鐵站原始資料轉為地圖用結果（不重新請求）。
  List<NearbyStationResult> metroResultsOf(List<MRTStation> stations) =>
      _filter.metroResults(stations.map((s) => s.toJson()).toList());

  List<NearbyStationResult> trainResultsOf(List<dynamic> rows) =>
      _filter.trainResults(rows);

  List<NearbyStationResult> busResultsOf(List<BusStationInfo> stations) =>
      _filter.busResults(stations);

  // ── 公車站牌詳細資料 ─────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBusStopGroup(
    String stopName,
    String city,
  ) {
    return _stations.fetchBusStopGroup(stopName, city);
  }

  Future<List<Map<String, dynamic>>> fetchStationArrivals(
    List<String> stationIds,
    String city,
  ) {
    return _stations.fetchStationArrivals(stationIds, city);
  }

  Future<Map<String, Map<String, dynamic>>> fetchRoutesByNames(
    Iterable<String> routeNames, {
    String city = 'Taichung',
  }) {
    return _stations.fetchRoutesByNames(routeNames, city: city);
  }

  Future<BusRoute> fetchRouteById({
    required String city,
    required String routeId,
  }) {
    return _stations.fetchRouteById(city: city, routeId: routeId);
  }

  // ── 收藏（SQLite）────────────────────────────────────

  /// 加入收藏站牌。回傳碼沿用 favorite_feature：100 成功、-1 已存在、200 失敗。
  Future<dynamic> addFavoriteStop({
    required String stopName,
    required String city,
  }) async {
    final dbHelper = favorite_feature();
    return await dbHelper.addFavoriteStop(stopName: stopName, city: city);
  }
}
