import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, String>> notifications = [];
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
    _initDatabase().then((db) {
      _database = db;
      _loadNotifications(); // 加载已有通知
    });
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notifications.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, time TEXT)',
        );
      },
    );
  }

  void _loadNotifications() async {
    final List<Map<String, dynamic>> maps = await _database!.query('notifications');
    setState(() {
      notifications.clear(); // 清空旧通知
      notifications.addAll(maps.map((map) => {
        'title': map['title'] as String,
        'description': map['description'] as String,
        'time': map['time'] as String,
      }));
    });
  }

  void _insertNotification(Map<String, String> notification) async {
    await _database!.insert(
      'notifications',
      {
        'title': notification['title'],
        'description': notification['description'],
        'time': notification['time'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadNotifications(); // 重新加载通知
  }

  void _setupFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('用户授權接收通知');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          final notification = {
            'title': message.notification!.title ?? '無標題',
            'time': DateTime.now().toString(),
            'description': message.notification!.body ?? '無內容',
          };
          _insertNotification(notification); // 插入到数据库
        }
      });
    } else {
      print('用戶拒絕通知');
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('應用從通知打開: ${message.notification?.title}');
      // 处理点击通知的逻辑
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知'),
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('當前沒有通知'))
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
