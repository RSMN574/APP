import 'dart:convert';

import 'metro_api_v2.dart';
import 'metro_cache.dart';
import 'models/metro_models.dart';

class CatalogResult {
  const CatalogResult(this.catalog, {required this.isStale});
  final MetroCatalog catalog;

  /// true = 網路失敗，目前顯示的是本機快取。
  final bool isStale;
}

class _Fetched<T> {
  const _Fetched(this.value, this.isStale);
  final T value;
  final bool isStale;
}

/// 單一資料來源：網路（ETag 驗證）→ 本機檔案快取（詳情另有記憶體快取）。
/// 相同資源的並行請求會合併成一次。
class MetroDataRepository {
  MetroDataRepository({MetroApiV2? api, MetroCache? cache})
      : _api = api ?? MetroApiV2(),
        _cache = cache ?? FileMetroCache();

  final MetroApiV2 _api;
  final MetroCache _cache;
  final Map<String, Future<Object?>> _inflight = {};
  final Map<String, StationDetail> _details = {};

  Future<T> _once<T>(String key, Future<T> Function() run) {
    final existing = _inflight[key];
    if (existing != null) return existing.then((v) => v as T);
    final f = run();
    _inflight[key] = f;
    f.then<void>((_) {}, onError: (_) {}).whenComplete(() => _inflight.remove(key));
    return f;
  }

  T _parse<T>(String body, T Function(Map<String, dynamic>) build) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) throw const FormatException('not an object');
      return build(Map<String, dynamic>.from(decoded));
    } on FormatException catch (e) {
      throw MetroApiException(MetroErrorKind.format, detail: e.message);
    } on TypeError catch (e) {
      throw MetroApiException(MetroErrorKind.format, detail: e.toString());
    }
  }

  Future<_Fetched<T>> _fetchWithCache<T>({
    required String key,
    required Future<ApiResponse> Function(String? etag) fetch,
    required T Function(Map<String, dynamic>) build,
  }) async {
    final cached = await _cache.read(key);
    try {
      final res = await fetch(cached?.etag);
      if (res.notModified && cached != null) {
        return _Fetched(_parse(cached.body, build), false);
      }
      final body = res.body;
      if (body == null) throw const MetroApiException(MetroErrorKind.format, detail: 'empty body');
      final value = _parse(body, build); // 先解析成功才寫入快取，避免壞資料被存下
      await _cache.write(key, CachedEntry(body: body, etag: res.etag));
      return _Fetched(value, false);
    } on MetroApiException {
      if (cached != null) {
        try {
          return _Fetched(_parse(cached.body, build), true);
        } on MetroApiException {
          // 快取也壞了，往外丟原本的錯誤
        }
      }
      rethrow;
    }
  }

  Future<CatalogResult> loadCatalog() => _once<CatalogResult>('catalog', () async {
        final r = await _fetchWithCache<MetroCatalog>(
          key: 'catalog',
          fetch: (etag) => _api.getCatalog(etag: etag),
          build: MetroCatalog.fromJson,
        );
        return CatalogResult(r.value, isStale: r.isStale);
      });

  Future<List<LineShape>> loadShapes(String operatorCode) =>
      _once<List<LineShape>>('shapes_$operatorCode', () async {
        final r = await _fetchWithCache<List<LineShape>>(
          key: 'shapes_$operatorCode',
          fetch: (etag) => _api.getShapes(operatorCode, etag: etag),
          build: (j) {
            final list = j['shapes'];
            if (list is! List) throw const FormatException('shapes missing');
            return list
                .whereType<Map>()
                .map((e) => LineShape.fromJson(Map<String, dynamic>.from(e)))
                .toList(growable: false);
          },
        );
        return r.value;
      });

  Future<StationDetail> loadDetail(String stationUid) async {
    final hit = _details[stationUid];
    if (hit != null) return hit;
    return _once<StationDetail>('detail_$stationUid', () async {
      final res = await _api.getStationDetail(stationUid);
      final body = res.body;
      if (body == null) throw const MetroApiException(MetroErrorKind.format, detail: 'empty body');
      final d = _parse(body, StationDetail.fromJson);
      _details[stationUid] = d;
      return d;
    });
  }

  void dispose() => _api.close();
}
