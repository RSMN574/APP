import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/city/taiwan_city.dart';
import '../../../database/tdx_api_client.dart';
import '../model/bus_daily_timetable.dart';

/// 該城市不在 TDX DailyStopTimeTable 支援清單。
class BusScheduleUnsupportedCityException implements Exception {
  const BusScheduleUnsupportedCityException(this.city);

  final String city;

  @override
  String toString() => 'DailyStopTimeTable does not support city: $city';
}

/// 取得 TDX 市區公車每日站別時刻表。
///
/// 官方 OAS：`GET /v2/Bus/DailyStopTimeTable/City/{City}/{RouteName}`
/// （server: `https://tdx.transportdata.tw/api/basic`）
class BusScheduleRemoteDataSource {
  BusScheduleRemoteDataSource({
    TdxApiClient? client,
    Future<BusTimetableParseResult> Function(String body)? parser,
  })  : _client = client ?? TdxApiClient(),
        _parser = parser ?? _parseInBackground;

  final TdxApiClient _client;
  final Future<BusTimetableParseResult> Function(String body) _parser;

  /// OAS 中 `City` path 參數的 enum。實測其他城市回傳
  /// HTTP 400 `City: 'Taipei' is not accepted but Taichung, Taoyuan, Kaohsiung`。
  /// 新增城市時只需更新此清單。
  static const Set<String> supportedCities = {
    'Taichung',
    'Taoyuan',
    'Kaohsiung',
  };

  /// 將 App 內任一種城市寫法轉為 TDX 代碼；無法辨識時回傳 null。
  static String? resolveCity(String city) => TaiwanCity.tryParse(city)?.tdxCode;

  static bool isSupported(String city) {
    final code = resolveCity(city);
    return code != null && supportedCities.contains(code);
  }

  /// 建立請求 URI。
  ///
  /// RouteName 路徑參數在 TDX 是「包含」比對（實測 `Taoyuan/1` 會回傳 `16`、
  /// `T102`），因此一律加上 `$filter`：有 RouteID 時以 RouteID 精確比對，
  /// 否則以 `RouteName/Zh_tw` 精確比對。
  static Uri buildUri({
    required String city,
    required String routeName,
    String? routeId,
  }) {
    final code = resolveCity(city);
    if (code == null || !supportedCities.contains(code)) {
      throw BusScheduleUnsupportedCityException(city);
    }
    final name = routeName.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(routeName, 'routeName', 'must not be empty');
    }
    final id = routeId?.trim() ?? '';
    final filter = id.isNotEmpty
        ? "RouteID eq '${_odata(id)}'"
        : "RouteName/Zh_tw eq '${_odata(name)}'";
    return Uri.https(
      'tdx.transportdata.tw',
      '/api/basic/v2/Bus/DailyStopTimeTable/City/$code/$name',
      {r'$filter': filter, r'$format': 'JSON'},
    );
  }

  Future<BusScheduleFetchResult> fetch({
    required String city,
    required String routeName,
    String? routeId,
  }) async {
    final uri = buildUri(city: city, routeName: routeName, routeId: routeId);
    final stopwatch = Stopwatch()..start();
    final response = await _client.getRaw(uri);
    final networkMs = stopwatch.elapsedMilliseconds;
    stopwatch
      ..reset()
      ..start();
    final parsed = await _parser(response.body);
    return BusScheduleFetchResult(
      parsed: parsed,
      networkMs: networkMs,
      parseMs: stopwatch.elapsedMilliseconds,
      bytes: response.bodyBytes.length,
      lastModified: response.headers['last-modified'],
    );
  }

  static String _odata(String value) => value.replaceAll("'", "''");

  /// 班表回應可達數百 KB（實測桃園 1 路約 790 KB），在背景 isolate 解析
  /// 避免阻塞 UI thread。
  static Future<BusTimetableParseResult> _parseInBackground(String body) {
    if (body.length < 32 * 1024) {
      return SynchronousFuture(_decodeAndParse(body));
    }
    return compute(_decodeAndParse, body);
  }
}

BusTimetableParseResult _decodeAndParse(String body) =>
    parseBusDailyTimetables(jsonDecode(body));

class BusScheduleFetchResult {
  const BusScheduleFetchResult({
    required this.parsed,
    required this.networkMs,
    required this.parseMs,
    required this.bytes,
    this.lastModified,
  });

  final BusTimetableParseResult parsed;
  final int networkMs;
  final int parseMs;
  final int bytes;
  final String? lastModified;
}
