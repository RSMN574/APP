import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _city = '臺北市'; // 默认城市
  String get city => _city;

  void setCity(String newCity) {
    _city = newCity;
    notifyListeners(); // 通知监听者状态已更新
  }
}

class AppProvider with ChangeNotifier {
  bool _isDarkTheme = false;
  String _language = 'zh'; // ✅ 改用標準語系代碼作為預設值

  bool get isDarkTheme => _isDarkTheme;
  String get language => _language;

  AppProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('darkTheme') ?? false;
    _language = prefs.getString('language') ?? 'zh'; // ✅ 讀取 'zh' 或 'en'
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Locale get locale =>
      _language == 'en' ? const Locale('en') : const Locale('zh');
}

class CityItem {
  final String name;
  final String id;

  const CityItem({
    required this.name,
    required this.id,
  });
}

class youbike {
  final String name;
  final LatLng latLng;

  youbike(this.name, this.latLng);

  @override
  LatLng get location => latLng;
}

class PolylineProvider extends ChangeNotifier {
  Set<Polyline> _polylines = {};

  // 取得 Polyline
  Set<Polyline> get polylines => _polylines;

  // 設定 Polyline
  void setPolylines(Set<Polyline> polylines) {
    _polylines = polylines;
    notifyListeners();
  }

  // 新增 Polyline
  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
    notifyListeners();
  }

  // 清空 Polyline
  void clearPolylines() {
    _polylines.clear();
    notifyListeners();
  }
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
