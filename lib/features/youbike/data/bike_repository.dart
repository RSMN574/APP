import 'dart:convert';

import 'package:com.rsmn574.app/features/youbike/data/get_bike.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/models/bike.dart';
import 'package:com.rsmn574.app/utils/convert.dart';

/// Owns YouBike data access and converts database rows into typed models.
class BikeRepository {
  const BikeRepository();

  Future<List<YouBikeStation>> fetchStations(String city) async {
    final cityCode = convertCityCode(city);
    final result = await executeQueryWithRetry(
      'SELECT * FROM Bike.ubike WHERE AuthorityID = ?',
      params: [cityCode],
    );
    final rows = result.rows.map((row) => row.assoc()).toList();

    return rows.map(_parseStationRow).toList(growable: false);
  }

  Future<BikeAvailability> fetchAvailability(String city, String stationId,
      {Future<void>? abortTrigger}) {
    return getBikeAvailability(city, stationId, abortTrigger: abortTrigger);
  }

  YouBikeStation _parseStationRow(Map<String, dynamic> row) {
    Map<String, dynamic> decodeMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String) {
        try {
          final decoded = json.decode(value);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } on FormatException {
          // Optional malformed JSON is represented as an empty object.
        }
      }
      return const {};
    }

    return YouBikeStation.fromJson({
      'StationUID': row['StationUID'],
      'StationID': row['StationID'],
      'AuthorityID': row['AuthorityID'],
      'StationName': decodeMap(row['StationName']),
      'StationPosition': decodeMap(row['StationPosition']),
      'StationAddress': decodeMap(row['StationAddress']),
      'BikesCapacity': row['BikesCapacity'],
      'ServiceType': row['ServiceType'],
      'SrcUpdateTime': row['SrcUpdateTime'],
      'UpdateTime': row['UpdateTime'],
    });
  }
}
