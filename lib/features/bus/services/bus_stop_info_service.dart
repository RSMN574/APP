import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/features/bus/data/get_station_info.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_stop_time_formatter.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';

/// 一次載入的完整結果。
class BusStopInfoResult {
  final List<String> stationIds;
  final Map<String, List<Map<String, dynamic>>> stopsByStation;
  final DateTime fetchedAt;

  const BusStopInfoResult({
    required this.stationIds,
    required this.stopsByStation,
    required this.fetchedAt,
  });

  bool get isEmpty => stationIds.isEmpty || stopsByStation.isEmpty;

  bool get hasLiveData {
    for (final list in stopsByStation.values) {
      for (final s in list) {
        if (s['hasLiveData'] == true) return true;
      }
    }
    return false;
  }
}

/// 站牌資訊服務：純資料流程，無 UI 依賴（僅需 l10n 產生顯示字串）。
///
/// 修正原版關鍵問題：
/// - O(n²) 重複呼叫 `fetchStationInfo`（原本 for 迴圈每次都撈全部站點）
/// - 硬編碼 `City = 'Taichung'`（改為參數帶入）
/// - 無 SQL 跳脫（route name 加 `_escapeSql`）
/// - 每次 Tab 切換都跑 SQL（改為載入時一次處理）
///
/// ✅ P3：到站時間格式化統一由 `BusStopTimeFormatter` 負責，
///         移除原本重複的 `_formatArrival`。
class BusStopInfoService {
  const BusStopInfoService();

  Future<BusStopInfoResult> load({
    required String stopName,
    required String city,
    required AppLocalizations l10n,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();

    final info = await GetBusStopInfo(stopName: stopName, city: city);
    final stationIds = info
        .map((e) => (e is Map ? e["StationID"] : null)?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (stationIds.isEmpty) {
      return BusStopInfoResult(
        stationIds: const [],
        stopsByStation: const {},
        fetchedAt: effectiveNow,
      );
    }

    // 一次取回所有站位的路線資料（原版每輪迴圈都重新撈）
    final rawStops = await fetchStationInfo(stationIds, city);

    // 補 RouteID / Departure / Destination 等路線資訊
    final enriched = await _enrichRouteInfo(rawStops, city, l10n);

    // 附加到站時間（含 hasLiveData 判斷）
    final withTime = _attachArrivalTimes(enriched, l10n, effectiveNow);

    // 依 stationId 分組
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in withTime) {
      final sid = item["StationID"]?.toString();
      if (sid == null || sid.isEmpty) continue;
      grouped.putIfAbsent(sid, () => []).add(item);
    }

    // 只保留實際存在的 stationId
    final filtered = <String, List<Map<String, dynamic>>>{};
    for (final id in stationIds) {
      filtered[id] = grouped[id] ?? const [];
    }

    return BusStopInfoResult(
      stationIds: stationIds,
      stopsByStation: filtered,
      fetchedAt: effectiveNow,
    );
  }

  // -------------------------------------------------------------------------
  // 路線資訊補全
  // -------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _enrichRouteInfo(
      List<Map<String, dynamic>> stationInfo,
      String city,
      AppLocalizations l10n,
      ) async {
    final routeNames = <String>{};
    for (final item in stationInfo) {
      final name = _routeNameOf(item);
      if (name != null && name.isNotEmpty) routeNames.add(name);
    }

    final routeInfoCache = <String, Map<String, dynamic>>{};
    if (routeNames.isNotEmpty) {
      try {
        final nameList =
        routeNames.map(_escapeSql).map((n) => "'$n'").join(',');
        final cityFilter = (city.isEmpty || city == 'all')
            ? ''
            : "AND City = '${_escapeSql(city)}'";
        final query = """
SELECT *
FROM Bus.bus_route
WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) IN ($nameList)
$cityFilter
""";
        final results = await mysqlSelect(query);
        for (final r in results) {
          if (r is! Map) continue;
          final name = _routeNameOf(Map<String, dynamic>.from(r));
          if (name != null) {
            routeInfoCache[name] = Map<String, dynamic>.from(r);
          }
        }
      } catch (e) {
        debugPrint('BusStopInfoService: batch route query failed: $e');
        // Fallback：逐個查（保持可用性，不再硬編碼城市）
        for (final name in routeNames) {
          try {
            final escaped = _escapeSql(name);
            final cityFilter = (city.isEmpty || city == 'all')
                ? ''
                : "AND City = '${_escapeSql(city)}'";
            final query = """
SELECT *
FROM Bus.bus_route
WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$escaped'
$cityFilter
LIMIT 1
""";
            final results = await mysqlSelect(query);
            if (results.isNotEmpty && results.first is Map) {
              routeInfoCache[name] =
              Map<String, dynamic>.from(results.first as Map);
            }
          } catch (e2) {
            debugPrint('BusStopInfoService: fallback route query failed: $e2');
          }
        }
      }
    }

    final enriched = <Map<String, dynamic>>[];
    for (final item in stationInfo) {
      final routeName = _routeNameOf(item);
      final routeInfo = routeName != null ? routeInfoCache[routeName] : null;

      final result = Map<String, dynamic>.from(item);
      final direction = item["Direction"];
      final isDirection1 = direction == 1;

      result["RouteID"] = routeInfo?["RouteID"]?.toString() ?? l10n.text_321;

      final departureName = routeInfo != null
          ? _safeStationName(routeInfo["DepartureStopNameZh"])
          : null;
      final destinationName = routeInfo != null
          ? _safeStationName(routeInfo["DestinationStopNameZh"])
          : null;
      final departureNameEn = routeInfo?["DepartureStopNameEn"]?.toString();
      final destinationNameEn = routeInfo?["DestinationStopNameEn"]?.toString();

      result["DepartureStopName"] = departureName ?? l10n.text_325;
      result["DestinationStopName"] = destinationName ?? l10n.text_326;

      result["from"] = isDirection1
          ? (destinationName ?? l10n.text_428)
          : (departureName ?? l10n.text_429);
      result["to"] = isDirection1
          ? (departureName ?? l10n.text_429)
          : (destinationName ?? l10n.text_428);
      final toEn = isDirection1 ? departureNameEn : destinationNameEn;
      result["toEn"] = (toEn != null && toEn.trim().isNotEmpty) ? toEn : null;

      enriched.add(result);
    }
    return enriched;
  }

