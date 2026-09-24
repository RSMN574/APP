import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../database/token_manager.dart';

class LocationService {
  /// 獲取目前經緯度（優先讀取快取，設定 8 秒逾時）
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // 1. 優先試取最後已知位置（提升體驗與速度）
    Position? lastPos = await Geolocator.getLastKnownPosition();
    if (lastPos != null) return lastPos;

    // 2. 獲取實時定位，加入逾時保護
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // 公車/捷運情境 Medium 即可，更省電快速
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// 根據經緯度向 TDX 查詢行政區資訊
  static Future<Map<String, String>?> getDistrictFromTDX({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await TokenManager().getToken();
      if (token == null) return null;

      final url = Uri.parse(
        "https://tdx.transportdata.tw/api/advanced/V3/Map/GeoLocating/District/LocationX/$longitude/LocationY/$latitude?\$format=JSON",
      );

      final response = await http.get(
        url,
        headers: {
          "accept": "application/json",
          "authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final item = data[0];
          return {
            "city": item["City"] ?? "",
            "district": item["District"] ?? "",
          };
        }
      }
    } catch (e) {
      // 可加上 Logging 記錄錯誤
    }
    return null;
  }
}