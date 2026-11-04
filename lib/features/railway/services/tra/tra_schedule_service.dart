import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';

import '../../../../config/app_config.dart';
import '../common/railway_date_utils.dart';
import 'tra_liveboard_service.dart';

/// 臺鐵（TRA）時刻表服務：車站時刻表、起訖站查詢、轉乘規劃。
class TraScheduleService {
  const TraScheduleService({
    TraLiveboardService liveboard = const TraLiveboardService(),
  }) : _liveboard = liveboard;

  final TraLiveboardService _liveboard;

  // 車站時刻表的短期快取（行為與原 get_train.dart 相同）。
  static final Map<String, List<dynamic>> _stationCache = {};
  static DateTime _lastCacheUpdate =
      DateTime.now().subtract(const Duration(minutes: 10));

  /// 取得車站在指定日期的時刻表；
  /// 查詢時間在現在前後 30 分鐘內時，會合併即時誤點（DelayTime）。
  Future<List<dynamic>> fetchStationTimetable(
      String stationID, DateTime date) async {
    final withinRange = RailwayDateUtils.isWithinMinutes(date, minutes: 30);

    List<Map<String, dynamic>> liveBoard = [];
    if (withinRange) {
      liveBoard = await _liveboard.fetchStationLiveBoard(stationID);
    }

    final dateStr = RailwayDateUtils.formatApiDate(date);
    final cacheKey = "$stationID-$dateStr";
    if (_stationCache.containsKey(cacheKey) &&
        DateTime.now().difference(_lastCacheUpdate).inMinutes < 1) {
      return _stationCache[cacheKey]!;
    }

    final url =
        "https://tdx.transportdata.tw/api/basic/v2/Rail/TRA/DailyTimetable/Station/$stationID/$dateStr?%24format=JSON";

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

      final Set<String> processedTrainNos = {};
      final List<dynamic> mergedData = [];

      for (final train in jsonData) {
        final trainNo = train["TrainNo"].toString();
        if (processedTrainNos.contains(trainNo)) continue;

        final Map<String, dynamic> matchedTrain = liveBoard.firstWhere(
          (item) => item["TrainNo"].toString() == trainNo,
          orElse: () => {},
        );

        mergedData.add({
          ...train,
          "DelayTime": matchedTrain["DelayTime"] != null
              ? int.tryParse(matchedTrain["DelayTime"].toString())
              : null,
        });

        processedTrainNos.add(trainNo);
      }

      _stationCache[cacheKey] = mergedData;
      _lastCacheUpdate = DateTime.now();

      return mergedData;
    } catch (e) {
      debugPrint('TraScheduleService.fetchStationTimetable error: $e');
      return [];
    }
  }

  /// 起訖站查詢（直達 / 轉乘），依星期取得班表。
  ///
  /// 失敗（非 200）時拋出 Exception，交由呼叫端顯示錯誤狀態。
  Future<Map<String, dynamic>> fetchOdTimetable({
    required String fromStationId,
    required String toStationId,
    required DateTime date,
  }) async {
    final weekday = date.weekday % 7;
    final response = await http.get(
      Uri.parse(
        "${AppConfig.serviceUrl}/api/train?from=$fromStationId&to=$toStationId&day=$weekday",
      ),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('API ${response.statusCode}');
    return jsonDecode(response.body);
  }

  /// MaaS 轉乘路線規劃（起訖座標 / 名稱 + 出發時間）。
  Future<List<dynamic>> fetchRoutePlan(
    String departurePosition,
    String destinationPosition,
    String time,
  ) async {
    final encodedDeparture = Uri.encodeComponent(departurePosition);
    final encodedDestination = Uri.encodeComponent(destinationPosition);
    final encodedTime = Uri.encodeComponent(time);
    final url =
        "https://tdx.transportdata.tw/api/maas/routing?origin=$encodedDeparture&destination=$encodedDestination&gc=0.0&top=10&transit=4&transfer_time=5%2C60&depart=$encodedTime&first_mile_mode=0&last_mile_mode=0";

    try {
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw HttpException('HTTP error! status: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData["data"]["routes"];
    } catch (e) {
      debugPrint('TraScheduleService.fetchRoutePlan error: $e');
    }
    return [];
  }
}