  // -------------------------------------------------------------------------
  // 到站時間
  // -------------------------------------------------------------------------

  /// ✅ P3：改為呼叫 `BusStopTimeFormatter.format`，與 bus_time_page 共用同一份邏輯。
  List<Map<String, dynamic>> _attachArrivalTimes(
      List<Map<String, dynamic>> stopData,
      AppLocalizations l10n,
      DateTime now,
      ) {
    return stopData.map((stop) {
      final arrival = BusStopTimeFormatter.format(
        stopTime: stop,
        l10n: l10n,
        now: now,
      );
      final result = Map<String, dynamic>.from(stop);
      result["time"] = arrival.displayTime;
      result["color"] = arrival.colorKey;
      result["PlateNumb"] =
      arrival.plateNumb.isEmpty ? null : arrival.plateNumb;
      result["hasLiveData"] = arrival.hasLiveData;
      return result;
    }).toList();
  }

  // -------------------------------------------------------------------------
  // 工具
  // -------------------------------------------------------------------------

  String? _routeNameOf(Map<String, dynamic> item) {
    final raw = item["RouteName"];
    if (raw is Map) return raw["Zh_tw"]?.toString();
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('{')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is Map) return decoded["Zh_tw"]?.toString();
        } catch (_) {}
      }
      return raw;
    }
    return null;
  }

  String? _safeStationName(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      if (s.startsWith('{')) {
        try {
          final decoded = json.decode(s);
          if (decoded is Map) {
            return (decoded["Zh_tw"] ?? decoded["En"] ?? decoded["zh_tw"])
                ?.toString();
          }
        } catch (_) {}
      }
      return s;
    }
    if (value is Map) {
      return (value["Zh_tw"] ?? value["En"] ?? value["zh_tw"])?.toString();
    }
    return value.toString();
  }

  String _escapeSql(String input) => input
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}