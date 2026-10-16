import 'package:com.rsmn574.app/database/sql/sqlite.dart';

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.description,
    required this.time,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
    );
  }

  final String title;
  final String description;
  final String time;

  Map<String, String> toMap() =>
      {'title': title, 'description': description, 'time': time};
}

class NotificationRepository {
  NotificationRepository({DatabaseHelper? database})
      : _database = database ?? DatabaseHelper();

  final DatabaseHelper _database;

  Future<List<NotificationItem>> getNotifications() async {
    final maps = await _database.getNotifications();
    return maps.map(NotificationItem.fromMap).toList();
  }
}
