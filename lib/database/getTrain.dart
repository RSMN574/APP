import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'getData.dart'; // 用于网络请求
Future<dynamic> fetchTrain(int trainNo,DateTime date) async {

  final tokenUri = Uri.parse('http://hidden.rsmn574.com:3920/token');
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