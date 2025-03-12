import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  /// 儲存 API 金鑰
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: 'api_key', value: apiKey);
  }

  /// 讀取 API 金鑰
  static Future<String?> getApiKey() async {
    return await _storage.read(key: 'api_key');
  }

  /// 刪除 API 金鑰
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: 'api_key');
  }

  /// 檢查是否為首次啟動，若是則儲存 API 金鑰
  static Future<void> initializeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await saveApiKey('PgRQhSulFPbmnccET+l8ykLC1s2k8IAvpAb3NFFwIXA=');
      await prefs.setBool('isFirstLaunch', false); // 記錄已初始化
    }
  }
}
