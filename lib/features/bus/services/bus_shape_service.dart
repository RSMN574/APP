import '../data/get_bus_time.dart' as tdx;

/// 路線形狀（Polyline 原始資料）服務。
class BusShapeService {
  const BusShapeService();

  /// 取得指定路線的 Shape（已依 RouteID 篩選）。
  Future<List<dynamic>> fetchShape({
    required String city,
    required String routeName,
    required String routeID,
  }) {
    return tdx.getShape(city, routeName, routeID);
  }
}
