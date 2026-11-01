import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

/// 臺鐵（TRA）即時資料服務：車站即時看板、單一車次即時位置、誤點資訊。
///
/// 只處理 TRA 的 TDX API，不依賴 BuildContext 或 Provider。
class TraLiveboardService {
  const TraLiveboardService();

  /// 車站即時看板（僅取出 TrainNo / DelayTime，供時刻表合併誤點）。
  Future<List<Map<String, dynamic>>> fetchStationLiveBoard(
      String stationID) async {
    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveBoard/Station/$stationID?%24&%24format=JSON";
    try {
      await connMysql();
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final List<dynamic> jsonData = jsonDecode(response.body);
      final extractedData = jsonData.map<Map<String, dynamic>>((train) {
        return {"TrainNo": train["TrainNo"], "DelayTime": train["DelayTime"]};
      }).toList();
      return extractedData;
    } catch (e) {
      debugPrint('TraLiveboardService.fetchStationLiveBoard error: $e');
    }
    return [];
  }

  /// 單一車次的即時位置（v3 TrainLiveBoard/TrainNo）。
  Future<List<Map<String, dynamic>>> fetchTrainLiveBoard(
      String trainNo) async {
    final url =
        'https://tdx.transportdata.tw/api/basic/v3/Rail/TRA/TrainLiveBoard/TrainNo/$trainNo'
        '?%24top=30&%24format=JSON';

    try {
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        debugPrint('LiveBoard API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final List boards = data['TrainLiveBoards'] ?? [];

      // 整理成 UI 好用的格式
      return boards.map<Map<String, dynamic>>((e) {
        return {
          'TrainNo': e['TrainNo'],
          'StationID': e['StationID'],
          'StationNameZh': e['StationName']?['Zh_tw'],
          'StationNameEn': e['StationName']?['En'],
          'TrainStationStatus': e['TrainStationStatus'],
          'DelayTime': e['DelayTime'] ?? 0,
          'UpdateTime': e['UpdateTime'],
        };
      }).toList();
    } catch (e) {
      debugPrint('TraLiveboardService.fetchTrainLiveBoard error: $e');
      return [];
    }
  }

  /// 列車即時準點 / 延誤時間（LiveTrainDelay）。
  Future<List<dynamic>> fetchTrainDelay(String trainNo) async {
    final filter = Uri.encodeComponent("TrainNo eq '$trainNo'");
    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/LiveTrainDelay?\$filter=$filter&\$format=JSON";

    try {
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } catch (e) {
      debugPrint('TraLiveboardService.fetchTrainDelay error: $e');
    }
    return [];
  }
}
