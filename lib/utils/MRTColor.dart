import 'package:flutter/material.dart';

mixin MRTColor {
  // 台北捷運
  static const Color taipeiRed = Color(0xFFE3002C); // 淡水信義線
  static const Color taipeiGreen = Color(0xFF008659); // 松山新店線
  static const Color taipeiBlue = Color(0xFF0070BD); // 板南線
  static const Color taipeiOrange = Color(0xFFF8B61C); // 中和新蘆線
  static const Color taipeiBrown = Color(0xFF8C4C2F); // 文湖線
  static const Color taipeiYellow = Color(0xFFF5D400); // 環狀線

  // 高雄捷運
  static const Color kaohsiungRed = Color(0xFFEA1D25); // 紅線
  static const Color kaohsiungOrange = Color(0xFFF8971D); // 橘線

  // 台中捷運
  static const Color taichungGreen = Color(0xFF86B338); // 綠線

  // 桃園捷運
  static const Color taoyuanPurple = Color(0xFF8E44AD); // 桃園機場捷運

  // 新北捷運
  static const Color newTaipeiGold = Color(0xFFF4A300); // 三鶯線（示例）

  // 靜態方法：根據捷運線名稱獲取顏色
  static Color? getColorByLineName(String lineName) {
    switch (lineName) {
      case '淡水信義線':
        return taipeiRed;
      case '松山新店線':
        return taipeiGreen;
      case '板南線':
        return taipeiBlue;
      case '中和新蘆線':
        return taipeiOrange;
      case '文湖線':
        return taipeiBrown;
      case '環狀線':
        return taipeiYellow;
      case '紅線':
        return kaohsiungRed;
      case '橘線':
        return kaohsiungOrange;
      case '烏日文心北屯線':
        return taichungGreen;
      case '桃園機場捷運':
        return taoyuanPurple;
      case '三鶯線':
        return newTaipeiGold;
      default:
        return null; // 如果沒有對應的顏色
    }
  }
}
