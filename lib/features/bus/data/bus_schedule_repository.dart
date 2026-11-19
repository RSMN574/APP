import 'dart:async';
import 'dart:convert';

import '../../../core/cache/api_cache.dart';
import '../../../core/cache/cached_entry.dart';
import '../model/bus_daily_timetable.dart';
import 'bus_schedule_remote_data_source.dart';

/// 班表查詢結果。
class BusScheduleResult {
  const BusScheduleResult({
    required this.timetables,
    required this.fetchedAt,
    required this.fromCache,
    this.isStale = false,
    this.staleReason,
    this.networkMs,
    this.parseMs,
    this.skippedEntries = 0,
  });

  final List<BusDailyTimetable> timetables;
  final DateTime fetchedAt;
  final bool fromCache;

  /// API 失敗時回傳的「最後一次有效資料」。
  final bool isStale;
  final Object? staleReason;
  final int? networkMs;
  final int? parseMs;
  final int skippedEntries;

  bool get isEmpty => timetables.every((t) => !t.hasAnyTime);
}

/// 班表 Repository：
/// - 以「城市 + RouteID（或路線名稱）」作為快取識別
/// - 記憶體 + 檔案兩層快取，TTL 預設 6 小時（資料每日更新一次）
/// - 同一路線同時間只發出一個請求（request de-duplication）
/// - API 失敗時回傳最後一次有效資料，並標記 isStale
/// - 空回應不會覆蓋既有的有效快取
class BusScheduleRepository {
  BusScheduleRepository({
    BusScheduleRemoteDataSource? remote,
    ApiCache? cache,
    Duration ttl = const Duration(hours: 6),
    DateTime Function()? clock,
  })  : _remote = remote ?? BusScheduleRemoteDataSource(),
        _cache = cache ?? FileApiCache(),
        _ttl = ttl,
        _now = clock ?? DateTime.now;

  final BusScheduleRemoteDataSource _remote;
  final ApiCache _cache;
  final Duration _ttl;
  final DateTime Function() _now;

  final Map<String, _MemoryEntry> _memory = {};
  final Map<String, Future<BusScheduleResult>> _inFlight = {};

  /// 統計（後台監控與報告使用）。
  int cacheHits = 0;
  int cacheMisses = 0;
  int networkRequests = 0;

  static String cacheKey({
    required String city,
    required String routeName,
    String? routeId,
  }) {
    final code = BusScheduleRemoteDataSource.resolveCity(city) ?? city;
    final id = (routeId?.trim().isNotEmpty ?? false)
        ? 'id:${routeId!.trim()}'
        : 'name:${routeName.trim()}';
    return 'bus_daily_timetable/v1/$code/$id';
  }

  Future<BusScheduleResult> load({
    required String city,
    required String routeName,
    String? routeId,
    bool forceRefresh = false,
  }) {
    final key = cacheKey(city: city, routeName: routeName, routeId: routeId);
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _load(
      key: key,
      city: city,
      routeName: routeName,
      routeId: routeId,
      forceRefresh: forceRefresh,
    );
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  Future<BusScheduleResult> _load({
    required String key,
    required String city,
    required String routeName,
    String? routeId,
    required bool forceRefresh,
  }) async {
    final cached = await _readCache(key);
    if (!forceRefresh && cached != null && _isFresh(cached.fetchedAt)) {
      cacheHits++;
      return BusScheduleResult(
        timetables: cached.timetables,
        fetchedAt: cached.fetchedAt,
        fromCache: true,
      );
    }
    cacheMisses++;

    try {
      networkRequests++;
      final fetched = await _remote.fetch(
        city: city,
        routeName: routeName,
        routeId: routeId,
      );
      final timetables = fetched.parsed.timetables;
      final hasData = timetables.any((t) => t.hasAnyTime);
      final now = _now();

      if (!hasData && cached != null && cached.timetables.isNotEmpty) {
        // 空回應不可覆蓋既有有效班表（TDX 偶爾在更新期間回傳空陣列）。
        return BusScheduleResult(
          timetables: cached.timetables,
          fetchedAt: cached.fetchedAt,
          fromCache: true,
          isStale: true,
          staleReason: 'empty_response',
          networkMs: fetched.networkMs,
          parseMs: fetched.parseMs,
        );
      }

      if (hasData) {
        _memory[key] = _MemoryEntry(timetables, now);
        await _cache.write(
          key,
          CachedEntry(
            body: jsonEncode([for (final t in timetables) t.toJson()]),
            cachedAt: now,
          ),
        );
      }

      return BusScheduleResult(
        timetables: timetables,
        fetchedAt: now,
        fromCache: false,
        networkMs: fetched.networkMs,
        parseMs: fetched.parseMs,
        skippedEntries: fetched.parsed.skippedEntries,
      );
    } catch (error) {
      if (error is BusScheduleUnsupportedCityException) rethrow;
      if (cached != null && cached.timetables.isNotEmpty) {
        return BusScheduleResult(
          timetables: cached.timetables,
          fetchedAt: cached.fetchedAt,
          fromCache: true,
          isStale: true,
          staleReason: error,
        );
      }
      rethrow;
    }
  }

  bool _isFresh(DateTime fetchedAt) => _now().difference(fetchedAt) < _ttl;

  Future<_MemoryEntry?> _readCache(String key) async {
    final memory = _memory[key];
    if (memory != null) return memory;
    final entry = await _cache.read(key);
    if (entry == null || entry.cachedAt == null) return null;
    try {
      final parsed = parseBusDailyTimetables(jsonDecode(entry.body));
      final restored = _MemoryEntry(parsed.timetables, entry.cachedAt!);
      _memory[key] = restored;
      return restored;
    } catch (_) {
      // 快取損壞視為 cache miss 並移除。
      await _cache.delete(key);
      return null;
    }
  }

  /// 清除記憶體快取（測試或使用者手動清除時使用）。
  void clearMemory() => _memory.clear();
}

class _MemoryEntry {
  _MemoryEntry(this.timetables, this.fetchedAt);

  final List<BusDailyTimetable> timetables;
  final DateTime fetchedAt;
}
