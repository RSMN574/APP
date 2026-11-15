// lib/services/bike_prediction_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../models/bike_prediction.dart';

/// 站點到站預測服務
///
/// 使用方式：
/// ```dart
/// final p = await BikePredictionService.instance.predict(
///   stationUID: 'TXG500605010',
///   targetTime: DateTime.now().add(const Duration(hours: 1)),
/// );
/// ```
class BikePredictionService {
  BikePredictionService._();
  static final BikePredictionService instance = BikePredictionService._();

  /// ⚠️ 請依你的環境修改：
  /// - Android Emulator 連本機 → http://10.0.2.2:3000/api
  /// - iOS Simulator     → http://localhost:3000/api
  /// - 實機 / 正式站     → https://your-domain.com/api
  static String baseUrl = AppConfig.serviceUrl+"/api";

  static const Duration _timeout = Duration(seconds: 12);

  /// 單站預測
  Future<BikePrediction?> predict({
    required String stationUID,
    required DateTime targetTime,
    int? days,
    int? window,
    bool adaptive = false,
  }) async {
    final uri = Uri.parse('$baseUrl/predict').replace(queryParameters: {
      'station': stationUID,
      'time': _isoLocal(targetTime),
      if (days != null) 'days': '$days',
      if (window != null) 'window': '$window',
      if (adaptive) 'adaptive': '1',
    });
  print(uri);
    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) {
        // 嘗試解析後端錯誤
        final body = _tryDecode(res.body);
        if (body != null) {
          final parsed = BikePredictionResponse.fromJson(body);
          throw BikePredictionException(
            code: body['error']?['code']?.toString() ?? 'HTTP_${res.statusCode}',
            message: parsed.errorMessage ?? 'HTTP ${res.statusCode}',
          );
        }
        throw BikePredictionException(
          code: 'HTTP_${res.statusCode}',
          message: 'HTTP ${res.statusCode}',
        );
      }

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final parsed = BikePredictionResponse.fromJson(body);
      if (!parsed.success) {
        throw BikePredictionException(
          code: 'PARSE_ERROR',
          message: parsed.errorMessage ?? '解析失敗',
        );
      }
      return parsed.data;
    } on BikePredictionException {
      rethrow;
    } catch (e) {
      throw BikePredictionException(code: 'NETWORK_ERROR', message: e.toString());
    }
  }

  /// 批次預測（最多 50 站）
  Future<Map<String, BikePrediction?>> predictBatch({
    required List<String> stationUIDs,
    required DateTime targetTime,
  }) async {
    if (stationUIDs.isEmpty) return {};
    final uri = Uri.parse('$baseUrl/predict/batch').replace(queryParameters: {
      'stations': stationUIDs.join(','),
      'time': _isoLocal(targetTime),
    });

    final res = await http.get(uri).timeout(_timeout);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (body['data'] as List?) ?? [];
    final map = <String, BikePrediction?>{};
    for (final item in list) {
      if (item is Map<String, dynamic> && item['station'] != null) {
        final uid = item['station'].toString();
        if (item['error'] != null) {
          map[uid] = null;
        } else {
          map[uid] = BikePrediction.fromJson(item);
        }
      }
    }
    return map;
  }

  // ─── helpers ───
  String _isoLocal(DateTime dt) {
    // 用本地時間 ISO 8601（後端會用 new Date(...) 解析）
    final p = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${p(dt.month)}-${p(dt.day)} '
        '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
  }

  Map<String, dynamic>? _tryDecode(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
}

class BikePredictionException implements Exception {
  final String code;
  final String message;
  BikePredictionException({required this.code, required this.message});

  @override
  String toString() => '[$code] $message';
}