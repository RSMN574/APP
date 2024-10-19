import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../Const/regularClass.dart';
import '../database/getWeather.dart';
import 'package:provider/provider.dart';

class WeatherWidget extends StatefulWidget {
  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  // 默认选中的城市
  String selectedCity = '臺中市';

  // 城市列表
  final List<String> cityList = [
    '宜蘭縣', '花蓮縣', '臺東縣', '澎湖縣', '金門縣', '連江縣', '臺北市',
    '新北市', '桃園市', '臺中市', '臺南市', '高雄市', '基隆市', '新竹縣',
    '新竹市', '苗栗縣', '彰化縣', '南投縣', '雲林縣', '嘉義縣', '嘉義市', '屏東縣'
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getWeatherInfo(context), // 确保返回的是一个Future
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            margin: EdgeInsets.all(12),
            child: Text(
              '获取天气信息失败: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          var info = snapshot.data!;

          return Container(
            margin: EdgeInsets.all(12),
            width: double.infinity,
            height: 120,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: selectedCity,
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 24,
                      elevation: 16,
                      style: TextStyle(
                        color: Color(0xFF1A2440),
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCity = newValue!;
                          // 更新 CityProvider 的城市状态
                          Provider.of<CityProvider>(context, listen: false).setCity(selectedCity);
                          // 重新获取天气信息
                          getWeatherInfo(context); // 重新获取天气信息
                        });
                      },
                      items: cityList.map<DropdownMenuItem<String>>((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city, style: TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          info["recentMinTemp"],
                          style: TextStyle(color: Color(0xFF545B70), fontSize: 16),
                        ),
                        SizedBox(width: 4),
                        Text('/', style: TextStyle(color: Color(0xFF545B70), fontSize: 16)),
                        SizedBox(width: 4),
                        Text(
                          info["recentMaxTemp"],
                          style: TextStyle(color: Color(0xFF545B70), fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 根据天气状态动态选择图标
                    Icon(
                      _getWeatherIcon(info["recentWeatherStatus"]),
                      size: 32,
                      color: Color(0xFF545B70),
                    ),
                    SizedBox(height: 4),
                    Text(
                      info["recentWeatherStatus"],
                      style: TextStyle(color: Color(0xFF545B70), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          margin: EdgeInsets.only(top: 12),
          child: Text('天气信息不可用', style: TextStyle(color: Colors.grey)),
        );
      },
    );
  }

  // 根据天气状态返回相应的图标
  IconData _getWeatherIcon(String weatherStatus) {
    if (weatherStatus.contains('晴')) {
      return Icons.wb_sunny; // 晴天图标
    } else if (weatherStatus.contains == '阴天') {
      return Icons.cloud; // 阴天图标
    } else if (weatherStatus == '下雨') {
      return Icons.beach_access; // 下雨图标
    } else {
      return Icons.wb_sunny; // 默认图标
    }
  }
}
