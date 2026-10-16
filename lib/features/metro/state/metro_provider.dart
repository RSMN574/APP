import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/get_metro.dart';
import '../data/metro_repository.dart';

class MetroProvider extends ChangeNotifier {
  MetroProvider({GetMetro? api}) : _api = api ?? GetMetro();

  final GetMetro _api;

  // ==========================================
  // 城市清單（從 API 載入）
  // ==========================================
  List<CityInfo> _cities = [];
  bool _isLoadingCities = true;
  String? _citiesError;

  List<CityInfo> get cities => _cities;
  bool get isLoadingCities => _isLoadingCities;
  String? get citiesError => _citiesError;

  // ==========================================
  // 目前城市資料（非 nullable，預設台北）
  // ==========================================
  CityMetroData _currentCity = MetroRepository.taipei;
  CityMetroData get currentCity => _currentCity;

  // ==========================================
  // 路線查詢狀態
  // ==========================================
  Station? _startStation;
  Station? _endStation;
  RouteResult? _routeResult;
  // ✅ 預設使用台北車站，避免一開始是空的
  List<Station> _filteredStations = MetroRepository.taipei.stations;
  bool _disposed = false;

  Station? get startStation => _startStation;
  Station? get endStation => _endStation;
  RouteResult? get routeResult => _routeResult;
  List<Station> get filteredStations => _filteredStations;

  // ==========================================
  // 載入城市清單（App 啟動時呼叫）
  // ==========================================
  Future<void> loadCities() async {
    _isLoadingCities = true;
    _citiesError = null;
    _notifyListeners();

    try {
      // 1. 先取得城市清單（顯示在 Dropdown）
      final cityInfos = await _api.getCities();
      _cities = cityInfos;

      // 2. 逐一載入每個城市的完整資料，合併到 MetroRepository
      final cities = await MetroRepository.loadFromApi(api: _api);

      // 3. 設定預設城市（台北，或清單第一個）
      if (cities.isNotEmpty) {
        _currentCity = cities.firstWhere(
              (c) => c.id == 'taipei',
          orElse: () => cities.first,
        );
        _filteredStations = _currentCity.stations;
      }

      _isLoadingCities = false;
      _notifyListeners();
    } catch (e) {
      _citiesError = e.toString();
      _isLoadingCities = false;
      _notifyListeners();
    }
  }

  // ==========================================
  // 用城市 ID 切換城市（會呼叫 API）
  // ==========================================
  Future<void> changeCityById(String cityId) async {
    try {
      final data = await _api.getMetro(cityId);

      final cityData = data is CityMetroData
          ? data
          : CityMetroData.fromJson(data as Map<String, dynamic>);

      _currentCity = cityData;
      _filteredStations = cityData.stations;   // ✅ 更新車站清單
      _startStation = null;
      _endStation = null;
      _routeResult = null;
      _notifyListeners();
    } catch (e) {
      _citiesError = e.toString();
      _notifyListeners();
      rethrow;
    }
  }

  // ==========================================
  // 直接切換城市（若已有資料）
  // ==========================================
  void changeCity(CityMetroData city) {
    _currentCity = city;
    _filteredStations = city.stations;
    _startStation = null;
    _endStation = null;
    _routeResult = null;
    _notifyListeners();
  }

  // ==========================================
  // 搜尋車站
  // ==========================================
  void filterStations(String query) {
    // ✅ _currentCity 非 nullable，不需 null 檢查
    _filteredStations = query.isEmpty
        ? _currentCity.stations
        : _currentCity.stations
        .where((station) => station.name.contains(query))
        .toList(growable: false);
    _notifyListeners();
  }

  // ==========================================
  // 選擇車站（起點/終點）
  // ==========================================
  void selectStation(Station station) {
    if (_startStation == null || _endStation != null) {
      _startStation = station;
      _endStation = null;
      _routeResult = null;
    } else if (_startStation == station) {
      _startStation = null;
      _routeResult = null;
    } else {
      _endStation = station;
      _calculateRoute();
    }
    _notifyListeners();
  }

  void setStartStation(Station station) {
    _startStation = station;
    if (_endStation == station) _endStation = null;
    _calculateRoute();
    _notifyListeners();
  }

  void setEndStation(Station station) {
    _endStation = station;
    if (_startStation == station) _startStation = null;
    _calculateRoute();
    _notifyListeners();
  }

  // ==========================================
  // 路線計算（BFS）
  // ==========================================
  void _calculateRoute() {
    final start = _startStation;
    final end = _endStation;
    // ✅ 只需檢查 start/end，_currentCity 非 nullable
    if (start == null || end == null) {
      _routeResult = null;
      return;
    }

    final city = _currentCity;
    final graph = <String, List<Edge>>{};
    for (final edge in city.edges) {
      graph.putIfAbsent(edge.stationA, () => []).add(edge);
      graph
          .putIfAbsent(edge.stationB, () => [])
          .add(Edge(edge.stationB, edge.stationA, edge.lineId));
    }

    List<String>? bestPathIds;
    final queue = Queue<List<String>>()..add([start.id]);
    final visited = {start.id};

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;
      if (current == end.id) {
        bestPathIds = path;
        break;
      }

      for (final edge in graph[current] ?? const <Edge>[]) {
        if (visited.add(edge.stationB)) {
          queue.add([...path, edge.stationB]);
        }
      }
    }

    if (bestPathIds == null) {
      _routeResult = null;
      return;
    }

    final pathStations = bestPathIds
        .map((id) =>
        city.stations.firstWhere((station) => station.id == id))
        .toList(growable: false);
    final stationCount = pathStations.length - 1;
    var transfers = 0;
    String? currentLine;

    for (var index = 0; index < pathStations.length - 1; index++) {
      final stationA = pathStations[index].id;
      final stationB = pathStations[index + 1].id;
      final edge = city.edges.firstWhere(
            (candidate) =>
        (candidate.stationA == stationA &&
            candidate.stationB == stationB) ||
            (candidate.stationA == stationB && candidate.stationB == stationA),
      );
      if (currentLine != null && currentLine != edge.lineId) transfers++;
      currentLine = edge.lineId;
    }

    _routeResult = RouteResult(
      path: pathStations,
      fare: 20 + ((stationCount / 3).floor() * 5),
      durationMinutes: (stationCount * 2) + (transfers * 4) + 3,
      stationCount: stationCount,
      transferCount: transfers,
    );
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _api.close();
    super.dispose();
  }
}