import 'package:com.rsmn574.app/core/cache/api_cache.dart';
import 'package:com.rsmn574.app/core/cache/cached_entry.dart';
import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/metro/data/metro_cache.dart' as metro;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestCache', () {
    test('shares in-flight requests and respects TTL', () async {
      final cache = RequestCache(ttl: const Duration(minutes: 1));
      var calls = 0;
      Future<int> load() async => ++calls;
      final a = cache.get('k', load);
      final b = cache.get('k', load);
      expect(await a, 1);
      expect(await b, 1);
      expect(calls, 1);
      await cache.get('k', load, force: true);
      expect(calls, 2);
    });

    test('evicts the least recently used entry beyond maxEntries', () async {
      final cache = RequestCache(maxEntries: 2);
      var calls = 0;
      Future<int> load() async => ++calls;
      await cache.get('a', load);
      await cache.get('b', load);
      await cache.get('a', load); // a 變成最近使用
      await cache.get('c', load); // 淘汰 b
      expect(cache.length, 2);
      final before = calls;
      await cache.get('a', load);
      expect(calls, before, reason: 'a 仍在快取中');
      await cache.get('b', load);
      expect(calls, before + 1, reason: 'b 已被淘汰需重新載入');
    });

    test('failed requests are not cached', () async {
      final cache = RequestCache();
      var calls = 0;
      Future<int> fail() async {
        calls++;
        throw StateError('x');
      }

      await expectLater(cache.get('k', fail), throwsStateError);
      await expectLater(cache.get('k', fail), throwsStateError);
      expect(calls, 2);
    });
  });

  test('metro cache uses the shared ApiCache and CachedEntry types', () async {
    final metro.MetroCache cache = metro.MemoryMetroCache();
    expect(cache, isA<ApiCache>());
    await cache.write('catalog', const CachedEntry(body: '{}', etag: 'W/"1"'));
    final read = await cache.read('catalog');
    expect(read!.etag, 'W/"1"');
    expect(read.body, '{}');
  });
}
