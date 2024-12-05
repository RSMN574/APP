import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;

import '../models/Station.dart';
import 'getData.dart'; // 用于网络请求
 final   tokenUri=Uri.parse('http://hidden.rsmn574.com:3920/token') ;
Future<dynamic> fetchBusTime(routeName,city) async {



int id=await getInfo('routeID');
  int? top=  await getInfo('sum');
  //List BusInfo=await getInfo('routeInfo');
  var url="https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName?%24filter=RouteID%20eq%20%27$id%27&%24top=$top&%24format=JSON";

  try {

    await  connMysql();
    final tokenResponse = await http.get(tokenUri);
  final token=tokenResponse.body;
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
Future<Map<String, dynamic>> getDirections(
    String origin, String destination) async {



  final String url =
      'https://tdx.transportdata.tw/api/maas/routing?origin=$origin&destination=$destination&gc=0.0&top=5&transit=3%2C4%2C5%2C6%2C7%2C8%2C9&transfer_time=15%2C60&first_mile_mode=0&first_mile_time=10&last_mile_mode=0&last_mile_time=10';
print(url);
  final tokenResponse = await http.get(tokenUri);
  final token=tokenResponse.body;
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

Future <List<Station>> getNearStation(
    String location) async {

  final String url =
    'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24select=StationName%2CStationID%2CStationPosition%2CStops%2CStationUID&%24spatialFilter=nearby%28$location%2C%20200%29&%24format=JSON';
  final String url2 =
      'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24top=30&%24spatialFilter=nearby%28$location%2C%201000%29&%24format=JSON';
  final tokenResponse = await http.get(tokenUri);
  final token=tokenResponse.body;
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
  final List rawData = json.decode(response.body) ;

  late final List<Station> stations;
  try {
    stations = rawData.map((e) => Station.fromJson(e))
        .toList();
    // 使用 Set 去重


  }catch (e) {
    print('JSON 解析错误: $e');
  }
  print(stations is List<Station>); // 应该返回 true
  if (stations is List) {
    // 检查 List 的所有元素是否都是 Station 类型
    bool allStations = jsonData.every((element) => element is Station);
    print("jsonData is List<Station>: $allStations");
  } else {
    print("jsonData is not a List.");
  }
  final seenNames = <String>{};
  final uniqueStations = stations.where((station) {
    final name = station.stationNameZh;
    if (seenNames.contains(name)) {
      return false;
    } else {
      seenNames.add(name);
      return true;
    }
  }).toList();


  print('JSON fetched successfully: $stations');
  return uniqueStations;
}