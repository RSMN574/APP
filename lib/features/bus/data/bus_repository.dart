import '../../../database/get_data.dart';
import '../../../models/bus.dart';

/// Provides bus data to the feature state layer.
///
/// The existing MySQL/TDX implementation remains the source of truth while
/// pages no longer need to know how bus routes are loaded.
class BusRepository {
  const BusRepository();

  Future<List<BusRoute>> fetchRoutes(String city) {
    return getBusRoute(city: city);
  }
}
