import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/bus.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();

  factory FavoriteService() => _instance;

  FavoriteService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        print('Creating FavoritesRoute table');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS FavoritesRoute (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routeUID TEXT NOT NULL,
            routeID TEXT NOT NULL,
            routeName TEXT NOT NULL,
            routeNameEn TEXT,
            departureStopNameZh TEXT NOT NULL,
            departureStopNameEn TEXT,
            destinationStopNameZh TEXT NOT NULL,
            destinationStopNameEn TEXT,
            city TEXT NOT NULL,
            cityCode TEXT,
            hasSubRoutes INTEGER DEFAULT 0,
            operatorName TEXT,
            ticketPriceDescriptionZh TEXT,
            ticketPriceDescriptionEn TEXT,
            routeMapImageUrl TEXT,
            firstBusTime TEXT,
            lastBusTime TEXT,
            created_at INTEGER DEFAULT (strftime('%s', 'now'))
          )
        ''');

        print('Creating FavoritesStop table');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS FavoritesStop (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            stopName TEXT NOT NULL,
            city TEXT NOT NULL,
            routeID TEXT,
            routeName TEXT,
            created_at INTEGER DEFAULT (strftime('%s', 'now'))
          )
        ''');

        // 創建索引以提高查詢速度
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_route_city ON FavoritesRoute(city)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_stop_city ON FavoritesStop(city)
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          // 添加新欄位
          try {
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN routeNameEn TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN departureStopNameEn TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN destinationStopNameEn TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN cityCode TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN hasSubRoutes INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN operatorName TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN firstBusTime TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN lastBusTime TEXT');
            await db.execute('ALTER TABLE FavoritesRoute ADD COLUMN created_at INTEGER DEFAULT (strftime("%s", "now"))');

            await db.execute('ALTER TABLE FavoritesStop ADD COLUMN routeID TEXT');
            await db.execute('ALTER TABLE FavoritesStop ADD COLUMN routeName TEXT');
            await db.execute('ALTER TABLE FavoritesStop ADD COLUMN created_at INTEGER DEFAULT (strftime("%s", "now"))');
          } catch (e) {
            print('升級數據庫時出錯: $e');
          }
        }
      },
    );
  }

  // ============ 路線收藏相關方法 ============

  /// 獲取所有收藏的路線
  Future<List<Map<String, dynamic>>> getFavoriteRoutes({String? city}) async {
    final db = await database;

    if (city != null && city.isNotEmpty) {
      return await db.query(
        'FavoritesRoute',
        where: 'city = ?',
        whereArgs: [city],
        orderBy: 'created_at DESC',
      );
    }

    return await db.query(
      'FavoritesRoute',
      orderBy: 'created_at DESC',
    );
  }

  /// 添加路線到收藏
  Future<int> addFavoriteRoute(BusRoute route) async {
    try {
      final db = await database;

      // 檢查是否已存在相同的記錄
      final existing = await db.query(
        'FavoritesRoute',
        where: 'routeUID = ? AND city = ?',
        whereArgs: [route.routeUID, route.city],
      );

      if (existing.isNotEmpty) {
        return -1; // 已存在
      }

      // 插入新記錄
      await db.insert(
        'FavoritesRoute',
        {
          'routeUID': route.routeUID,
          'routeID': route.routeID,
          'routeName': route.routeZh,
          'routeNameEn': route.routeEn,
          'departureStopNameZh': route.departureStopNameZh,
          'departureStopNameEn': route.departureStopNameEn,
          'destinationStopNameZh': route.destinationStopNameZh,
          'destinationStopNameEn': route.destinationStopNameEn,
          'city': route.city,
          'cityCode': route.cityCode,
          'hasSubRoutes': route.hasSubRoutes ? 1 : 0,
          'operatorName': route.operatorName,
          'ticketPriceDescriptionZh': route.ticketPriceDescriptionZh,
          'ticketPriceDescriptionEn': route.ticketPriceDescriptionEn,
          'routeMapImageUrl': route.routeMapImageUrl,
          'firstBusTime': route.firstBusTime,
          'lastBusTime': route.lastBusTime,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return 100; // 成功
    } catch (e) {
      print('添加收藏路線失敗: $e');
      return 200; // 失敗
    }
  }

  /// 從收藏中移除路線
  Future<int> removeFavoriteRoute(String routeUID, String city) async {
    try {
      final db = await database;

      final rowsAffected = await db.delete(
        'FavoritesRoute',
        where: 'routeUID = ? AND city = ?',
        whereArgs: [routeUID, city],
      );

      return rowsAffected > 0 ? 100 : 200;
    } catch (e) {
      print('移除收藏路線失敗: $e');
      return 200;
    }
  }

  /// 檢查路線是否已被收藏
  Future<bool> isRouteFavorite(String routeUID, String city) async {
    try {
      final db = await database;
      final result = await db.query(
        'FavoritesRoute',
        where: 'routeUID = ? AND city = ?',
        whereArgs: [routeUID, city],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('檢查收藏狀態失敗: $e');
      return false;
    }
  }

  /// 將收藏的路線轉換為 BusRoute 物件
  Future<List<BusRoute>> getFavoriteBusRoutes({String? city}) async {
    final routesData = await getFavoriteRoutes(city: city);
    return routesData.map((data) => _mapToBusRoute(data)).toList();
  }

  BusRoute _mapToBusRoute(Map<String, dynamic> data) {
    return BusRoute(
      routeUID: data['routeUID'] ?? '',
      routeID: data['routeID'] ?? '',
      hasSubRoutes: data['hasSubRoutes'] == 1,
      operators: [], // 從收藏中無法還原完整的 operators
      subRoutes: [
        {
          'FirstBusTime': data['firstBusTime'] ?? '',
          'LastBusTime': data['lastBusTime'] ?? '',
        }
      ],
      routeName: {
        'Zh_tw': data['routeName'] ?? '',
        'En': data['routeNameEn'] ?? '',
      },
      departureStopNameZh: data['departureStopNameZh'] ?? '',
      departureStopNameEn: data['departureStopNameEn'] ?? '',
      destinationStopNameZh: data['destinationStopNameZh'] ?? '',
      destinationStopNameEn: data['destinationStopNameEn'] ?? '',
      ticketPriceDescriptionZh: data['ticketPriceDescriptionZh'],
      ticketPriceDescriptionEn: data['ticketPriceDescriptionEn'],
      routeMapImageUrl: data['routeMapImageUrl'],
      city: data['city'] ?? '',
      cityCode: data['cityCode'] ?? '',
      updateTime: DateTime.now(), // 收藏時不保存更新時間
      versionID: 0,
    );
  }

  // ============ 站牌收藏相關方法 ============

  /// 獲取所有收藏的站牌
  Future<List<Map<String, dynamic>>> getFavoriteStops({String? city}) async {
    final db = await database;

    if (city != null && city.isNotEmpty) {
      return await db.query(
        'FavoritesStop',
        where: 'city = ?',
        whereArgs: [city],
        orderBy: 'created_at DESC',
      );
    }

    return await db.query(
      'FavoritesStop',
      orderBy: 'created_at DESC',
    );
  }

  /// 添加站牌到收藏
  Future<int> addFavoriteStop({
    required String stopName,
    required String city,
    String? routeID,
    String? routeName,
  }) async {
    try {
      final db = await database;

      // 檢查是否已存在
      final existing = await db.query(
        'FavoritesStop',
        where: 'stopName = ? AND city = ?',
        whereArgs: [stopName, city],
      );

      if (existing.isNotEmpty) {
        return -1; // 已存在
      }

      await db.insert(
        'FavoritesStop',
        {
          'stopName': stopName,
          'city': city,
          'routeID': routeID,
          'routeName': routeName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return 100; // 成功
    } catch (e) {
      print('添加收藏站牌失敗: $e');
      return 200; // 失敗
    }
  }

  /// 從收藏中移除站牌
  Future<int> removeFavoriteStop(String stopName, String city) async {
    try {
      final db = await database;

      final rowsAffected = await db.delete(
        'FavoritesStop',
        where: 'stopName = ? AND city = ?',
        whereArgs: [stopName, city],
      );

      return rowsAffected > 0 ? 100 : 200;
    } catch (e) {
      print('移除收藏站牌失敗: $e');
      return 200;
    }
  }

  /// 檢查站牌是否已被收藏
  Future<bool> isStopFavorite(String stopName, String city) async {
    try {
      final db = await database;
      final result = await db.query(
        'FavoritesStop',
        where: 'stopName = ? AND city = ?',
        whereArgs: [stopName, city],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('檢查站牌收藏狀態失敗: $e');
      return false;
    }
  }

  // ============ 通用方法 ============

  /// 獲取所有收藏（路線和站牌）
  Future<Map<String, List<Map<String, dynamic>>>> getAllFavorites({String? city}) async {
    final routes = await getFavoriteRoutes(city: city);
    final stops = await getFavoriteStops(city: city);

    return {
      'routes': routes,
      'stops': stops,
    };
  }

  /// 清除所有收藏
  Future<void> clearAllFavorites() async {
    final db = await database;
    await db.delete('FavoritesRoute');
    await db.delete('FavoritesStop');
  }

  /// 獲取收藏數量
  Future<int> getFavoriteCount() async {
    final db = await database;
    final routeCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM FavoritesRoute')
    ) ?? 0;
    final stopCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM FavoritesStop')
    ) ?? 0;
    return routeCount + stopCount;
  }

  /// 關閉數據庫
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

// 為了向後兼容，保留原類名作為別名
typedef favorite_feature = FavoriteService;