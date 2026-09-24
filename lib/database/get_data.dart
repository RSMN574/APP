import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/bus.dart';
import 'package:mysql1/mysql1.dart';

import '../utils/convert.dart';
import '../config/app_config.dart';
import 'tdx_api_client.dart';

Timer? _idleTimer;
const int idleTimeout = 30; // 30秒無操作超時
var result;
MySQLConnection? conn;

int? sum = 0;
List jsonData = [];

String busCurrentCity = 'Taichung';

String _validatedBusCity(String city) {
  if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(city)) {
    throw ArgumentError.value(city, 'city', 'Invalid city identifier');
  }
  return city;
}

// 全局連接池
late ConnectionPool connectionPool;
bool isPoolInitialized = false;

// 初始化連接池
Future<void> initConnectionPool() async {
  if (isPoolInitialized) return;
  AppConfig.requireDatabaseConfig();

  final settings = ConnectionSettings(
    host: AppConfig.databaseHost,
    port: 3306,
    user: AppConfig.databaseUser,
    password: AppConfig.databasePassword,
    db: AppConfig.databaseName,
  );

  connectionPool = ConnectionPool(settings, 5); // 5個連接的池
  isPoolInitialized = true;
}

class ConnectionPool {
  final ConnectionSettings _settings;
  final int _maxPoolSize;

  // 存放「目前閒置可用」的連線
  final List<MySqlConnection> _availablePool = [];

  // 存放「正在排隊等待連線」的預約隊列
  final List<Completer<MySqlConnection>> _waitingQueue = [];

  // 關鍵：記錄目前由該 Pool 建立的「總連線數」（包含閒置與工作中的）
  int _currentTotalConnections = 0;

  ConnectionPool(this._settings, this._maxPoolSize);

  /// 獲取連線（支援併發排隊）
  Future<MySqlConnection> getConnection() async {
    // 1. 如果有現成閒置的連線，直接拿去用
    if (_availablePool.isNotEmpty) {
      return _availablePool.removeLast();
    }

    // 2. 如果沒有閒置連線，但總連線數還沒達到上限，就建立一條新連線
    if (_currentTotalConnections < _maxPoolSize) {
      _currentTotalConnections++;
      try {
        AppConfig.requireDatabaseConfig();
        return await MySqlConnection.connect(_settings);
      } catch (e) {
        _currentTotalConnections--; // 建立失敗，扣回計數器
        rethrow;
      }
    }

    // 3. 如果連線池全滿（都在工作），就進入隊列排隊，不要直接拋出錯誤
    final completer = Completer<MySqlConnection>();
    _waitingQueue.add(completer);

    // 可以設定一個逾時時間，避免使用者無限期等待
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _waitingQueue.remove(completer);
        throw TimeoutException("獲取資料庫連線逾時，目前伺服器繁忙");
      },
    );
  }

  /// 釋放連線（還給連線池）
  void releaseConnection(MySqlConnection conn) {
    // 1. 先檢查有沒有人在排隊？如果有，直接把連線交棒給排隊的人
    if (_waitingQueue.isNotEmpty) {
      final nextWaiter = _waitingQueue.removeAt(0);
      nextWaiter.complete(conn);
      return;
    }

    // 2. 如果沒人排隊，且閒置池還沒滿，就放回池子裡備用
    if (_availablePool.length < _maxPoolSize) {
      _availablePool.add(conn);
    } else {
      // 3. 防呆關閉：如果池子莫名滿了，安全地關閉此連線
      _currentTotalConnections--;
      _safeClose(conn);
    }
  }

  /// 安全關閉連線，避免拋出 Connection state 異常
  void _safeClose(MySqlConnection conn) {
    try {
      // 某些套件可以檢查連線狀態，如：if (conn.connected)
      // 若套件不支援，可用 try-catch 包覆，確保關閉失敗不會讓主程式崩潰
      conn.close();
    } catch (e) {
      print('安全關閉連線時忽略的異常: $e');
    }
  }

  /// 關閉所有連線（App 關閉或重置時呼叫）
  Future<void> closeAllConnections() async {
    // 清空排隊隊列
    for (var waiter in _waitingQueue) {
      waiter.completeError(Exception("連線池已關閉"));
    }
    _waitingQueue.clear();

    // 關閉所有閒置連線
    for (var conn in _availablePool) {
      _safeClose(conn);
    }
    _availablePool.clear();
    _currentTotalConnections = 0;
  }
}

