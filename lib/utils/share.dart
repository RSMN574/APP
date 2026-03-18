import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
class StationActions {
  // 1. 撥打電話
  static Future<void> makeCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('無法撥打電話: $phoneNumber');
    }
  }

  // 2. 開啟導航 (Google Maps/Apple Maps)
  static Future<void> openNavigation(double lat, double lng, param2) async {
    // 使用通用格式，這會觸發手機的地圖選擇器
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      // mode: LaunchMode.externalApplication 非常重要，它會強制跳出 App 去開地圖
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw '無法開啟地圖連結：$url';
    }
  }

  // 3. 分享資訊
  static void shareStation(Map station) {
    final String content = '【${station['StationName']}】\n地址：${station['Address']}\n電話：${station['Telephone']}';

    SharePlus.instance.share(
        ShareParams(text: content)
    );
  }
}