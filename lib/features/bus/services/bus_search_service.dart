import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';

import '../../../database/sql/app_database.dart';


/// 純查詢服務：不依賴 BuildContext，方便測試、跨頁重用與邏輯抽離。
class BusSearchService {
  const BusSearchService._();

  /// 公車模組支援的城市 id 白名單（用於表名防護）。
  static const Set<String> allowedCityIds = {
    'Taichung', 'Taipei', 'NewTaipei', 'Taoyuan',
    'Tainan', 'Kaohsiung', 'Keelung', 'Hsinchu', 'InterCity',
  };

  /// 路線搜尋：DB + 記憶體合併、去重、精確符合優先。
  static Future<List<BusRoute>> searchRoutes({
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

    final fromMemory = memoryRoutes.where((r) {
      final name = languageCode == 'en' ? r.routeEn : r.routeZh;
      return name.contains(keyword);
    });

    final seen = <String>{};
    final merged = <BusRoute>[];
    for (final r in [...fromDb, ...fromMemory]) {
      if (seen.add('${r.city}|${r.routeID}')) merged.add(r);
    }

    merged.sort((a, b) {
      final an = languageCode == 'en' ? a.routeEn : a.routeZh;
      final bn = languageCode == 'en' ? b.routeEn : b.routeZh;
      final aExact = an == keyword;
      final bExact = bn == keyword;
      if (aExact != bExact) return aExact ? -1 : 1;
      return an.compareTo(bn);
    });

    return merged;
  }

  /// 站牌搜尋：表名白名單 + LIKE 轉義（在 mysqlSelect 尚未支援參數化前的緩解）。
  /// 待 get_data.dart 支援參數化後，可直接替換為 prepared statement。
  static Future<List<String>> searchStops({
    required String cityId,
    required String keyword,
    required String languageCode,
  }) async {
    if (keyword.isEmpty || !allowedCityIds.contains(cityId)) return const [];

    final jsonPath = languageCode == 'en' ? r'$.En' : r'$.Zh_tw';
    final escaped = _escapeLikeInput(keyword);

    final rawData = await mysqlSelect(
      "SELECT StationName FROM Bus.Bus_${cityId}_Stop "
          "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '$jsonPath')) "
          "LIKE '%$escaped%'",
    );

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

  /// 取得單一路線詳細資料（給 BusTime 導航用）。
  static Future<Map<String, dynamic>?> fetchRouteDetail({
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

  static String _escapeLikeInput(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_')
      .replaceAll("'", r"\'");
}