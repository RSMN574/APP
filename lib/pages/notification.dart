import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, String>> notifications = [];
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    // 请求通知权限
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('用户授权接收通知');

      // 监听前台消息
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          // 将通知添加到列表
          setState(() {
            notifications.add({
              'title': message.notification!.title ?? '无标题',
              'time': DateTime.now().toString(),
              'description': message.notification!.body ?? '无内容',
            });
          });
        }
      });
    } else {
      print('用户拒绝接收通知');
    }

    // 处理打开应用时的通知
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('应用从通知打开: ${message.notification?.title}');
      // 这里可以添加处理点击通知的逻辑
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知'),
      ),
      body: notifications.isEmpty
          ? Center(child: Text('当前没有通知'))
          : ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            leading: Icon(Icons.notifications),
            title: Text(notification['title']!),
            subtitle: Text(notification['description']!),
            trailing: Text(notification['time']!),
            onTap: () {
              // 可以添加点击通知的处理逻辑
            },
          );
        },
      ),
    );
  }
}
