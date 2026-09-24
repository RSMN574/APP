import 'package:flutter/foundation.dart';

import '../data/bus_repository.dart';
import '../../../models/bus.dart';

class BusProvider extends ChangeNotifier {
  BusProvider({BusRepository? repository})
      : _repository = repository ?? const BusRepository();

  final BusRepository _repository;
  final Map<String, List<BusRoute>> _routeCache = {};
  final Map<String, Future<List<BusRoute>>> _pendingRequests = {};

  List<BusRoute> _routes = const [];
  Object? _error;
  String? _city;

  List<BusRoute> get routes => _routes;
  Object? get error => _error;
  String? get city => _city;
  bool get isLoading => _pendingRequests.containsKey(_city);

  Future<List<BusRoute>> loadRoutes(
    String city, {
    bool force = false,
  }) {
    _city = city;
    _error = null;

    final cachedRoutes = _routeCache[city];
    if (!force && cachedRoutes != null) {
      _routes = cachedRoutes;
      notifyListeners();
      return Future.value(_routes);
    }

    final pendingRequest = _pendingRequests[city];
    if (pendingRequest != null) return pendingRequest;

    final request = _loadRoutes(city);
    _pendingRequests[city] = request;
    notifyListeners();
    return request;
  }

  Future<List<BusRoute>> _loadRoutes(String city) async {
    try {
      final routes = await _repository.fetchRoutes(city);
      _routeCache[city] = routes;
      if (_city == city) {
        _routes = routes;
      }
      return routes;
    } catch (error) {
      if (_city == city) {
        _error = error;
        _routes = const [];
      }
      rethrow;
    } finally {
      _pendingRequests.remove(city);
      if (_city == city) notifyListeners();
    }
  }

  void clearCache() {
    _routeCache.clear();
    _routes = const [];
    _error = null;
    notifyListeners();
  }
}
