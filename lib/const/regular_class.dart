import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/city/taiwan_city.dart';

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

/// App 唯一的「目前城市」狀態來源。
///
/// - 使用者切換城市時保存到 SharedPreferences（`last_city`）
/// - 啟動時讀取上次城市；第一次使用或保存值無效時回退到預設城市
/// - GPS 偵測只在使用者從未手動選擇城市時套用（[applyDetectedCity]）
/// - 一律保存中文名稱（與既有頁面相容），TDX 代碼請用 [tdxCode]
class CityProvider with ChangeNotifier {
  CityProvider({String? initialCity, bool hasUserSelection = false})
      : _city = TaiwanCity.tryParse(initialCity)?.zhName ??
            TaiwanCity.defaultCity.zhName,
        _hasUserSelection = hasUserSelection;

  static const String prefsKey = 'last_city';

  String _city;
  bool _hasUserSelection;

  String get city => _city;

  /// TDX API 使用的城市代碼（例如 `Taichung`、`HsinchuCounty`）。
  String get tdxCode =>
      (TaiwanCity.tryParse(_city) ?? TaiwanCity.defaultCity).tdxCode;

  /// 使用者是否曾手動選擇過城市。
  bool get hasUserSelection => _hasUserSelection;

  /// 讀取上次城市。保存資料損壞（型別錯誤、未知城市）時安全回退到預設城市，
  /// 並清除損壞值，避免每次啟動都讀到同一筆錯誤資料。
  static Future<CityProvider> load({SharedPreferences? prefs}) async {
    try {
      final store = prefs ?? await SharedPreferences.getInstance();
      final Object? raw = store.get(prefsKey);
      final parsed = raw is String ? TaiwanCity.tryParse(raw) : null;
      if (raw != null && parsed == null) {
        await store.remove(prefsKey);
      }
      return CityProvider(
        initialCity: parsed?.zhName,
        hasUserSelection: parsed != null,
      );
    } catch (_) {
      return CityProvider();
    }
  }

  /// 使用者手動選擇城市：更新狀態並保存。無效城市會被忽略並回傳 false。
  Future<bool> setCity(String newCity) async {
    final parsed = TaiwanCity.tryParse(newCity);
    if (parsed == null) return false;
    final changed = parsed.zhName != _city;
    _city = parsed.zhName;
    _hasUserSelection = true;
    if (changed) notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, parsed.zhName);
    } catch (_) {
      // 保存失敗不影響目前畫面；下次啟動回退到預設城市。
    }
    return true;
  }

  /// GPS 偵測到的城市：只在使用者從未手動選擇過城市時套用，且不保存，
  /// 讓「上次選擇的城市」永遠優先。
  bool applyDetectedCity(String detected) {
    if (_hasUserSelection) return false;
    final parsed = TaiwanCity.tryParse(detected);
    if (parsed == null || parsed.zhName == _city) return false;
    _city = parsed.zhName;
    notifyListeners();
    return true;
  }
}

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode;
  String _language;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkTheme => _themeMode == ThemeMode.dark;
  String get language => _language;

  AppProvider({
    bool isDarkTheme = false,
    ThemeMode? themeMode,
    String language = 'zh',
  })  : _themeMode =
            themeMode ?? (isDarkTheme ? ThemeMode.dark : ThemeMode.light),
        _language = language;

  static Future<AppProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? 'zh';
    final savedThemeMode = prefs.getString('themeMode');
    final themeMode = switch (savedThemeMode) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      _ =>
        prefs.getBool('darkTheme') == true ? ThemeMode.dark : ThemeMode.system,
    };
    return AppProvider(
      themeMode: themeMode,
      language: savedLanguage == 'en' ? 'en' : 'zh',
    );
  }

  Future<void> toggleTheme(bool value) async {
    await setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    await prefs.setBool('darkTheme', mode == ThemeMode.dark);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if (value != 'zh' && value != 'en') {
      throw ArgumentError.value(value, 'value', 'Unsupported language');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    _language = value;
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
