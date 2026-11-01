import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

import '../common/railway_date_utils.dart';

/// 臺鐵（TRA）指定車次服務：車次基本資料與經停站（DailyTimetable/TrainNo）。
class TraTrainService {
  const TraTrainService();

  /// 取得指定日期、指定車次的時刻資料；失敗時回傳 null。
  Future<dynamic> fetchTrain(int trainNo, DateTime date) async {
    final dateStr = RailwayDateUtils.formatApiDate(date);
    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/TrainNo/$trainNo/TrainDate/$dateStr?%24format=JSON";

    try {
      await connMysql();
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(response.body)[0];
      return jsonData;
    } catch (e) {
      debugPrint('TraTrainService.fetchTrain error: $e');
    }
    return null;
  }
}
