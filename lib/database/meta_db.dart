

import 'package:com.rsmn574.app/database/sql/app_database.dart';
import 'package:sqflite/sqflite.dart';

class MetaDb {
  MetaDb._();
  static final MetaDb instance = MetaDb._();

  Future<String?> get(String key) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}