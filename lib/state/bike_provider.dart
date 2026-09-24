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
  Object? _availabilityError;
  String _city = 'Taichung';

  List<YouBikeStation> get stations => _stations;
  YouBikeStation? get selectedStation => _selectedStation;
  Future<Map<String, dynamic>>? get availabilityFuture => _availabilityFuture;
  Object? get stationError => _stationError;
  Object? get availabilityError => _availabilityError;
  String get city => _city;
  bool get isLoadingStations => _stationLoadFuture != null;

  Future<void> loadStations({
    String city = 'Taichung',
    bool force = false,
  }) {
    _city = city;
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
      _stations = await _repository.fetchStations(_city);
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
    _availabilityError = null;
    _availabilityFuture = _loadAvailability(station.stationID);
    notifyListeners();
  }

  Future<Map<String, dynamic>> _loadAvailability(String stationId) async {
    try {
      return await _repository.fetchAvailability(_city, stationId);
    } catch (error, stackTrace) {
      _availabilityError = error;
      debugPrint('Unable to load YouBike availability: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedStation = null;
    _availabilityFuture = null;
    _availabilityError = null;
    notifyListeners();
  }
}
