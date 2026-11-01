import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/tdx_api_client.dart';

/// 高鐵（THSR）時刻表服務：指定日期、起訖站之站間時刻表。
class ThsrScheduleService {
  const ThsrScheduleService();

  /// 取得指定 [date]（yyyy-MM-dd）、起訖站間的時刻表；失敗時回傳空清單。
  Future<List<dynamic>> fetchOdTimetable(
    dynamic departureId,
    dynamic destinationId,
    dynamic date,
  ) async {
    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/DailyTimetable/OD/$departureId/to/$destinationId/$date?%24format=JSON";

    try {
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } catch (e) {
      debugPrint('ThsrScheduleService.fetchOdTimetable error: $e');
    }
    return [];
  }
}
