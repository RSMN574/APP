import 'dart:async';

import 'package:com.rsmn574.app/features/youbike/data/bike_repository.dart';
import 'package:com.rsmn574.app/models/bike.dart';
import 'package:flutter/foundation.dart';

/// The single source of truth for the YouBike sheet and map.
class BikeProvider extends ChangeNotifier {
  BikeProvider({
    BikeRepository? repository,
    Duration stationCacheTtl = const Duration(minutes: 2),
  })  : _repository = repository ?? const BikeRepository(),
        _stationCacheTtl = stationCacheTtl;

  final BikeRepository _repository;
  final Duration _stationCacheTtl;
  final Map<String, _StationCacheEntry> _stationCache = {};
  final Map<String, Future<void>> _stationLoads = {};
  List<YouBikeStation> _stations = const [];
  YouBikeStation? _selectedStation;
  Future<BikeAvailability>? _availabilityFuture;
  Completer<void>? _availabilityAbort;
  Object? _stationError;
  Object? _availabilityError;
  String _city = 'Taichung';
  int _availabilityRequestId = 0;
  bool _disposed = false;

  List<YouBikeStation> get stations => _stations;
  YouBikeStation? get selectedStation => _selectedStation;
  Future<BikeAvailability>? get availabilityFuture => _availabilityFuture;
  Object? get stationError => _stationError;
  Object? get availabilityError => _availabilityError;
  String get city => _city;
  bool get isLoadingStations => _stationLoads.containsKey(_city);

  Future<void> loadStations({
    String city = 'Taichung',
    bool force = false,
  }) {
    if (_disposed) {
      return Future.error(StateError('BikeProvider has been disposed'));
    }

    if (_city != city) {
      _city = city;
      _stations = const [];
      _selectedStation = null;
      _cancelAvailabilityRequest();
      _availabilityFuture = null;
      _availabilityError = null;
      _stationError = null;
    }

    final cachedEntry = _stationCache[city];
    if (!force &&
        cachedEntry != null &&
        DateTime.now().difference(cachedEntry.cachedAt) < _stationCacheTtl) {
      _stations = cachedEntry.stations;
      _stationError = null;
      _notifyListeners();
      return Future.value();
    }

    final existingLoad = _stationLoads[city];
    if (existingLoad != null) return existingLoad;

    final loadFuture = _loadStations(city);
    _stationLoads[city] = loadFuture;
    _notifyListeners();
    return loadFuture;
  }

  Future<void> _loadStations(String city) async {
    if (_city == city) _stationError = null;
    try {
      final stations = await _repository.fetchStations(city);
      _stationCache[city] = _StationCacheEntry(stations, DateTime.now());
      if (_city == city && !_disposed) _stations = stations;
    } catch (error, stackTrace) {
      if (_city == city && !_disposed) _stationError = error;
      debugPrint('Unable to load YouBike stations: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _stationLoads.remove(city);
      _notifyListeners();
    }
  }

  void selectStation(YouBikeStation station) {
    if (_disposed) return;
    _cancelAvailabilityRequest();
    _selectedStation = station;
    _availabilityError = null;
    final requestId = ++_availabilityRequestId;
    final abort = Completer<void>();
    _availabilityAbort = abort;
    _availabilityFuture = _loadAvailability(
      _city,
      station.stationID,
      requestId,
      abort,
    );
    _notifyListeners();
  }

  Future<BikeAvailability> _loadAvailability(
    String city,
    String stationId,
    int requestId,
    Completer<void> abort,
  ) async {
    try {
      return await _repository.fetchAvailability(
        city,
        stationId,
        abortTrigger: abort.future,
      );
    } catch (error, stackTrace) {
      if (requestId == _availabilityRequestId && !_disposed) {
        _availabilityError = error;
        debugPrint('Unable to load YouBike availability: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    } finally {
      if (requestId == _availabilityRequestId) {
        _availabilityAbort = null;
      }
      _notifyListeners();
    }
  }

  void clearSelection() {
    if (_disposed) return;
    _cancelAvailabilityRequest();
    _selectedStation = null;
    _availabilityFuture = null;
    _availabilityError = null;
    _notifyListeners();
  }

  void _cancelAvailabilityRequest() {
    final abort = _availabilityAbort;
    if (abort != null && !abort.isCompleted) abort.complete();
    _availabilityAbort = null;
    _availabilityRequestId++;
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelAvailabilityRequest();
    super.dispose();
  }
}

class _StationCacheEntry {
  const _StationCacheEntry(this.stations, this.cachedAt);

  final List<YouBikeStation> stations;
  final DateTime cachedAt;
}
