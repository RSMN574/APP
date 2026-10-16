import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/ev_charging/data/ev_station_repository.dart';
import 'package:flutter/foundation.dart';

class EvStationProvider extends ChangeNotifier {
  EvStationProvider({
    EvStationRepository? repository,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _repository = repository ?? const EvStationRepository(),
        _cache = RequestCache(ttl: cacheTtl);

  final EvStationRepository _repository;
  final RequestCache _cache;

  Future<List<dynamic>> connectorLiveStatus(String stationId,
          {bool force = false}) =>
      _cache.get('connector:$stationId',
          () => _repository.connectorLiveStatus(stationId),
          force: force);

  void refresh() {
    _cache.invalidate();
    notifyListeners();
  }
}
