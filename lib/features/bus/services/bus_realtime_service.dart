import '../data/get_bus_time.dart' as tdx;

/// TDX A1 即時公車位置與歷史動態服務。
class BusRealtimeService {
  const BusRealtimeService();

  /// 即時車輛位置（TDX A1 RealTimeByFrequency）。
  Future<List<Map<String, dynamic>>> fetchPositions({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return tdx.fetchBusRealtimePosition(routeName, city, routeID);
  }

  /// 歷史公車動態（前兩天資料）。
  Future<List<Map<String, dynamic>>> fetchHistory({
    required String city,
    required String routeId,
    required int count,
  }) async {
    return await tdx.getHistoryData(city, routeId, count) ?? const [];
  }
}
