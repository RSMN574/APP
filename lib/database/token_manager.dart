import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  final _storage = const FlutterSecureStorage();

  String? _token;
  DateTime? _expireTime;

  /// 🔹 伺服器 URL & API Key
  static const _apiUrl = "http://hidden.rsmn574.com:3920/tokens";
  static const _apiKey = "PgRQhSulFPbmnccET+l8ykLC1s2k8IAvpAb3NFFwIXA=";

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
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "X-Timestamp": now,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? '';

        // 假設有效期為 1 小時
        final expireTime = DateTime.now().add(const Duration(hours: 1));

        // 儲存到記憶體與安全儲存
        _token = token;
        _expireTime = expireTime;

        await _storage.write(key: "server_token", value: token);
        await _storage.write(key: "token_expire", value: expireTime.toIso8601String());

        print("✅ Token 更新成功");
        return token;
      } else {
        print("❌ 更新 Token 失敗: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ 無法更新 Token: $e");
    }
    return null;
  }

  /// ⏰ 啟動自動刷新（例如每 55 分鐘）
  void startAutoRefresh() {
    Future.delayed(const Duration(minutes: 55), () async {
      await refreshToken();
      startAutoRefresh(); // 再次排程
    });
  }
}
