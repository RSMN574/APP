import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/sql/sqlite.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
String? FCMtoken;

// 初始化本地通知插件
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

StreamSubscription<RemoteMessage>? _onMessageSubscription;
StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

void setupForegroundMessageHandler() {
  // 先取消已有的监听器，避免重复触发
  _onMessageSubscription?.cancel();

  print("前台消息处理已启动");
  _onMessageSubscription =
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final notification = {
        'title': message.notification!.title ?? '無標題',
        'description': message.notification!.body ?? '無内容',
        'time': DateTime.now().toString(),
      };

      // 保存到数据库
      DatabaseHelper().insertNotification(notification);

      // 只显示一次通知
      showFlutterNotification(message);
    }
  });
}

void disposeFirebaseMessagingListeners() {
  _onMessageSubscription?.cancel();
  _onMessageSubscription = null;
  _onMessageOpenedAppSubscription?.cancel();
  _onMessageOpenedAppSubscription = null;
}

// 显示通知
Future<void> showFlutterNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel', // 通知渠道 ID
    'High Importance Notifications', // 通知渠道名称
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // 通知 ID
    message.notification?.title, // 通知标题
    message.notification?.body, // 通知内容
    platformChannelSpecifics,
  );
}

// 请求通知权限
Future<void> requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
}

// 初始化 Firebase Messaging 并获取设备令牌
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 创建通知渠道
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 获取设备令牌
  FCMtoken = await messaging.getToken();
  print("FCM Token: $FCMtoken");

  // 处理点击通知
  _onMessageOpenedAppSubscription?.cancel();
  _onMessageOpenedAppSubscription =
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A message was opened: ${message.notification?.title}');
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');

  // 初始化 Firebase (必須在後台處理程序中初始化)
  await Firebase.initializeApp();

  // 初始化本地通知插件
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 發送本地通知
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // 通知 ID
    message.notification?.title, // 通知标题
    message.notification?.body, // 通知内容
    platformChannelSpecifics,
  );

  // 注意：後台通知無法直接保存到數據庫
  // 可以考慮使用 shared_preferences 或其他輕量級存儲方式
  // 或者在應用程序下次啟動時從 FCM 獲取未讀通知
}
