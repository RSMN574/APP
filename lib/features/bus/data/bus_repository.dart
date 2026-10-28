import '../../../database/get_data.dart';
import 'get_bus_time.dart';
import '../model/bus_route_model.dart';

/// Provides bus data to the feature state layer.
///
/// The existing MySQL/TDX implementation remains the source of truth while
/// pages no longer need to know how bus routes are loaded.
class BusRepository {
  const BusRepository();

  Future<List<BusRoute>> fetchRoutes(String city) {
    return getBusRoute(city: city);
  }

  /// TDX A2：指定路線的預估到站時間。
  Future<List<dynamic>> fetchEstimatedArrivals({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return fetchBusTime(routeName, city, routeID);
  }

  /// TDX A1：指定路線的即時車輛位置。
  Future<List<Map<String, dynamic>>> fetchRealtimePositions({
    required String routeName,
    required String city,
    required String routeID,
  }) {
    return fetchBusRealtimePosition(routeName, city, routeID);
  }

  /// TDX：指定路線的形狀（Polyline 解碼前的原始資料）。
  Future<List<dynamic>> fetchRouteShape({
    required String city,
    required String routeName,
    required String routeID,
  }) {
    return getShape(city, routeName, routeID);
  }
}