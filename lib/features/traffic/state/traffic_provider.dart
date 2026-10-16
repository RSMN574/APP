import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/traffic/data/traffic_repository.dart';
import 'package:flutter/foundation.dart';

class TrafficProvider extends ChangeNotifier {
  TrafficProvider({
    TrafficRepository? repository,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _repository = repository ?? const TrafficRepository(),
        _cache = RequestCache(ttl: cacheTtl);

  final TrafficRepository _repository;
  final RequestCache _cache;

  Future<List<dynamic>> freewayRoadEvents({bool force = false}) => _cache.get(
        'freeway-events',
        _repository.freewayRoadEvents,
        force: force,
      );

  void refresh() {
    _cache.invalidate();
    notifyListeners();
  }
}
