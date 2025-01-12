import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../Const/regularClass.dart';


Future<String?> getLocation(BuildContext context) async {
  // 请求定位权限
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('定位服務未啟用');
    return '定位服務未啟用';
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('定位权限被拒绝');
      return '定位权限被拒绝';
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('定位权限被永久拒绝');
    return '定位权限被永久拒绝';
  }

  // 获取当前位置
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
Provider.of<LocationProvider>(context, listen: false).setLocation(position.latitude, position.longitude);

  Map<String, String>  placemark = await getCountryAndCity( position.latitude, position.longitude);

  if (placemark.isNotEmpty) {

print(placemark );
    if (placemark["country"] == "臺灣") {
      // 优先返回 subAdministrativeArea（市或县），如果没有，则返回 administrativeArea（省或州）



// 使用 cityMap 替换城市名称
      for (var key in cityMap.keys) {
        if (placemark["city"]!.startsWith(key)) {
          print('原始城市名稱: ${placemark["city"]}');
          placemark["city"] = cityMap[key]!;
          print('替換後的城市名稱: ${cityMap[key]}');
          break; // 找到匹配後直接跳出循環
        }
      }

      // 更新 CityProvider 的城市状态
      Provider.of<CityProvider>(context, listen: false).setCity( placemark["city"]!);

      return placemark["city"];
    } else {
      print('非臺灣地區');
      return '非臺灣地區';
    }
  } else {
    print('無法取得城市');
    return '無法取得城市';
  }
}



Future<Map<String, String>> getCountryAndCity(double latitude, double longitude) async {
  String url =
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&addressdetails=1&accept-language=zh-TW';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String country = data['address']['country'] ?? 'Unable to retrieve country';
      String city = data['address']['city'] ??
          data['address']['town'] ??
          data['address']['village'] ??
          data['address']['state_district'] ?? 'Unable to retrieve city';

      return {'country': country, 'city': city};
    } else {
      return {'error': 'Request failed'};
    }
  } catch (e) {
    return {'error': 'Error: $e'};
  }
}
