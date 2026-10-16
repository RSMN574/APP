import 'get_traffic.dart';

class TrafficRepository {
  const TrafficRepository();

  Future<List<dynamic>> freewayRoadEvents() => fetchFreewayRoadEvent();
}
