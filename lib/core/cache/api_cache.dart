import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'cached_entry.dart';

/// 全專案共用快取介面
abstract class ApiCache {
  Future<CachedEntry?> read(String key);

  Future<void> write(String key, CachedEntry entry);

  Future<void> delete(String key);

  Future<void> clear();
}

/// 正式環境：使用 JSON 檔案儲存快取
class FileApiCache implements ApiCache {
  Directory? _directory;

  static const String _folderName = 'api_cache';

  /// 取得快取資料夾
  Future<Directory> get _dir async {
    if (_directory != null) return _directory!;

    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(
      '${supportDir.path}${Platform.pathSeparator}$_folderName',
    );

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _directory = dir;
    return dir;
  }

  /// 將 Cache Key 轉換為安全檔名
  String _safeKey(String key) {
    final bytes = utf8.encode(key);
    final encoded = base64Url.encode(bytes).replaceAll('=', '');
    return encoded;
  }

  Future<File> _file(String key) async {
    final dir = await _dir;
    final filename = '${_safeKey(key)}.json';

    return File(
      '${dir.path}${Platform.pathSeparator}$filename',
    );
  }

  @override
  Future<CachedEntry?> read(String key) async {
    try {
      final file = await _file(key);

      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is! Map || data['body'] is! String) {
        return null;
      }

      return CachedEntry(
        body: data['body'] as String,
        etag: data['etag'] as String?,
        cachedAt: data['cachedAt'] != null
            ? DateTime.tryParse(data['cachedAt'] as String)
            : null,
      );
    } catch (_) {
      // 快取讀取失敗視為 Cache Miss
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedEntry entry) async {
    try {
      final file = await _file(key);

      final data = {
        'body': entry.body,
        'etag': entry.etag,
        'cachedAt': (entry.cachedAt ?? DateTime.now()).toIso8601String(),
      };

      await file.writeAsString(
        jsonEncode(data),
        flush: true,
      );
    } catch (_) {
      // 快取寫入失敗不影響主要流程
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final file = await _file(key);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _dir;

      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      _directory = null;
    } catch (_) {}
  }
}

/// 測試環境：使用記憶體儲存快取
class MemoryApiCache implements ApiCache {
  final Map<String, CachedEntry> _cache = {};

  @override
  Future<CachedEntry?> read(String key) async {
    return _cache[key];
  }

  @override
  Future<void> write(String key, CachedEntry entry) async {
    _cache[key] = entry;
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }
}