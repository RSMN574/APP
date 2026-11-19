import 'dart:async';

import 'package:com.rsmn574.app/core/error/app_error_handler.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'dart:convert'; // For JSON decoding
import 'dart:io'; // For file reading and writing

Future<List<Map<String, dynamic>>> fetchStationInfo(
    List<String> stationIds, String city) async {
  try {
    // 只呼叫 TDX；不需要 MySQL 連線（連線失敗會讓整個查詢失敗）。

    // Fetch the token
    // Generate all requests for each station ID
    List<Future<List<Map<String, dynamic>>>> requests =
        stationIds.map((stationId) async {
          final String url;
          if (city == 'InterCity') {
            // InterCity
            // 先前查詢字串被接在路徑上（Station/{id}$t&$format=JSON?...），
            // TDX 會把它當成不存在的站位 ID，公路客運永遠回傳 0 筆。
            url =
                'https://tdx.transportdata.tw/api/advanced/v2/Bus/EstimatedTimeOfArrival/InterCity/PassThrough/Station/$stationId?\$format=JSON';
          }else{
            url =
            "https://tdx.transportdata.tw/api/advanced/v2/Bus/EstimatedTimeOfArrival/City/$city/PassThrough/Station/$stationId?\$format=JSON";

          }

      // Fetch data for the specific station ID
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
        },
      );

      // Check the response status
      if (response.statusCode != 200) {
        throw HttpException(
            'HTTP error for StationID $stationId! Status: ${response.statusCode}');
      }

      // Parse and return JSON data
      final List<dynamic> jsonData = jsonDecode(response.body);

// Add the 'type' field to each item
      final List<Map<String, dynamic>> modifiedData = jsonData.map((item) {
        final modifiedItem = Map<String, dynamic>.from(item);
        modifiedItem['StationID'] = stationId; // 新增 type 字段，值为 stationId
        return modifiedItem;
      }).toList();

      // print('JSON fetched successfully for StationID $stationId: $modifiedData');

      return modifiedData.map((item) => item).toList();
    }).toList();

    // QA B09：先前任何一個站位失敗就整批回傳 []，UI 顯示「無資料」而非錯誤。
    // 現在保留成功站位的資料；全部失敗時丟出錯誤讓上層顯示錯誤與重試。
    final settled = await Future.wait(requests.map((request) => request
        .then<Object>((value) => value)
        .catchError((Object error, StackTrace stack) =>
            _StationFailure(error, stack))));

    final failures = settled.whereType<_StationFailure>().toList();
    final results = settled.whereType<List<Map<String, dynamic>>>().toList();
    if (failures.isNotEmpty) {
      unawaited(AppErrorHandler.recordNonFatal(
        failures.first.error,
        failures.first.stack,
        feature: 'bus_station_eta',
        reason: '${failures.length}/${settled.length} stations failed',
      ));
      if (results.isEmpty) {
        Error.throwWithStackTrace(failures.first.error, failures.first.stack);
      }
    }

    return results.expand((element) => element).toList();
  } on ArgumentError {
    rethrow;
  }
}

class _StationFailure {
  const _StationFailure(this.error, this.stack);

  final Object error;
  final StackTrace stack;
}
