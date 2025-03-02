import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Const/regularConst.dart';
import '../../models/Station.dart';
import '../getData.dart'; // 用于网络请求

Future<dynamic> fetchBusTime(routeName, city) async {
  int id = await getInfo('routeID');
  int? top = await getInfo('sum');
  var url =
      "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName?%24filter=RouteID%20eq%20%27$id%27&%24top=$top&%24format=JSON";

  try {
    await connMysql();
    final tokenResponse = await http.get(tokenUri);
    final token = tokenResponse.body;
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
  print(url);
  final tokenResponse = await http.get(tokenUri);
  final token = tokenResponse.body;
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
  const String testurl =
      "https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24spatialFilter=nearby%2824.150784%2C%20120.646877%2C1000%29&%24format=JSON";
  final String url =
      'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24&%24spatialFilter=nearby%28$location%2C%20400%29&%24format=JSON';
  final tokenResponse = await http.get(tokenUri);
  final token = tokenResponse.body;
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
  final List rawData = json.decode(response.body);

  late final List<Station> stations;
  try {
    stations = rawData.map((e) => Station.fromJson(e)).toList();
    // 使用 Set 去重
  } catch (e) {
    print('JSON 解析错误: $e');
  }
  print(stations is List<Station>); // 应该返回 true
  // 检查 List 的所有元素是否都是 Station 类型
  bool allStations = jsonData.every((element) => element is Station);
  print("jsonData is List<Station>: $allStations");

  print('JSON fetched successfully: $stations');
  return stations;
}

Future<List<Map<String, dynamic>>?> getHistoryData(
    String city, String routeId, int sum) async {
  final DateTime yesterday = DateTime.now().subtract(const Duration(days: 2));

  final String url =
      "https://tdx.transportdata.tw/api/historical/v2/Historical/Bus/RealTimeNearStop/City/$city/Date/${DateFormat('yyyy-MM-dd').format(yesterday)}/RouteID/$routeId?%24top=$sum&%24format=JSONL";

  final tokenResponse = await http.get(tokenUri);

  if (tokenResponse.statusCode != 200) {
    throw HttpException(
        'Failed to get token! status: ${tokenResponse.statusCode}');
  }
  final token = tokenResponse.body; // 你可能需要解析 token
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
