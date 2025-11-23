import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../Const/regularClass.dart';
import '../database/token_manager.dart';
import '../utils/convert.dart';

Future<Map<String, String>?> getDistrictFromTDX({
  required double latitude,
  required double longitude,
}) async {
  final token = await TokenManager().getToken();
  if (token == null) return null;

  final url = Uri.parse(
      "https://tdx.transportdata.tw/api/advanced/V3/Map/GeoLocating/District/LocationX/$longitude/LocationY/$latitude?\$format=JSON");

  final response = await http.get(
    url,
    headers: {
      "accept": "application/json",
      "authorization": "Bearer $token",
    },
  );

  if (response.statusCode != 200) {
    return null;
  }

  final data = jsonDecode(response.body);

  if (data is List && data.isNotEmpty) {
    final item = data[0];

    return {
      "city": item["City"] ?? "",
      "district": item["District"] ?? "",
    };
  }

  return null;
}

Future<String?> getLocation(BuildContext context) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return '定位服務未啟用';

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return '定位权限被拒绝';
  }
  if (permission == LocationPermission.deniedForever) {
    return '定位权限被永久拒绝';
  }

  Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  Provider.of<LocationProvider>(context, listen: false)
      .setLocation(pos.latitude, pos.longitude);

  // 使用 TDX 查縣市
  final districtInfo = await getDistrictFromTDX(
    latitude: pos.latitude,
    longitude: pos.longitude,
  );

  if (districtInfo == null) return '無法取得城市';

  String city = cityNameConverter(districtInfo["city"] ?? "");



   Provider.of<CityProvider>(context, listen: false).setCity(city);
  return city;
}


