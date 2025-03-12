import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider with ChangeNotifier {
  double _latitude = 0.0;
  double _longitude = 0.0;

  double get latitude => _latitude;
  double get longitude => _longitude;

  void setLocation(double latitude, double longitude) {
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }
}
class CityProvider with ChangeNotifier {
  String _city = '臺北市';  // 默认城市
  String get city => _city;

  void setCity(String newCity) {
    _city = newCity;
    notifyListeners(); // 通知监听者状态已更新
  }

}
// class WeatherProvider with ChangeNotifier {
//   String _city = '臺北市';  // 默认
//
//   String get city => _city;
//
//   void setCity(String newCity) {
//     _city = newCity;
//     notifyListeners(); // 通知监听者状态已更新
//   }
// }
class youbike  {
  final String name;
  final LatLng latLng;

  youbike(this.name, this.latLng);

  @override
  LatLng get location => latLng;
}

class MarkerProvider extends ChangeNotifier {
  Set<Marker> _markers = {};
  List<youbike> _items = []; // ClusterManager 需要的是這個

  Set<Marker> get markers => _markers;
  List<youbike> get items => _items;

  void setMarkers(Set<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }

  void setItems(List<youbike> items) {
    _items = items;
    notifyListeners();
  }
}

Map<String, String> cityMap = {
  '宜蘭': '宜蘭縣',
  '花蓮': '花蓮縣',
  '台東': '臺東縣',
  '澎湖': '澎湖縣',
  '金門': '金門縣',
  '連江': '連江縣',
  '台北': '臺北市',
  '新北': '新北市',
  '桃園': '桃園市',
  '台中': '臺中市',
  '台南': '臺南市',
  '高雄': '高雄市',
  '基隆': '基隆市',
  '新竹縣': '新竹縣',
  '新竹市': '新竹市',
  '苗栗': '苗栗縣',
  '彰化': '彰化縣',
  '南投': '南投縣',
  '雲林': '雲林縣',
  '嘉義縣': '嘉義縣',
  '嘉義市': '嘉義市',
  '屏東': '屏東縣',
};