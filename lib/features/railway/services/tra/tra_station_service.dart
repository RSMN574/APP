import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

/// 臺鐵（TRA）車站與路網服務：車站清單、車站設施、鐵路路網 Polyline。
class TraStationService {
  const TraStationService();

  /// 取得全部臺鐵車站（供車站選擇）。
  Future<List<Map<String, dynamic>>> fetchStations() async {
    final List stationData = await mysqlSelect(
        "SELECT StationID,StationClass,StationName,StationPosition,LocationCity FROM Train.Train_Station;");

    return stationData.map<Map<String, dynamic>>((item) {
      final stationName = json.decode(item["StationName"]);
      return {
        'StationName': {
          'Zh_tw': stationName['Zh_tw'],
          'En': stationName['En'],
        },
        'LocationCity': item['LocationCity'],
        'StationClass': item['StationClass'],
        'StationID': item['StationID'],
        'StationPosition': item['StationPosition'],
      };
    }).toList();
  }

  /// 取得車站設施資料。
  Future<List<dynamic>> fetchStationFacility(String stationID) {
    return fetchTrainStationFacility(stationID);
  }

  /// 解析 WKT 格式的 Geometry 字串（LINESTRING / MULTILINESTRING）。
  static List<List<LatLng>> parseWKTGeometry(String wkt) =>
      _parseWKTGeometry(wkt);

  /// 取得臺鐵路網 Polyline（TDX GeoJSON / WKT）。
  Future<Set<Polyline>> fetchNetworkLine() async {
    const String url =
        "https://tdx.transportdata.tw/api/basic/V3/Map/Rail/Network/Line/OperatorCode/TRA?format=GEOJSON";

    try {
      // 確保 token 有取得
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
        },
      );

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
          final geometryString = f["Geometry"] as String?;

          if (geometryString == null || geometryString.isEmpty) {
            debugPrint("No geometry for LineID: $lineID");
            continue;
          }

          debugPrint(
              "Processing LineID: $lineID, Geometry type: ${geometryString.substring(0, min(20, geometryString.length))}...");

          // 解析WKT格式的Geometry字串
          List<List<LatLng>> lineStrings = parseWKTGeometry(geometryString);

          for (var points in lineStrings) {
            if (points.length < 2) {
              debugPrint(
                  "Warning: LineID $lineID has insufficient points: ${points.length}");
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
          debugPrint("Error processing feature: $e");
          continue;
        }
      }

      debugPrint("Total polylines created: ${allPolylines.length}");
      return allPolylines;
    } catch (e) {
      debugPrint("Error occurred: $e");
      return {};
    }
  }
}

// 解析WKT格式的Geometry字串
List<List<LatLng>> _parseWKTGeometry(String wkt) {
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
      debugPrint("Unknown WKT format: ${wkt.substring(0, min(50, wkt.length))}");
    }
  } catch (e) {
    debugPrint(
        "Error parsing WKT: $e, WKT: ${wkt.substring(0, min(100, wkt.length))}");
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
    debugPrint("Error parsing coordinates: $e, String: $coordsStr");
  }

  return points;
}

// 根據LineID回傳不同的顏色
Color _getLineColor(String lineID) {
  final colors = {
    'WL': Colors.blue, // 西部幹線
    'EL': Colors.green, // 東部幹線
    'SH': Colors.orange, // 沙崙線
    'PM': Colors.purple, // 平溪線
    'JL': Colors.red, // 集集線
    'SL': Colors.teal, // 深澳線
  };

  return colors[lineID] ?? Colors.grey;
}
