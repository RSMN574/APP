import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';




// 初始化通知
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
Future<dynamic> fetchBusTimeByTask(routeName,routeID, city,stopID) async {


  String filter = "StopID eq '$stopID' and RouteID eq '$routeID'";
  String encodedFilter = Uri.encodeQueryComponent(filter);



  var url = "https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName"
      "?%24filter=$encodedFilter&%24format=JSON";
  // final token =await  getToken();

  try {
    // await connMysql();

    // 发起 GET 请求
    final response = await http.get(
      Uri.parse(url),
      headers: {
        // 'Authorization': 'Bearer $token',
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

    if (kDebugMode) {
      print('JSON fetched successfully: $jsonData');
    }
    return jsonData;
  } catch (e) {
    if (kDebugMode) {
      print('Error occurred: $e');
    }
  }
}
Future<void> backgroundTask() async {
  final prefs    = await SharedPreferences.getInstance();
  final tasks    = prefs.getStringList('reminderTasks') ?? [];

  for (var jsonStr in tasks) {
    final task = jsonDecode(jsonStr) as Map<String, dynamic>;
    final type  = task['transportType'] as String;
    final name  = task['routeName']     as String;
    final id    = task['routeID']       as String;
    final city  = task['city']          as String;
    final UserDestinationStopName  = task['UserDestinationStopName']          as String;

    List<dynamic> data;
    // 根據 type 呼叫不同的 fetchXxxByTask(...)
    if (type == 'bus') {
      final stop  = task['stopID']        as String;
      data = await fetchBusTimeByTask(name, id, city, stop);
      for (final item in data) {
        final et = item['EstimateTime'] as int?;
        if (et != null && et < 300) {
          await flutterLocalNotificationsPlugin.show(
            id.hashCode, // 每筆任務不同的通知 ID
            '到站提醒',
            '【$type】$name 即將抵達 $UserDestinationStopName！',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                '到站提醒', '到站提醒通知',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
          break;
        }
      }
    } else   if (type == 'train') {
      await flutterLocalNotificationsPlugin.show(
        id.hashCode, // 每筆任務不同的通知 ID
        '到站提醒',
        '【$type】$name 即將抵達 $UserDestinationStopName！',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            '到站提醒', '到站提醒通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }else {
      continue; // 其他類型同理
    }


  }
}

Future<void> startReminder({
  required String transportType, // 例如 'bus'
  required String routeName,
  required String routeID,
  required String city,
  String? stopID, // 改為可選
   required UserStartingStopName, required UserDestinationStopName,
}) async {
  final prefs = await SharedPreferences.getInstance();
if(transportType=="bus"){
  // 建立新提醒任務資料
  final newTask = {
    'transportType': transportType,
    'routeName': routeName,
    'routeID': routeID,
    'city': city,
    'stopID': stopID,
    'UserStartingStopName':UserStartingStopName,
    'UserDestinationStopName':UserDestinationStopName

  };
  // 加入提醒任務清單
  List<String> taskList = prefs.getStringList('reminderTasks') ?? [];
  taskList.add(jsonEncode(newTask));
  await prefs.setStringList('reminderTasks', taskList);

  // 啟動背景任務（僅需啟動一次）
  await AndroidAlarmManager.periodic(
    const Duration(minutes: 1),
    9999, // 全域任務 ID，建議不要用 routeID，否則會重複啟動
    backgroundTask,
    wakeup: true,
    exact: true,
    rescheduleOnReboot: true,
  );

  print("提醒已啟動：${newTask['transportType']} ${newTask['routeName']}");
}



}
Future<void> removeReminder(String routeID) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> taskList = prefs.getStringList('reminderTasks') ?? [];

  // 移除符合 routeID 的項目
  taskList.removeWhere((task) {
    final taskData = jsonDecode(task);
    return taskData['routeID'] == routeID;
  });

  await prefs.setStringList('reminderTasks', taskList);
  print("提醒已移除：$routeID");

  // 如果全部都刪光了，也可以考慮停止 Alarm Manager
  if (taskList.isEmpty) {
    await AndroidAlarmManager.cancel(9999);
    print("已停止所有背景任務");
  }
}
Future<void> testTask() async {
  try {
    // 獲取當前時間的分鐘數
    int currentMinute = DateTime.now().minute;

    // 檢查當前分鐘數是否為偶數
    if (currentMinute % 2 == 0) {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // 使用時間戳作為唯一 ID
        '到站提醒測試',
        '【測試類型】測試路線 即將抵達 測試站牌！',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'arrival_alerts_channel', // 必須與主 channel ID 一致
            '到站提醒通知',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true, // 測試時建議開啟聲音
            enableVibration: true,
          ),
        ),
      );
      debugPrint('測試通知已觸發');
    } else {
      debugPrint('當前分鐘數為奇數，未觸發通知');
    }
  } catch (e) {
    debugPrint('通知發送失敗: $e');
  }
}
