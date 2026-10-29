import '../model/s2s_travel_time.dart';

/// Parser and analyzer for a decoded TDX S2STravelTime JSON array.
/// The network loader is injected by the app so its existing TDX auth/backend is reused.
class S2STravelTimeService {
  const S2STravelTimeService();

  List<S2STravelTimeRoute> parseResponse(dynamic body) {
    if (body is! List) throw const FormatException('S2STravelTime response must be a JSON array.');
    return body.whereType<Map>().map((e) => S2STravelTimeRoute.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<S2SSegmentAnalysis> analyze({
    required List<S2STravelTimeRoute> routes,
    required List<Map<String, dynamic>> stops,
    required int direction,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final weekday = now.weekday % 7; // Sunday=0 ... Saturday=6
    final hour = now.hour;
    S2STravelTimeRoute? route;
    for (final item in routes) {
      if (item.direction == direction) { route = item; break; }
    }
    if (route == null) return const [];

    S2STravelTimeWindow? window;
    for (final item in route.windows) {
      if (item.weekday == weekday && item.containsHour(hour)) { window = item; break; }
    }
    // If current hour has no matching window, use this weekday's first window
    // as a baseline but flag that it is not an exact time-window match.
    final selected = window ?? route.windows.where((e) => e.weekday == weekday).firstOrNull;
    final segments = selected?.segments ?? const <S2STravelTime>[];
    final byPair = <String, S2STravelTime>{
      for (final s in segments) '${s.fromStopId}→${s.toStopId}': s,
    };

    String id(Map<String, dynamic> s) => (s['StopID'] ?? s['stopId'] ?? s['StopUID'] ?? '').toString();
    String name(Map<String, dynamic> s) => (s['displayStopName'] ?? s['stopName'] ?? s['StopName'] ?? '').toString();
    final result = <S2SSegmentAnalysis>[];
    for (var i = 0; i + 1 < stops.length; i++) {
      final from = stops[i], to = stops[i + 1];
      final fromId = id(from), toId = id(to);
      final match = byPair['$fromId→$toId'];
      result.add(S2SSegmentAnalysis(
        fromStopId: fromId,
        toStopId: toId,
        fromStopName: name(from),
        toStopName: name(to),
        expectedSeconds: match == null || match.runTimeSeconds <= 0 ? null : match.runTimeSeconds,
        hasExactTimeWindow: window != null,
      ));
    }
    return result;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
