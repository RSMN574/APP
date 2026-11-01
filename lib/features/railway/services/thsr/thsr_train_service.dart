import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

import '../common/railway_date_utils.dart';

/// 高鐵（THSR）車次服務：指定車次的時刻與停靠站、單車次座位狀態。
class ThsrTrainService {
  const ThsrTrainService();

  /// 取得指定日期、指定車次（4 碼）的時刻資料；失敗時回傳 null。
  Future<dynamic> fetchTrain(String trainNo, DateTime date) async {
    final dateStr = RailwayDateUtils.formatApiDate(date);
    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/DailyTimetable/TrainNo/$trainNo/TrainDate/$dateStr?%24format=JSON";

    try {
      await connMysql();
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(response.body)[0];
      return jsonData;
    } catch (e) {
      debugPrint('ThsrTrainService.fetchTrain error: $e');
    }
    return null;
  }

  /// 指定車次、起訖站與日期的座位狀態（AvailableSeatStatus/Train/OD/.../TrainNo）。
  Future<dynamic> fetchAvailableSeatStatus(
    String departureID,
    String arrivalID,
    String trainNo,
    String date,
  ) async {
    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/AvailableSeatStatus/Train/OD/$departureID/to/$arrivalID/TrainDate/$date/TrainNo/$trainNo?%24&%24format=JSON";

    try {
      await connMysql();
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } catch (e) {
      debugPrint('ThsrTrainService.fetchAvailableSeatStatus error: $e');
    }
    return null;
  }
}
