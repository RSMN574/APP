import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final _storage = const FlutterSecureStorage();

  String? _token;
  DateTime? _expireTime;
  Future<String?>? _refreshFuture;
  Timer? _autoRefreshTimer;

  /// 🔹 伺服器 URL & API Key

  /// 🔹 取得目前 Token（自動檢查是否過期）
  Future<String?> getToken() async {
    if (_token != null && _expireTime != null) {
      if (DateTime.now().isBefore(_expireTime!)) {
        return _token; // Token 還有效
      }
    }

    // 嘗試從儲存中讀取
    final savedToken = await _storage.read(key: "server_token");
    final savedExpire = await _storage.read(key: "token_expire");

    if (savedToken != null && savedExpire != null) {
      final expireTime = DateTime.tryParse(savedExpire);
      if (expireTime != null && DateTime.now().isBefore(expireTime)) {
        _token = savedToken;
        _expireTime = expireTime;
        return _token;
      }
    }

    // 否則重新取得
    return await refreshToken();
  }

  /// 🔄 手動刷新 Token（例如過期或 1 小時自動更新）
  Future<String?> refreshToken() async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _refreshToken();
    _refreshFuture = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    }
  }

  Future<String?> _refreshToken() async {
    try {
      AppConfig.requireTokenServiceConfig();
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await http.post(
        Uri.parse(AppConfig.tokenServiceUrl),
        headers: {
          "Authorization": "Bearer ${AppConfig.tokenServiceApiKey}",
          "X-Timestamp": now,
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']?.toString() ?? '';
        if (token.isEmpty) {
          throw const FormatException('Token response did not contain a token');
        }

        // 假設有效期為 1 小時
        final expireTime = DateTime.now().add(const Duration(hours: 1));

        // 儲存到記憶體與安全儲存
        _token = token;
        _expireTime = expireTime;

        await _storage.write(key: "server_token", value: token);
        await _storage.write(
            key: "token_expire", value: expireTime.toIso8601String());

        return token;
      } else {
        throw HttpException(
          'Token service rejected the request: ${response.statusCode}',
        );
      }
    } catch (_) {
      rethrow;
    }
  }

  /// ⏰ 啟動自動刷新（例如每 55 分鐘）
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 55), (_) {
      unawaited(refreshToken());
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
}
