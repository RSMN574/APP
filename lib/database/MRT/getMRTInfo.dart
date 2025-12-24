import 'dart:convert';

import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;

import '../../Const/regularConst.dart';
import '../../models/MRTStation.dart';
import '../getData.dart';
Future <List<MRTStation>> getNearMRTStation(String location) async {

   final String url = 'https://tdx.transportdata.tw/api/advanced/v2/Bus/Station/NearBy?%24&%24spatialFilter=nearby%28$location%2C%201000%29&%24format=JSON';
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

// 捷運對應表
final Map<String, String> metroMap = {
  'TRTC': '臺北捷運',
  'TYMC': '桃園捷運',
  'TMRT': '臺中捷運',
  'NTMC': '新北捷運',
};

// 根據 city 生成捷運代碼列表
List<String> getMetroByCity(String city) {
  switch (city.toLowerCase()) {
    case 'taipei':
      return ['NTMC', 'TRTC']; // 台北市 → 新北捷運 + 台北捷運
    case 'taoyuan':
      return ['TYMC'];
    case 'taichung':
      return ['TMRT'];
    case 'newtaipei':
      return ['NTMC'];
    default:
      return [];
  }
}

// 取得捷運班距資料
Future<List<dynamic>> getNearMRTFrequency(String city) async {
  final metroCodes = getMetroByCity(city);
  final List<dynamic> allData = [];

  // 假設 tokenUri 已經定義好
  final tokenResponse = await http.get(tokenUri);
  if (tokenResponse.statusCode != 200) {
    throw HttpException('Failed to get token: ${tokenResponse.statusCode}');
  }
  final token = tokenResponse.body;

  // 逐個捷運代碼抓取資料
  for (final code in metroCodes) {
    final url =
        'https://tdx.transportdata.tw/api/basic/v2/Rail/Metro/Frequency/$code?%24format=JSON';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      print('Warning: HTTP error for $code: ${response.statusCode}');
      continue;
    }

    final List rawData = json.decode(response.body);
    allData.addAll(rawData);
  }

  return allData;
}