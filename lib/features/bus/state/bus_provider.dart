import 'package:flutter/foundation.dart';

import '../data/bus_repository.dart';
import '../model/bus_route_model.dart';

class BusProvider extends ChangeNotifier {
  BusProvider({
    BusRepository? repository,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _repository = repository ?? const BusRepository(),
        _cacheTtl = cacheTtl;

  final BusRepository _repository;
  final Duration _cacheTtl;
  final Map<String, _CachedRoutes> _routeCache = {};
  final Map<String, Future<List<BusRoute>>> _pendingRequests = {};

  List<BusRoute> _routes = const [];
  Object? _error;
  String? _city;
  int _cacheGeneration = 0;
  bool _disposed = false;

  List<BusRoute> get routes => _routes;
  Object? get error => _error;
  String? get city => _city;
  bool get isLoading => _city != null && _pendingRequests.containsKey(_city);

  Future<List<BusRoute>> loadRoutes(
    String city, {
    bool force = false,
  }) {
    if (_disposed) {
      return Future.error(StateError('BusProvider has been disposed'));
    }

    _city = city;
    _error = null;

    final cachedRoutes = _routeCache[city];
    if (!force &&
        cachedRoutes != null &&
        DateTime.now().difference(cachedRoutes.cachedAt) < _cacheTtl) {
      _routes = cachedRoutes.routes;
      _notifyListeners();
      return Future.value(_routes);
    }

    final pendingRequest = _pendingRequests[city];
    if (pendingRequest != null) return pendingRequest;

    final generation = _cacheGeneration;
    late final Future<List<BusRoute>> request;
    request = _loadRoutes(city, generation).whenComplete(() {
      if (identical(_pendingRequests[city], request)) {
        _pendingRequests.remove(city);
      }
      _notifyListeners();
    });
    _pendingRequests[city] = request;
    _notifyListeners();
    return request;
  }

  Future<List<BusRoute>> _loadRoutes(String city, int generation) async {
    try {
      final routes = await _repository.fetchRoutes(city);
      if (generation == _cacheGeneration) {
        _routeCache[city] = _CachedRoutes(routes, DateTime.now());
        if (_city == city && !_disposed) _routes = routes;
      }
      return routes;
    } catch (error) {
      if (generation == _cacheGeneration && _city == city && !_disposed) {
        _error = error;
        _routes = const [];
      }
      rethrow;
    }
  }

  void clearCache() {
    _cacheGeneration++;
    _routeCache.clear();
    _pendingRequests.clear();
    _routes = const [];
    _error = null;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pendingRequests.clear();
    super.dispose();
  }
}

class _CachedRoutes {
  const _CachedRoutes(this.routes, this.cachedAt);

  final List<BusRoute> routes;
  final DateTime cachedAt;
}
