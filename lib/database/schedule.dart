

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class schedule {
  static final schedule _instance = schedule._internal();
  factory schedule() => _instance;

  schedule._internal();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'schedule.db');

    return await openDatabase(
      path,
      version: 2, // 提升版本号以触发升级
      onCreate: (db, version) async {
        // 创建 FavoritesRoute 表
        print('Creating schedule table');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS schedule (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            Route TEXT NOT NULL,
            DepartureStopName TEXT NOT NULL,
            DestinationStopName TEXT NOT NULL,
            other JSON,
            city TEXT NOT NULL
          )
        ''');



      },

    );
  }

  Future<List<Map<String, dynamic>>> getSchedule(String key, String city) async {
    final db = await database;

    // 添加搜索条件，查询符合城市条件的记录
    final results = await db.query(
      "schedule",
      where: 'city = ?',
      whereArgs: [city],
    );

print(results);
    return results;
  }

  Future<int> addSchedule({
    String? DepartureStopName,
    String? DestinationStopName,
    String? route,
    String? other,
    required String type,
    required String city,

  }) async {

      try {
        final db = await database;

        // 检查是否已存在相同的记录
        final existing = await db.query(
          'schedule',
          where:
          'DepartureStopName = ? AND DestinationStopName = ? AND type = ? AND Route = ? AND city = ?',
          whereArgs: [
            DepartureStopName,
            DestinationStopName,
            type,
            route,
            city
          ],
        );

        // 如果记录已存在，返回 -1 表示重复
        if (existing.isNotEmpty) {
          return -1;
        }

        // 尝试插入新记录
        await db.insert(
          'schedule',
          {
            'DepartureStopName': DepartureStopName,
            'DestinationStopName': DestinationStopName,
            'type':type,
            'Route': route,
            'city': city,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 插入成功返回 100
        return 100;
      } catch (e) {
        // 插入失败返回 200
          print(e);
        return 200;
      }

  }



  Future<int> removeSchedule(
      {String? route,String? stopName, required String city,required String type,required String table,required int id,required String DestinationStopName,required String DepartureStopName}) async {
    final db = await database;
    // 尝试删除记录
    if(table=="schedule"){
      final rowsAffected = await db.delete(
        'schedule',
        where: 'Route = ? AND city = ? AND id = ? AND type = ? AND DestinationStopName = ? AND DepartureStopName = ?', // 添加 city 条件
        whereArgs: [route, city,id,type,DestinationStopName,DepartureStopName], // 传递 routeName 和 city
      );
      // 根据删除结果返回不同值
      if (rowsAffected > 0) {
        return 100; // 成功删除
      } else {
        return 200; // 未找到匹配的记录，删除失败
      }
    }else{
      return 200;
    }


  }


  Future<bool> isSchedule(String route) async {
    final db = await database;
    final result = await db.query(
      'schedule',
      where: 'Route = ?',
      whereArgs: [route],
    );
    return result.isNotEmpty;
  }
}
