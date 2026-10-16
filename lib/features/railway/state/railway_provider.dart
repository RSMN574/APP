import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/railway/data/railway_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Caches rail requests that pages previously refetched on every rebuild.
class RailwayProvider extends ChangeNotifier {
  RailwayProvider({
    RailwayRepository? repository,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _repository = repository ?? const RailwayRepository(),
        _cache = RequestCache(ttl: cacheTtl),
        _staticCache = RequestCache(ttl: const Duration(hours: 1));

  final RailwayRepository _repository;
  final RequestCache _cache;
  final RequestCache _staticCache;

  Future<List<dynamic>> trainStation(String stationId, DateTime date,
          {bool force = false}) =>
      _cache.get('station:$stationId:${date.toIso8601String()}',
          () => _repository.trainStation(stationId, date),
          force: force);

  Future<List<Map<String, dynamic>>> trainLiveBoard(String stationId,
          {bool force = false}) =>
      _cache.get('board:$stationId', () => _repository.trainLiveBoard(stationId),
          force: force);

  Future<List<dynamic>> liveTrainDelay(String trainNo, {bool force = false}) =>
      _cache.get('delay:$trainNo', () => _repository.liveTrainDelay(trainNo),
          force: force);

  Future<List<dynamic>> hsrRoute(
          dynamic departureId, dynamic destinationId, dynamic time,
          {bool force = false}) =>
      _cache.get('hsr:$departureId:$destinationId:$time',
          () => _repository.hsrRoute(departureId, destinationId, time),
          force: force);

  Future<Set<Polyline>> trainNetworkLine({bool force = false}) =>
      _staticCache.get('network-line', _repository.trainNetworkLine,
          force: force);
}
