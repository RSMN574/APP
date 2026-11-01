import 'dart:convert';

import '../../../database/get_data.dart';
import '../../../database/mrt/get_mrt_info.dart';
import '../../../models/mrt_station.dart';
import '../../bus/data/get_bus_time.dart';
import '../../bus/data/get_station_info.dart';
import '../../bus/model/bus_route_model.dart';
import '../../bus/model/bus_station_model.dart';

/// 附近站點資料來源：公車 / 捷運 / 臺鐵附近站點，以及公車站牌詳細資料。
///
/// 只負責呼叫既有資料來源，不依賴 BuildContext、Provider 或地圖 SDK。
class NearbyStationService {
  const NearbyStationService();

  // ── 附近站點 ─────────────────────────────────────────

  Future<List<BusStationInfo>> fetchNearbyBusStations(
    double latitude,
    double longitude,
  ) {
    return getNearStation(Uri.encodeComponent('$latitude,$longitude'));
  }

  Future<List<MRTStation>> fetchNearbyMetroStations(
    double latitude,
    double longitude,
  ) {
    return getNearMRTStation(Uri.encodeComponent('$latitude,$longitude'));
  }

  Future<List<dynamic>> fetchNearbyTrainStations(
    double latitude,
    double longitude,
  ) {
    return getNearTrainStation(latitude, longitude);
  }

  // ── 公車站牌詳細資料 ─────────────────────────────────

  /// 依站名取得同一站牌群組的站位資料（含各方向 StationID）。
  Future<List<Map<String, dynamic>>> fetchBusStopGroup(
    String stopName,
    String city,
  ) async {
    return await GetBusStopInfo(stopName: stopName, city: city);
  }

  /// 依站位 ID 取得途經路線的預估到站資料。
  Future<List<Map<String, dynamic>>> fetchStationArrivals(
    List<String> stationIds,
    String city,
  ) async {
    return List<Map<String, dynamic>>.from(
      await fetchStationInfo(stationIds, city),
    );
  }

  /// 以路線名稱（Zh_tw）批次取得路線基本資料，回傳 `路線名稱 → 路線資料`。
  Future<Map<String, Map<String, dynamic>>> fetchRoutesByNames(
    Iterable<String> routeNames, {
    String city = 'Taichung',
  }) async {
    final names = routeNames.where((n) => n.isNotEmpty).toSet();
    final cache = <String, Map<String, dynamic>>{};
    if (names.isEmpty) return cache;

    try {
      final nameList = names.map((n) => "'${_escapeSql(n)}'").join(',');
      final query = """
SELECT *
FROM Bus.bus_route
WHERE City = '${_escapeSql(city)}'
  AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) IN ($nameList)
""";

      final results = await mysqlSelect(query);
      for (final result in results) {
        final name = _routeNameZh(result['RouteName']);
        if (name != null && name.isNotEmpty) {
          cache[name] = Map<String, dynamic>.from(result as Map);
        }
      }
    } catch (_) {
      // 批次查詢失敗時，逐一路線查詢。
      for (final name in names) {
        try {
          final escaped = _escapeSql(name);
          final query = """
SELECT * FROM Bus.Bus_Taichung_Route
WHERE RouteName LIKE '%"Zh_tw": "$escaped"%'
OR JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$escaped'
""";
          final results = await mysqlSelect(query);
          if (results.isNotEmpty) {
            cache[name] = Map<String, dynamic>.from(results.first as Map);
          }
        } catch (_) {}
      }
    }
    return cache;
  }

  /// 依 RouteID 取得單一路線。
  Future<BusRoute> fetchRouteById({
    required String city,
    required String routeId,
  }) async {
    final raw = await getBusRouteWithId(city: city, routeId: routeId);
    return BusRoute.fromJson(raw);
  }

  // ── helpers ──────────────────────────────────────────

  static String? _routeNameZh(dynamic field) {
    if (field is Map) return field['Zh_tw'] as String?;
    if (field is String) {
      try {
        final parsed = json.decode(field) as Map<String, dynamic>;
        return parsed['Zh_tw'] as String?;
      } catch (_) {
        return field;
      }
    }
    return null;
  }

  static String _escapeSql(String input) =>
      input.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
}
