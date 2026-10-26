import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/bus/model/bus_route_model.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bus_route.db');

    return await openDatabase(
      path,
      version: 3, // 從 1 升到 2，觸發重建
      onCreate: (db, version) async => _createTables(db),
      onUpgrade: (db, oldV, newV) async {
        await db.execute('DROP TABLE IF EXISTS bus_route');
        await db.execute('DROP TABLE IF EXISTS meta');
        await _createTables(db);
      },
    );
  }

  // 欄位名稱、順序完全對齊 MySQL Bus.bus_route
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE bus_route (
        RouteUID TEXT,
        RouteID TEXT,
        HasSubRoutes TEXT,
        Operators TEXT,
        AuthorityID TEXT,
        ProviderID TEXT,
        SubRoutes TEXT,
        BusRouteType TEXT,
        RouteName TEXT,
        DepartureStopNameZh TEXT,
        DepartureStopNameEn TEXT,
        DestinationStopNameZh TEXT,
        DestinationStopNameEn TEXT,
        TicketPriceDescriptionZh TEXT,
        TicketPriceDescriptionEn TEXT,
        RouteMapImageUrl TEXT,
        City TEXT,
        CityCode TEXT,
        UpdateTime TEXT,
        VersionID TEXT,

        PRIMARY KEY (RouteUID, City)
      )
    ''');
    await db.execute('CREATE INDEX idx_bus_route_city ON bus_route(City)');
    await db.execute('CREATE INDEX idx_bus_route_uid ON bus_route(RouteUID)');

    await db.execute('''
      CREATE TABLE meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }
}

class BusRouteDb {
  BusRouteDb._();
  static final BusRouteDb instance = BusRouteDb._();

  Future<void> replaceCity(String city, List<BusRoute> routes) async {
    debugPrint('[replace] city=$city in=${routes.length}');
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      if (city == 'all') {
        await txn.delete('bus_route');
      } else {
        await txn.delete('bus_route', where: 'City = ?', whereArgs: [city]);
      }
      final batch = txn.batch();
      for (final r in routes) {
        batch.insert('bus_route', _toRow(r));
      }
      await batch.commit(noResult: true);
      final c = await txn.rawQuery('SELECT COUNT(*) c FROM bus_route');
      debugPrint('[replace] after insert db_count=${c.first['c']}');
    });
  }

  Future<List<BusRoute>> getByCity(String city) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('bus_route',
        where: 'City = ?', whereArgs: [city]);
    return rows.map(_fromRow).toList();
  }

  Future<List<BusRoute>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('bus_route');
    return rows.map(_fromRow).toList();
  }

  Future<BusRoute?> getById(String city, String routeId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('bus_route',
        where: 'City = ? AND RouteID = ?',
        whereArgs: [city, routeId],
        limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<void> clear() async {
    final db = await AppDatabase.instance.database;
    await db.delete('bus_route');
  }

  // ── BusRoute → row（key 完全照 MySQL 欄位名）──
  Map<String, dynamic> _toRow(BusRoute r) {
    return {
      'RouteUID': r.routeUID,
      'RouteID': r.routeID,
      'HasSubRoutes': r.hasSubRoutes ? 'true' : 'false',
      'Operators': jsonEncode(r.operators),

      'SubRoutes': jsonEncode(r.subRoutes),

      'RouteName': jsonEncode(r.routeName),
      'DepartureStopNameZh': r.departureStopNameZh,
      'DepartureStopNameEn': r.departureStopNameEn,
      'DestinationStopNameZh': r.destinationStopNameZh,
      'DestinationStopNameEn': r.destinationStopNameEn,
      'TicketPriceDescriptionZh': r.ticketPriceDescriptionZh,
      'TicketPriceDescriptionEn': r.ticketPriceDescriptionEn,
      'RouteMapImageUrl': r.routeMapImageUrl,
      'City': r.city,
      'CityCode': r.cityCode,
      'UpdateTime': r.updateTime.toIso8601String(),
      'VersionID': r.versionID.toString(),

    };
  }

  Future<List<BusRoute>> searchByName({
    required String city,
    required String keyword,
    String languageCode = 'zh',
  }) async {
    final kw = keyword.trim();
    if (kw.isEmpty) return [];

    final db = await AppDatabase.instance.database;
    final like = '%$kw%';

    final rows = await db.query('bus_route',
        where: 'City = ? AND RouteName LIKE ?',
        whereArgs: [city, like],
        orderBy: 'RouteID ASC');

    final all = rows.map(_fromRow).toList();
    final matched = all.where((r) {
      final name = languageCode == 'en' ? r.routeEn : r.routeZh;
      return name.contains(kw);
    }).toList();

    matched.sort((a, b) {
      final an = languageCode == 'en' ? a.routeEn : a.routeZh;
      final bn = languageCode == 'en' ? b.routeEn : b.routeZh;
      if (an == kw && bn != kw) return -1;
      if (an != kw && bn == kw) return 1;
      return an.compareTo(bn);
    });

    return matched;
  }

  // ── row → BusRoute（key 照 MySQL 欄位名，fromJson 也吃這些）──
  BusRoute _fromRow(Map<String, dynamic> row) {
    return BusRoute.fromJson({
      'RouteUID': row['RouteUID'],
      'RouteID': row['RouteID'],
      'HasSubRoutes': row['HasSubRoutes'],
      'Operators': row['Operators'],
      'AuthorityID': row['AuthorityID'],
      'ProviderID': row['ProviderID'],
      'SubRoutes': row['SubRoutes'],
      'BusRouteType': row['BusRouteType'],
      'RouteName': row['RouteName'],
      'DepartureStopNameZh': row['DepartureStopNameZh'],
      'DepartureStopNameEn': row['DepartureStopNameEn'],
      'DestinationStopNameZh': row['DestinationStopNameZh'],
      'DestinationStopNameEn': row['DestinationStopNameEn'],
      'TicketPriceDescriptionZh': row['TicketPriceDescriptionZh'],
      'TicketPriceDescriptionEn': row['TicketPriceDescriptionEn'],
      'RouteMapImageUrl': row['RouteMapImageUrl'],
      'City': row['City'],
      'CityCode': row['CityCode'],
      'UpdateTime': row['UpdateTime'],
      'VersionID': row['VersionID'],
      'FareBufferZoneDescriptionZh': row['FareBufferZoneDescriptionZh'],
      'FareBufferZoneDescriptionEn': row['FareBufferZoneDescriptionEn'],
    });
  }
}