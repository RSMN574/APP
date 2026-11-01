import 'package:com.rsmn574.app/database/sql/schedule.dart';
import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/railway/data/railway_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Caches rail requests that pages previously refetched on every rebuild.
///
/// 只透過 [RailwayRepository] 取得資料，不直接存取 Service 或 Database。
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

  // ============================================================
  // TRA 臺鐵
  // ============================================================

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

  Future<Set<Polyline>> trainNetworkLine({bool force = false}) =>
      _staticCache.get('network-line', _repository.trainNetworkLine,
          force: force);

  /// 全部臺鐵車站（靜態資料，快取 1 小時）。
  Future<List<Map<String, dynamic>>> traStations({bool force = false}) =>
      _staticCache.get('tra-stations', _repository.traStations, force: force);

  /// 臺鐵車站設施（靜態資料，快取 1 小時）。
  Future<List<dynamic>> traStationFacility(String stationId,
          {bool force = false}) =>
      _staticCache.get('tra-facility:$stationId',
          () => _repository.traStationFacility(stationId),
          force: force);

  /// 指定車次時刻資料。失敗時為 null，因此不做快取以便立即重試。
  Future<dynamic> traTrain(int trainNo, DateTime date) =>
      _repository.traTrain(trainNo, date);

  /// 單一車次即時位置（即時資料，不快取）。
  Future<List<Map<String, dynamic>>> traTrainLiveBoard(String trainNo) =>
      _repository.traTrainLiveBoard(trainNo);

  /// 起訖站班表（直達 / 轉乘）。
  Future<Map<String, dynamic>> traOdTimetable({
    required String fromStationId,
    required String toStationId,
    required DateTime date,
  }) =>
      _repository.traOdTimetable(
        fromStationId: fromStationId,
        toStationId: toStationId,
        date: date,
      );

  // ============================================================
  // THSR 高鐵
  // ============================================================

  Future<List<dynamic>> hsrRoute(
          dynamic departureId, dynamic destinationId, dynamic time,
          {bool force = false}) =>
      _cache.get('hsr:$departureId:$destinationId:$time',
          () => _repository.hsrRoute(departureId, destinationId, time),
          force: force);

  /// 全部高鐵車站（靜態資料，快取 1 小時）。
  Future<List<Map<String, dynamic>>> thsrStations({bool force = false}) =>
      _staticCache.get('thsr-stations', _repository.thsrStations,
          force: force);

  /// 指定車次時刻資料。失敗時為 null，因此不做快取以便立即重試。
  Future<dynamic> thsrTrain(String trainNo, DateTime date) =>
      _repository.thsrTrain(trainNo, date);

  // ============================================================
  // 使用者行程（SQLite，經 Repository）
  // ============================================================

  Future<dynamic> addSchedule(ScheduleModel schedule) =>
      _repository.addSchedule(schedule);

  Future<dynamic> updateSchedule(ScheduleModel schedule) =>
      _repository.updateSchedule(schedule);

  Future<dynamic> removeSchedule(ScheduleModel schedule) =>
      _repository.removeSchedule(schedule);

  Future<List<Map<String, dynamic>>> loadSchedules() =>
      _repository.loadSchedules();
}
