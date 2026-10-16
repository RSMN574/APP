import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:intl/intl.dart';
import 'package:com.rsmn574.app/database/get_data.dart';

Future<dynamic> fetchHSR(String trainNo, DateTime date) async {
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  String _trainNo = trainNo;
  var _date = dateFormat.format(date);
  var url =
      "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/DailyTimetable/TrainNo/$_trainNo/TrainDate/$_date?%24format=JSON";

  try {
    await connMysql();
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
    Map<String, dynamic> jsonData = await jsonDecode(response.body)[0];
    print(jsonData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}

//取得指定[日期],[起迄站間]之站間時刻表資料
Future<List<dynamic>> fetchHSRRoute(departureID, destinationID, time) async {
  // 对参数进行 URL 编码
  // String encodedDeparture = Uri.encodeComponent(departurePosition);
  // String encodedDestination = Uri.encodeComponent(destinationPosition);

  // String url="https://tdx.transportdata.tw/api/basic/v3/Rail/TRA/DailyTrainTimetable/OD/Inclusive/$departureID/to/$destinationID/$date?%24&%24format=JSON";
  String url =
      "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/DailyTimetable/OD/$departureID/to/$destinationID/$time?%24format=JSON";

  try {
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
    List<dynamic> jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}

Future<dynamic> fetchAvailableSeatStatus(
    String departureID, String arrivalID, String TrainNo, String date) async {
  var url =
      "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/AvailableSeatStatus/Train/OD/$departureID/to/$arrivalID/TrainDate/$date/TrainNo/$TrainNo?%24&%24format=JSON";

  try {
    await connMysql();
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
    Map<String, dynamic> jsonData = await jsonDecode(response.body);
    print(jsonData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}
