import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Const/regularConst.dart';
import '../../models/Station.dart';
import '../../utils/convert.dart';
import '../getData.dart'; // 用于网络请求

Future<dynamic> fetchBusTime(routeName, city) async {
  int id = await getInfo('routeID');
  int? top = await getInfo('sum');
  var url =
      "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName?%24filter=RouteID%20eq%20%27$id%27&%24top=$top&%24format=JSON";
  final token =await  getToken();

  try {
    await connMysql();

    // 发起 GET 请求
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      throw HttpException('HTTP error! status: ${response.statusCode}');
    }

    // 解析 JSON 数据
    final jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    print('JSON fetched successfully: $jsonData');
    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}

Future<Map<String, dynamic>> getDirections(String origin, String destination, time, Map<String, dynamic> option) async {
  List<String> transportModes = option["TransportModes"]; // 假設這是 List

// 將 List 轉換為 String，並使用逗號分隔
  String transit = Uri.encodeComponent(transportModes.join(","));
  if (kDebugMode) {
    print(transit);
  }
  final String url =
      'https://tdx.transportdata.tw/api/maas/routing?origin=$origin&destination=$destination&gc=1.0&top=10&transit=$transit&transfer_time=5%2C60&depart=$time&first_mile_mode=${option["TravelMode"]}&first_mile_time=10&last_mile_mode=${option["TravelMode"]}&last_mile_time=10';
  final token =await  getToken();
  // 发起 GET 请求
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }

  // 解析 JSON 数据
  final jsonData = await jsonDecode(response.body);

  print('JSON fetched successfully: $jsonData');
  return jsonData;
}

Future<List<Station>> getNearStation(String location) async {
  final String url =
      'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24&%24spatialFilter=nearby%28$location%2C%20400%29&%24format=JSON';

  final token = await getToken();

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    },
  );

  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }

  final List rawData = json.decode(response.body);
  late final List<Station> stations;
  try {
    stations = rawData.map((e) => Station.fromJson(e)).toList();
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
    double distanceA = calculateApproxDistance(
        userLat, userLon, a.positionLat, a.positionLon);
    double distanceB = calculateApproxDistance(
        userLat, userLon, b.positionLat, b.positionLon);
    return distanceA.compareTo(distanceB);
  });

  print('排序後的站牌: $stations');
  return stations;
}
Future<List<Map<String, dynamic>>?> getHistoryData(String city, String routeId, int sum) async {
  final DateTime yesterday = DateTime.now().subtract(const Duration(days: 2));

  final String url =
      "https://tdx.transportdata.tw/api/historical/v2/Historical/Bus/RealTimeNearStop/City/$city/Date/${DateFormat('yyyy-MM-dd').format(yesterday)}/RouteID/$routeId?%24top=$sum&%24format=JSONL";

  final tokenResponse = await http.get(tokenUri);

  if (tokenResponse.statusCode != 200) {
    throw HttpException(
        'Failed to get token! status: ${tokenResponse.statusCode}');
  }
  final token =await  getToken();
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    },
  );

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
    String routeName, String city, String stopID ,String direction ) async {
  try {
    final token = await getToken(); // 獲取 Token
    await connMysql(); // 連接 MySQL（如果必要）

    // 使用 Uri 構建 URL
    final url = Uri.https(
      "tdx.transportdata.tw",
      "/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName",
      {
        "\$filter": "StopID eq '$stopID' and Direction eq $direction",
        "\$format": "JSON",
      },
    );
print(url);
    // 發起 GET 請求
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

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
