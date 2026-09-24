import 'package:com.rsmn574.app/database/bike/bike_repository.dart';
import 'package:com.rsmn574.app/models/bike.dart';
import 'package:flutter/foundation.dart';

/// The single source of truth for the YouBike sheet and map.
class BikeProvider extends ChangeNotifier {
  BikeProvider({BikeRepository? repository})
      : _repository = repository ?? const BikeRepository();

  final BikeRepository _repository;
  List<YouBikeStation> _stations = const [];
  YouBikeStation? _selectedStation;
  Future<Map<String, dynamic>>? _availabilityFuture;
  Future<void>? _stationLoadFuture;
  Object? _stationError;

  List<YouBikeStation> get stations => _stations;
  YouBikeStation? get selectedStation => _selectedStation;
  Future<Map<String, dynamic>>? get availabilityFuture => _availabilityFuture;
  Object? get stationError => _stationError;
  bool get isLoadingStations => _stationLoadFuture != null;

  Future<void> loadStations({bool force = false}) {
    if (!force && _stations.isNotEmpty) return Future.value();
    if (_stationLoadFuture != null) return _stationLoadFuture!;

    final loadFuture = _loadStations();
    _stationLoadFuture = loadFuture;
    notifyListeners();
    return loadFuture;
  }

  Future<void> _loadStations() async {
    _stationError = null;
    try {
      _stations = await _repository.fetchStations('Taichung');
    } catch (error, stackTrace) {
      _stationError = error;
      debugPrint('Unable to load YouBike stations: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _stationLoadFuture = null;
      notifyListeners();
    }
  }

  void selectStation(YouBikeStation station) {
    _selectedStation = station;
    _availabilityFuture = _repository.fetchAvailability('Taichung', station.stationID);
    notifyListeners();
  }

  void clearSelection() {
    _selectedStation = null;
    _availabilityFuture = null;
    notifyListeners();
  }
}
