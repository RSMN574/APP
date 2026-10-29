class S2STravelTime {
  const S2STravelTime({required this.fromStopId, required this.toStopId, required this.runTimeSeconds});
  final String fromStopId;
  final String toStopId;
  final int runTimeSeconds;

  factory S2STravelTime.fromJson(Map<String, dynamic> json) => S2STravelTime(
    fromStopId: (json['FromStopID'] ?? '').toString(),
    toStopId: (json['ToStopID'] ?? '').toString(),
    runTimeSeconds: _int(json['RunTime']) ?? 0,
  );

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}

class S2STravelTimeWindow {
  const S2STravelTimeWindow({required this.weekday, required this.startHour, required this.endHour, required this.segments});
  final int weekday;
  final int startHour;
  final int endHour;
  final List<S2STravelTime> segments;

  factory S2STravelTimeWindow.fromJson(Map<String, dynamic> json) => S2STravelTimeWindow(
    weekday: _int(json['Weekday']) ?? -1,
    startHour: _int(json['StartHour']) ?? -1,
    endHour: _int(json['EndHour']) ?? -1,
    segments: json['S2STimes'] is List
        ? (json['S2STimes'] as List).whereType<Map>().map((e) => S2STravelTime.fromJson(Map<String, dynamic>.from(e))).toList()
        : const [],
  );

  bool containsHour(int hour) {
    if (startHour < 0 || endHour < 0) return false;
    return startHour <= endHour ? hour >= startHour && hour < endHour : hour >= startHour || hour < endHour;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}

class S2STravelTimeRoute {
  const S2STravelTimeRoute({required this.routeUid, required this.routeId, required this.subRouteUid, required this.subRouteId, required this.direction, required this.windows, this.updateTime});
  final String routeUid, routeId, subRouteUid, subRouteId;
  final int direction;
  final List<S2STravelTimeWindow> windows;
  final DateTime? updateTime;

  factory S2STravelTimeRoute.fromJson(Map<String, dynamic> json) => S2STravelTimeRoute(
    routeUid: (json['RouteUID'] ?? '').toString(),
    routeId: (json['RouteID'] ?? '').toString(),
    subRouteUid: (json['SubRouteUID'] ?? '').toString(),
    subRouteId: (json['SubRouteID'] ?? '').toString(),
    direction: _int(json['Direction']) ?? -1,
    windows: json['TravelTimes'] is List
        ? (json['TravelTimes'] as List).whereType<Map>().map((e) => S2STravelTimeWindow.fromJson(Map<String, dynamic>.from(e))).toList()
        : const [],
    updateTime: DateTime.tryParse(json['UpdateTime']?.toString() ?? '')?.toLocal(),
  );

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}

class S2SSegmentAnalysis {
  const S2SSegmentAnalysis({required this.fromStopId, required this.toStopId, required this.fromStopName, required this.toStopName, required this.expectedSeconds, required this.hasExactTimeWindow});
  final String fromStopId, toStopId, fromStopName, toStopName;
  final int? expectedSeconds;
  final bool hasExactTimeWindow;
}
