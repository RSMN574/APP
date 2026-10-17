import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

import '../model/bus_station_model.dart';

/// TDX 路徑片段：跨縣市為 InterCity，其餘為 City/<city>。
String _busScope(String city) =>
    city.isEmpty || city == 'all' || city == 'InterCity'
        ? 'InterCity'
        : 'City/$city';

Future<List<dynamic>> fetchBusTime(
  String routeName,
  String city,
  String routeID,
) async {
  final client = TdxApiClient();
  final path =
      '/api/basic/v2/Bus/EstimatedTimeOfArrival/${_busScope(city)}/$routeName';

  final queryParams = {
    '\$filter': "RouteID eq '$routeID'",
    '\$format': 'JSON',
  };

  try {
    return await client.get(path, queryParams: queryParams) as List<dynamic>;
  } catch (e, stackTrace) {
    debugPrint('fetchBusTime 錯誤: $e');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

Future<Map<String, dynamic>> getDirections(String origin, String destination,
    time, Map<String, dynamic> option) async {
  List<String> transportModes = option["TransportModes"]; // 假設這是 List

// 將 List 轉換為 String，並使用逗號分隔
  String transit = Uri.encodeComponent(transportModes.join(","));
  if (kDebugMode) {
    print(transit);
  }
  final String url =
      'https://tdx.transportdata.tw/api/maas/routing?origin=$origin&destination=$destination&gc=1.0&top=10&transit=$transit&transfer_time=5%2C60&depart=$time&first_mile_mode=${option["TravelMode"]}&first_mile_time=10&last_mile_mode=${option["TravelMode"]}&last_mile_time=10';
  // 发起 GET 请求
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  ).timeout(const Duration(seconds: 20));

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }

  // 解析 JSON 数据
  final jsonData = await jsonDecode(response.body);

  print('JSON fetched successfully: $jsonData');
  return jsonData;
}

Future<List<BusStationInfo>> getNearStation(String location) async {
  final String url =
      'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24&%24spatialFilter=nearby%28$location%2C%20400%29&%24format=JSON';
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  ).timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }

  final List rawData = json.decode(response.body);

  late final List<BusStationInfo> stations;
  try {
    stations = rawData.map((e) => BusStationInfo.fromMap(e)).toList();
  } catch (e) {
    print('JSON 解析錯誤: $e');
    stations = [];
  }

  // 解析 location
  final decodedLocation = Uri.decodeComponent(location);
  final parts = decodedLocation.split(',');
  if (parts.length < 2) {
    throw FormatException("Location 格式錯誤，必須為 'latitude,longitude'");
  }
  final double userLat = double.parse(parts[0].trim());
  final double userLon = double.parse(parts[1].trim());

  // 使用 `calculateApproxDistance` 來排序
  stations.sort((a, b) {
    double distanceA =
        calculateApproxDistance(userLat, userLon, a.positionLat, a.positionLon);
    double distanceB =
        calculateApproxDistance(userLat, userLon, b.positionLat, b.positionLon);
    return distanceA.compareTo(distanceB);
  });

  return stations;
}

Future<List<Map<String, dynamic>>?> getHistoryData(
    String city, String routeId, int sum) async {
  final DateTime yesterday = DateTime.now().subtract(const Duration(days: 2));

  final String url =
      "https://tdx.transportdata.tw/api/historical/v2/Historical/Bus/RealTimeNearStop/${_busScope(city)}/Date/${DateFormat('yyyy-MM-dd').format(yesterday)}/RouteID/$routeId?%24top=$sum&%24format=JSONL";
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  ).timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }

  // 解析 JSONL（JSON Lines）格式，每行都是一個 JSON 物件
  List<Map<String, dynamic>> data = response.body
      .split('\n') // 按行分割
      .where((line) => line.isNotEmpty) // 過濾空行
      .map((line) => jsonDecode(line) as Map<String, dynamic>) // 解析 JSON
      .toList();

  return data;
}

Future<List<Map<String, dynamic>>> fetchBusTimeWithStopID(
    String routeName, String city, String stopID, String direction) async {
  try {
    await connMysql(); // 連接 MySQL（如果必要）

    // 使用 Uri 構建 URL
    final url = Uri.https(
      "tdx.transportdata.tw",
      "/api/basic/v2/Bus/EstimatedTimeOfArrival/${_busScope(city)}/$routeName",
      {
        "\$filter": "StopID eq '$stopID' and Direction eq $direction",
        "\$format": "JSON",
      },
    );

    // 發起 GET 請求
    final response = await TdxApiClient().getRaw(
      url,
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    // 檢查 HTTP 狀態碼
    if (response.statusCode != 200) {
      throw HttpException(
          'HTTP error! status: ${response.statusCode}, body: ${response.body}');
    }

    // 解析 JSON 數據
    final List<dynamic> jsonData = json.decode(response.body);

    // 轉換為 List<Map<String, dynamic>>
    final result = List<Map<String, dynamic>>.from(jsonData);

    // print('✅ JSON fetched successfully: ${result.length} records');
    return result;
  } catch (e, stackTrace) {
    print('❌ Error occurred in fetchBusTimeWithStopID: $e');
    print(stackTrace); // 印出詳細的錯誤堆疊，方便 Debug
    return []; // 返回空列表，而不是 null，避免影響調用方
  }
}

Future<List<dynamic>> getShape(
    String city, String routeName, String routeID) async {
  final String url =
      "https://tdx.transportdata.tw/api/basic/v2/Bus/Shape/${_busScope(city)}/$routeName?%24format=JSON";
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  ).timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }

  // 解析 JSON 数据
  final List<dynamic> jsonData = jsonDecode(response.body);

  // 過濾出 RouteID == routeID 的項目
  final filteredData = jsonData.where((item) {
    // RouteID 可能是字串或 int，要對應類型
    final itemRouteID = item['RouteID'];
    return itemRouteID != null && (itemRouteID.toString()) == routeID;
  }).toList();

  return filteredData;
}
