import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Const/regularConst.dart';
import '../models/Station.dart';
import '../secure_storage/secure_storage.dart';
import 'package:mysql1/mysql1.dart';

import '../utils/convert.dart';

Timer? _idleTimer;
const int idleTimeout = 30; // 30秒無操作超時
var result;
MySQLConnection? conn;
var busid;
List busName = [];
int? sum = 0;
List jsonData = [];
int routeID = 0;
String busCurrentCity = 'Taichung';

// 全局連接池
late ConnectionPool connectionPool;
bool isPoolInitialized = false;

// 初始化連接池
Future<void> initConnectionPool() async {
  if (isPoolInitialized) return;

  final settings = ConnectionSettings(
    host: "hidden.rsmn574.com",
    port: 3306,
    user: "onlyForApiRead",
    password: "@Nick0319Lucas0221",
    db: "Bus",
  );

  connectionPool = ConnectionPool(settings, 5); // 5個連接的池
  isPoolInitialized = true;
}

class ConnectionPool {
  final List<MySqlConnection> _pool = [];
  final int _maxPoolSize;
  final ConnectionSettings _settings;

  ConnectionPool(this._settings, this._maxPoolSize);

  Future<MySqlConnection> getConnection() async {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    }

    if (_pool.length < _maxPoolSize) {
      return await MySqlConnection.connect(_settings);
    }

    throw Exception("Connection pool is full");
  }

  void releaseConnection(MySqlConnection conn) {
    if (_pool.length < _maxPoolSize) {
      _pool.add(conn);
    } else {
      conn.close();
    }
  }

  Future<void> closeAllConnections() async {
    for (var conn in _pool) {
      await conn.close();
    }
    _pool.clear();
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
      host: "hidden.rsmn574.com",
      port: 3306,
      userName: "onlyForApiRead",
      password: "@Nick0319Lucas0221",
      databaseName: "Bus",
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
    await Future.delayed(Duration(seconds: 2));
    if (conn == null) {
      await connMysql(); // 重試連接
    }
  }
}

