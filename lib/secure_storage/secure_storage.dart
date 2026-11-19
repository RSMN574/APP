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

  /// 清除舊版寫入的 API 金鑰（QA A2）。
  ///
  /// 舊版在首次啟動時把一組寫死在原始碼中的金鑰存入 SecureStorage，
  /// 但程式從未讀取。新版移除該金鑰，並在已安裝的裝置上清掉殘留值。
  static Future<void> purgeLegacyApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_legacyFirstLaunchKey)) return;
    await deleteApiKey();
    await prefs.remove(_legacyFirstLaunchKey);
  }

  static const _legacyFirstLaunchKey = 'isFirstLaunch';
}
