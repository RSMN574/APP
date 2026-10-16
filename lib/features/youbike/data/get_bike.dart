import 'dart:io';

import 'package:com.rsmn574.app/models/bike.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

// 取得指定城市與站點的公共自行車即時車位資料。
Future<BikeAvailability> getBikeAvailability(
  String city,
  String stationID, {
  Future<void>? abortTrigger,
}) async {
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(city)) {
    throw ArgumentError.value(city, 'city', 'Invalid city identifier');
  }
  if (stationID.trim().isEmpty) {
    throw const FormatException('Station ID cannot be empty');
  }

  final data = await TdxApiClient().get(
    '/api/basic/v2/Bike/Availability/City/$city',
    queryParams: {
      r'$filter': "StationID eq '$stationID'",
      r'$format': 'JSON',
    },
    abortTrigger: abortTrigger,
  );

  if (data is! List || data.isEmpty || data.first is! Map) {
    throw const HttpException('Bike availability response is empty');
  }

  return BikeAvailability.fromJson(
    Map<String, dynamic>.from(data.first as Map),
  );
}
