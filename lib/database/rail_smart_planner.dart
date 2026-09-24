import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../const/regular_const.dart';

Future<Map<String, dynamic>> fetchTrainRoutes(String origin, String destination, String time) async {

  final baseUrl = 'https://tdx.transportdata.tw/api/basic/v3';
  String encodedTime = Uri.encodeComponent(time);
  // 查詢直達班次
  final url = '$baseUrl/Rail/TRA/DailyTrainTimetable/OD/$origin/to/$destination/$encodedTime?%24format=JSON';


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
  Map<String, dynamic>  jsonData = await jsonDecode(response.body);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['DailyTrainInfo'].isNotEmpty) {
      print('直達班次: ${data['DailyTrainInfo']}');
      await _findTransferRoutes(origin, destination, encodedTime, baseUrl);
    } else {
      // 如果沒有直達班次，進行轉乘查詢
      await _findTransferRoutes(origin, destination, encodedTime, baseUrl);
    }
  } else {
    print('查詢失敗: ${response.statusCode}');
  }
  return jsonData;
}

// 查詢轉乘路徑
Future<void> _findTransferRoutes(String origin, String destination, String date,  String baseUrl) async {
  // Step 1: 查詢所有從起點站出發的班次
  final fromOriginUrl = '$baseUrl/Rail/TRA/DailyTimetable/OD/$origin/to/$destination/$date';

  final tokenResponse = await http.get(tokenUri);
  final token=tokenResponse.body;
  // 发起 GET 请求
  final response = await http.get(
    Uri.parse(fromOriginUrl),
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
  Map<String, dynamic>  jsonData = await jsonDecode(response.body);


  // Step 2: 查詢中間站可能的班次
  final transferStation = '1005'; // 替换为合适的中间站 (如宜蘭站)
  final toTransferUrl = '$baseUrl/Rail/TRA/DailyTimetable/OD/$origin/to/$transferStation/$date';
  final fromTransferUrl = '$baseUrl/Rail/TRA/DailyTimetable/OD/$transferStation/to/$destination/$date';

  final response2 = await http.get(Uri.parse(toTransferUrl), headers:    {
  'Authorization': 'Bearer $token',
  'accept': 'application/json',
  },);

  final response3 = await http.get(Uri.parse(fromTransferUrl), headers: {
    'Authorization': 'Bearer $token',
    'accept': 'application/json',
  },);

  if (response2.statusCode == 200 && response3.statusCode == 200) {
    final toTransferData = jsonDecode(response2.body);
    final fromTransferData = jsonDecode(response3.body);

    // 整合轉乘班次
    _combineTransferRoutes(toTransferData, fromTransferData);
  }
}

// 整合轉乘班次
void _combineTransferRoutes(Map<String, dynamic> toTransfer, Map<String, dynamic> fromTransfer) {
  final transferRoutes = [];

  for (var toRoute in toTransfer['DailyTrainInfo']) {
    for (var fromRoute in fromTransfer['DailyTrainInfo']) {
      // 確保轉乘時間符合邏輯（如到站時間 < 出發時間）
      final toArrivalTime = DateTime.parse(toRoute['ArrivalTime']);
      final fromDepartureTime = DateTime.parse(fromRoute['DepartureTime']);

      if (toArrivalTime.isBefore(fromDepartureTime)) {
        transferRoutes.add({
          'firstLeg': toRoute,
          'secondLeg': fromRoute,
        });
      }
    }
  }

  print('轉乘班次: $transferRoutes');
}

// // 生成請求頭
Future<Map<String, dynamic>> _generateHeaders(String url) async {

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
  Map<String, dynamic>  jsonData = await jsonDecode(response.body);
return jsonData;
}
