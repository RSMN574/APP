import 'get_park.dart';

class ParkingRepository {
  const ParkingRepository();

  Future<List<dynamic>> liveStatus(String city) => fetchParkLiveStatus(city);
}
