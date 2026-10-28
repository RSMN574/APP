
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/tdx_api_client.dart';

const String _tasksKey = 'reminderTasks';
const int _alarmId = 9999;
const String _channelId = 'arrival_alerts_channel';
const String _channelName = '到站提醒通知';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const InitializationSettings _notificationSettings = InitializationSettings(
  android: AndroidInitializationSettings('@mipmap/ic_launcher'),
);

const NotificationDetails _arrivalNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: '公車到站提醒',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  ),
);

/// 在 main() 的 runApp() 之前呼叫。
Future<void> initializeArrivalReminderService() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialized = await AndroidAlarmManager.initialize();
  debugPrint('[ArrivalReminder] AlarmManager initialized: $initialized');

  await flutterLocalNotificationsPlugin.initialize(
    _notificationSettings,
  );

  final androidPlugin =
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  final permissionGranted =
  await androidPlugin?.requestNotificationsPermission();

  debugPrint(
    '[ArrivalReminder] Notification permission: $permissionGranted',
  );
}

/// 查詢 TDX 公車預估到站資料。
Future<List<dynamic>> fetchBusTimeByTask(
    String routeName,
    String routeID,
    String city,
    String stopID,
    ) async {
  final filter = "StopID eq '$stopID' and RouteID eq '$routeID'";

  final uri = Uri.https(
    'tdx.transportdata.tw',
    '/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName',
    {
      r'$filter': filter,
      r'$format': 'JSON',
    },
  );

  final response = await TdxApiClient().getRaw(
    uri,
    headers: const {'accept': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw HttpException(
      'TDX HTTP ${response.statusCode}',
      uri: uri,
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! List) {
    throw const FormatException('TDX 回傳格式不是清單');
  }

  return decoded;
}

/// 穩定的通知 ID。
int _notificationId(String key) {
  var hash = 0;

  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }

  return hash == 0 ? 1 : hash;
}

String _taskKey({
  required String transportType,
  required String routeID,
  required String city,
  required String stopID,
}) {
  return '$transportType|$city|$routeID|$stopID';
}

/// 背景工作入口必須是頂層函式。
@pragma('vm:entry-point')
Future<void> backgroundTask() async {
  try {
    DartPluginRegistrant.ensureInitialized();

    await flutterLocalNotificationsPlugin.initialize(
      _notificationSettings,
    );

    final prefs = await SharedPreferences.getInstance();
    final storedTasks = prefs.getStringList(_tasksKey) ?? [];

    if (storedTasks.isEmpty) return;

    final updatedTasks = <String>[];

    for (final raw in storedTasks) {
      Map<String, dynamic> task;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        task = Map<String, dynamic>.from(decoded);
      } catch (error) {
        debugPrint('[ArrivalReminder] 無效任務資料：$error');
        continue;
      }

      if (task['notified'] == true ||
          task['transportType'] != 'bus') {
        updatedTasks.add(jsonEncode(task));
        continue;
      }

      final routeName = task['routeName']?.toString() ?? '';
      final routeID = task['routeID']?.toString() ?? '';
      final city = task['city']?.toString() ?? '';
      final stopID = task['stopID']?.toString() ?? '';
      final stopName =
          task['UserDestinationStopName']?.toString() ?? '';

      if (routeName.isEmpty ||
          routeID.isEmpty ||
          city.isEmpty ||
          stopID.isEmpty ||
          stopName.isEmpty) {
        debugPrint('[ArrivalReminder] 任務缺少必要欄位：$task');
        updatedTasks.add(jsonEncode(task));
        continue;
      }

      try {
        final data = await fetchBusTimeByTask(
          routeName,
          routeID,
          city,
          stopID,
        );

        var shouldNotify = false;

        for (final item in data) {
          if (item is! Map) continue;

          if (item['RouteID']?.toString() != routeID ||
              item['StopID']?.toString() != stopID) {
            continue;
          }

          final estimate = item['EstimateTime'];

          if (estimate is num && estimate >= 0 && estimate < 300) {
            shouldNotify = true;
            break;
          }
        }

        if (shouldNotify) {
          final key = task['taskKey']?.toString() ??
              _taskKey(
                transportType: 'bus',
                routeID: routeID,
                city: city,
                stopID: stopID,
              );

          await flutterLocalNotificationsPlugin.show(
            _notificationId(key),
            '公車到站提醒',
            '$routeName 即將抵達 $stopName，請留意公車動態。',
            _arrivalNotificationDetails,
          );

          task['notified'] = true;
          debugPrint('[ArrivalReminder] 已通知：$routeName / $stopName');
        }
      } catch (error, stackTrace) {
        // API 失敗時保留任務，下一輪仍可重試。
        debugPrint('[ArrivalReminder] 提醒任務執行失敗：$error');
        debugPrintStack(stackTrace: stackTrace);
      }

      updatedTasks.add(jsonEncode(task));
    }

    await prefs.setStringList(_tasksKey, updatedTasks);
  } catch (error, stackTrace) {
    debugPrint('[ArrivalReminder] 背景工作失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

/// 建立公車到站提醒。
Future<void> startReminder({
  required String transportType,
  required String routeName,
  required String routeID,
  required String city,
  String? stopID,
  required String UserStartingStopName,
  required String UserDestinationStopName,
}) async {
  final normalizedStopID = stopID?.trim() ?? '';

  if (transportType != 'bus') {
    throw ArgumentError('目前只支援公車到站提醒');
  }

  if (routeName.trim().isEmpty ||
      routeID.trim().isEmpty ||
      city.trim().isEmpty ||
      normalizedStopID.isEmpty) {
    throw ArgumentError('路線名稱、路線 ID、城市及站牌 ID 不可為空');
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final originalTasks = prefs.getStringList(_tasksKey) ?? [];
    final tasks = <Map<String, dynamic>>[];

    for (final raw in originalTasks) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          tasks.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // 忽略損壞的舊任務資料。
      }
    }

    final key = _taskKey(
      transportType: 'bus',
      routeID: routeID.trim(),
      city: city.trim(),
      stopID: normalizedStopID,
    );

    final existingIndex = tasks.indexWhere((task) {
      if (task['taskKey'] == key) return true;

      return task['transportType'] == 'bus' &&
          task['city']?.toString() == city.trim() &&
          task['routeID']?.toString() == routeID.trim() &&
          task['stopID']?.toString() == normalizedStopID;
    });

    if (existingIndex == -1) {
      tasks.add({
        'taskKey': key,
        'transportType': 'bus',
        'routeName': routeName.trim(),
        'routeID': routeID.trim(),
        'city': city.trim(),
        'stopID': normalizedStopID,
        'UserStartingStopName': UserStartingStopName,
        'UserDestinationStopName': UserDestinationStopName,
        'notified': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    final saved = await prefs.setStringList(
      _tasksKey,
      tasks.map(jsonEncode).toList(),
    );

    if (!saved) {
      throw StateError('無法儲存提醒任務');
    }

    // 先確認 AlarmManager 已初始化，再建立週期排程。
    final scheduled = await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      _alarmId,
      backgroundTask,
      wakeup: true,
      rescheduleOnReboot: true,
      exact: false,
    );

    if (!scheduled) {
      // 回復儲存前的任務清單。
      await prefs.setStringList(_tasksKey, originalTasks);
      throw StateError('AndroidAlarmManager 無法建立背景排程');
    }

    debugPrint('[ArrivalReminder] 提醒建立成功：$key');
  } catch (error, stackTrace) {
    debugPrint('[ArrivalReminder] 新增提醒失敗：$error');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }
}

/// 移除指定路線的所有提醒。
Future<void> removeReminder(String routeID) async {
  final prefs = await SharedPreferences.getInstance();
  final tasks = prefs.getStringList(_tasksKey) ?? [];
  final remaining = <String>[];

  for (final raw in tasks) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) continue;

      final task = Map<String, dynamic>.from(decoded);

      if (task['routeID']?.toString() == routeID) {
        final key = task['taskKey']?.toString();
        if (key != null) {
          await flutterLocalNotificationsPlugin.cancel(
            _notificationId(key),
          );
        }
      } else {
        remaining.add(raw);
      }
    } catch (_) {
      remaining.add(raw);
    }
  }

  await prefs.setStringList(_tasksKey, remaining);

  if (remaining.isEmpty) {
    await AndroidAlarmManager.cancel(_alarmId);
  }

  debugPrint('[ArrivalReminder] 已移除路線提醒：$routeID');
}

/// 移除指定站牌的提醒。
Future<void> removeReminderByStop({
  required String routeID,
  required String city,
  required String stopID,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final tasks = prefs.getStringList(_tasksKey) ?? [];

  final key = _taskKey(
    transportType: 'bus',
    routeID: routeID,
    city: city,
    stopID: stopID,
  );

  final remaining = <String>[];

  for (final raw in tasks) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        remaining.add(raw);
        continue;
      }

      final task = Map<String, dynamic>.from(decoded);

      if (task['taskKey'] == key) {
        await flutterLocalNotificationsPlugin.cancel(
          _notificationId(key),
        );
      } else {
        remaining.add(raw);
      }
    } catch (_) {
      remaining.add(raw);
    }
  }

  await prefs.setStringList(_tasksKey, remaining);

  if (remaining.isEmpty) {
    await AndroidAlarmManager.cancel(_alarmId);
  }
}

/// 手動測試本機通知。
Future<void> testTask() async {
  await flutterLocalNotificationsPlugin.show(
    777001,
    '到站提醒測試',
    '這是一則台灣通本機通知測試。',
    _arrivalNotificationDetails,
  );
}