// 改進的查詢執行函數，包含重試邏輯
Future<IResultSet> executeQueryWithRetry(String query, {int maxRetries = 3}) async {
  int attempts = 0;

  while (attempts < maxRetries) {
    try {
      // 確保連接存在且有效
      if (conn == null || !(await checkConnection())) {
        await disconnect(); // 確保舊連接已關閉
        await connMysql(); // 重新連接
      }

      // 執行查詢
      var result = await conn!.execute(query);
      _startIdleTimer(); // 重置閒置計時器
      return result;
    } catch (e) {
      attempts++;
      print("Query error (attempt $attempts): $e");

      // 如果是連接問題，嘗試重新連接
      if (e.toString().contains("connection closed")) {
        await disconnect();
        await connMysql();
      }

      // 如果已達到最大重試次數，拋出異常
      if (attempts >= maxRetries) {
        throw Exception(
            "Failed to execute query after $maxRetries attempts: $e");
      }

      // 等待短暫時間後重試
      await Future.delayed(Duration(milliseconds: 500 * attempts));
    }
  }

  throw Exception("Unexpected error in executeQueryWithRetry");
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

Future<List> GetBus(String city) async {
  List data = [];

  try {
    // 構建查詢
    String query2 = "SELECT * FROM Bus.Bus_${city}_Route";
    if (city == "all") {
      query2 = """
        SELECT UID, RouteUID, RouteID, HasSubRoutes, Operators, AuthorityID, ProviderID, SubRoutes, BusRouteType, RouteName, DepartureStopNameZh, DepartureStopNameEn, DestinationStopNameZh, DestinationStopNameEn, RouteMapImageUrl, City, CityCode, UpdateTime, VersionID
FROM Bus.Bus_Taipei_Route
UNION ALL
SELECT UID, RouteUID, RouteID, HasSubRoutes, Operators, AuthorityID, ProviderID, SubRoutes, BusRouteType, RouteName, DepartureStopNameZh, DepartureStopNameEn, DestinationStopNameZh, DestinationStopNameEn, RouteMapImageUrl, City, CityCode, UpdateTime, VersionID
FROM Bus.Bus_Taichung_Route;
 """;
    }

    data.clear();
    // 使用改進的查詢執行函數
    var result = await executeQueryWithRetry(query2);

    // 迭代結果並將其儲存到 list 中
    for (final row in result.rows) {
      data.add(row.assoc());
    }
  } catch (e) {
    print("GetBus error: $e");
    Fluttertoast.showToast(
      msg: "獲取公車資料失敗，請稍後再試",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  return data;
}

Future<List<Map<String, dynamic>>> GetBusInfo({required int routeid, required String city,}) async {
  sum = 0;
  List<Map<String, dynamic>> routeName = [];

  routeID = routeid;

  try {
    await connMysql(); // 連接資料庫

    // 使用參數化查詢防止SQL注入
    var query =
        'SELECT Stops FROM Bus.Bus_${city}_Route_Stop WHERE Routeid = $routeid';

    // 使用改進的查詢執行函數，包含重試邏輯
    var result = await executeQueryWithRetry(query);

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
    print("GetBusInfo error: $e");
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

getInfo(data) {
  if (data == 'sum') {
    return sum;
  } else if (data == 'routeInfo') {
    return jsonData;
  } else if (data == 'routeID') {
    return routeID;
  }
}

Future<List<Map<String, dynamic>>> GetBusStopInfo(String stopName, String city,) async {
  await connMysql(); // 連接資料庫

  var query =
      "SELECT  StationID,StationPosition FROM Bus.Bus_${city}_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '$stopName'";
  List<Map<String, dynamic>> stopInfo = [];

  jsonData = await mysqlSelect(query);
  List<dynamic> data = await mysqlSelect(query);

  for (var i in data) {
    stopInfo.add(i);
  }

  // 重置閒置計時器
  _startIdleTimer();

  return stopInfo;
}

Future<dynamic> fetchByUrl(String url, {dynamic other}) async {
  // var url="https://tdx.transportdata.tw/api/basic/v2/Bus/Alert/City/Taichung?%24top=10&%24format=JSON";
  try {
    await connMysql(); // 連接資料庫
    final tokenResponse = await http.get(tokenUri);
    final token = tokenResponse.body;
    // 发起 GET 请求
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      throw HttpException('HTTP error! status: ${response.statusCode}');
    }

    // 解析 JSON 数据
    final jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  } finally {
    // 重置閒置計時器
    _startIdleTimer();
  }
}

Future<List<Map<String, dynamic>>> fetchTrainStationFacility(String stationID) async {
  try {
    // 连接数据库
    await connMysql();

    String queryFacility =
        "SELECT * FROM Train.Station_StationFacility WHERE StationID = $stationID;";
    String queryStation =
        "SELECT * FROM Train.Train_Station WHERE StationID = $stationID;";
    // 查询设施数据
    List<Map<String, dynamic>> facilityData = await mysqlSelect(queryFacility);

    // 查询车站数据
    List<Map<String, dynamic>> stationData = await mysqlSelect(queryStation);

    // 打印调试信息

    // 合并两个查询结果
    List<Map<String, dynamic>> combinedData = [
      ...facilityData,
      ...stationData,
    ];

    // 重置闲置计时器
    _startIdleTimer();
    print("combinedData $combinedData");
    return combinedData;
  } catch (e, stackTrace) {
    // 捕获并记录错误
    print("Error fetching station facilities: $e");
    print(stackTrace);

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
    List<Map<String, dynamic>> nearStation = await mysqlSelect(queryNearStation);

    _startIdleTimer();

    List<Map<String, dynamic>> findNearestStations(
        List<Map<String, dynamic>> stations,
        double userLat,
        double userLon, {
          required double maxDistance,
          required int count,
        }) {
      List<Map<String, dynamic>> filtered = stations.where((station) {
        double stationLat = json.decode(station["StationPosition"])["PositionLat"];
        double stationLon = json.decode(station["StationPosition"])["PositionLon"];
        double distance = calculateApproxDistance(userLat, userLon, stationLat, stationLon);
        return distance <= maxDistance;
      }).toList();

      filtered.sort((a, b) {
        double distanceA = calculateApproxDistance(
          userLat,
          userLon,
          json.decode(a["StationPosition"])["PositionLat"],
          json.decode(a["StationPosition"])["PositionLon"],
        );
        double distanceB = calculateApproxDistance(
          userLat,
          userLon,
          json.decode(b["StationPosition"])["PositionLat"],
          json.decode(b["StationPosition"])["PositionLon"],
        );
        return distanceA.compareTo(distanceB);
      });

      return filtered.take(count).toList();
    }

    List<dynamic> nearestStations = findNearestStations(
      nearStation,
      latitude,
      longitude,
      maxDistance: maxDistanceInKm,
      count: count,
    );

    return nearestStations;
  } catch (e, stackTrace) {
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

Future<String> getToken() async {
  String token = "";
  try {
    // 取得當前時間戳記（ISO 8601 格式）
    String timestamp = DateTime.now().toUtc().toIso8601String();
    String? apiKey = await SecureStorage.getApiKey();

    if (apiKey == null) {
      // 如果 apiKey 為 null，則儲存新的 apiKey
      await SecureStorage.saveApiKey(
          'PgRQhSulFPbmnccET+l8ykLC1s2k8IAvpAb3NFFwIXA=');
      print('API Key 儲存成功');
    } else {
      print('已存在 API Key: $apiKey');
    }
    final Map<String, String> headers = {
      'Content-Type': 'application/json', // 指定 JSON 格式
      'Authorization': 'Bearer ${await SecureStorage.getApiKey()}', // API 金鑰
      'X-Timestamp': timestamp, // 加入時間戳記
    };

    final response = await http
        .post(
          tokens,
          headers: headers,
        )
        .timeout(Duration(seconds: 30)); // 設置請求超時（例如 30 秒）

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // 確保 API 回應的 key 是 "token"
      if (data.containsKey('token')) {
        token = data['token'];
        print('Token 儲存成功: $token');
      } else {
        throw Exception('回應中未包含 token');
      }
    } else {
      throw Exception('取得 Token 失敗，HTTP 狀態碼: ${response.statusCode}');
    }
  } catch (e) {
    print('請求 Token 時發生錯誤: $e');
    // 可以根據需要返回錯誤訊息
  }
  return token;
}
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
    final validDirections = results.entries
        .where((e) => e.value['isValid'] == true)
        .toList();

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


Future<Map<String, dynamic>> getRouteStops(String routeName,String direction) async {
  // SQL 查詢，根據站牌名稱過濾
  var query = "SELECT * FROM Bus.Bus_Taichung_Route_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName' AND Direction=$direction ;";

  // 從資料庫取得資料
  List<Map<String, dynamic>> stopsList = await mysqlSelect(query); // 先等待 Future 完成
  Map<String, dynamic> stops ={} ;
  if (stopsList.isNotEmpty) {
    stops = stopsList[0]; // 取第一個元素
  } else {
    // stopsList 為空時的處理方式
  }



  // 若只有一個方向，另一個列表會是空的
  return stops;
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
        throw FormatException("Invalid stops data type: ${stopsData.runtimeType}");
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

        if (!stop.containsKey('StopSequence') ||
            stop['StopSequence'] is! int) {
          throw FormatException("Invalid StopSequence in stop: $stop");
        }

        return stop;
      }).toList();

      // 排序并验证顺序
      _stops.sort((a, b) => (a['StopSequence'] as int).compareTo(b['StopSequence'] as int));
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
    final index = _stops.indexWhere((stop) =>
    (stop['StopName']['Zh_tw'] as String) == zhName
    );

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
      if (sequences[i] <= sequences[i-1]) {
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