import 'dart:convert';

import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;

import '../../Const/regularConst.dart';
import '../../models/MRTStation.dart';
import '../getData.dart';
Future <List<MRTStation>> getNearMRTStation(
    String location) async {

  const String testurl ="https://tdx.transportdata.tw/api/advanced/v2/Rail/Metro/Station/NearBy?%24spatialFilter=nearby%2824.150862%2C%20120.646511%2C%20500%29&%24format=JSON";
  final String url =
      'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24&%24spatialFilter=nearby%28$location%2C%20600%29&%24format=JSON';
  final tokenResponse = await http.get(tokenUri);
  final token=tokenResponse.body;
  // 发起 GET 请求
  final response = await http.get(
    Uri.parse(testurl),
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

  late final List<MRTStation> stations;
  try {
    stations = rawData.map((e) => MRTStation.fromJson(e))
        .toList();
    // 使用 Set 去重


  }catch (e) {
    print('JSON 解析错误: $e');
  }
  print(stations is List<MRTStation>); // 应该返回 true
  if (stations is List) {
    // 检查 List 的所有元素是否都是 Station 类型
    bool allStations = jsonData.every((element) => element is MRTStation);
    print("jsonData is List<Station>: $allStations");
  } else {
    print("jsonData is not a List.");
  }



  print('JSON fetched successfully: $stations');
  return stations;
}