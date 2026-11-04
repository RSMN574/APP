class CachedEntry {
  const CachedEntry({
    required this.body,
    this.etag,
    this.cachedAt,
  });

  /// Server 回傳的 JSON 原文
  final String body;

  /// HTTP ETag
  final String? etag;

  /// 快取儲存時間
  final DateTime? cachedAt;

  /// 建立新的快取時間
  CachedEntry copyWith({
    String? body,
    String? etag,
    DateTime? cachedAt,
  }) {
    return CachedEntry(
      body: body ?? this.body,
      etag: etag ?? this.etag,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}