Future<void> connMysql() async {
  // 如果連接已存在，則避免重複連接
  if (conn != null && await checkConnection()) {
    return;
  }

  try {
    // 確保連接池已初始化
    await initConnectionPool();

    // 建立連接
    conn = await MySQLConnection.createConnection(
      host: AppConfig.databaseHost,
      port: 3306,
      userName: AppConfig.databaseUser,
      password: AppConfig.databasePassword,
      databaseName: AppConfig.databaseName,
    );
    await conn!.connect();

    // 重置閒置計時器
    _startIdleTimer();
  } catch (e) {
    print("Connection error: $e");
    Fluttertoast.showToast(
      msg: "連接失敗: $e",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black45,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // 連接失敗後等待短暫時間再重試
    await Future.delayed(const Duration(seconds: 2));
    if (conn == null) {
      await connMysql(); // 重試連接
    }
  }
}

Future<bool> checkConnection() async {
  try {
    // 執行一個輕量級查詢來驗證連線
    await conn?.execute('SELECT 1');
    return true; // 連線正常
  } catch (e) {
    print("Database connection check failed: $e");
    return false; // 連線失敗
  }
}

// 改進的 mysqlSelect 函數
Future<List<Map<String, dynamic>>> mysqlSelect(String query) async {
  List<Map<String, dynamic>> jsonArray = [];

  try {
    // 使用改進的查詢執行函數
    var result = await executeQueryWithRetry(query);

    // 處理查詢結果
    for (final row in result.rows) {
      jsonArray.add(row.assoc());
    }
  } catch (e) {
    print("Error during mysqlSelect: $e");
    Fluttertoast.showToast(
      msg: "查詢失敗，請稍後再試",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  return jsonArray;
}

/// 關閉連接
Future<void> disconnect() async {
  _idleTimer?.cancel(); // 取消計時器

  if (conn != null) {
    try {
      await conn!.close();
    } catch (e) {
      print('Error closing connection: $e');
    } finally {
      conn = null;
    }
  }
}

// 啟動閒置計時器
void _startIdleTimer() {
  // 如果已有計時器，則取消
  _idleTimer?.cancel();

  // 設置計時器，每30秒沒有操作時斷開連接
  _idleTimer = Timer(Duration(seconds: idleTimeout), () {
    disconnect();
  });
}

Future<Map<String, dynamic>> getBusRouteWithId({
  required String city,
  required String routeId,
}) async {
  try {
    final parameters = <dynamic>[];
    final StringBuffer queryBuffer = StringBuffer();

    if (city == 'all') {
      queryBuffer.write("SELECT * FROM Bus.bus_route");
    } else if (city == 'InterCity') {
      queryBuffer.write("SELECT * FROM Bus.Bus_InterCity_Route");
    } else {
      queryBuffer.write("SELECT * FROM Bus.bus_route WHERE City = ?");
      parameters.add(city);
    }

    if (routeId.isNotEmpty) {
      if (city == 'all' || city == 'InterCity') {
        queryBuffer.write(" WHERE RouteID = ?");
      } else {
        queryBuffer.write(" AND RouteID = ?");
      }
      parameters.add(routeId);
    }
    queryBuffer.write(" LIMIT 1");

    final String query = queryBuffer.toString();

    // ✅ executeQueryWithRetry 现在返回 IResultSet
    final IResultSet result =
        await executeQueryWithRetry(query, params: parameters);

    if (result.rows.isEmpty) return {};

    // ✅ 正确转换为 Map
    return result.rows.first.assoc();
  } catch (e, stack) {
    debugPrint('GetBusRouteWithId error: $e');
    debugPrintStack(stackTrace: stack);
    // 可选：显示toast
    return {};
  }
}

Future<List<BusRoute>> getBusRoute({
  required String city,
}) async {
  try {
    String query;
    List<dynamic> parameters = [];

// 選擇基礎資料表
    if (city == 'all') {
      query = ("SELECT * FROM Bus.bus_route");
    } else if (city == 'InterCity') {
      query = ("SELECT * FROM Bus.Bus_InterCity_Route");
    } else {
      query = ("SELECT * FROM Bus.bus_route WHERE City = ?");
      parameters.add(city);
    }

    final result = await executeQueryWithRetry(query, params: parameters);

    return result.rows
        .map(
          (row) => BusRoute.fromJson(row.assoc()),
        )
        .toList();
  } catch (e, stack) {
    debugPrint('GetBus error: $e');
    debugPrintStack(stackTrace: stack);

    Fluttertoast.showToast(
      msg: "獲取公車資料失敗，請稍後再試",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    rethrow;
  }
}

Future<List<Map<String, dynamic>>> getBusStop(
    {required String city, required String input}) async {
  try {
    final safeCity = _validatedBusCity(city);
    String query;
    List<dynamic> parameters = [];

// 選擇基礎資料表
    if (city == 'all') {
      query = ("SELECT StationName FROM Bus.Bus_${safeCity}_Stop "
          "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE ?");
      parameters.add('%$input%');
    } else if (city == 'InterCity') {
      query = ("SELECT StationName FROM Bus.Bus_InterCity_Route_Stop "
          "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE ?");
      parameters.add('%$input%');
    } else {
      query = ("SELECT StationName FROM Bus.Bus_${safeCity}_Stop "
          "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE ?");
      parameters.add('%$input%');
    }

    final result = await executeQueryWithRetry(query, params: parameters);

    return result.rows.map<Map<String, dynamic>>((row) => row.assoc()).toList();
  } catch (e, stack) {
    debugPrint('GetBus error: $e');
    debugPrintStack(stackTrace: stack);

    Fluttertoast.showToast(
      msg: "獲取公車資料失敗，請稍後再試",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    return [];
  }
}

Future<IResultSet> executeQueryWithRetry(
  String query, {
  List<dynamic>? params,
  int maxRetries = 3,
}) async {
  int attempts = 0;
  Duration delay = const Duration(milliseconds: 500);

  // 轉換 SQL：將 ? 替換為 :arg0, :arg1, ...
  // ✅ 修正：確保 index 變數宣告在函式內部，每次呼叫都精準從 0 開始
  String convertToNamedParams(String sql, List<dynamic>? p) {
    if (p == null || p.isEmpty) return sql;
    int index = 0;
    return sql.replaceAllMapped(RegExp(r'\?'), (match) => ':arg${index++}');
  }

  // 轉換參數列表為 Map
  Map<String, dynamic>? convertToMap(List<dynamic>? p) {
    if (p == null || p.isEmpty) return null;
    final map = <String, dynamic>{};
    for (int i = 0; i < p.length; i++) {
      map['arg$i'] = p[i];
    }
    return map;
  }

  // 🚀 效能優化：SQL 轉換與 Map 建立在迴圈外「只做一次」即可，重試時不需重複運算
  final convertedSql = convertToNamedParams(query, params);
  final Map<String, dynamic>? namedParams = convertToMap(params);
  final hasParams = namedParams != null && namedParams.isNotEmpty;

  while (attempts < maxRetries) {
    try {
      // 檢查連線狀態，如果失效則重連
      if (conn == null || !(await checkConnection())) {
        debugPrint("Connection invalid, reconnecting before query...");
        await disconnect();
        await connMysql();
      }

      // 使用 execute 並傳入對應參數
      final result = hasParams
          ? await conn!.execute(convertedSql, namedParams)
          : await conn!.execute(convertedSql);

      _startIdleTimer();
      return result;
    } catch (e) {
      attempts++;
      debugPrint("Query error (attempt $attempts/$maxRetries): $e");

      final errorMsg = e.toString().toLowerCase();
      final isConnectionError = errorMsg.contains('connection closed') ||
          errorMsg.contains('lost connection') ||
          errorMsg.contains('dead') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('timeout') ||
          errorMsg
              .contains('not in connectionestablished'); // ✅ 把上幾題你遇到的錯誤也納入斷線判定

      // 如果是連線類型的錯誤，嘗試在下次重試前修復連線
      if (isConnectionError) {
        try {
          await disconnect();
          await connMysql();
        } catch (reconnectErr) {
          debugPrint("Reconnection failed during retry: $reconnectErr");
        }
      }

      if (attempts >= maxRetries) {
        throw Exception(
            "Failed to execute query after $maxRetries attempts. Last error: $e");
      }

      // 指數退避延遲
      await Future.delayed(delay);
      delay =
          Duration(milliseconds: (delay.inMilliseconds * 2).clamp(500, 5000));
    }
  }

  throw Exception("Unexpected error in executeQueryWithRetry");
}

Future<List<Map<String, dynamic>>> getBusStopOfRoute({
  required String routeId,
  required String city,
}) async {
  List<Map<String, dynamic>> routeName = [];

  late final String query;
  try {
    await connMysql(); // 連接資料庫
    if (city == 'InterCity') {
      query = '''
    SELECT *
    FROM Bus.Bus_InterCity_Route_Stop
    WHERE RouteID = ?
  ''';
    } else {
      query = '''
  SELECT *
  FROM Bus.stopOfRoute
  WHERE City = ?
    AND RouteID = ?
''';
    }

    // 使用改進的查詢執行函數，包含重試邏輯
    final parameters =
        city == 'InterCity' ? <dynamic>[routeId] : <dynamic>[city, routeId];
    var result = await executeQueryWithRetry(query, params: parameters);

    // 清空舊數據
    jsonData = [];

    // 處理查詢結果
    for (final row in result.rows) {
      var rowData = row.assoc();
      jsonData.add(rowData);

      // 安全解析JSON並計算總和
      try {
        var stopsData = json.decode(rowData['Stops']!);
        sum = (sum ?? 0) + (stopsData is List ? stopsData.length : 0);
      } catch (e) {
        print("JSON解析錯誤: $e");
      }

      routeName.add(rowData);
    }

    // 重置閒置計時器
    _startIdleTimer();

    return routeName;
  } catch (e) {
    print("getBusStopOfRoute error: $e");
    Fluttertoast.showToast(
      msg: "獲取公車路線資料失敗，請稍後再試",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
    return [];
  }
}

Future<List<Map<String, dynamic>>> GetBusStopInfo({
  required String stopName,
  required String city,
}) async {
  await connMysql(); // 連接資料庫

  final safeCity = _validatedBusCity(city);
  final query =
      "SELECT StationID,StationPosition FROM Bus.Bus_${safeCity}_Stop "
      "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = ?";
  List<Map<String, dynamic>> stopInfo = [];

  final result = await executeQueryWithRetry(query, params: [stopName]);
  final data = result.rows.map((row) => row.assoc()).toList();
  jsonData = data;

  for (var i in data) {
    stopInfo.add(i);
  }

  // 重置閒置計時器
  _startIdleTimer();

  return stopInfo;
}

Future<dynamic> fetchByUrl(String url, {dynamic other}) async {
  if (url.isEmpty) {
    throw const FormatException('TDX URL cannot be empty');
  }

  final uri = Uri.parse(url);
  if (uri.host != 'tdx.transportdata.tw') {
    throw ArgumentError('Only TDX URLs are supported');
  }

  return TdxApiClient().get(uri.path, queryParams: uri.queryParameters);
}

Future<List<Map<String, dynamic>>> fetchTrainStationFacility(
    String stationID) async {
  try {
    // 连接数据库
    await connMysql();

    const queryFacility =
        "SELECT * FROM Train.Station_StationFacility WHERE StationID = ?";
    const queryStation =
        "SELECT * FROM Train.Train_Station WHERE StationID = ?";
    // 查询设施数据
    final facilityResult =
        await executeQueryWithRetry(queryFacility, params: [stationID]);
    final facilityData = facilityResult.rows.map((row) => row.assoc()).toList();

    // 查询车站数据
    final stationResult =
        await executeQueryWithRetry(queryStation, params: [stationID]);
    final stationData = stationResult.rows.map((row) => row.assoc()).toList();

    // 打印调试信息

    // 合并两个查询结果
    List<Map<String, dynamic>> combinedData = [
      ...facilityData,
      ...stationData,
    ];

    // 重置闲置计时器
    _startIdleTimer();

    return combinedData;
  } catch (e, stackTrace) {
    // 捕获并记录错误
    print("Error fetching station facilities: $e");
    debugPrintStack(stackTrace: stackTrace);

    // 返回空列表以防止程序崩溃
    return [];
  }
}

Future<List> getNearTrainStation(double latitude, double longitude,
    {double maxDistanceInKm = 30.0, int count = 5}) async {
  try {
    await connMysql();

    String queryNearStation =
        "SELECT StationName,StationID,StationPosition,LocationCity,LocationTown FROM Train.Train_Station;";
    List<Map<String, dynamic>> nearStation =
        await mysqlSelect(queryNearStation);

    _startIdleTimer();

    List<Map<String, dynamic>> findNearestStations(
      List<Map<String, dynamic>> stations,
      double userLat,
      double userLon, {
      required double maxDistance,
      required int count,
    }) {
      final withDistance = stations
          .map((station) {
            final pos = json.decode(station["StationPosition"]);
            final distance = calculateApproxDistance(
                  userLat,
                  userLon,
                  pos["PositionLat"],
                  pos["PositionLon"],
                ) /
                1000;
            return {...station, "distance": distance};
          })
          .where((s) => s["distance"] <= maxDistance)
          .toList();

      withDistance.sort((a, b) =>
          (a["distance"] as double).compareTo(b["distance"] as double));

      return withDistance.take(count).toList();
    }

    List<dynamic> nearestStations = findNearestStations(
      nearStation,
      latitude,
      longitude,
      maxDistance: maxDistanceInKm,
      count: count,
    );

    return nearestStations;
  } catch (e) {
    print("Error fetching station facilities: $e");

    return [];
  }
}

// Future<List<dynamic>> getNearBusStation(double latitude, double longitude) async {
//   try {
//     // 連接資料庫
//     await connMysql();
//
//     String queryNearStation = "SELECT * FROM Bus.Bus_Taichung_Stop";
//     // 查詢所有站牌資料
//     List<Map<String, dynamic>> nearStation = await mysqlSelect(queryNearStation);
//
//     // 重置閒置計時器（視情況使用）
//     _startIdleTimer();
//
//
//     // 過濾出 500m 範圍內的站牌，並根據距離排序
//     List<Map<String, dynamic>> findNearbyStations(
//         List<Map<String, dynamic>> stations,
//         double userLat,
//         double userLon,
//         ) {
//       // 過濾符合距離條件的站牌
//       List<Map<String, dynamic>> filteredStations = stations.where((station) {
//         // 假設 StationPosition 是以 JSON 字串儲存，解碼後取得緯度與經度
//         final pos = json.decode(station["StationPosition"]);
//         double stationLat = pos["PositionLat"];
//         double stationLon = pos["PositionLon"];
//         double distance = calculateApproxDistance(userLat, userLon, stationLat, stationLon);
//         return distance <= 500;
//       }).toList();
//
//       // 根據距離排序（最近的排在前面）
//       filteredStations.sort((a, b) {
//         final posA = json.decode(a["StationPosition"]);
//         final posB = json.decode(b["StationPosition"]);
//         double distanceA = calculateApproxDistance(
//           userLat,
//           userLon,
//           posA["PositionLat"],
//           posA["PositionLon"],
//         );
//         double distanceB = calculateApproxDistance(
//           userLat,
//           userLon,
//           posB["PositionLat"],
//           posB["PositionLon"],
//         );
//         return distanceA.compareTo(distanceB);
//       });
//       return filteredStations;
//     }
//
//     // 呼叫函式取得 500m 範圍內的所有站牌
//     List<dynamic> nearestStations = findNearbyStations(nearStation, latitude, longitude);
//     print("附近 500m 內的站牌: $nearestStations");
//
//
//     return nearestStations;
//   } catch (e, stackTrace) {
//     // 捕獲錯誤並輸出
//     print("Error fetching station facilities: $e");
//     print(stackTrace);
//     // 若發生錯誤，返回空列表以防止應用程式崩潰
//     return [];
//   }
// }

enum RouteDirection { directionOne, directionTwo, none }

Future<Map<String, dynamic>?> getRouteStopsAndDirection(
  String routeName,
  String originName,
  String destinationName,
) async {
  try {
    // 取得兩個方向的站牌資料
    final direction0 = await getRouteStops(routeName, '0');
    final direction1 = await getRouteStops(routeName, '1');

    // 建立驗證器
    final validator0 = RouteValidator.fromDirectionMap(direction0);
    final validator1 = RouteValidator.fromDirectionMap(direction1);

    // 驗證雙向路線
    final result0 = validator0.validateRoute(originName, destinationName);
    final result1 = validator1.validateRoute(originName, destinationName);

    // 處理驗證結果
    final results = {
      'direction_0': result0,
      'direction_1': result1,
    };

    // 判斷有效路線方向
    final validDirections =
        results.entries.where((e) => e.value['isValid'] == true).toList();

    if (validDirections.isEmpty) {
      return {
        'status': 'error',
        'message': '沒有符合的行車方向',
        'details': results,
      };
    }

    if (validDirections.length > 1) {
      return {
        'status': 'warning',
        'message': '多個方向符合路線',
        'details': results,
      };
    }

    final validDirection = validDirections.first;
    return {
      'status': 'success',
      'direction': validDirection.key.split('_').last,
      'originStopID': validDirection.value['originStopID'],
      'destStopID': validDirection.value['destStopID'],
      'details': results,
    };
  } catch (e) {
    return {
      'status': 'error',
      'message': '發生例外錯誤: ${e.toString()}',
      'details': null,
    };
  }
}

Future<Map<String, dynamic>> getRouteStops(
    String routeName, String direction) async {
  // SQL 查詢，根據站牌名稱過濾
  var query =
      "SELECT * FROM Bus.Bus_Taichung_Route_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName' AND Direction=$direction ;";

  // 從資料庫取得資料
  List<Map<String, dynamic>> stopsList =
      await mysqlSelect(query); // 先等待 Future 完成
  Map<String, dynamic> stops = {};
  if (stopsList.isNotEmpty) {
    stops = stopsList[0]; // 取第一個元素
  } else {
    // stopsList 為空時的處理方式
  }

  // 若只有一個方向，另一個列表會是空的
  return stops;
}

Future<List<dynamic>> getGeneralTrainTimetable(
    String originName, String destinationName) async {
  // SQL 查詢，根據站牌名稱過濾
  var query = '''
SELECT 
    t.*,
    s1.StopSequence AS s1_StopSequence,
    s2.StopSequence AS s2_StopSequence
FROM 
    Train.GeneralTrainTimetable t,
    JSON_TABLE(t.StopTimes, "\$[*]" COLUMNS (
        StopSequence INT PATH "\$.StopSequence",
        StationID VARCHAR(20) PATH "\$.StationID",
        StationNameZh VARCHAR(50) PATH "\$.StationName.Zh_tw"
    )) AS s1,
    JSON_TABLE(t.StopTimes, "\$[*]" COLUMNS (
        StopSequence INT PATH "\$.StopSequence",
        StationID VARCHAR(20) PATH "\$.StationID", 
        StationNameZh VARCHAR(50) PATH "\$.StationName.Zh_tw"
    )) AS s2
WHERE 
    s1.StationNameZh = '$originName'
    AND s2.StationNameZh = '$destinationName'
    AND s1.StopSequence < s2.StopSequence
    AND JSON_EXTRACT(t.ServiceDay, '\$.Monday') = 1;
    ''';

  // 從資料庫取得資料
  List<dynamic> stopsList = await mysqlSelect(query); // 先等待 Future 完成

  return stopsList;
}

class RouteValidator {
  late final List<Map<String, dynamic>> _stops;
  bool _initialized = false;

  RouteValidator.fromDirectionMap(Map<dynamic, dynamic> directionMap) {
    try {
      dynamic stopsData = directionMap['Stops'];

      // 处理 JSON 字符串输入
      if (stopsData is String) {
        print("[DEBUG] Parsing JSON string for stops...");
        stopsData = json.decode(stopsData);
      }

      // 类型安全检查
      if (stopsData is! List) {
        throw FormatException(
            "Invalid stops data type: ${stopsData.runtimeType}");
      }

      // 深度验证数据结构
      _stops = stopsData.map((dynamic item) {
        if (item is! Map) {
          throw FormatException("Stop item is not a Map: $item");
        }

        final stop = Map<String, dynamic>.from(item);

        // 验证必要字段
        if (!stop.containsKey('StopID')) {
          throw FormatException("Missing StopID in stop: $stop");
        }

        if (!stop.containsKey('StopName') ||
            stop['StopName'] is! Map<String, dynamic> ||
            !(stop['StopName'] as Map<String, dynamic>).containsKey('Zh_tw')) {
          throw FormatException("Invalid StopName format in stop: $stop");
        }

        if (!stop.containsKey('StopSequence') || stop['StopSequence'] is! int) {
          throw FormatException("Invalid StopSequence in stop: $stop");
        }

        return stop;
      }).toList();

      // 排序并验证顺序
      _stops.sort((a, b) =>
          (a['StopSequence'] as int).compareTo(b['StopSequence'] as int));
      _validateSequence();

      _initialized = true;
      print("[INFO] Validator initialized with ${_stops.length} stops");
    } catch (e) {
      _initialized = false;
      print("[ERROR] Initialization failed: $e");
      rethrow;
    }
  }

  Map<String, dynamic> validateRoute(String originZhName, String destZhName) {
    if (!_initialized) {
      return _errorResponse("Validator not initialized");
    }

    try {
      // 输入验证
      if (originZhName.isEmpty || destZhName.isEmpty) {
        throw ArgumentError("Station names cannot be empty");
      }

      // 查找站点信息
      final origin = _findStop(originZhName);
      final destination = _findStop(destZhName);

      // 构建结果
      return {
        'isValid': origin['index'] < destination['index'],
        'originStopID': origin['stopID'],
        'destStopID': destination['stopID'],
        'error': null,
      };
    } catch (e) {
      return _errorResponse(e.toString());
    }
  }

  Map<String, dynamic> _findStop(String zhName) {
    final index = _stops
        .indexWhere((stop) => (stop['StopName']['Zh_tw'] as String) == zhName);

    if (index == -1) {
      throw ("Station '$zhName' not found");
    }

    return {
      'index': index,
      'stopID': _stops[index]['StopID'] as String,
    };
  }

  void _validateSequence() {
    final sequences = _stops.map((s) => s['StopSequence'] as int).toList();
    if (sequences.toSet().length != sequences.length) {
      throw FormatException("Duplicate StopSequence found");
    }

    for (int i = 1; i < sequences.length; i++) {
      if (sequences[i] <= sequences[i - 1]) {
        throw FormatException("Invalid StopSequence order at index $i");
      }
    }
  }

  Map<String, dynamic> _errorResponse(String message) {
    return {
      'isValid': false,
      'originStopID': null,
      'destStopID': null,
      'error': message,
    };
  }
}
