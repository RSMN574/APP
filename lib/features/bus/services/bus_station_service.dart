import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart';

import '../../../core/utils/convert.dart';
import 'bus_route_service.dart';

/// 站牌資料服務（MySQL / 後端）。
class BusStationService {
  const BusStationService();

  /// 站牌名稱搜尋：表名白名單 + LIKE 轉義（在 mysqlSelect 尚未支援參數化前的緩解）。
  Future<List<String>> searchStopNames({
    required String city,
    required String keyword,
    required String languageCode,
  }) async {
    if (keyword.isEmpty || !BusRouteService.allowedCityIds.contains(city)) {
      return const [];
    }


    final escaped = _escapeLikeInput(keyword);
// 1. city 轉小寫
    final cityLower = city.toLowerCase();

// 2. 從 kCityAuthorityCodes() 取得對應的 LocationCityCode
//    假設 kCityAuthorityCodes() 回傳 Map<String, List<String>> 或 Map<String, String>
    final cityCode = kCityAuthorityCodes[cityLower];
    final rawData;
    print(city);
if(city=="InterCity"){
  rawData = await mysqlSelect(
    "SELECT * FROM Bus.Bus_InterCity_Station "
        "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) "
        "LIKE '%$escaped%'",
  );
}else{
  // 3. 套進 LocationCityCode 做搜尋
  rawData = await mysqlSelect(
    "SELECT StationName FROM Bus.bus_station "
        "WHERE LocationCityCode='$cityCode' "
        "AND JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) "
        "LIKE '%$escaped%'",
  );

}

    return _collectStopNames(rawData, keyword, languageCode);
  }

  /// 國道/台灣好行（TaiwanTrip）站牌名稱搜尋。
  Future<List<String>> searchTaiwanTripStopNames(String keyword) async {
    final rawData = await mysqlSelect(
      "SELECT StationName FROM Bus.Bus_TaiwanTrip_Stop "
      "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) "
      "LIKE '%${_escapeLikeInput(keyword)}%'",
    );

    return _collectStopNames(rawData, keyword, 'zh');
  }

  /// 依站牌名稱取得站位資訊（含 StationID）。
  Future<List<dynamic>> fetchStopInfo({
    required String stopName,
    required String city,
  }) async {
    return await GetBusStopInfo(stopName: stopName, city: city);
  }

  List<String> _collectStopNames(
    List<dynamic> rawData,
    String keyword,
    String languageCode,
  ) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in rawData) {
      try {
        final decoded = json.decode(item['StationName'] as String);
        final name = (languageCode == 'en'
            ? decoded['En']
            : decoded['Zh_tw']) as String?;
        if (name == null || name.isEmpty) continue;
        if (seen.add(name)) out.add(name);
      } catch (e) {
        debugPrint('invalid StationName json: $e');
      }
    }
    out.sort((a, b) {
      if (a == keyword) return -1;
      if (b == keyword) return 1;
      return a.compareTo(b);
    });
    return out;
  }

  static String _escapeLikeInput(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_')
      .replaceAll("'", r"\'");
}
