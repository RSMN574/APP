import 'dart:math';

import 'package:flutter/material.dart';

String cityNameConverter(String inputCity) {
  // 全台灣縣市對應表
  Map<String, String> cityMapping = {
    // 英文 → 中文
    "Taipei": "臺北市",
    "New Taipei": "新北市",
    "Taichung": "臺中市",
    "Tainan": "臺南市",
    "Kaohsiung": "高雄市",
    "Keelung": "基隆市",
    "Hsinchu City": "新竹市",
    "Hsinchu County": "新竹縣",
    "Miaoli": "苗栗縣",
    "Changhua": "彰化縣",
    "Nantou": "南投縣",
    "Yunlin": "雲林縣",
    "Chiayi City": "嘉義市",
    "Chiayi County": "嘉義縣",
    "Pingtung": "屏東縣",
    "Yilan": "宜蘭縣",
    "Hualien": "花蓮縣",
    "Taitung": "臺東縣",
    "Penghu": "澎湖縣",
    "Kinmen": "金門縣",
    "Lienchiang": "連江縣",
    // 中文 → 英文
    "臺北市": "Taipei",
    "新北市": "New Taipei",
    "臺中市": "Taichung",
    "臺南市": "Tainan",
    "高雄市": "Kaohsiung",
    "基隆市": "Keelung",
    "新竹市": "Hsinchu City",
    "新竹縣": "Hsinchu County",
    "苗栗縣": "Miaoli",
    "彰化縣": "Changhua",
    "南投縣": "Nantou",
    "雲林縣": "Yunlin",
    "嘉義市": "Chiayi City",
    "嘉義縣": "Chiayi County",
    "屏東縣": "Pingtung",
    "宜蘭縣": "Yilan",
    "花蓮縣": "Hualien",
    "臺東縣": "Taitung",
    "澎湖縣": "Penghu",
    "金門縣": "Kinmen",
    "連江縣": "Lienchiang",
  };

  // 查找并返回对应的城市名称
  return cityMapping[inputCity] ?? "Unknown city";
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

double calculateEuclideanDistance(double lat1, double lon1, double lat2, double lon2) {
  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;
  return sqrt(dLat * dLat + dLon * dLon); // 直接計算歐幾里得距離
}
