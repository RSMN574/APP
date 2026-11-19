/// TDX `BusDailyStopTimeTable`（市區公車每日站別時刻表）資料模型。
///
/// 依官方 OAS 3.0.4（公共運輸-公車 v2）
/// `PTX.Service.DTO.Bus.Specification.V2.BusDailyStopTimeTable`：
/// - 必填：BusDate, RouteUID, RouteID, RouteName, OperatorID, SubRouteUID,
///   SubRouteID, DestinationStopID, Stops, UpdateTime
/// - 可為 null：OperatorCode, SubRouteName, DestinationStopName,
///   Stops[].StopName, Stops[].TimeTables
/// - TimeTables[]：Sequence(int), ArrivalTime/DepartureTime(`HH:mm`),
///   TimeType(int, 0=估算時間, 1=表訂時間), TripID?, IsLowFloor?
///
/// 注意：此資料是「預定班表」，與 EstimatedTimeOfArrival（預估到站）不同，
/// UI 不可把兩者混為一談。
library;

/// 名稱（NameType）：Zh_tw 必填、En 可為 null。
class BusTimetableName {
  const BusTimetableName({required this.zhTw, this.en});

  final String zhTw;
  final String? en;

  static BusTimetableName? tryParse(Object? json) {
    if (json is! Map) return null;
    final zh = _string(json['Zh_tw']);
    if (zh == null || zh.isEmpty) return null;
    return BusTimetableName(zhTw: zh, en: _string(json['En']));
  }

  String localized({required bool english}) =>
      english && en != null && en!.isNotEmpty ? en! : zhTw;

  Map<String, dynamic> toJson() => {'Zh_tw': zhTw, if (en != null) 'En': en};
}

/// 時刻表時間類型。
enum BusTimeType {
  /// 0：估算時間（由業者依發車時刻推算各站時間）
  estimated,

  /// 1：表訂時間
  scheduled,

  /// 未定義的值
  unknown;

  static BusTimeType fromCode(Object? code) {
    final value = code is int ? code : int.tryParse('$code');
    return switch (value) {
      0 => BusTimeType.estimated,
      1 => BusTimeType.scheduled,
      _ => BusTimeType.unknown,
    };
  }

  int get code => switch (this) {
        BusTimeType.estimated => 0,
        BusTimeType.scheduled => 1,
        BusTimeType.unknown => -1,
      };
}

/// `HH:mm` 時間，允許 24:00 以後的跨日時間（例如 `24:30` = 隔日 00:30）。
class BusClockTime implements Comparable<BusClockTime> {
  const BusClockTime(this.minutesFromServiceDayStart);

  /// 從營運日 00:00 起算的分鐘數；跨日時 >= 1440。
  final int minutesFromServiceDayStart;

  static final RegExp _pattern = RegExp(r'^(\d{1,2}):(\d{2})$');

  /// 解析失敗回傳 null（格式錯誤、分鐘 >= 60、小時 > 47）。
  static BusClockTime? tryParse(Object? raw) {
    if (raw is! String) return null;
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (minute >= 60 || hour > 47) return null;
    return BusClockTime(hour * 60 + minute);
  }

  bool get isNextDay => minutesFromServiceDayStart >= 24 * 60;

