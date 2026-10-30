import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

enum MetroErrorKind { timeout, network, server, format }

/// 資料層只回報錯誤「種類」，不含任何顯示文字，文字由 UI 依語系決定。
class MetroApiException implements Exception {
  const MetroApiException(this.kind, {this.statusCode, this.detail});
  final MetroErrorKind kind;
  final int? statusCode;
  final String? detail;
  @override
  String toString() => 'MetroApiException($kind, status=$statusCode, $detail)';
}

class ApiResponse {
  const ApiResponse({this.body, this.etag, this.notModified = false});
  final String? body;
  final String? etag;
  final bool notModified;
}

/// 呼叫後端 v2 API（見 backend/metro-v2）。App 不直接連線資料庫。
/// 以 --dart-define=METRO_API_BASE=https://your-host 覆寫；正式環境應使用 HTTPS。
class MetroApiV2 {
  MetroApiV2({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = Uri.parse(baseUrl ??
            const String.fromEnvironment('METRO_API_BASE', defaultValue: 'http://hidden.rsmn574.com:3920'));

  final http.Client _client;
  final Uri _base;
  static const _timeout = Duration(seconds: 15);

  Future<ApiResponse> getCatalog({String? etag}) => _get(['api', 'metro', 'v2', 'catalog'], etag: etag);

  Future<ApiResponse> getShapes(String operatorCode, {String? etag}) =>
      _get(['api', 'metro', 'v2', 'shapes'], query: {'operator': operatorCode}, etag: etag);

  Future<ApiResponse> getStationDetail(String stationUid) =>
      _get(['api', 'metro', 'v2', 'stations', stationUid, 'detail']);

  Future<ApiResponse> _get(List<String> segments, {Map<String, String>? query, String? etag}) async {
    final uri = _base.replace(pathSegments: segments, queryParameters: query);
    final http.Response res;
    try {
      res = await _client.get(uri, headers: {
        'Accept': 'application/json',
        if (etag != null) 'If-None-Match': etag,
      }).timeout(_timeout);
    } on TimeoutException {
      throw const MetroApiException(MetroErrorKind.timeout);
    } on SocketException catch (e) {
      throw MetroApiException(MetroErrorKind.network, detail: e.message);
    } on http.ClientException catch (e) {
      throw MetroApiException(MetroErrorKind.network, detail: e.message);
    }
    if (res.statusCode == 304) return ApiResponse(etag: etag, notModified: true);
    if (res.statusCode != 200) {
      throw MetroApiException(MetroErrorKind.server, statusCode: res.statusCode);
    }
    return ApiResponse(body: utf8.decode(res.bodyBytes), etag: res.headers['etag']);
  }

  void close() => _client.close();
}
