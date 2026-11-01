import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/mrt_station.dart';
import '../../bus/model/bus_route_model.dart';
import '../../bus/model/bus_station_model.dart';
import '../data/nearby_stations_repository.dart';
import '../models/nearby_station_result.dart';
import '../utils/ttl_future_cache.dart';

/// 附近站點狀態與請求管理。
///
/// - 只透過 [NearbyStationsRepository] 取得資料。
/// - 相同（約 11 公尺內）座標的請求在 TTL 內重用結果，並行請求合併。
/// - 失敗的請求不快取，重建 / 重試時會重新請求。
/// - [loadMarkerStations] / [loadBusMarkerStations] 以 generation 防止
///   舊請求（例如快速切換分頁）覆蓋新結果。
class NearbyStationsProvider extends ChangeNotifier {
  NearbyStationsProvider({
    NearbyStationsRepository? repository,
    Duration stationsTtl = const Duration(seconds: 60),
  })  : _repository = repository ?? const NearbyStationsRepository(),
        _bus = TtlFutureCache(ttl: stationsTtl, maxEntries: 8),
        _metro = TtlFutureCache(ttl: stationsTtl, maxEntries: 8),
        _train = TtlFutureCache(ttl: stationsTtl, maxEntries: 8);

  final NearbyStationsRepository _repository;
  final TtlFutureCache<List<BusStationInfo>> _bus;
  final TtlFutureCache<List<MRTStation>> _metro;
  final TtlFutureCache<List<dynamic>> _train;

  // 站牌群組資料：5 分鐘、最多 10 筆（沿用原 BusStopCache / StopInfoCache）。
  final TtlFutureCache<List<Map<String, dynamic>>> _stopGroups =
      TtlFutureCache(ttl: const Duration(minutes: 5), maxEntries: 10);

  // 路線基本資料幾乎不變：1 小時。
  final TtlFutureCache<Map<String, Map<String, dynamic>>> _routeInfo =
      TtlFutureCache(ttl: const Duration(hours: 1), maxEntries: 20);

  int _generation = 0;
  bool _disposed = false;

  double? _latitude;
  double? _longitude;
  bool _invalidLocation = false;
  Object? _lastError;

  /// 最近一次查詢使用的座標。
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  /// 最近一次查詢的座標是否無效（尚未定位或座標異常）。
  bool get hasInvalidLocation => _invalidLocation;

  /// 最近一次失敗的錯誤；成功後清除。
  Object? get lastError => _lastError;

  // ── 附近站點（列表用，原始模型）──────────────────────

  Future<List<BusStationInfo>> busStations(
    double latitude,
    double longitude, {
    bool force = false,
  }) {
    if (!_accept(latitude, longitude)) return Future.value(const []);
    return _track(_bus.get(
      _key(latitude, longitude),
      () => _repository.fetchNearbyBusStations(
        latitude: latitude,
        longitude: longitude,
      ),
      force: force,
    ));
  }

  Future<List<MRTStation>> metroStations(
    double latitude,
    double longitude, {
    bool force = false,
  }) {
    if (!_accept(latitude, longitude)) return Future.value(const []);
    return _track(_metro.get(
      _key(latitude, longitude),
      () => _repository.fetchNearbyMetroStations(
        latitude: latitude,
        longitude: longitude,
      ),
      force: force,
    ));
  }

  Future<List<dynamic>> trainStations(
    double latitude,
    double longitude, {
    bool force = false,
  }) {
    if (!_accept(latitude, longitude)) return Future.value(const []);
    return _track(_train.get(
      _key(latitude, longitude),
      () => _repository.fetchNearbyTrainStations(
        latitude: latitude,
        longitude: longitude,
      ),
      force: force,
    ));
  }

  // ── 附近站點（地圖用）────────────────────────────────

  /// 載入公車站牌供地圖使用。若期間有更新的請求，回傳 null（結果已過期）。
  Future<List<BusStationInfo>?> loadBusMarkerStations(
    double latitude,
    double longitude, {
    bool force = false,
  }) async {
    final gen = ++_generation;
    final stations = await busStations(latitude, longitude, force: force);
    return gen == _generation ? stations : null;
  }

  /// 載入捷運 / 臺鐵站供地圖 Marker 使用。若期間有更新的請求，回傳 null。
  Future<List<NearbyStationResult>?> loadMarkerStations(
    NearbyStationType type,
    double latitude,
    double longitude, {
    bool force = false,
  }) async {
    final gen = ++_generation;
    List<NearbyStationResult> results;
    switch (type) {
      case NearbyStationType.metro:
        results = _repository.metroResultsOf(
          await metroStations(latitude, longitude, force: force),
        );
        break;
      case NearbyStationType.train:
        results = _repository.trainResultsOf(
          await trainStations(latitude, longitude, force: force),
        );
        break;
      case NearbyStationType.bus:
        results = _repository.busResultsOf(
          await busStations(latitude, longitude, force: force),
        );
        break;
    }
    return gen == _generation ? results : null;
  }

  // ── 公車站牌詳細資料 ─────────────────────────────────

  Future<List<Map<String, dynamic>>> busStopGroup(
    String stopName,
    String city, {
    bool force = false,
  }) {
    return _stopGroups.get(
      '$city-$stopName',
      () => _repository.fetchBusStopGroup(stopName, city),
      force: force,
    );
  }

  /// 即時到站資料，不快取。
  Future<List<Map<String, dynamic>>> stationArrivals(
    List<String> stationIds,
    String city,
  ) {
    return _repository.fetchStationArrivals(stationIds, city);
  }

  Future<Map<String, Map<String, dynamic>>> routeInfoByNames(
    Iterable<String> routeNames, {
    String city = 'Taichung',
  }) {
    final names = routeNames.toList()..sort();
    return _routeInfo.get(
      '$city|${names.join('|')}',
      () => _repository.fetchRoutesByNames(names, city: city),
    );
  }

  Future<BusRoute> routeById({
    required String city,
    required String routeId,
  }) {
    return _repository.fetchRouteById(city: city, routeId: routeId);
  }

  Future<dynamic> addFavoriteStop({
    required String stopName,
    required String city,
  }) {
    return _repository.addFavoriteStop(stopName: stopName, city: city);
  }

  // ── 快取管理 ─────────────────────────────────────────

  void clearCache() {
    _bus.clear();
    _metro.clear();
    _train.clear();
    _stopGroups.clear();
    _routeInfo.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── internals ────────────────────────────────────────

  /// 約 11 公尺精度（小數 4 位）：相近座標重用同一份結果。
  String _key(double lat, double lon) =>
      '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';

  bool _accept(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    final valid = NearbyStationsRepository.isValidLocation(latitude, longitude);
    if (_invalidLocation == valid) {
      _invalidLocation = !valid;
      _scheduleNotify();
    }
    return valid;
  }

  Future<T> _track<T>(Future<T> future) {
    future.then<void>((_) {
      if (_lastError != null) {
        _lastError = null;
        _scheduleNotify();
      }
    }, onError: (Object e) {
      _lastError = e;
      _scheduleNotify();
    });
    return future;
  }

  // 呼叫點可能在 build 期間，因此延後到 microtask 再通知。
  void _scheduleNotify() {
    scheduleMicrotask(() {
      if (!_disposed) notifyListeners();
    });
  }
}
