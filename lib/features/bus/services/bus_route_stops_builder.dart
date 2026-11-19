import 'dart:convert';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';

import 'bus_stop_time_formatter.dart';

/// 將「路線站序（StopOfRoute）」與「預估到站（EstimatedTimeOfArrival）」
/// 合併成畫面使用的站序列表。
///
/// 原本寫在 `bus_time_page.dart` 的 State 內（依賴 BuildContext），
/// 抽出成純函式後可單元測試（QA 架構審查 B1）。
class BusRouteStopsBuilder {
  const BusRouteStopsBuilder._();

  /// 車牌只在「該車最靠近的站」且預估 < 180 秒時顯示。
  static const int plateVisibleSeconds = 180;

  static List<Map<String, dynamic>> build({
    required int direction,
    required List<dynamic> busTimeData,
    required List<Map<String, dynamic>> routeStopsData,
    required AppLocalizations l10n,
    required bool isEnglish,
    required DateTime now,
    List<dynamic>? highlightStops,
    int? highlightDirection,
  }) {
    final result = <Map<String, dynamic>>[];

    Map<String, dynamic>? targetRouteStop;
    for (final item in routeStopsData) {
      if (_direction(item['Direction']) == direction) {
        targetRouteStop = item;
        break;
      }
    }
    if (targetRouteStop == null || targetRouteStop['Stops'] == null) {
      return result;
    }

    final List<dynamic> stopData;
    try {
      final raw = targetRouteStop['Stops'];
      final decoded = raw is String ? json.decode(raw) : raw;
      if (decoded is! List) return result;
      stopData = decoded;
    } catch (_) {
      return result;
    }

    final dirBusTimeData = busTimeData
        .where((s) => s is Map && _direction(s['Direction']) == direction)
        .toList();

    final stopArrivals = <String, StopArrival>{};
    // PlateNumb -> (該車最快到達的 stopUID, 最小 EstimateTime 秒)
    final bestByPlate = <String, MapEntry<String, num>>{};

    for (final stop in stopData) {
      if (stop is! Map) continue;
      final stopUID = stop['StopUID']?.toString() ?? '';
      if (stopUID.isEmpty) continue;

      Map<String, dynamic>? match;
      for (final s in dirBusTimeData) {
        if ((s as Map)['StopUID']?.toString() == stopUID) {
          match = Map<String, dynamic>.from(s);
          break;
        }
      }
      final arrival =
          BusStopTimeFormatter.format(stopTime: match, l10n: l10n, now: now);
      stopArrivals[stopUID] = arrival;

      for (final e in parseEstimates(arrival.estimatesJson)) {
        final plate = e['PlateNumb']?.toString().trim() ?? '';
        final sec = num.tryParse(e['EstimateTime']?.toString() ?? '');
        if (plate.isEmpty || sec == null || sec < 0) continue;
        final prev = bestByPlate[plate];
        if (prev == null || sec < prev.value) {
          bestByPlate[plate] = MapEntry(stopUID, sec);
        }
      }
    }

    for (final stop in stopData) {
      if (stop is! Map) continue;
      final stopName = localizedText(stop['StopName'], isEnglish: false);
      final displayStopName =
          localizedText(stop['StopName'], isEnglish: isEnglish);
      final stopUID = stop['StopUID']?.toString() ?? '';
      final arrival = stopArrivals[stopUID];
      if (arrival == null) continue;

      final isHighlighted = highlightStops != null &&
          highlightDirection == direction &&
          highlightStops.contains(stopName);

      var displayPlate = '';
      num? bestSec;
      bestByPlate.forEach((plate, entry) {
        if (entry.key == stopUID && entry.value < plateVisibleSeconds) {
          if (bestSec == null || entry.value < bestSec!) {
            bestSec = entry.value;
            displayPlate = plate;
          }
        }
      });

      result.add({
        'stopName': stopName,
        'displayStopName': displayStopName,
        'nextBusTime': arrival.displayTime,
        'arrivalStatus': arrival.status,
        'PlateNumb': displayPlate,
        'Estimates': arrival.estimatesJson,
        'StopPosition': stop['StopPosition'],
        'StopID': stop['StopID'],
        'StopUID': stopUID,
        'hasLiveData': arrival.hasLiveData,
        'isHighlighted': isHighlighted,
      });
    }
    return result;
  }

  static int? _direction(dynamic d) =>
      d is int ? d : int.tryParse(d?.toString() ?? '');

  /// 取 `{Zh_tw, En}` 名稱；指定語言缺值時回退到另一種語言。
  static String localizedText(dynamic value, {required bool isEnglish}) {
    if (value is! Map) return value?.toString() ?? '';
    final preferred = value[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
    if (preferred.isNotEmpty) return preferred;
    return value[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
  }

  /// 解析 Estimates：支援 List / Map / 合法 JSON / DB 還原的偽 JSON。
  static List<Map<String, dynamic>> parseEstimates(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) return [Map<String, dynamic>.from(raw)];
    if (raw is! String) return [];
    final s = raw.trim();
    if (s.isEmpty) return [];
    try {
      final d = json.decode(s);
      if (d is List) {
        return d
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    // 寬鬆解析偽 JSON：{PlateNumb: 739-U5, EstimateTime: 60, ...}
    final out = <Map<String, dynamic>>[];
    final itemReg = RegExp(r'\{([^{}]*)\}');
    final kvReg = RegExp(r'(\w+)\s*:\s*([^,}]+)');
    for (final m in itemReg.allMatches(s)) {
      final map = <String, dynamic>{};
      for (final kv in kvReg.allMatches(m.group(1)!)) {
        final k = kv.group(1)!.trim();
        final v = kv.group(2)!.trim();
        map[k] = v == 'null'
            ? null
            : (v == 'true'
                ? true
                : (v == 'false' ? false : (num.tryParse(v) ?? v)));
      }
      if (map.isNotEmpty) out.add(map);
    }
    return out;
  }
}
