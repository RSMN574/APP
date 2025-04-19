


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
      version: 7, // 提升版本號
      onCreate: (db, version) async {
        // 創建 schedule 表
        await db.execute('''
        CREATE TABLE IF NOT EXISTS schedule (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          Route TEXT NOT NULL,
          StartingStopName TEXT NOT NULL,   -- 新增路線起始站
          UserStartingStopName TEXT,        -- 新增用戶上車站
          FinalStopName TEXT NOT NULL,      -- 路線終點站
          UserDestinationStopName TEXT,     -- 用戶目的站
          other TEXT,                       -- 存儲 JSON 字符串
          city TEXT,
          routeID INTEGER,
          category TEXT,
          time TEXT,
          seatNumber TEXT                   -- 新增座位號碼
        )
      ''');

      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          // 確保舊版本升級到 6，添加 seatNumber 欄位
          await db.execute('ALTER TABLE schedule ADD COLUMN seatNumber TEXT');
        }
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
        if(type=="train") {
          // 检查是否已存在相同的记录
          final existing = await db.query(
            'schedule',
            where:
            'UserStartingStopName = ? AND UserDestinationStopName = ? AND StartingStopName = ? AND FinalStopName = ?  AND type = ? AND Route = ? AND time = ?',
            whereArgs: [
              UserStartingStopName,
              UserDestinationStopName,
              StartingStopName,
              FinalStopName,
              type,
              route,

            ],
          );

          // 如果记录已存在，返回 -1 表示重复
          if (existing.isNotEmpty) {
            return -1;
          }

        }else{
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
              city,

            ],
          );

          // 如果记录已存在，返回 -1 表示重复
          if (existing.isNotEmpty) {
            return -1;
          }
        }


            if(type=="train"  ) {
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

              "trainType": other?["trainType"] ?? "",
              'startDeparture':other?["startDeparture"],
              'endDeparture':other?["endDeparture"]
            }), // 轉為 JSON 字串存入
            'category': other?["category"],
            'time':  other?["DateTime"] ,
            'seatNumber':other?["seatNumber"],

          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
            else if( type=="HSR" ) {
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

                "trainType": other?["trainType"] ?? ""
              }), // 轉為 JSON 字串存入
              'category': other?["category"],
              'time':  other?["DateTime"] ,
              'seatNumber':other?["seatNumber"]
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
  Future<int> updateSchedule({
    required int id,
    String? UserStartingStopName,
    String? UserDestinationStopName,
    String? StartingStopName,
    String? FinalStopName,
    String? route,
    Map<String, dynamic>? other,
    String? type, // 改為非必填，僅更新時傳入
    String? city,
  }) async {
    try {
      final db = await database;
      Map<String, dynamic> updatedData = {};

      // 只更新傳入的非 null 值
      if (UserStartingStopName != null) {
        updatedData['UserStartingStopName'] = UserStartingStopName;
      }
      if (UserDestinationStopName != null) {
        updatedData['UserDestinationStopName'] = UserDestinationStopName;
      }
      if (StartingStopName != null) {
        updatedData['StartingStopName'] = StartingStopName;
      }
      if (FinalStopName != null) {
        updatedData['FinalStopName'] = FinalStopName;
      }
      if (route != null) {
        updatedData['Route'] = route;
      }
      if (type != null) {
        updatedData['type'] = type;
        // 根據 type 判斷其他欄位
        if (type == "train" || type == "HSR") {
          if (other != null) {
            if (other.containsKey("trainType")) {
              updatedData['other'] = jsonEncode({"trainType": other["trainType"]});
            }
            if (other.containsKey("category")) {
              updatedData['category'] = other["category"];
            }
            if (other.containsKey("DateTime")) {
              updatedData['time'] = other["DateTime"];
            }
            if (other.containsKey("seatNumber")) {
              updatedData['seatNumber'] = other["seatNumber"];
            }
          }
        } else {
          if (city != null) {
            updatedData['city'] = city;
          }
          if (other != null) {
            if (other.containsKey("routeID")) {
              updatedData['routeID'] = other["routeID"];
            }
            if (other.containsKey("category")) {
              updatedData['category'] = other["category"];
            }
          }
        }
      } else {
        // 若 type 沒有更新，但可能還有其他欄位
        if (city != null) {
          updatedData['city'] = city;
        }
        if (other != null) {
          if (other.containsKey("routeID")) {
            updatedData['routeID'] = other["routeID"];
          }
          if (other.containsKey("category")) {
            updatedData['category'] = other["category"];
          }
        }
      }

      int result = await db.update(
        'schedule',
        updatedData,
        where: 'id = ?',
        whereArgs: [id],
      );
      return result > 0 ? 100 : -1; // 100 表示成功，-1 表示未更新到資料（找不到記錄）
    } catch (e) {
      print("更新失敗: $e");
      return 200; // 200 表示發生錯誤
    }
  }
  Future<void> deleteExpiredSchedules( ) async {
    final db = await database;
    await db.execute('''
    DELETE FROM schedule WHERE time < datetime('now')
  ''');
  }


}
