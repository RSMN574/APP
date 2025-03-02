import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/SQL/sqlite.dart';

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

// 处理前台消息
void setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final notification = {
        'title': message.notification!.title ?? '无标题',
        'description': message.notification!.body ?? '无内容',
        'time': DateTime.now().toString(),
      };

      // 保存到数据库
      DatabaseHelper().insertNotification(notification); // 确保使用实例访问

      // print('Message Title: ${message.notification!.title}');
      // print('Message Body: ${message.notification!.body}');

      // 手动显示通知
      showFlutterNotification(message);
    }
  });
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
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A message was opened: ${message.notification?.title}');
  });
}

// 处理后台消息的顶级函数
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // 你可以在这里处理后台消息的逻辑，比如存储消息到本地数据库或显示通知
}
