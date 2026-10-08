import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 資料模型
class ScheduleModel {
  int? id;
  final String type;
  final String route;
  final String? startingStopName;
  final String? userStartingStopName;
  final String? finalStopName;
  final String? userDestinationStopName;
  final String? city;
  final int? routeID;
  final String? category;
  final String? time;
  final String? seatNumber;
  final Map<String, dynamic>? other;

  ScheduleModel({
    this.id,
    required this.type,
    required this.route,
    this.startingStopName,
    this.userStartingStopName,
    this.finalStopName,
    this.userDestinationStopName,
    this.city,
    this.routeID,
    this.category,
    this.time,
    this.seatNumber,
    this.other,
  });
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'Route': route,
      'StartingStopName': startingStopName,
      'UserStartingStopName': userStartingStopName,
      'FinalStopName': finalStopName,
      'UserDestinationStopName': userDestinationStopName,
      'city': city,
      'routeID': routeID,
      'category': category,
      'time': time,
      'seatNumber': seatNumber,
    };
    if (other != null) {
      map['other'] = jsonEncode(other);
    }
    return map;
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      route: map['Route'] as String,
      startingStopName: map['StartingStopName'] as String,
      userStartingStopName: map['UserStartingStopName'] as String?,
      finalStopName: map['FinalStopName'] as String,
      userDestinationStopName: map['UserDestinationStopName'] as String?,
      city: map['city'] as String?,
      routeID: map['routeID'] as int?,
      category: map['category'] as String?,
      time: map['time'] as String,
      seatNumber: map['seatNumber'] as String?,
      other: map['other'] != null ? jsonDecode(map['other'] as String) : null,
    );
  }
}

/// 單例服務
class ScheduleService {
  ScheduleService._privateconstructor();
  static final ScheduleService instance = ScheduleService._privateconstructor();

  static const _dbName = 'schedule.db';
  static const _dbVersion = 7;
  static const _tableName = 'schedule';
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  // 初始化数据库的方法，通常用于应用启动时
  Future<void> initDatabase() async {
    await database; // 强制调用数据库初始化
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        Route TEXT NOT NULL,
        StartingStopName TEXT NOT NULL,
        UserStartingStopName TEXT,
        FinalStopName TEXT NOT NULL,
        UserDestinationStopName TEXT,
        city TEXT,
        routeID INTEGER,
        category TEXT,
        time TEXT ,
        seatNumber TEXT,
        other TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 6) {
      // Example: if version 6 added 'category'
      await db.execute('ALTER TABLE $_tableName ADD COLUMN category TEXT');
    }
    if (oldV < 7) {
      await db.execute('ALTER TABLE $_tableName ADD COLUMN seatNumber TEXT');
    }
  }

  /// 查詢排程，可傳入過濾條件
  Future<List<Map<String, dynamic>>> getSchedules({
    String? type,
    String? city,
    String? route,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      whereClauses.add('type = ?');
      args.add(type);
    }
    if (city != null) {
      whereClauses.add('city = ?');
      args.add(city);
    }
    if (route != null) {
      whereClauses.add('Route = ?');
      args.add(route);
    }

    final results = await db.query(
      _tableName,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
    );

    // 直接返回 Map<String, dynamic> 类型的结果
    return results;
  }

  /// 新增排程（避免重複）
  Future<int> addSchedule(ScheduleModel model) async {
    final db = await database;
    if (await _isDuplicate(model)) return -1;
    try {
      await db.insert(
        _tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 100;
    } catch (e) {
      // 可換成 logger
      return 200;
    }
  }

  /// 判斷是否已有相同排程
  Future<bool> _isDuplicate(ScheduleModel m) async {
    final db = await database;
    final whereClauses = <String>[
      'type = ?',
      'Route = ?',
      'StartingStopName = ?',
      'FinalStopName = ?'
    ];
    final args = [m.type, m.route, m.startingStopName, m.finalStopName];
    if (m.userStartingStopName != null) {
      whereClauses.add('UserStartingStopName = ?');
      if (m.userStartingStopName != null) {
        args.add(m.userStartingStopName!);
      }
    }
    if (m.userDestinationStopName != null) {
      whereClauses.add('UserDestinationStopName = ?');

      if (m.userDestinationStopName != null) {
        args.add(m.userDestinationStopName!);
      }
    }
    if (m.city != null) {
      whereClauses.add('city = ?');

      if (m.city != null) {
        args.add(m.city!);
      }
    }
    if (m.time != null) {
      whereClauses.add('time = ?');
      args.add(m.time!);
    }
    final existing = await db.query(
      _tableName,
      where: whereClauses.join(' AND '),
      whereArgs: args,
    );
    return existing.isNotEmpty;
  }

  /// 刪除排程
  Future<int> removeSchedule({
    required ScheduleModel model,
  }) async {
    final db = await database;

    final count = await db.delete(
      _tableName,
      where: 'id = ? AND type = ? AND Route = ?',
      whereArgs: [
        model.id,
        model.type,
        model.route,
      ],
    );

    return count > 0 ? 100 : 200;
  }

  /// 更新排程
  Future<int> updateSchedule(ScheduleModel model) async {
    final db = await database;
    if (model.id == null) return -1;

    // 準備要更新的欄位和對應的值
    final updateMap = <String, dynamic>{};

    if (model.userStartingStopName != null) {
      updateMap['UserStartingStopName'] = model.userStartingStopName;
    }
    if (model.userDestinationStopName != null) {
      updateMap['UserDestinationStopName'] = model.userDestinationStopName;
    }
    if (model.startingStopName != null) {
      updateMap['StartingStopName'] = model.startingStopName;
    }
    if (model.finalStopName != null) {
      updateMap['FinalStopName'] = model.finalStopName;
    }
    if (model.route != null) {
      updateMap['Route'] = model.route;
    }
    if (model.time != null) {
      updateMap['time'] = model.time;
    }
    if (model.category != null) {
      updateMap['category'] = model.category;
    }
    if (model.seatNumber != null) {
      updateMap['seatNumber'] = model.seatNumber;
    }
    if (model.other != null) {
      updateMap['other'] = jsonEncode(model.other);
    }

    // 如果沒有任何變更，則不執行更新
    if (updateMap.isEmpty) return -1;

    // 執行更新操作
    final updated = await db.update(
      _tableName,
      updateMap,
      where: 'id = ?',
      whereArgs: [model.id],
    );

    return updated > 0 ? 100 : -1;
  }

  /// 刪除過期排程，使用 Dart 時區
  Future<void> deleteExpiredSchedules() async {
    final db = await database;

    // 取得兩天前的日期時間
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final twoDaysAgoString = twoDaysAgo.toIso8601String();

    // 刪除時間早於兩天前的資料
    await db.delete(
      _tableName,
      where: 'time < ?',
      whereArgs: [twoDaysAgoString],
    );
  }

  /// 判斷是否有任何排程
  Future<bool> hasSchedule({String? type, String? route}) async {
    final list = await getSchedules(type: type, route: route);
    return list.isNotEmpty;
  }

  /// 🔴 清除資料表全部資料
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