  /// 顯示用 `HH:mm`（跨日時回到 00~23 點）。
  String format() {
    final normalized = minutesFromServiceDayStart % (24 * 60);
    final h = (normalized ~/ 60).toString().padLeft(2, '0');
    final m = (normalized % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  int compareTo(BusClockTime other) =>
      minutesFromServiceDayStart.compareTo(other.minutesFromServiceDayStart);

  @override
  bool operator ==(Object other) =>
      other is BusClockTime &&
      other.minutesFromServiceDayStart == minutesFromServiceDayStart;

  @override
  int get hashCode => minutesFromServiceDayStart.hashCode;

  @override
  String toString() => format();
}

class BusTimetableEntry {
  const BusTimetableEntry({
    required this.sequence,
    required this.arrival,
    required this.departure,
    required this.timeType,
    this.tripId,
    this.isLowFloor,
  });

  final int sequence;
  final BusClockTime arrival;
  final BusClockTime departure;
  final BusTimeType timeType;
  final String? tripId;
  final bool? isLowFloor;

  /// 欄位缺失或時間格式錯誤時回傳 null（由呼叫端略過並計數）。
  static BusTimetableEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    final arrival = BusClockTime.tryParse(json['ArrivalTime']);
    final departure = BusClockTime.tryParse(json['DepartureTime']);
    // 兩者皆必填；其中一個缺漏時以另一個補上，兩者都無效才捨棄。
    final resolvedArrival = arrival ?? departure;
    final resolvedDeparture = departure ?? arrival;
    if (resolvedArrival == null || resolvedDeparture == null) return null;
    final sequence = json['Sequence'];
    return BusTimetableEntry(
      sequence: sequence is int ? sequence : int.tryParse('$sequence') ?? 0,
      arrival: resolvedArrival,
      departure: resolvedDeparture,
      timeType: BusTimeType.fromCode(json['TimeType']),
      tripId: _string(json['TripID']),
      isLowFloor:
          json['IsLowFloor'] is bool ? json['IsLowFloor'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'Sequence': sequence,
        'ArrivalTime': _formatRaw(arrival),
        'DepartureTime': _formatRaw(departure),
        'TimeType': timeType.code,
        if (tripId != null) 'TripID': tripId,
        if (isLowFloor != null) 'IsLowFloor': isLowFloor,
      };
}

class BusTimetableStop {
  const BusTimetableStop({
    required this.stopUid,
    required this.stopId,
    required this.name,
    required this.entries,
  });

  final String stopUid;
  final String stopId;
  final BusTimetableName? name;

  /// 已依離站時間排序。
  final List<BusTimetableEntry> entries;

  BusClockTime? get firstDeparture =>
      entries.isEmpty ? null : entries.first.departure;
  BusClockTime? get lastDeparture =>
      entries.isEmpty ? null : entries.last.departure;

  Map<String, dynamic> toJson() => {
        'StopUID': stopUid,
        'StopID': stopId,
        if (name != null) 'StopName': name!.toJson(),
        'TimeTables': [for (final e in entries) e.toJson()],
      };
}

/// 單一附屬路線、單一方向（以迄點站區分）的當日班表。
class BusDailyTimetable {
  const BusDailyTimetable({
    required this.routeUid,
    required this.routeId,
    required this.routeName,
    required this.subRouteUid,
    required this.subRouteId,
    required this.subRouteName,
    required this.operatorId,
    required this.destinationStopId,
    required this.destinationStopName,
    required this.busDate,
    required this.updateTime,
    required this.stops,
  });

  final String routeUid;
  final String routeId;
  final BusTimetableName routeName;
  final String subRouteUid;
  final String subRouteId;
  final BusTimetableName? subRouteName;
  final String operatorId;
  final String destinationStopId;
  final BusTimetableName? destinationStopName;

  /// 適用日期（營運日）。
  final DateTime? busDate;

  /// 資料更新時間。
  final DateTime? updateTime;
  final List<BusTimetableStop> stops;

  int get tripCount => stops.fold<int>(
        0,
        (max, stop) => stop.entries.length > max ? stop.entries.length : max,
      );

  bool get hasAnyTime => stops.any((s) => s.entries.isNotEmpty);

  /// 是否全部為估算時間（TimeType=0）。
  bool get isEstimatedOnly => stops
      .expand((s) => s.entries)
      .every((e) => e.timeType == BusTimeType.estimated);

  Map<String, dynamic> toJson() => {
        'RouteUID': routeUid,
        'RouteID': routeId,
        'RouteName': routeName.toJson(),
        'SubRouteUID': subRouteUid,
        'SubRouteID': subRouteId,
        if (subRouteName != null) 'SubRouteName': subRouteName!.toJson(),
        'OperatorID': operatorId,
        'DestinationStopID': destinationStopId,
        if (destinationStopName != null)
          'DestinationStopName': destinationStopName!.toJson(),
        if (busDate != null) 'BusDate': busDate!.toIso8601String(),
        if (updateTime != null) 'UpdateTime': updateTime!.toIso8601String(),
        'Stops': [for (final s in stops) s.toJson()],
      };
}

/// 解析結果，附帶被略過的資料筆數，方便監控資料品質。
class BusTimetableParseResult {
  const BusTimetableParseResult({
    required this.timetables,
    required this.skippedRecords,
    required this.skippedEntries,
  });

  final List<BusDailyTimetable> timetables;
  final int skippedRecords;
  final int skippedEntries;
}

/// 解析 API 回應（JSON 陣列）。可在背景 isolate 執行。
///
/// - 非陣列：丟出 [FormatException]
/// - 單筆缺少必要欄位（RouteID / RouteName）：略過並計數
/// - 單一班次時間格式錯誤：略過並計數
BusTimetableParseResult parseBusDailyTimetables(Object? json) {
  if (json is! List) {
    throw const FormatException('DailyStopTimeTable 回應不是 JSON 陣列');
  }
  var skippedRecords = 0;
  var skippedEntries = 0;
  final result = <BusDailyTimetable>[];

  for (final raw in json) {
    if (raw is! Map) {
      skippedRecords++;
      continue;
    }
    final routeId = _string(raw['RouteID']);
    final routeName = BusTimetableName.tryParse(raw['RouteName']);
    if (routeId == null || routeId.isEmpty || routeName == null) {
      skippedRecords++;
      continue;
    }

    final stops = <BusTimetableStop>[];
    final rawStops = raw['Stops'];
    if (rawStops is List) {
      for (final rawStop in rawStops) {
        if (rawStop is! Map) {
          skippedRecords++;
          continue;
        }
        final entries = <BusTimetableEntry>[];
        final rawTimes = rawStop['TimeTables'];
        if (rawTimes is List) {
          for (final rawTime in rawTimes) {
            final entry = BusTimetableEntry.tryParse(rawTime);
            if (entry == null) {
              skippedEntries++;
            } else {
              entries.add(entry);
            }
          }
        }
        entries.sort((a, b) {
          final byTime = a.departure.compareTo(b.departure);
          return byTime != 0 ? byTime : a.sequence.compareTo(b.sequence);
        });
        stops.add(BusTimetableStop(
          stopUid: _string(rawStop['StopUID']) ?? '',
          stopId: _string(rawStop['StopID']) ?? '',
          name: BusTimetableName.tryParse(rawStop['StopName']),
          entries: List.unmodifiable(entries),
        ));
      }
    }

    result.add(BusDailyTimetable(
      routeUid: _string(raw['RouteUID']) ?? '',
      routeId: routeId,
      routeName: routeName,
      subRouteUid: _string(raw['SubRouteUID']) ?? '',
      subRouteId: _string(raw['SubRouteID']) ?? routeId,
      subRouteName: BusTimetableName.tryParse(raw['SubRouteName']),
      operatorId: _string(raw['OperatorID']) ?? '',
      destinationStopId: _string(raw['DestinationStopID']) ?? '',
      destinationStopName:
          BusTimetableName.tryParse(raw['DestinationStopName']),
      busDate: _date(raw['BusDate']),
      updateTime: _date(raw['UpdateTime']),
      stops: List.unmodifiable(stops),
    ));
  }

  return BusTimetableParseResult(
    timetables: List.unmodifiable(result),
    skippedRecords: skippedRecords,
    skippedEntries: skippedEntries,
  );
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String _formatRaw(BusClockTime time) {
  final h = (time.minutesFromServiceDayStart ~/ 60).toString().padLeft(2, '0');
  final m = (time.minutesFromServiceDayStart % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
