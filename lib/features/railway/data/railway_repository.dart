import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'get_hsr.dart';
import 'get_train.dart';

/// Single access point for TRA / HSR data.
class RailwayRepository {
  const RailwayRepository();

  Future<List<dynamic>> trainStation(String stationId, DateTime date) =>
      fetchTrainStation(stationId, date);

  Future<List<Map<String, dynamic>>> trainLiveBoard(String stationId) =>
      fetchTrainLiveBoard(stationId);

  Future<List<dynamic>> liveTrainDelay(String trainNo) =>
      fetchLiveTrainDelay(trainNo);

  Future<Set<Polyline>> trainNetworkLine() => fetchTrainNetworkLine();

  Future<List<dynamic>> hsrRoute(
          dynamic departureId, dynamic destinationId, dynamic time) =>
      fetchHSRRoute(departureId, destinationId, time);
}
