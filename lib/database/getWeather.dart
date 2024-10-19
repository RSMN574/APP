import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mysql_client/mysql_client.dart';
import '../Const/regularClass.dart';

MySQLConnection? _conn;

Future<Map<String, dynamic>> getWeatherInfo( context) async {
  String currentCity = Provider.of<CityProvider>(context, listen: false).city;
  String? recentWeatherStatus;
  String? recentMinTemp;
  String? recentMaxTemp;
  String unit = "°C"; // 假设温度单位为摄氏度

  try {
    // 建立 MySQL 连接
    _conn = await MySQLConnection.createConnection(
      host: "hidden.rsmn574.com",
      port: 3306,
      userName: "onlyForApiRead",
      password: "@Nick0319Lucas0221",
      databaseName: "Weather",
    );
    await _conn!.connect();
    print("MySQL connection established.");

    // 获取当前时间
    final now = DateTime.now();
    final currentTimeString = now.toIso8601String().replaceFirst('T', ' ').substring(0, 19);

    // 查询 startTime 和 endTime 在当前时间范围内的所有天气数据
    final results = await _conn?.execute(
      'SELECT * FROM weather ',

    );
    // 处理结果
    if (results != null) {
      for (var row in results) {
        print(row);
        // recentWeatherStatus = row[4]; // 假设天气状态在第5列
        // recentMinTemp = row[5]; // 假设最小温度在第6列
        // recentMaxTemp = row[6]; // 假设最大温度在第7列
        // print('Resource ID: ${row[0]}, Location: ${row[1]}, Start Time: ${row[2]}, End Time: ${row[3]}');
      }
    } else {
      print("No weather data found for the current time.");
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    // 关闭连接
    await _conn?.close();
  }

  return {
    "city": currentCity,
    "recentWeatherStatus": recentWeatherStatus ?? "N/A",
    "recentMinTemp": recentMinTemp != null ? '$recentMinTemp$unit' : "N/A",
    "recentMaxTemp": recentMaxTemp != null ? '$recentMaxTemp$unit' : "N/A",
  };
}
