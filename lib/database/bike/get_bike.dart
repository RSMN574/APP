import 'dart:io';

import '../tdx_api_client.dart';

// 取得指定城市與站點的公共自行車即時車位資料。
Future<Map<String, dynamic>> getBikeAvailability(
  String city,
  String stationID,
) async {
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
  );

  if (data is! List || data.isEmpty || data.first is! Map) {
    throw const HttpException('Bike availability response is empty');
  }

  return Map<String, dynamic>.from(data.first as Map);
}
