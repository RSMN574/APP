import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/core/cache/api_cache.dart';
import 'package:com.rsmn574.app/core/cache/cached_entry.dart';
import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'package:com.rsmn574.app/features/bus/data/bus_schedule_remote_data_source.dart';
import 'package:com.rsmn574.app/features/bus/data/bus_schedule_repository.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_daily_timetable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _fixture =
    File('test/fixtures/tdx/daily_stop_timetable_taichung_300.json')
        .readAsStringSync();

/// 以 MockClient 驅動真正的 TdxApiClient，覆蓋 URI 與 Token 流程。
class _Harness {
  _Harness();

  final requests = <Uri>[];
  http.Response Function(http.Request) responder =
      (_) => http.Response.bytes(utf8.encode(_fixture), 200);
  Completer<void>? gate;

  TdxApiClient client() => TdxApiClient(
        loadToken: () async => 'test-token',
        refreshToken: () async => 'test-token',
        clientFactory: () => MockClient((request) async {
          requests.add(request.url);
          if (gate != null) await gate!.future;
          return responder(request);
        }),
      );
}

BusScheduleRepository _repo(
  _Harness h, {
  ApiCache? cache,
  DateTime Function()? clock,
}) {
  return BusScheduleRepository(
    remote: BusScheduleRemoteDataSource(
      client: h.client(),
      parser: (body) async => parseBusDailyTimetables(jsonDecode(body)),
    ),
    cache: cache ?? MemoryApiCache(),
    clock: clock,
  );
}

void main() {
  group('BusScheduleRemoteDataSource.buildUri', () {
    test('uses the selected city and route, never hard-coded', () {
      final uri = BusScheduleRemoteDataSource.buildUri(
          city: '桃園市', routeName: '1', routeId: '1');
      expect(uri.path, '/api/basic/v2/Bus/DailyStopTimeTable/City/Taoyuan/1');
      expect(uri.queryParameters[r'$filter'], "RouteID eq '1'");
      expect(uri.queryParameters[r'$format'], 'JSON');
    });

    test('falls back to exact RouteName filter without RouteID', () {
      final uri = BusScheduleRemoteDataSource.buildUri(
          city: 'Kaohsiung', routeName: "紅3'", routeId: '');
      expect(uri.queryParameters[r'$filter'], "RouteName/Zh_tw eq '紅3'''");
    });

    test('rejects cities outside the OAS enum', () {
      expect(BusScheduleRemoteDataSource.isSupported('臺北市'), isFalse);
      expect(BusScheduleRemoteDataSource.isSupported('Taichung'), isTrue);
      expect(
        () => BusScheduleRemoteDataSource.buildUri(
            city: 'Taipei', routeName: '307'),
        throwsA(isA<BusScheduleUnsupportedCityException>()),
      );
    });
  });

  group('BusScheduleRepository', () {
    test('caches by city + route and respects TTL', () async {
      final h = _Harness();
      var now = DateTime(2026, 11, 19, 8);
      final repo = _repo(h, clock: () => now);

      final first =
          await repo.load(city: 'Taichung', routeName: '300', routeId: '300');
      expect(first.fromCache, isFalse);
      final second =
          await repo.load(city: '臺中市', routeName: '300', routeId: '300');
      expect(second.fromCache, isTrue, reason: '中文城市名與代碼共用快取');
      expect(h.requests, hasLength(1));

      now = now.add(const Duration(hours: 7));
      final third =
          await repo.load(city: 'Taichung', routeName: '300', routeId: '300');
      expect(third.fromCache, isFalse);
      expect(h.requests, hasLength(2));
      expect(repo.cacheHits, 1);
    });

    test('deduplicates concurrent requests for the same route', () async {
      final h = _Harness()..gate = Completer<void>();
      final repo = _repo(h);
      final a = repo.load(city: 'Taichung', routeName: '300', routeId: '300');
      final b = repo.load(city: 'Taichung', routeName: '300', routeId: '300');
      await Future<void>.delayed(Duration.zero);
      h.gate!.complete();
      final results = await Future.wait([a, b]);
      expect(h.requests, hasLength(1));
      expect(identical(results[0], results[1]), isTrue);
    });

    test('keeps the last valid timetable when the API fails', () async {
      final h = _Harness();
      final cache = MemoryApiCache();
      var now = DateTime(2026, 11, 19, 8);
      final repo = _repo(h, cache: cache, clock: () => now);
      await repo.load(city: 'Taichung', routeName: '300', routeId: '300');

      h.responder = (_) => throw const SocketException('offline');
      final result = await repo.load(
          city: 'Taichung',
          routeName: '300',
          routeId: '300',
          forceRefresh: true);
      expect(result.isStale, isTrue);
      expect(result.timetables.single.tripCount, 108);
    });

    test('restores from the persistent cache after restart', () async {
      final cache = MemoryApiCache();
      final now = DateTime(2026, 11, 19, 8);
      await _repo(_Harness(), cache: cache, clock: () => now)
          .load(city: 'Taichung', routeName: '300', routeId: '300');

      final h2 = _Harness()
        ..responder = (_) => throw const SocketException('offline');
      final restarted = _repo(h2, cache: cache, clock: () => now);
      final result = await restarted.load(
          city: 'Taichung', routeName: '300', routeId: '300');
      expect(result.fromCache, isTrue);
      expect(h2.requests, isEmpty);
    });

    test('empty response never overwrites a valid cached timetable', () async {
      final h = _Harness();
      final cache = MemoryApiCache();
      final repo = _repo(h, cache: cache);
      await repo.load(city: 'Taichung', routeName: '300', routeId: '300');

      h.responder = (_) => http.Response('[]', 200);
      final result = await repo.load(
          city: 'Taichung',
          routeName: '300',
          routeId: '300',
          forceRefresh: true);
      expect(result.isStale, isTrue);
      expect(result.staleReason, 'empty_response');
      expect(result.timetables, isNotEmpty);
    });

    test('empty response without cache is reported as empty', () async {
      final h = _Harness()..responder = (_) => http.Response('[]', 200);
      final result =
          await _repo(h).load(city: 'Taichung', routeName: '不存在', routeId: 'X');
      expect(result.isEmpty, isTrue);
      expect(result.isStale, isFalse);
    });

    test('API failure without cache propagates the error', () async {
      final h = _Harness()..responder = (_) => http.Response('oops', 500);
      expect(
        _repo(h).load(city: 'Taichung', routeName: '300', routeId: '300'),
        throwsA(isA<HttpException>()),
      );
    });

    test('corrupted persistent cache is treated as a miss', () async {
      final cache = MemoryApiCache();
      final key = BusScheduleRepository.cacheKey(
          city: 'Taichung', routeName: '300', routeId: '300');
      await cache.write(
          key, CachedEntry(body: '{not json', cachedAt: DateTime.now()));
      final h = _Harness();
      final result = await _repo(h, cache: cache)
          .load(city: 'Taichung', routeName: '300', routeId: '300');
      expect(result.fromCache, isFalse);
      expect(h.requests, hasLength(1));
    });

    test('unsupported city fails fast without a network request', () async {
      final h = _Harness();
      expect(
        _repo(h).load(city: '臺北市', routeName: '307'),
        throwsA(isA<BusScheduleUnsupportedCityException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(h.requests, isEmpty);
    });
  });
}
