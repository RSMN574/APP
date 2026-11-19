/// Short-lived cache that also shares an in-flight request between callers,
/// so rebuilding a page does not trigger duplicate API calls.
///
/// QA C7：加上筆數上限（預設 100），超過時淘汰最久未使用的項目，
/// 避免長時間使用（例如反覆切換大量站牌）時記憶體持續成長。
class RequestCache {
  RequestCache({this.ttl = const Duration(seconds: 60), this.maxEntries = 100})
      : assert(maxEntries > 0);

  final Duration ttl;
  final int maxEntries;

  /// LinkedHashMap 依插入順序；命中時重新插入即成為「最近使用」。
  final Map<String, _CacheEntry> _entries = {};

  int get length => _entries.length;

  Future<T> get<T>(
    String key,
    Future<T> Function() loader, {
    bool force = false,
  }) {
    final entry = _entries[key];
    if (!force &&
        entry != null &&
        DateTime.now().difference(entry.createdAt) < ttl) {
      _entries
        ..remove(key)
        ..[key] = entry;
      return entry.future as Future<T>;
    }

    final future = loader();
    final created = _CacheEntry(future);
    _entries
      ..remove(key)
      ..[key] = created;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_entries[key], created)) _entries.remove(key);
    });
    return future;
  }

  void invalidate([String? key]) {
    if (key == null) {
      _entries.clear();
    } else {
      _entries.remove(key);
    }
  }
}

class _CacheEntry {
  _CacheEntry(this.future) : createdAt = DateTime.now();

  final Future<dynamic> future;
  final DateTime createdAt;
}
