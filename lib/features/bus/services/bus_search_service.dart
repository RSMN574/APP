import '../model/bus_route_model.dart';
import 'bus_route_service.dart';

/// 純搜尋邏輯：合併、去重與排序。
///
/// 不存取資料庫或網路；資料由 BusRepository 提供後交給本類別整理。
class BusSearchService {
  const BusSearchService._();

  /// 公車模組支援的城市 id 白名單（用於表名防護）。
  static const Set<String> allowedCityIds = BusRouteService.allowedCityIds;

  /// 合併本地（SQLite）與記憶體路線，去重並讓精確符合優先。
  static List<BusRoute> mergeRoutes({
    required List<BusRoute> fromDb,
    required List<BusRoute> memoryRoutes,
    required String keyword,
    required String languageCode,
  }) {
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
}
