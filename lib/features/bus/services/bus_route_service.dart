import 'dart:convert';

import 'package:com.rsmn574.app/database/get_data.dart';

import '../model/bus_route_model.dart';

/// 公車路線資料服務（MySQL / 後端）。
///
/// 只負責遠端路線資料的取得與整理，不依賴 BuildContext、Provider 或 SQLite。
/// UI 層請透過 BusProvider → BusRepository 使用。
class BusRouteService {
  const BusRouteService();

  /// 公車模組支援的城市 id 白名單（用於表名防護）。
  static const Set<String> allowedCityIds = {
    'Taichung',
    'Taipei',
    'NewTaipei',
    'Taoyuan',
    'Tainan',
    'Kaohsiung',
    'Keelung',
    'Hsinchu',
    'InterCity',
  };

  /// 取得指定縣市的遠端路線。
  Future<List<BusRoute>> fetchRoutes(String city) async {
    return await getBusRoute(city: city);
  }

  /// 取得遠端原始路線資料（不轉型），給仍使用 Map 結構的頁面使用。
  Future<dynamic> fetchRawRoutes(String city) async {
    return await getBusRoute(city: city);
  }

  /// 依 RouteID 取得單一路線（回傳可直接交給 `BusRoute.fromJson` 的 Map）。
  Future<BusRoute> fetchRouteById({
    required String city,
    required String routeId,
  }) async {
    final raw = await getBusRouteWithId(city: city, routeId: routeId);
    return BusRoute.fromJson(raw);
  }

  /// 取得路線的站序資料。
  Future<List<Map<String, dynamic>>> fetchRouteStops({
    required String city,
    required String routeId,
  }) async {
    return await getBusStopOfRoute(city: city, routeId: routeId);
  }

  /// 取得單一路線詳細資料（給 BusTime 導航用）。
  Future<Map<String, dynamic>?> fetchRouteDetail({
    required String cityId,
    required String routeName,
    required String jsonField, // 'Zh_tw' 或 'En'
  }) async {
    if (!allowedCityIds.contains(cityId) || routeName.isEmpty) return null;

    final escapedRouteName = routeName.replaceAll("'", r"\'");
    final result = await mysqlSelect("""
SELECT *
FROM Bus.bus_route
WHERE City = '$cityId'
AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.$jsonField')) = '$escapedRouteName'
""");
    if (result.isEmpty) return null;
    return Map<String, dynamic>.from(result[0] as Map);
  }

  /// 取得縣市的路線名稱（Zh_tw）與 RouteID，給路線規劃選單使用。
  Future<List<Map<String, dynamic>>> fetchRouteNames(String city) async {
    final result = await mysqlSelect(
      "SELECT RouteName,RouteID FROM Bus.bus_route "
      "WHERE City = '${city.replaceAll("'", r"\'")}'",
    );

    final routes = <Map<String, dynamic>>[];
    for (final row in result) {
      routes.add({
        'route': json.decode(row['RouteName'])['Zh_tw'],
        'id': row['RouteID'],
      });
    }
    return routes;
  }

  /// 取得指定城市路線基本資訊與兩個方向的站序（路線規劃用）。
  Future<Map<String, dynamic>> fetchRouteWithStops({
    required String routeName,
    required String city,
  }) async {
    final name = routeName.replaceAll("'", r"\'");
    final safeCity = city.replaceAll("'", r"\'");
    final routeQuery = await mysqlSelect(
      "SELECT * FROM Bus.bus_route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$name' AND City = '$safeCity';",
    );
    final stopsQuery = await mysqlSelect(
      "SELECT Stops FROM Bus.stopOfRoute WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$name' AND City = '$safeCity' ;",
    );
    return {'route': routeQuery[0], 'stops': stopsQuery};
  }

  /// 以路線名稱批次查詢路線資料（站牌資訊補全用）。
  ///
  /// [names] 需為未跳脫的 Zh_tw 路線名稱；[city] 為空或 `all` 時不限縣市。
  Future<List<Map<String, dynamic>>> fetchRoutesByNames({
    required Iterable<String> names,
    required String city,
  }) async {
    final nameList = names.map(_escapeSql).map((n) => "'$n'").join(',');
    if (nameList.isEmpty) return const [];

    final cityFilter = (city.isEmpty || city == 'all')
        ? ''
        : "AND City = '${_escapeSql(city)}'";
    final results = await mysqlSelect("""
SELECT *
FROM Bus.bus_route
WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) IN ($nameList)
$cityFilter
""");
    return results
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  /// 以單一路線名稱查詢路線資料（批次查詢失敗時的 fallback）。
  Future<Map<String, dynamic>?> fetchRouteByName({
    required String name,
    required String city,
  }) async {
    final cityFilter = (city.isEmpty || city == 'all')
        ? ''
        : "AND City = '${_escapeSql(city)}'";
    final results = await mysqlSelect("""
SELECT *
FROM Bus.bus_route
WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${_escapeSql(name)}'
$cityFilter
LIMIT 1
""");
    if (results.isEmpty || results.first is! Map) return null;
    return Map<String, dynamic>.from(results.first as Map);
  }

  /// 國道/台灣好行路線詳細資料（TaiwanTrip）。
  Future<List<dynamic>> fetchTaiwanTripRouteDetail(String routeName) async {
    final name = routeName.replaceAll("'", r"\'");
    return await mysqlSelect(
      "SELECT * FROM Bus.Bus_TaiwanTrip_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))='$name'",
    );
  }

  static String _escapeSql(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
