import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CachedEntry {
  const CachedEntry({required this.body, this.etag});
  final String body;
  final String? etag;
}

abstract class MetroCache {
  Future<CachedEntry?> read(String key);
  Future<void> write(String key, CachedEntry entry);
}

/// 把後端回傳的 JSON 原文連同 ETag 存成檔案。資料量小（目錄約 80 KB、Shape 約 190 KB），不需要 SQLite。
/// 更新策略：每次載入都帶 If-None-Match 向後端驗證，版本沒變回 304，直接沿用本機資料。
/// 任何讀寫失敗都視為「沒有快取」，不影響主流程。
class FileMetroCache implements MetroCache {
  Directory? _dir;

  Future<File> _file(String key) async {
    _dir ??= await getApplicationSupportDirectory();
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return File('${_dir!.path}${Platform.pathSeparator}metro_v2_$safe.json');
  }

  @override
  Future<CachedEntry?> read(String key) async {
    try {
      final f = await _file(key);
      if (!await f.exists()) return null;
      final m = jsonDecode(await f.readAsString());
      if (m is Map && m['body'] is String) {
        return CachedEntry(body: m['body'] as String, etag: m['etag'] as String?);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> write(String key, CachedEntry entry) async {
    try {
      final f = await _file(key);
      await f.writeAsString(jsonEncode({'etag': entry.etag, 'body': entry.body}), flush: true);
    } catch (_) {}
  }
}

/// 測試用。
class MemoryMetroCache implements MetroCache {
  final Map<String, CachedEntry> _m = {};
  @override
  Future<CachedEntry?> read(String key) async => _m[key];
  @override
  Future<void> write(String key, CachedEntry entry) async => _m[key] = entry;
}
