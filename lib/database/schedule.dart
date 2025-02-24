


import 'dart:convert';

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
      version: 6, // 提升版本号以触发升级
      onCreate: (db, version) async {
        // 创建 FavoritesRoute 表

        await db.execute('''
  CREATE TABLE IF NOT EXISTS schedule (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    Route TEXT NOT NULL,
    StartingStopName TEXT NOT NULL,         -- 新增路線起始站
    UserStartingStopName TEXT,             -- 新增用戶上車站
    FinalStopName TEXT NOT NULL,           -- 路線終點站
    UserDestinationStopName TEXT,          -- 用戶目的站
    other TEXT,                            -- 存储 JSON 字符串
    city TEXT ,
    routeID INTEGER,
    category TEXT
  )
''');



      },

    );
  }

  Future<List<Map<String, dynamic>>> getSchedule(String key, [String? city]) async {
    final db = await database;

    // 添加搜索条件，查询符合城市条件的记录
    final results = await db.query(
      "schedule",
      // where: 'city = ?',
      // whereArgs: [city],
    );


    return results;
  }

  Future<int> addSchedule({
    String? UserStartingStopName,
    String? UserDestinationStopName,
    String? StartingStopName,
    String? FinalStopName,
    String? route,
     Map<String,dynamic>? other,
    required String type,
     String? city,

  }) async {

      try {
        final db = await database;

        // 检查是否已存在相同的记录
        final existing = await db.query(
          'schedule',
          where:
          'UserStartingStopName = ? AND UserDestinationStopName = ? AND StartingStopName = ? AND FinalStopName = ?  AND type = ? AND Route = ? AND city = ?',
          whereArgs: [
            UserStartingStopName,
            UserDestinationStopName,
            StartingStopName,
            FinalStopName,
            type,
            route,
            city
          ],
        );

        // 如果记录已存在，返回 -1 表示重复
        if (existing.isNotEmpty) {
          return -1;
        }

            if(type=="train") {
        // 尝试插入新记录
        await db.insert(
          'schedule',
          {
            'UserStartingStopName': UserStartingStopName,
            'UserDestinationStopName': UserDestinationStopName,
            'StartingStopName': StartingStopName,
            'FinalStopName': FinalStopName,
            'type': type,
            'Route': route,
            'other': jsonEncode({
              "DateTime": other?["DateTime"] ?? "",
              "trainType": other?["trainType"] ?? ""
            }), // 轉為 JSON 字串存入
            'category': other?["category"]
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }else{
              // 尝试插入新记录
              await db.insert(
                'schedule',
                {
                  'UserStartingStopName': UserStartingStopName,
                  'UserDestinationStopName': UserDestinationStopName,
                  'StartingStopName': StartingStopName,
                  'FinalStopName': FinalStopName,
                  'type': type,
                  'Route': route,
                  'city': city,
                  'routeID': other?["routeID"],
                  'category': other?["category"]
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }

      // 插入成功返回 100
        return 100;
      } catch (e) {
        // 插入失败返回 200
          print(200);
          print(e);
        return 200;
      }

  }



  Future<int> removeSchedule(
      {required String route,String? stopName, required String city,required String type,required String table,required String UserStartingStopName,
        required String UserDestinationStopName,required String StartingStopName,required String FinalStopName}) async {
    final db = await database;
    // 尝试删除记录
    if(table=="schedule"){
    if(type=="bus"){
      final rowsAffected = await db.delete(
        'schedule',
        where: 'Route = ? AND city = ? AND type = ? AND UserStartingStopName = ? AND UserDestinationStopName = ? AND StartingStopName = ? AND FinalStopName = ?', // 添加 city 条件
        whereArgs: [route, city,type,UserStartingStopName,UserDestinationStopName,StartingStopName,FinalStopName,], // 传递 routeName 和 city
      );
      // 根据删除结果返回不同值
      if (rowsAffected > 0) {
        return 100; // 成功删除
      } else {
        return 200; // 未找到匹配的记录，删除失败
      }
    }else{
      final rowsAffected = await db.delete(
        'schedule',
        where: 'Route = ?  AND type = ? AND UserStartingStopName = ? AND UserDestinationStopName = ? AND StartingStopName = ? AND FinalStopName = ?', // 去除 city 条件
        whereArgs: [route,type,UserStartingStopName,UserDestinationStopName,StartingStopName,FinalStopName,], // 传递 routeName
      );
      // 根据删除结果返回不同值
      if (rowsAffected > 0) {
        return 100; // 成功删除
      } else {
        return 200; // 未找到匹配的记录，删除失败
      }
    }
    }else{
      return -1;
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
