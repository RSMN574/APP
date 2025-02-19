import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Const/regularConst.dart';
import '../getData.dart'; // 用于网络请求
Future<dynamic> fetchTrain(int trainNo,DateTime date) async {


  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  int _trainNo=trainNo;
  var _date=dateFormat.format(date) ;
  var url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/TrainNo/$_trainNo/TrainDate/$_date?%24format=JSON";

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
Map<String, dynamic>  jsonData = await jsonDecode(response.body)[0];

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}
// Future<List<dynamic>> fetchTrainStation(String station) async {
//
//
//
//   String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveBoard/Station/${station}?%24format=JSON";
//   try {
//     await  connMysql();
//     final tokenResponse = await http.get(tokenUri);
//     final token=tokenResponse.body;
//     // 发起 GET 请求
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'accept': 'application/json',
//       },
//     );
//
//     // 检查响应状态
//     if (response.statusCode != 200) {
//       throw HttpException('HTTP error! status: ${response.statusCode}');
//     }
//
//     // 解析 JSON 数据
//     List<dynamic>  jsonData = await jsonDecode(response.body);
// print(jsonData);
//     // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
//     // 这里你可以根据你的需求来构建 SQL 语句，例如：
//     // String sql = 'INSERT INTO $tableName (...) VALUES (...)';
//
//     return jsonData;
//   } catch (e) {
//     print('Error occurred: $e');
//   }
//   return [];
// }


Future<List<dynamic>> fetchTrainStation(String stationID,String date) async {



  String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/Station/$stationID/$date?%24format=JSON";
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
    List<dynamic>  jsonData = await jsonDecode(response.body);
    print(jsonData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
//取得指定[日期],[起迄站間]之站間時刻表資料
Future<List<dynamic>> fetchTrainRoute(departurePosition,destinationPosition,time) async {
  print(time);
  // 对参数进行 URL 编码
  String encodedDeparture = Uri.encodeComponent(departurePosition);
  String encodedDestination = Uri.encodeComponent(destinationPosition);
  String encodedTime = Uri.encodeComponent(time);
 // String url="https://tdx.transportdata.tw/api/basic/v3/Rail/TRA/DailyTrainTimetable/OD/Inclusive/$departureID/to/$destinationID/$date?%24&%24format=JSON";
  String url="https://tdx.transportdata.tw/api/maas/routing?origin=$encodedDeparture&destination=$encodedDestination&gc=0.0&top=10&transit=4&transfer_time=5%2C60&depart=$encodedTime&first_mile_mode=0&last_mile_mode=0";

  try {


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

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData["data"]["routes"];
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
//取得列車即時準點/延誤時間資料。
Future<List<dynamic>> fetchLiveTrainDelay(String trainNo) async {


  String filter = Uri.encodeComponent("TrainNo eq '$trainNo'");
  String url = "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveTrainDelay?\$filter=$filter&\$format=JSON";

  try {
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
    List<dynamic> jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';
    print(jsonData);
    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
