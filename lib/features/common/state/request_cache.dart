/// Short-lived cache that also shares an in-flight request between callers,
/// so rebuilding a page does not trigger duplicate API calls.
class RequestCache {
  RequestCache({this.ttl = const Duration(seconds: 60)});

  final Duration ttl;
  final Map<String, _CacheEntry> _entries = {};

  Future<T> get<T>(
    String key,
    Future<T> Function() loader, {
    bool force = false,
  }) {
    final entry = _entries[key];
    if (!force &&
        entry != null &&
        DateTime.now().difference(entry.createdAt) < ttl) {
      return entry.future as Future<T>;
    }

    final future = loader();
    final created = _CacheEntry(future);
    _entries[key] = created;
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
