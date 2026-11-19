import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../city/taiwan_city.dart';

/// 中文縣市名稱 ↔ 英文名稱轉換（相容舊呼叫端）。
///
/// - 輸入中文（臺中市／台中市）→ 回傳 TDX City 代碼（`Taichung`、`HsinchuCounty`）
/// - 輸入英文或 TDX 代碼（含 `HsinchuCounty`、`Hsinchu County`）→ 回傳中文名稱
/// - 無法辨識時回傳 `Unknown city`（保留既有行為讓呼叫端判斷）
///
/// 統一使用 [TaiwanCity] 目錄，修正 QA B04/B05：先前縣（County）與含空白的
/// 英文名稱無法互轉，導致 GPS 定位與 YouBike 查詢失敗。
String cityNameConverter(String inputCity) {
  final city = TaiwanCity.tryParse(inputCity);
  if (city == null) return "Unknown city";
  final trimmed = inputCity.trim();
  final isChinese = RegExp(r'[一-鿿]').hasMatch(trimmed);
  return isChinese ? city.tdxCode : city.zhName;
}
double calculateCornerRadius(BuildContext context,{double percentage = 0.02, double min = 4.0, double max = 16.0}) {
  // 獲取螢幕寬度
  final screenWidth = MediaQuery.of(context).size.width;

  // 計算圓角半徑，根據螢幕寬度的百分比
  double cornerRadius = screenWidth * percentage;

  // 限制圓角半徑的最小和最大值
  return cornerRadius.clamp(min, max);
}
String convertTrainType(String trainType) {
  // 定義火車車種對應表（使用關鍵字匹配）
  Map<String, String> trainTypeMapping = {
    "EMU3000": "新自強",
    "普悠瑪": "普悠瑪",
    "太魯閣": "太魯閣",
    "莒光": "莒光號",
    "區間快": "區間快",
    "區間": "區間車",
    "普快":"普快",
    "復興":"復興",
    "柴聯": "柴聯自強",
    "自強": "自強號",
  };

  // 遍歷對應表，檢查是否包含關鍵字
  for (var key in trainTypeMapping.keys) {
    if (trainType.contains(key)) {
      return trainTypeMapping[key]!;
    }
  }

  // 如果找不到則回傳原值
  return trainType;
}


/// 計算兩個座標之間的近似距離（單位：公尺）
double calculateApproxDistance(double lat1, double lon1, double lat2, double lon2) {
  const double meterPerDegree = 111000; // 1° 緯度 ≈ 111,000 公尺
  double latDiff = (lat2 - lat1) * meterPerDegree;
  double lonDiff = (lon2 - lon1) * meterPerDegree * cos(lat1 * pi / 180);
  return sqrt(latDiff * latDiff + lonDiff * lonDiff);
}
String getChineseName(String? name) {
  if (name == null) return '';
  // 移除 () 或 （） 內的文字（含括號）
  return name.replaceAll(RegExp(r'[\(（][^()（）]*[\)）]'), '');
}
List<LatLng> parseGeoJsonLine(Map<String, dynamic> geoJson) {
  List<LatLng> points = [];

  if (geoJson["geometry"]?["type"] == "MultiLineString") {
    List coords = geoJson["geometry"]["coordinates"];

    for (var line in coords) {
      for (var pair in line) {
        double lng = pair[0]; // GeoJSON → Lng
        double lat = pair[1]; // GeoJSON → Lat
        points.add(LatLng(lat, lng));
      }
    }
  }

  return points;
}
List<LatLng> decodePolyline(String encoded) {
  final List<LatLng> points = [];
  int index = 0, lat = 0, lng = 0;

  while (index < encoded.length) {
    int shift = 0, result = 0;
    int b;

    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;

    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);

    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

/// TDX / AuthorityID 城市代碼（City id → code）。
const Map<String, String> kCityAuthorityCodes = {
  'taipei': 'TPE',
  'newtaipei': 'NWT',
  'taoyuan': 'TAO',
  'taichung': 'TXG',
  'tainan': 'TNN',
  'kaohsiung': 'KHH',
  'keelung': 'KEE',
  'hsinchu': 'HSZ',
  'hsinchucity': 'HSZ',
  'miaoli': 'MIA',
  'changhua': 'CHA',
  'nantou': 'NAN',
  'yunlin': 'YUN',
  'chiayi': 'CYI',
  'chiayicity': 'CYI',
  'pingtung': 'PIF',
  'yilan': 'ILA',
  'hualien': 'HUA',
  'taitung': 'TTT',
  'penghu': 'PEN',
  'kinmen': 'KIN',
  'lienchiang': 'LIE',
};

/// AuthorityID / CityCode → 專案使用的英文 City id。
const Map<String, String> kCityCodeToEnglishId = {
  'TPE': 'Taipei',
  'NWT': 'NewTaipei',
  'TAO': 'Taoyuan',
  'TXG': 'Taichung',
  'TNN': 'Tainan',
  'KHH': 'Kaohsiung',
  'KEE': 'Keelung',
  'HSZ': 'Hsinchu',
  'MIA': 'Miaoli',
  'CHA': 'Changhua',
  'NAN': 'Nantou',
  'YUN': 'Yunlin',
  'CYI': 'Chiayi',
  'PIF': 'Pingtung',
  'ILA': 'Yilan',
  'HUA': 'Hualien',
  'TTT': 'Taitung',
  'PEN': 'Penghu',
  'KIN': 'Kinmen',
  'LIE': 'Lienchiang',
};

String convertCityCode(String city) {
  final trimmed = city.trim();
  if (trimmed.isEmpty) return trimmed;
  final upper = trimmed.toUpperCase();
  if (kCityCodeToEnglishId.containsKey(upper)) return upper;
  final known = kCityAuthorityCodes[trimmed.toLowerCase()];
  if (known != null) return known;
  // 中文名、TDX 代碼（HsinchuCounty）、含空白英文名（New Taipei）。
  return TaiwanCity.tryParse(trimmed)?.authorityCode ?? upper;
}

/// 依目前城市（City id 或 AuthorityID）顯示名稱。
String localizedCityName(String city, {required bool isEnglish}) {
  final trimmed = city.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed == 'all') return isEnglish ? 'All' : '全部';
  if (trimmed == 'InterCity') return isEnglish ? 'InterCity' : '公路客運';

  final code = convertCityCode(trimmed);
  final englishId = kCityCodeToEnglishId[code] ?? trimmed;
  if (isEnglish) return englishId;

  final spaced = englishId.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
  final zh = cityNameConverter(englishId);
  if (zh != 'Unknown city') return zh;
  final zhSpaced = cityNameConverter(spaced);
  return zhSpaced == 'Unknown city' ? englishId : zhSpaced;
}