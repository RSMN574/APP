import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../l10n/app_localizations.dart';

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
    print(maps);
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

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          final notification = {
            'title': message.notification!.title ?? AppLocalizations.of(context as BuildContext)!.text_25,
            'time': DateTime.now().toString(),
            'description': message.notification!.body ?? AppLocalizations.of(context as BuildContext)!.text_433,
          };
          _insertNotification(notification); // 插入到数据库
        }
      });
    } else {
      print(AppLocalizations.of(context as BuildContext)!.text_434);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('應用從通知打開: ${message.notification?.title}');
      // 处理点击通知的逻辑
    });
  }

  @override
  Widget build( context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.text_435,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState(context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A73E8),
                    Color(0xFF1A73E8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 60,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context )!.text_436,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context )!.text_437,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                AppLocalizations.of(context )!.text_438,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return Column(
      children: [
        // 標題欄
        _buildHeader(),
        const SizedBox(height: 8),
        // 通知列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context as BuildContext)!.text_439,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            '${notifications.length} 則通知',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isUnread = notification['read'] == false;
    final notificationType = notification['type'] ?? 'info';

    return Transform.translate(
      offset: Offset(0, index * 0.5), // 微妙的層次感
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
          highlightColor: const Color(0xFFEEF3FB).withOpacity(0.5),
          child: Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isUnread ? 0.08 : 0.04),
                  blurRadius: isUnread ? 20 : 12,
                  offset: Offset(0, isUnread ? 6 : 3),
                ),
              ],
              border: isUnread
                  ? Border.all(
                color: const Color(0xFF1A73E8).withOpacity(0.2),
                width: 1.5,
              )
                  : null,
            ),
            child: Stack(
              children: [
                // 左側裝飾線
                if (isUnread)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A73E8),
                            const Color(0xFF1A73E8).withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.only(
                    left: isUnread ? 20 : 24,
                    right: 24,
                    top: 20,
                    bottom: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 圖標區域
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: _getNotificationGradient(notificationType),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _getNotificationColor(notificationType).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getNotificationIcon(notificationType),
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 內容區域
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 標題和時間
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title']!,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isUnread ? Colors.black87 : Colors.grey[700],
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    notification['time']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // 描述
                            Text(
                              notification['description']!,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // 標籤和操作
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // 類型標籤
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(notificationType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getNotificationColor(notificationType).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _getNotificationTypeText(notificationType),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getNotificationColor(notificationType),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // 未讀標記
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A73E8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getNotificationGradient(String type) {
    final color = _getNotificationColor(type);
    return LinearGradient(
      colors: [
        color,
        color.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return const Color(0xFFFF9500);
      case 'error':
        return const Color(0xFFFF3B30);
      case 'success':
        return const Color(0xFF34C759);
      case 'promotion':
        return const Color(0xFFAF52DE);
      case 'info':
      default:
        return const Color(0xFF1A73E8);
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'warning':
        return AppLocalizations.of(context as BuildContext)!.text_440;
      case 'error':
        return AppLocalizations.of(context as BuildContext)!.text_441;
      case 'success':
        return AppLocalizations.of(context as BuildContext)!.text_442;
      case 'promotion':
        return AppLocalizations.of(context as BuildContext)!.text_443;
      case 'info':
      default:
        return AppLocalizations.of(context as BuildContext)!.text_444;
    }
  }

  void _showMoreOptions() {
    // 顯示更多選項
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // 處理通知點擊
  }
}
