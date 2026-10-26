import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'package:com.rsmn574.app/utils/convert.dart';

import '../model/bus_station_model.dart';

const String _tdxHost = 'tdx.transportdata.tw';

/// 回傳 TDX 公車 API 使用的路徑片段。
///
/// 市區公車：City/Taipei
/// 公路客運：InterCity
///
/// 注意：回傳值已包含 City/，呼叫端不要再額外加一次 City/。
String _busScope(String city) {
  final normalizedCity = city.trim();

  if (normalizedCity.isEmpty ||
      normalizedCity.toLowerCase() == 'all' ||
      normalizedCity == 'InterCity') {
    return 'InterCity';
  }

  // 避免呼叫端傳入已經帶有 City/ 的值時重複加前綴。
  if (normalizedCity.startsWith('City/')) {
    return normalizedCity;
  }

  return 'City/$normalizedCity';
}

/// 將 OData 字串值中的單引號跳脫，避免 filter 字串格式錯誤。
String _odataString(String value) => value.replaceAll("'", "''");

/// 將路線名稱編碼成 URL path segment。
String _encodePathSegment(String value) => Uri.encodeComponent(value.trim());

/// 解析 API 回傳的陣列，並轉成 Map 清單。
List<Map<String, dynamic>> _parseMapList(
    dynamic response, {
      required String apiName,
    }) {
  if (response is! List) {
    throw FormatException('$apiName 回傳格式不是 JSON 陣列');
  }

  return response
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

/// 取得指定路線的預估到站時間。
Future<List<dynamic>> fetchBusTime(
    String routeName,
    String city,
    String routeID,
    ) async {
  final client = TdxApiClient();
  final path =
      '/api/basic/v2/Bus/EstimatedTimeOfArrival/'
      '${_busScope(city)}/${_encodePathSegment(routeName)}';

  final queryParams = <String, String>{
    r'$filter': "RouteID eq '${_odataString(routeID)}'",
    r'$format': 'JSON',
  };

  try {
    final response = await client.get(
      path,
      queryParams: queryParams,
    );

    if (response is! List) {
      throw const FormatException('TDX 預估到站時間 API 回傳格式不是陣列');
    }

    return response;
  } catch (error, stackTrace) {
    debugPrint('fetchBusTime 失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

/// 取得指定縣市與路線的公車動態定時資料（TDX A1）。
///
/// 重要：
/// _busScope(city) 已包含 City/，因此這裡不能再寫成
/// RealTimeByFrequency/City/${_busScope(city)}。
///
/// 若 city 為 Taipei，路徑應為：
/// /api/basic/v2/Bus/RealTimeByFrequency/City/Taipei/307
Future<List<Map<String, dynamic>>> fetchBusRealtimePosition(
    String routeName,
    String city,
    String routeID,
    ) async {
  final client = TdxApiClient();
  final path =
      '/api/basic/v2/Bus/RealTimeByFrequency/'
      '${_busScope(city)}/${_encodePathSegment(routeName)}';

  final queryParams = <String, String>{
    r'$filter': "RouteID eq '${_odataString(routeID)}'",
    r'$format': 'JSON',
  };

  try {
    debugPrint('🚌 TDX 即時公車 API 路徑：$path');

    final response = await client.get(
      path,
      queryParams: queryParams,
    );

    final result = _parseMapList(
      response,
      apiName: 'TDX 即時公車 API',
    );

    debugPrint('🚌 即時公車資料筆數：${result.length}');
    if (result.isNotEmpty) {
      debugPrint('🚌 即時公車第一筆資料：${result.first}');
    } else {
      debugPrint('🚌 此路線目前沒有回傳即時公車資料');
    }

    return result;
  } catch (error, stackTrace) {
    debugPrint('fetchBusRealtimePosition 失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

/// 取得大眾運輸路線規劃結果。
Future<Map<String, dynamic>> getDirections(
    String origin,
    String destination,
    dynamic time,
    Map<String, dynamic> option,
    ) async {
  final rawModes = option['TransportModes'];
  final transportModes = rawModes is List
      ? rawModes.map((value) => value.toString()).toList()
      : <String>[];

  final travelMode = option['TravelMode']?.toString() ?? '';

  final uri = Uri.https(
    _tdxHost,
    '/api/maas/routing',
    <String, String>{
      'origin': origin,
      'destination': destination,
      'gc': '1.0',
      'top': '10',
      'transit': transportModes.join(','),
      'transfer_time': '5,60',
      'depart': time.toString(),
      'first_mile_mode': travelMode,
      'first_mile_time': '10',
      'last_mile_mode': travelMode,
      'last_mile_time': '10',
    },
  );

  try {
    final response = await TdxApiClient()
        .getRaw(
      uri,
      headers: const {'Accept': 'application/json'},
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        '路線規劃 API HTTP ${response.statusCode}: ${response.body}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('路線規劃 API 回傳格式不是 JSON 物件');
    }

    return Map<String, dynamic>.from(decoded);
  } catch (error, stackTrace) {
    debugPrint('getDirections 失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

/// 取得指定座標附近的公車站牌，並依距離排序。
///
/// location 格式：latitude,longitude
Future<List<BusStationInfo>> getNearStation(String location) async {
  final decodedLocation = Uri.decodeComponent(location);
  final parts = decodedLocation.split(',');

  if (parts.length < 2) {
    throw const FormatException(
      "Location 格式錯誤，必須為 'latitude,longitude'",
    );
  }

  final userLat = double.tryParse(parts[0].trim());
  final userLon = double.tryParse(parts[1].trim());

  if (userLat == null ||
      userLon == null ||
      !userLat.isFinite ||
      !userLon.isFinite ||
      userLat < -90 ||
      userLat > 90 ||
      userLon < -180 ||
      userLon > 180) {
    throw const FormatException('Location 的經緯度無效');
  }

  final uri = Uri.https(
    _tdxHost,
    '/api/advanced/v2/Bus/Station/NearBy',
    <String, String>{
      r'$spatialFilter': 'nearby($userLat,$userLon,400)',
      r'$format': 'JSON',
    },
  );

  final response = await TdxApiClient()
      .getRaw(
    uri,
    headers: const {'Accept': 'application/json'},
  )
      .timeout(const Duration(seconds: 20));

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      '附近站牌 API HTTP ${response.statusCode}: ${response.body}',
      uri: uri,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const FormatException('附近站牌 API 回傳格式不是 JSON 陣列');
  }

  final List<BusStationInfo> stations;
  try {
    stations = decoded
        .whereType<Map>()
        .map(
          (item) => BusStationInfo.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  } catch (error, stackTrace) {
    debugPrint('附近站牌 JSON 解析失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  stations.sort((a, b) {
    final distanceA = calculateApproxDistance(
      userLat,
      userLon,
      a.positionLat,
      a.positionLon,
    );
    final distanceB = calculateApproxDistance(
      userLat,
      userLon,
      b.positionLat,
      b.positionLon,
    );
    return distanceA.compareTo(distanceB);
  });

  return stations;
}

/// 取得指定日期、路線的歷史公車動態資料。
Future<List<Map<String, dynamic>>?> getHistoryData(
    String city,
    String routeId,
    int sum,
    ) async {
  if (sum <= 0) {
    return <Map<String, dynamic>>[];
  }

  final date = DateFormat('yyyy-MM-dd').format(
    DateTime.now().subtract(const Duration(days: 2)),
  );

  final uri = Uri.https(
    _tdxHost,
    '/api/historical/v2/Historical/Bus/RealTimeNearStop/'
        '${_busScope(city)}/Date/$date/RouteID/${_encodePathSegment(routeId)}',
    <String, String>{
      r'$top': sum.toString(),
      r'$format': 'JSONL',
    },
  );

  final response = await TdxApiClient()
      .getRaw(
    uri,
    headers: const {'Accept': 'application/json'},
  )
      .timeout(const Duration(seconds: 20));

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      '歷史公車動態 API HTTP ${response.statusCode}: ${response.body}',
      uri: uri,
    );
  }

  final result = <Map<String, dynamic>>[];
  for (final line in response.body.split('\n')) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) continue;

    final decoded = jsonDecode(trimmedLine);
    if (decoded is Map) {
      result.add(Map<String, dynamic>.from(decoded));
    } else {
      debugPrint('略過非 JSON 物件的歷史資料行');
    }
  }

  return result;
}

/// 依站牌 ID 取得預估到站時間。
Future<List<Map<String, dynamic>>> fetchBusTimeWithStopID(
    String routeName,
    String city,
    String stopID,
    String direction,
    ) async {
  try {
    await connMysql();

    final uri = Uri.https(
      _tdxHost,
      '/api/basic/v2/Bus/EstimatedTimeOfArrival/'
          '${_busScope(city)}/${_encodePathSegment(routeName)}',
      <String, String>{
        r'$filter':
        "StopID eq '${_odataString(stopID)}' and Direction eq $direction",
        r'$format': 'JSON',
      },
    );

    final response = await TdxApiClient()
        .getRaw(
      uri,
      headers: const {'Accept': 'application/json'},
    )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        '預估到站時間 API HTTP ${response.statusCode}: ${response.body}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(response.body);
    return _parseMapList(
      decoded,
      apiName: '預估到站時間 API',
    );
  } catch (error, stackTrace) {
    debugPrint('fetchBusTimeWithStopID 失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

/// 取得指定路線的行駛形狀資料，並依 RouteID 篩選。
Future<List<dynamic>> getShape(
    String city,
    String routeName,
    String routeID,
    ) async {
  final uri = Uri.https(
    _tdxHost,
    '/api/basic/v2/Bus/Shape/'
        '${_busScope(city)}/${_encodePathSegment(routeName)}',
    const <String, String>{
      r'$format': 'JSON',
    },
  );

  final response = await TdxApiClient()
      .getRaw(
    uri,
    headers: const {'Accept': 'application/json'},
  )
      .timeout(const Duration(seconds: 20));

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      '公車路線形狀 API HTTP ${response.statusCode}: ${response.body}',
      uri: uri,
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! List) {
    throw const FormatException('公車路線形狀 API 回傳格式不是 JSON 陣列');
  }

  return decoded.where((item) {
    if (item is! Map) return false;
    final itemRouteID = item['RouteID'];
    return itemRouteID != null && itemRouteID.toString() == routeID;
  }).toList();
}
