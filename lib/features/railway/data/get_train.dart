// 相容層：TRA 實作已搬到 features/railway/services/tra/。
// 新程式請透過 RailwayProvider → RailwayRepository 取得資料，不要直接引用本檔。
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/tra/tra_liveboard_service.dart';
import '../services/tra/tra_schedule_service.dart';
import '../services/tra/tra_station_service.dart';
import '../services/tra/tra_train_service.dart';

@Deprecated('Use RailwayRepository.traTrain')
Future<dynamic> fetchTrain(int trainNo, DateTime date) =>
    const TraTrainService().fetchTrain(trainNo, date);

@Deprecated('Use RailwayRepository.traTrainLiveBoard')
Future<List<Map<String, dynamic>>> fetchTrainStationByTrainNo(
        String trainNo) =>
    const TraLiveboardService().fetchTrainLiveBoard(trainNo);

@Deprecated('Use RailwayRepository.trainStation')
Future<List<dynamic>> fetchTrainStation(String stationID, DateTime date) =>
    const TraScheduleService().fetchStationTimetable(stationID, date);

@Deprecated('Use RailwayRepository.traRoutePlan')
Future<List<dynamic>> fetchTrainRoute(
        String departurePosition, String destinationPosition, String time) =>
    const TraScheduleService()
        .fetchRoutePlan(departurePosition, destinationPosition, time);

@Deprecated('Use RailwayRepository.liveTrainDelay')
Future<List<dynamic>> fetchLiveTrainDelay(String trainNo) =>
    const TraLiveboardService().fetchTrainDelay(trainNo);

@Deprecated('Use RailwayRepository.trainLiveBoard')
Future<List<Map<String, dynamic>>> fetchTrainLiveBoard(String stationID) =>
    const TraLiveboardService().fetchStationLiveBoard(stationID);

@Deprecated('Use RailwayRepository.trainNetworkLine')
Future<Set<Polyline>> fetchTrainNetworkLine() =>
    const TraStationService().fetchNetworkLine();

@Deprecated('Use TraStationService.parseWKTGeometry')
List<List<LatLng>> parseWKTGeometry(String wkt) =>
    TraStationService.parseWKTGeometry(wkt);
