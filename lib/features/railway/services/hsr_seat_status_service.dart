import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:com.rsmn574.app/database/get_data.dart'
    show fetchByUrl;


import '../model/hsr_seat_status_model.dart';

/// 高鐵 OD 座位狀態服務。
///
/// 職責：
/// - 呼叫 TDX `AvailableSeatStatus/Train/OD` API
/// - 以 (origin|dest|date) 為 key 快取
/// - 相同 key 請求共用 Future（in-flight 去重）
/// - API 失敗時回傳上一次成功的資料（stale fallback）
/// - 依 TDX 更新頻率設定 TTL
class HsrSeatStatusService {
  HsrSeatStatusService._();

  static final HsrSeatStatusService instance =
  HsrSeatStatusService._();

  /// 測試注入點：預設用 `fetchByUrl`。
  @visibleForTesting
  Future<dynamic> Function(String url) fetchUrl = fetchByUrl;

  static const String _baseUrl =
      'https://tdx.transportdata.tw/api/basic/v2/Rail/THSR/'
      'AvailableSeatStatus/Train/OD';

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<HsrOdSeatStatus>> _inFlight = {};

  /// 取得指定 OD + 日期的座位狀態。
  Future<HsrOdSeatStatus> fetch({
    required String originStationId,
    required String destinationStationId,
    required DateTime date,
    bool forceRefresh = false,
  }) async {
    final dateStr = _formatDate(date);
    final key = '$originStationId|$destinationStationId|$dateStr';
    final now = DateTime.now();
    final cached = _cache[key];

    // 1. 快取仍新鮮 → 直接回傳
    if (!forceRefresh &&
        cached != null &&
        now.isBefore(cached.expiresAt)) {
      return cached.data;
    }

    // 2. in-flight 去重
    final pending = _inFlight[key];
    if (!forceRefresh && pending != null) return pending;

    // 3. 發請求
    final future = _loadAndCache(
      key,
      originStationId: originStationId,
      destinationStationId: destinationStationId,
      dateStr: dateStr,
      date: date,
    );
    _inFlight[key] = future;
    try {
      return await future;
    } catch (e, s) {
      // 4. API 失敗：有舊資料就用舊資料
      if (cached != null) {
        debugPrint(
            'HsrSeatStatusService: API 失敗，使用舊資料: $e');
        return cached.data;
      }
      debugPrintStack(stackTrace: s);
      rethrow;
    } finally {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    }
  }

  Future<HsrOdSeatStatus> _loadAndCache(
      String key, {
        required String originStationId,
        required String destinationStationId,
        required String dateStr,
        required DateTime date,
      }) async {
    final url = '$_baseUrl/$originStationId/to/$destinationStationId'
        '/TrainDate/$dateStr?\$format=JSON';

    final dynamic response = await fetchUrl(url);

    // API 可能直接回 Map，或包在 List 裡（防禦性處理）
    Map<String, dynamic> json;
    if (response is Map) {
      json = Map<String, dynamic>.from(response);
    } else if (response is List && response.isNotEmpty) {
      final first = response.first;
      json = first is Map ? Map<String, dynamic>.from(first) : {};
    } else {
      json = {};
    }

    final parsed = HsrOdSeatStatus.fromJson(json);

    _cache[key] = _CacheEntry(
      data: parsed,
      expiresAt: DateTime.now().add(_ttlFor(date)),
    );
    return parsed;
  }

  /// TTL 策略：
  /// - 當日（date == today）：10 分鐘（對應 TDX 更新頻率）
  /// - 未來 27 天：10 分鐘（保守，避免拿到舊資料；實際 TDX 每天 10/16/22 更新）
  /// - 超過 27 天：1 小時（TDX 通常不提供資料）
  Duration _ttlFor(DateTime date) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    if (isToday) return const Duration(minutes: 10);

    final diff = date.difference(today).inDays;
    if (diff <= 27) return const Duration(minutes: 10);
    return const Duration(hours: 1);
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  void invalidate({
    required String originStationId,
    required String destinationStationId,
    required DateTime date,
  }) {
    _cache.remove(
        '$originStationId|$destinationStationId|${_formatDate(date)}');
  }

  void clearCache() => _cache.clear();
}

class _CacheEntry {
  const _CacheEntry({required this.data, required this.expiresAt});
  final HsrOdSeatStatus data;
  final DateTime expiresAt;
}