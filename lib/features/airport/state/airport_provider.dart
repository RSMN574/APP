import 'package:com.rsmn574.app/features/airport/data/airport_repository.dart';
import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:flutter/foundation.dart';

/// Caches airport requests so FutureBuilders can rebuild without refetching.
class AirportProvider extends ChangeNotifier {
  AirportProvider({
    AirportRepository? repository,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _repository = repository ?? const AirportRepository(),
        _cache = RequestCache(ttl: cacheTtl);

  final AirportRepository _repository;
  final RequestCache _cache;

  Future<List<dynamic>> arrivals(String airport, {bool force = false}) =>
      _cache.get('arr:$airport', () => _repository.arrivals(airport),
          force: force);

  Future<List<dynamic>> departures(String airport, {bool force = false}) =>
      _cache.get('dep:$airport', () => _repository.departures(airport),
          force: force);

  Future<List<dynamic>> flight(String airlineId, String flightNumber,
          {bool force = false}) =>
      _cache.get('flt:$airlineId:$flightNumber',
          () => _repository.flight(airlineId, flightNumber),
          force: force);

  Future<List<dynamic>> metar(String location, {bool force = false}) =>
      _cache.get('metar:$location', () => _repository.metar(location),
          force: force);

  void refresh() {
    _cache.invalidate();
    notifyListeners();
  }
}
