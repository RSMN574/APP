import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'metro_repository.dart';

// ==========================================
// GetMetro API 服務
// ==========================================
class GetMetro {
  GetMetro({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = "http://hidden.rsmn574.com:3920";
  final http.Client _client;

  /// 取得所有城市清單
  ///
  /// 對應後端：GET /api/metro/cities
  Future<List<CityInfo>> getCities() async {
    final uri = Uri.parse("$_baseUrl/api/metro/cities");

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('取得城市清單逾時，請稍後再試');
    } on SocketException catch (e) {
      throw Exception('無法連線到伺服器：${e.message}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        '取得城市清單失敗：HTTP ${response.statusCode}\n${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const FormatException('城市清單 JSON 格式錯誤');
    }

    if (decoded is! List) {
      throw const FormatException('城市清單格式不是陣列');
    }

    return decoded
        .map((e) => CityInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 取得指定城市的捷運資料
  ///
  /// 對應後端：GET /api/metro/:city
// GetMetro.dart
  Future<CityMetroData> getMetro(String city) async {
    final normalizedCity = city.trim().toLowerCase();

    if (normalizedCity.isEmpty) {
      throw ArgumentError('城市代碼不可為空');
    }

    final uri = Uri.parse("$_baseUrl/api/metro/$normalizedCity");

    final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('連線逾時，請稍後再試');
    } on SocketException catch (e) {
      throw Exception('無法連線到伺服器：${e.message}');
    }

    if (response.statusCode != 200) {
      throw Exception(
        '取得捷運資料失敗：HTTP ${response.statusCode}\n${response.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const FormatException('捷運 API 回傳的 JSON 格式錯誤');
    }

    if (decoded is Map && decoded.containsKey('error')) {
      throw Exception('API 錯誤：${decoded['error']}');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON 格式不是物件');
    }

    // ✅ 這裡直接轉回 CityMetroData
    return CityMetroData.fromJson(decoded);
  }
  void close() {
    _client.close();
  }
}
