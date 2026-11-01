import '../data/get_bus_time.dart' as tdx;
import '../data/get_station_info.dart' as station_info;

/// TDX A2 預估到站時間服務。
class BusArrivalService {
  const BusArrivalService();

  /// 指定路線預估到站時間。
  Future<List<dynamic>> fetchEstimatedArrivals({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return tdx.fetchBusTime(routeName, city, routeID);
  }

  /// 依站牌 ID 取得預估到站時間。
  Future<List<Map<String, dynamic>>> fetchArrivalsByStopId({
    required String routeName,
    required String city,
    required String stopID,
    required String direction,
  }) {
    return tdx.fetchBusTimeWithStopID(routeName, city, stopID, direction);
  }

  /// 依站位 ID 清單取得途經該站位的所有預估到站時間。
  Future<List<Map<String, dynamic>>> fetchStationArrivals({
    required List<String> stationIds,
    required String city,
  }) {
    return station_info.fetchStationInfo(stationIds, city);
  }
}
