import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:com.rsmn574.app/database/sql/schedule.dart';

import '../model/hsr_seat_status_model.dart';
import '../services/hsr_seat_status_service.dart';
import '../services/thsr/thsr_schedule_service.dart';
import '../services/thsr/thsr_station_service.dart';
import '../services/thsr/thsr_train_service.dart';
import '../services/tra/tra_liveboard_service.dart';
import '../services/tra/tra_schedule_service.dart';
import '../services/tra/tra_station_service.dart';
import '../services/tra/tra_train_service.dart';

/// Single access point for TRA / THSR data.
///
/// 統整臺鐵（TRA）與高鐵（THSR）各自獨立的 Service，以及使用者行程
/// （SQLite，[ScheduleService]）。兩套系統的 API 與資料格式刻意不合併：
/// TRA 方法以 `tra` 開頭、THSR 方法以 `thsr` / `hsr` 開頭。
///
/// 不依賴 BuildContext、Widget 或 Provider。
/// Provider 只能呼叫本類別，不得直接存取 Service 或 Database。
class RailwayRepository {
  const RailwayRepository({
    TraStationService traStationService = const TraStationService(),
    TraScheduleService traScheduleService = const TraScheduleService(),
    TraTrainService traTrainService = const TraTrainService(),
    TraLiveboardService traLiveboardService = const TraLiveboardService(),
    ThsrStationService thsrStationService = const ThsrStationService(),
    ThsrScheduleService thsrScheduleService = const ThsrScheduleService(),
    ThsrTrainService thsrTrainService = const ThsrTrainService(),
    HsrSeatStatusService? hsrSeatStatusService,
  })  : _traStation = traStationService,
        _traSchedule = traScheduleService,
        _traTrain = traTrainService,
        _traLiveboard = traLiveboardService,
        _thsrStation = thsrStationService,
        _thsrSchedule = thsrScheduleService,
        _thsrTrain = thsrTrainService,
        _hsrSeatStatus = hsrSeatStatusService;

  final TraStationService _traStation;
  final TraScheduleService _traSchedule;
  final TraTrainService _traTrain;
  final TraLiveboardService _traLiveboard;
  final ThsrStationService _thsrStation;
  final ThsrScheduleService _thsrSchedule;
  final ThsrTrainService _thsrTrain;
  final HsrSeatStatusService? _hsrSeatStatus;

  HsrSeatStatusService get _seatStatus =>
      _hsrSeatStatus ?? HsrSeatStatusService.instance;

  // ============================================================
  // TRA 臺鐵
  // ============================================================

  /// 全部臺鐵車站。
  Future<List<Map<String, dynamic>>> traStations() =>
      _traStation.fetchStations();

  /// 臺鐵車站設施資料。
  Future<List<dynamic>> traStationFacility(String stationId) =>
      _traStation.fetchStationFacility(stationId);

  /// 臺鐵路網 Polyline。
  Future<Set<Polyline>> trainNetworkLine() => _traStation.fetchNetworkLine();

  /// 車站時刻表（時間接近現在時會合併即時誤點）。
  Future<List<dynamic>> trainStation(String stationId, DateTime date) =>
      _traSchedule.fetchStationTimetable(stationId, date);

  /// 起訖站班表（直達 / 轉乘）。
  Future<Map<String, dynamic>> traOdTimetable({
    required String fromStationId,
    required String toStationId,
    required DateTime date,
  }) {
    return _traSchedule.fetchOdTimetable(
      fromStationId: fromStationId,
      toStationId: toStationId,
      date: date,
    );
  }

  /// MaaS 轉乘路線規劃。
  Future<List<dynamic>> traRoutePlan(
    String departurePosition,
    String destinationPosition,
    String time,
  ) {
    return _traSchedule.fetchRoutePlan(
        departurePosition, destinationPosition, time);
  }

  /// 指定車次與日期的時刻資料；失敗時為 null。
  Future<dynamic> traTrain(int trainNo, DateTime date) =>
      _traTrain.fetchTrain(trainNo, date);

  /// 車站即時看板（TrainNo / DelayTime）。
  Future<List<Map<String, dynamic>>> trainLiveBoard(String stationId) =>
      _traLiveboard.fetchStationLiveBoard(stationId);

  /// 單一車次即時位置。
  Future<List<Map<String, dynamic>>> traTrainLiveBoard(String trainNo) =>
      _traLiveboard.fetchTrainLiveBoard(trainNo);

  /// 列車即時誤點資料。
  Future<List<dynamic>> liveTrainDelay(String trainNo) =>
      _traLiveboard.fetchTrainDelay(trainNo);

  // ============================================================
  // THSR 高鐵
  // ============================================================

  /// 全部高鐵車站。
  Future<List<Map<String, dynamic>>> thsrStations() =>
      _thsrStation.fetchStations();

  /// 高鐵起訖站時刻表（[time] 為 yyyy-MM-dd）。
  Future<List<dynamic>> hsrRoute(
          dynamic departureId, dynamic destinationId, dynamic time) =>
      _thsrSchedule.fetchOdTimetable(departureId, destinationId, time);

  /// 指定車次（4 碼）與日期的時刻資料；失敗時為 null。
  Future<dynamic> thsrTrain(String trainNo, DateTime date) =>
      _thsrTrain.fetchTrain(trainNo, date);

  /// 指定車次、起訖站與日期的座位狀態。
  Future<dynamic> thsrAvailableSeatStatus(
    String departureId,
    String arrivalId,
    String trainNo,
    String date,
  ) {
    return _thsrTrain.fetchAvailableSeatStatus(
        departureId, arrivalId, trainNo, date);
  }

  /// 高鐵 OD 座位狀態（含快取、in-flight 去重、stale fallback）。
  Future<HsrOdSeatStatus> hsrSeatStatus({
    required String originStationId,
    required String destinationStationId,
    required DateTime date,
    bool forceRefresh = false,
  }) {
    return _seatStatus.fetch(
      originStationId: originStationId,
      destinationStationId: destinationStationId,
      date: date,
      forceRefresh: forceRefresh,
    );
  }

  // ============================================================
  // 使用者行程（SQLite）
  // ============================================================

  Future<dynamic> addSchedule(ScheduleModel schedule) async =>
      await ScheduleService.instance.addSchedule(schedule);

  Future<dynamic> updateSchedule(ScheduleModel schedule) async =>
      await ScheduleService.instance.updateSchedule(schedule);

  Future<dynamic> removeSchedule(ScheduleModel schedule) async =>
      await ScheduleService.instance.removeSchedule(model: schedule);

  Future<List<Map<String, dynamic>>> loadSchedules() async {
    await ScheduleService.instance.deleteExpiredSchedules();
    return await ScheduleService.instance.getSchedules();
  }
}
