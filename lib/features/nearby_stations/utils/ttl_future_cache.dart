import 'dart:collection';

/// 具 TTL 與 LRU 上限的 Future 快取。
///
/// - 同 key 的並行請求共用同一個 Future（請求合併）。
/// - TTL 內重複呼叫回傳同一個 Future 物件，`FutureBuilder` 不會因重建而重置。
/// - 失敗的請求不會被快取，下次呼叫會重新請求。
class TtlFutureCache<T> {
  TtlFutureCache({required this.ttl, this.maxEntries = 20});

  final Duration ttl;
  final int maxEntries;
  final LinkedHashMap<String, _Entry<T>> _entries = LinkedHashMap();

  Future<T> get(
    String key,
    Future<T> Function() loader, {
    bool force = false,
  }) {
    final now = DateTime.now();
    final existing = _entries[key];
    if (!force && existing != null && existing.expiresAt.isAfter(now)) {
      // 最近使用的移到最後（LRU）。
      _entries.remove(key);
      _entries[key] = existing;
      return existing.future;
    }

    Future<T> future;
    try {
      future = loader();
    } catch (e, s) {
      return Future<T>.error(e, s);
    }

    final entry = _Entry<T>(future, now.add(ttl));
    _entries.remove(key);
    _entries[key] = entry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_entries[key], entry)) _entries.remove(key);
    });
    return future;
  }

  void remove(String key) => _entries.remove(key);

  void clear() => _entries.clear();
}

class _Entry<T> {
  _Entry(this.future, this.expiresAt);
  final Future<T> future;
  final DateTime expiresAt;
}
