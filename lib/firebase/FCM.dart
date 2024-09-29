import 'package:firebase_messaging/firebase_messaging.dart';
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
Future<void> requestPermission() async {
  NotificationSettings settings = await _firebaseMessaging.requestPermission();
  print('User granted permission: ${settings.authorizationStatus}');
}

void setupForegroundMessageHandler() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message while in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
}

Future<void> setupFirebaseMessaging() async {
  // 获取 FCM 注册令牌
  String? token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    print("FCM Token: $token");
    // 在这里可以将 token 发送到你的服务器或保存到用户的设置中
  } else {
    print("无法获取 FCM Token");
  }
}