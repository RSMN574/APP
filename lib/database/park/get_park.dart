import '../tdx_api_client.dart';
import 'dart:convert';

/// 取得台灣所有動態停車場資訊（市區 + 台鐵車站 + 高鐵車站）
Future<List<dynamic>> fetchParkLiveStatus(String city) async {
  /// 三個 API url
  final urls = [
    // 市區停車場
    "https://tdx.transportdata.tw/api/basic/v1/Parking/OffStreet/ParkingAvailability/City/$city?%24format=JSON",

    // 台鐵車站停車場
    "https://tdx.transportdata.tw/api/basic/v1/Parking/OffStreet/ParkingAvailability/Rail/Station/TRA?%24format=JSON",

    // 高鐵車站停車場
    "https://tdx.transportdata.tw/api/basic/v1/Parking/OffStreet/ParkingAvailability/Rail/Station/THSR?%24format=JSON",
  ];

  final List<dynamic> allData = [];

  for (final url in urls) {
    try {
      final response = await TdxApiClient().getRaw(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        print("❌ API 失敗：$url -> ${response.statusCode}");
        continue;
      }

      final decoded = jsonDecode(response.body);
      final list = decoded["ParkingAvailabilities"] as List<dynamic>?;

      if (list != null) {
        // 加上來源標記
        final withSource = list.map((e) {
          final map = Map<String, dynamic>.from(e);
          map["Source"] = _detectSourceFromURL(url);
          return map;
        }).toList();

        allData.addAll(withSource);
      }
    } catch (e) {
      print("❌ 解析錯誤：$url -> $e");
      continue;
    }
  }

  print("✅ 合併完成，共 ${allData.length} 筆資料");
  return allData;
}

/// 根據 URL 判斷來源：City / TRA / THSR
String _detectSourceFromURL(String url) {
  if (url.contains("/City/")) return "City";
  if (url.contains("/TRA")) return "TRA";
  if (url.contains("/THSR")) return "THSR";
  return "Unknown";
}
