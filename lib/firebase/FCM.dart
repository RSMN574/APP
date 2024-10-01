import 'package:firebase_messaging/firebase_messaging.dart';

String? FCMtoken;
// 处理后台消息
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');

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

// 前台消息处理
void setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('Message title: ${message.notification!.title}');
      print('Message body: ${message.notification!.body}');
    }
  });
}

// 初始化 Firebase Messaging 并获取设备令牌
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 获取设备令牌
  FCMtoken = await messaging.getToken();
  print("FCM Token: $FCMtoken");

  // 处理点击通知
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A message was opened: ${message.notification?.title}');
  });
}
