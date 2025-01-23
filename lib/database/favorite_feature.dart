import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class favorite_feature {
  static final favorite_feature _instance = favorite_feature._internal();

  factory favorite_feature() => _instance;

  favorite_feature._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'data.db');

    return await openDatabase(
      path,
      version: 3, // 提升版本号以触发升级
      onCreate: (db, version) async {
        // 创建 FavoritesRoute 表
        print('Creating FavoritesRoute table');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS FavoritesRoute (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routeName TEXT NOT NULL,
            DepartureStopNameZh TEXT NOT NULL,
            DestinationStopNameZh TEXT NOT NULL,
            city TEXT NOT NULL,
            routeID INT NOT NULL
          )
        ''');

        // 创建 FavoritesStop 表
        print('Creating FavoritesStop table');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS FavoritesStop (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stopName TEXT NOT NULL,
            city TEXT NOT NULL
              
          )
        ''');
      },
      // onUpgrade: (db, oldVersion, newVersion) async {
      //   if (oldVersion < 3) {
      //     // 数据库版本从 1 升级到 2，创建 FavoritesStop 表
      //     print('Upgrading database to version $newVersion');
      //     await db.execute('''
      //       CREATE TABLE IF NOT EXISTS FavoritesStop (
      //         id INTEGER PRIMARY KEY AUTOINCREMENT,
      //         stopName TEXT NOT NULL,
      //         city TEXT NOT NULL
      //       )
      //     ''');
      //   }
      // },
    );
  }

  Future<List<Map<String, dynamic>>> getFavorites(
      String key, String currentCity, String city) async {
    final db = await database;

    // 添加搜索条件，查询符合城市条件的记录
    final results = await db.query(
      key,
      where: 'city = ?',
      whereArgs: [currentCity],
    );

    return results;
  }

  Future<int> addFavorite({
    String? DepartureStopNameZh,
    String? DestinationStopNameZh,
    String? routeName,
    String? StopName,
    required String city,
    required String table,
    routeID,
  }) async {
    if (table == "FavoritesRoute") {
      try {
        final db = await database;

        // 检查是否已存在相同的记录
        final existing = await db.query(
          'FavoritesRoute',
          where:
              'DepartureStopNameZh = ? AND DestinationStopNameZh = ? AND routeName = ? AND city = ? AND routeID = ?',
          whereArgs: [
            DepartureStopNameZh,
            DestinationStopNameZh,
            routeName,
            city,
            routeID
          ],
        );

        // 如果记录已存在，返回 -1 表示重复
        if (existing.isNotEmpty) {
          return -1;
        }

        // 尝试插入新记录
        await db.insert(
          'FavoritesRoute',
          {
            'DepartureStopNameZh': DepartureStopNameZh,
            'DestinationStopNameZh': DestinationStopNameZh,
            'routeName': routeName,
            'city': city,
            'routeID': routeID
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 插入成功返回 100
        return 100;
      } catch (e) {
        // 插入失败返回 200
        return 200;
      }
    } else if (table == "FavoritesStop") {
      try {
        final db = await database;

        // 检查是否已存在相同的记录
        final existing = await db.query(
          'FavoritesStop',
          where: 'stopName = ?  AND city = ?',
          whereArgs: [StopName, city],
        );

        // 如果记录已存在，返回 -1 表示重复
        if (existing.isNotEmpty) {
          return -1;
        }

        // 尝试插入新记录
        await db.insert(
          'FavoritesStop',
          {
            'stopName': StopName,
            'city': city,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 插入成功返回 100
        return 100;
      } catch (e) {
        // 插入失败返回 200
        return 200;
      }
    } else {
      return 200;
    }
  }

  Future<int> removeFavorite(
      {String? routeName,
      String? stopName,
      required String city,
      required String table}) async {
    final db = await database;
    // 尝试删除记录
    if (table == "FavoritesRoute") {
      final rowsAffected = await db.delete(
        'FavoritesRoute',
        where: 'routeName = ? AND city = ?', // 添加 city 条件
        whereArgs: [routeName, city], // 传递 routeName 和 city
      );
      // 根据删除结果返回不同值
      if (rowsAffected > 0) {
        return 100; // 成功删除
      } else {
        return 200; // 未找到匹配的记录，删除失败
      }
    } else if (table == "FavoritesStop") {
      final rowsAffected = await db.delete(
        'FavoritesStop',
        where: 'stopName = ? AND city = ?', // 添加 city 条件
        whereArgs: [stopName, city], // 传递 routeName 和 city
      );
      // 根据删除结果返回不同值
      if (rowsAffected > 0) {
        return 100; // 成功删除
      } else {
        return 200; // 未找到匹配的记录，删除失败
      }
    } else {
      return 200;
    }
  }

  Future<bool> isFavorite(String routeId) async {
    final db = await database;
    final result = await db.query(
      'FavoritesRoute',
      where: 'routeId = ?',
      whereArgs: [routeId],
    );
    return result.isNotEmpty;
  }
}
