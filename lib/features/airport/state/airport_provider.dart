import 'package:com.rsmn574.app/features/airport/data/airport_repository.dart';

import 'package:com.rsmn574.app/features/airport/model/airport_model.dart';
import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:flutter/foundation.dart';

import '../data/get_flight.dart';

class AirportProvider extends ChangeNotifier {
  AirportProvider({
    AirportRepository? repository,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _repository = repository ?? const AirportRepository(),
        _cache = RequestCache(ttl: cacheTtl);

  final AirportRepository _repository;
  final RequestCache _cache;

  // 航班（原本）
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

  // 機場資料
  Map<String, AirportData> _airports = {};
  bool _isLoading = true;   // ← 初始 true
  String? _error;
  bool _loaded = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, AirportData> get airports => _airports;
  List<AirportData> get all => _airports.values.toList();
  bool get hasData => _loaded && _airports.isNotEmpty;

  AirportData? byCode(String code) => _airports[code];

  Future<void> loadAirports({bool force = false}) async {
    if (!force && _loaded) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _airports = await AirportService.loadAllAirports();
      debugPrint('✅ 載入機場成功：${_airports.length} 個');
      _loaded = true;
      _isLoading = false;
    } catch (e, stack) {
      debugPrint('❌ 載入機場失敗：$e');
      debugPrint(stack.toString());
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> refreshAirports() async {
    _loaded = false;
    await loadAirports(force: true);
  }

  void refresh() {
    _cache.invalidate();
    _loaded = false;
    _airports = {};
    _error = null;
    _isLoading = true;   // ← 重設為 true
    notifyListeners();
  }
}