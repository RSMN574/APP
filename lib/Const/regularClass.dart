import 'package:flutter/cupertino.dart';


class CityProvider with ChangeNotifier {
  String _city = '臺北市';  // 默认城市

  String get city => _city;

  void setCity(String newCity) {
    _city = newCity;
    notifyListeners(); // 通知监听者状态已更新
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