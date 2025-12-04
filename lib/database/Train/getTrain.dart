import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'dart:math';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../Const/regularConst.dart';

import '../getData.dart';
import '../token_manager.dart'; // 用于网络请求
// 定義快取
Map<String, List<dynamic>> _trainStationCache = {};
DateTime _lastCacheUpdate = DateTime.now().subtract(const Duration(minutes: 10));

Future<dynamic> fetchTrain(int trainNo,DateTime date) async {


  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  int _trainNo=trainNo;
  var _date=dateFormat.format(date) ;
  var url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/TrainNo/$_trainNo/TrainDate/$_date?%24format=JSON";

  try {
    await  connMysql();
    final tokenResponse = await http.get(tokenUri);
    final token = await TokenManager().getToken();
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
Map<String, dynamic>  jsonData = await jsonDecode(response.body)[0];

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}
// Future<List<dynamic>> fetchTrainStation(String station) async {
//
//
//
//   String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveBoard/Station/${station}?%24format=JSON";
//   try {
//     await  connMysql();
//     final tokenResponse = await http.get(tokenUri);
//     final token=tokenResponse.body;
//     // 发起 GET 请求
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'accept': 'application/json',
//       },
//     );
//
//     // 检查响应状态
//     if (response.statusCode != 200) {
//       throw HttpException('HTTP error! status: ${response.statusCode}');
//     }
//
//     // 解析 JSON 数据
//     List<dynamic>  jsonData = await jsonDecode(response.body);
// print(jsonData);
//     // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
//     // 这里你可以根据你的需求来构建 SQL 语句，例如：
//     // String sql = 'INSERT INTO $tableName (...) VALUES (...)';
//
//     return jsonData;
//   } catch (e) {
//     print('Error occurred: $e');
//   }
//   return [];
// }


Future<List<dynamic>> fetchTrainStation(String stationID, DateTime date) async {
  DateTime now = DateTime.now();
  DateTime targetTime = date;

  // 計算前後 30 分鐘範圍
  DateTime startRange = now.subtract(Duration(minutes: 30));
  DateTime endRange = now.add(Duration(minutes: 30));

  // 判斷 targetTime 是否在範圍內
  bool isWithinRange = targetTime.isAfter(startRange) && targetTime.isBefore(endRange);

  List<Map<String, dynamic>> trainLiveBoard = [];

  if (isWithinRange) {
    trainLiveBoard = await fetchTrainLiveBoard(stationID);
    print("時間在前後 30 分鐘內，載入即時列車資訊");
  } else {
    print("時間超出範圍，僅載入時刻表");
  }

  // 檢查快取是否有效
  String cacheKey = "$stationID-${DateFormat('yyyy-MM-dd').format(date)}";
  if (_trainStationCache.containsKey(cacheKey) && DateTime.now().difference(_lastCacheUpdate).inMinutes < 1) {
    print("使用快取資料");
    return _trainStationCache[cacheKey]!;
  }

  // 構建 API URL
  String url = "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/Station/$stationID/${DateFormat('yyyy-MM-dd').format(date)}?%24format=JSON";

  try {
    await connMysql();
    final tokenResponse = await http.get(tokenUri);
    final token = await TokenManager().getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('HTTP error! status: ${response.statusCode}');
    }

    List<dynamic> jsonData = jsonDecode(response.body);

    // **處理合併衝突**
    Set<String> processedTrainNos = {}; // 避免重複合併相同 TrainNo
    List<dynamic> mergedData = [];

    for (var train in jsonData) {
      String trainNo = train["TrainNo"].toString();
      if (processedTrainNos.contains(trainNo)) continue; // 防止重複合併

      Map<String, dynamic>? matchedTrain = trainLiveBoard.firstWhere(
            (item) => item["TrainNo"].toString() == trainNo,
        orElse: () => {}, // 回傳空 Map 來避免錯誤
      );

      mergedData.add({
        ...train, // 原始時刻表資料
        "DelayTime": matchedTrain["DelayTime"] != null
            ? int.tryParse(matchedTrain["DelayTime"].toString())
            : null, // 預設 DelayTime 為 0
      });

      processedTrainNos.add(trainNo);
    }

    // 更新快取
    _trainStationCache[cacheKey] = mergedData;
    _lastCacheUpdate = DateTime.now();

    return mergedData;
  } catch (e) {
    print('發生錯誤: $e');
    return [];
  }
}
//取得指定[日期],[起迄站間]之站間時刻表資料
Future<List<dynamic>> fetchTrainRoute(String departurePosition,String destinationPosition,String time) async {

  // 对参数进行 URL 编码
  String encodedDeparture = Uri.encodeComponent(departurePosition);
  String encodedDestination = Uri.encodeComponent(destinationPosition);
  String encodedTime = Uri.encodeComponent(time);
 // String url="https://tdx.transportdata.tw/api/basic/v3/Rail/TRA/DailyTrainTimetable/OD/Inclusive/$departureID/to/$destinationID/$date?%24&%24format=JSON";
  String url="https://tdx.transportdata.tw/api/maas/routing?origin=$encodedDeparture&destination=$encodedDestination&gc=0.0&top=10&transit=4&transfer_time=5%2C60&depart=$encodedTime&first_mile_mode=0&last_mile_mode=0";

  try {


    final tokenResponse = await http.get(tokenUri);
    final token = await TokenManager().getToken();
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
    Map<String, dynamic>  jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData["data"]["routes"];
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
//取得列車即時準點/延誤時間資料。
Future<List<dynamic>> fetchLiveTrainDelay(String trainNo) async {


  String filter = Uri.encodeComponent("TrainNo eq '$trainNo'");
  String url = "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveTrainDelay?\$filter=$filter&\$format=JSON";

  try {
    final tokenResponse = await http.get(tokenUri);
    final token = await TokenManager().getToken();
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
    List<dynamic> jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';
    print(jsonData);
    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}

Future<List<Map<String, dynamic>>> fetchTrainLiveBoard(String stationID) async {


  String url="https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveBoard/Station/$stationID?%24&%24format=JSON";
  try {
    await  connMysql();
    final tokenResponse = await http.get(tokenUri);
    final token = await TokenManager().getToken();
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
    List<dynamic>  jsonData = await jsonDecode(response.body);
    List<Map<String, dynamic>> extractedData = jsonData.map((train) {
      return {
        "TrainNo": train["TrainNo"],
        "DelayTime": train["DelayTime"]
      };
    }).toList();
    print(extractedData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return extractedData;
  } catch (e) {
    print('Error occurred: $e');
  }
  return [];
}
Future<Set<Polyline>> fetchTrainNetworkLine() async {
  const String url =
      "https://tdx.transportdata.tw/api/basic/V3/Map/Rail/Network/Line/OperatorCode/TRA?format=GEOJSON";

  try {
    // 確保 token 有取得
    final token = await TokenManager().getToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    print("HTTP Status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('HTTP error! status: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    if (data == null || !(data is List)) {
      throw Exception("Invalid data format: Expected List");
    }

    List features = data;
    Set<Polyline> allPolylines = {};
    int polylineIdCounter = 1;

    for (var f in features) {
      try {
        final lineID = f["LineID"] ?? "unknown";
        final lineName = f["LineName"] ?? "unknown";
        final geometryString = f["Geometry"] as String?;

        if (geometryString == null || geometryString.isEmpty) {
          print("No geometry for LineID: $lineID");
          continue;
        }

        print("Processing LineID: $lineID, Geometry type: ${geometryString.substring(0, min(20, geometryString.length))}...");

        // 解析WKT格式的Geometry字串
        List<List<LatLng>> lineStrings = parseWKTGeometry(geometryString);

        for (var points in lineStrings) {
          if (points.length < 2) {
            print("Warning: LineID $lineID has insufficient points: ${points.length}");
            continue;
          }

          allPolylines.add(Polyline(
            polylineId: PolylineId("$lineID-$polylineIdCounter"),
            points: points,
            color: _getLineColor(lineID),
            width: 4,
          ));
          polylineIdCounter++;
        }
      } catch (e) {
        print("Error processing feature: $e");
        continue;
      }
    }

    print("Total polylines created: ${allPolylines.length}");
    return allPolylines;
  } catch (e) {
    print("Error occurred: $e");
    return {};
  }
}

// 解析WKT格式的Geometry字串
List<List<LatLng>> parseWKTGeometry(String wkt) {
  List<List<LatLng>> result = [];

  try {
    // 移除多餘的空格和括號
    wkt = wkt.trim();

    if (wkt.startsWith('MULTILINESTRING')) {
      // MULTILINESTRING ((x y, x y), (x y, x y))
      String coordsStr = wkt.substring('MULTILINESTRING'.length).trim();
      coordsStr = coordsStr.substring(1, coordsStr.length - 1); // 移除外層括號

      // 分割每個LineString
      List<String> lineStrings = _splitLineStrings(coordsStr);

      for (String lineStr in lineStrings) {
        List<LatLng> points = _parseCoordinates(lineStr);
        if (points.isNotEmpty) {
          result.add(points);
        }
      }
    } else if (wkt.startsWith('LINESTRING')) {
      // LINESTRING (x y, x y)
      String coordsStr = wkt.substring('LINESTRING'.length).trim();
      coordsStr = coordsStr.substring(1, coordsStr.length - 1); // 移除括號

      List<LatLng> points = _parseCoordinates(coordsStr);
      if (points.isNotEmpty) {
        result.add(points);
      }
    } else {
      print("Unknown WKT format: ${wkt.substring(0, min(50, wkt.length))}");
    }
  } catch (e) {
    print("Error parsing WKT: $e, WKT: ${wkt.substring(0, min(100, wkt.length))}");
  }

  return result;
}

// 分割MultiLineString中的各個LineString
List<String> _splitLineStrings(String coordsStr) {
  List<String> result = [];
  int depth = 0;
  int start = 0;

  for (int i = 0; i < coordsStr.length; i++) {
    if (coordsStr[i] == '(') {
      depth++;
      if (depth == 1) {
        start = i;
      }
    } else if (coordsStr[i] == ')') {
      depth--;
      if (depth == 0) {
        result.add(coordsStr.substring(start, i + 1));
      }
    }
  }

  return result;
}

// 解析座標點字串
List<LatLng> _parseCoordinates(String coordsStr) {
  List<LatLng> points = [];

  try {
    // 分割座標點
    List<String> coordPairs = coordsStr.split(',');

    for (String pair in coordPairs) {
      pair = pair.trim();
      // 移除可能的括號
      pair = pair.replaceAll('(', '').replaceAll(')', '').trim();

      List<String> coords = pair.split(' ');
      if (coords.length >= 2) {
        double lng = double.tryParse(coords[0]) ?? 0.0;
        double lat = double.tryParse(coords[1]) ?? 0.0;

        // 確保座標有效
        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          points.add(LatLng(lat, lng));
        }
      }
    }
  } catch (e) {
    print("Error parsing coordinates: $e, String: $coordsStr");
  }

  return points;
}

// 根據LineID回傳不同的顏色
Color _getLineColor(String lineID) {
  final colors = {
    'WL': Colors.blue,      // 西部幹線
    'EL': Colors.green,     // 東部幹線
    'SH': Colors.orange,    // 沙崙線
    'PM': Colors.purple,    // 平溪線
    'JL': Colors.red,       // 集集線
    'SL': Colors.teal,      // 深澳線
  };

  return colors[lineID] ?? Colors.grey;
}


