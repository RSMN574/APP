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

  // 通过经纬度获取地址信息
  List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude);

  if (placemarks.isNotEmpty) {
    String? administrativeArea = placemarks[0].administrativeArea; // 省、州或区
    String? subAdministrativeArea = placemarks[0].subAdministrativeArea; // 市或县

    if (placemarks[0].country == "台灣") {
      // 优先返回 subAdministrativeArea（市或县），如果没有，则返回 administrativeArea（省或州）
      String taiwanCity = subAdministrativeArea ?? administrativeArea ?? '无法获取城市';

      // 使用 cityMap 替换城市名称
      for (var key in cityMap.keys) {
        if (administrativeArea!.contains(key)) {
          administrativeArea = cityMap[key];
          print(cityMap[key]);
        }
      }

      // 更新 CityProvider 的城市状态
      Provider.of<CityProvider>(context, listen: false).setCity(administrativeArea!);

      return administrativeArea;
    } else {
      print('非台湾地区');
      return '非台湾地区';
    }
  } else {
    print('无法获取城市');
    return '无法获取城市';
  }
}
