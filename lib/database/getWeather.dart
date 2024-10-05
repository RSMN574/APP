import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';
import '../widget/geolocator.dart';

Future<Map<String, dynamic>> getWeatherInfo(context) async {
  String currentCity = Provider
      .of<CityProvider>(context, listen: false)
      .city;
  print(currentCity);

  // API URL
  final url = Uri.parse(
      'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001?Authorization=CWA-5150C3FB-47F0-4156-8441-02FDEFC90A22&locationName=$currentCity&sort=time');

  // 发起 GET 请求
  final response = await http.get(url, headers: {'accept': 'application/json'});

  // 检查响应状态
  if (response.statusCode == 200) {
    // 解析 JSON 数据
    Map<String, dynamic> weatherData = json.decode(response.body);


    // 获取最近的天气状态和温度
    var locations = weatherData['records']['location'];
    if (locations.isNotEmpty) {
      var weatherElement = locations[0]['weatherElement'];

      print(
          weatherData["records"]["location"][0]["weatherElement"][0]["time"][0]["parameter"]["parameterName"]);
      // 创建变量来存储最近的天气状态和温度
      String? recentWeatherStatus=  weatherData["records"]["location"][0]["weatherElement"][0]["time"][0]["parameter"]["parameterName"];
      String? recentMinTemp=  weatherData["records"]["location"][0]["weatherElement"][2]["time"][0]["parameter"]["parameterName"];
      String? recentMaxTemp=  weatherData["records"]["location"][0]["weatherElement"][4]["time"][0]["parameter"]["parameterName"];
   String? unit=weatherData["records"]["location"][0]["weatherElement"][4]["time"][0]["parameter"]["parameterUnit"]=="C"? '\u00B0C' :'\u00B0F';
      // 获取当前时间
      DateTime now = DateTime.now();
      DateTime? closestStartTime;
      DateTime? closestEndTime;
      bool foundCurrentPeriod = false;


      // 提取天气状态和温度信息
      // for (var element in weatherElement) {
      //   for (var time in element['time']) {
      //     DateTime startTime = DateTime.parse(time['startTime']);
      //     DateTime endTime = DateTime.parse(time['endTime']);
      //
      //     // 打印每个时间段以调试
      //     print('时间段: ${time['startTime']} 到 ${time['endTime']}');

      // 检查是否在当前时间范围内
      // if (now.isAfter(startTime) && now.isBefore(endTime)) {
      //   foundCurrentPeriod = true; // 标记找到当前时间段
      //   if (element['elementName'] == "Wx") {
      //     recentWeatherStatus = time['parameter']['parameterName'];
      //   } else if (element['elementName'] == "MinT") {
      //     recentMinTemp = '${time['parameter']['parameterName']} ${time['parameter']['parameterUnit']}';
      //   } else if (element['elementName'] == "MaxT") {
      //     recentMaxTemp = '${time['parameter']['parameterName']} ${time['parameter']['parameterUnit']}';
      //   }
      // } else {
      //   print(element);
      //   // 如果没有找到当前时间段的信息，记录最近的时间段
      //   if (closestStartTime == null || startTime.isAfter(closestStartTime)) {
      //     closestStartTime = startTime;
      //     closestEndTime = endTime;
      //     if (element['elementName'] == "Wx") {
      //
      //       recentWeatherStatus = time['parameter']['parameterName'];
      //     } else if (element['elementName'] == "MinT") {
      //       recentMinTemp = '${time['parameter']['parameterName']} ${time['parameter']['parameterUnit']}';
      //     } else if (element['elementName'] == "MaxT") {
      //       recentMaxTemp = '${time['parameter']['parameterName']} ${time['parameter']['parameterUnit']}';
      //       print(recentMaxTemp);
      //     }
      //
      //   }
      // }

      return {
        "city": currentCity,
        "recentWeatherStatus": recentWeatherStatus ?? "N/A",
        "recentMinTemp": recentMinTemp!+unit ?? "N/A",
        "recentMaxTemp": recentMaxTemp!+unit ?? "N/A"
      };
    }

  }else{
    return{
      "city": currentCity,
      "recentWeatherStatus":  "N/A",
      "recentMinTemp":  "N/A",
      "recentMaxTemp":  "N/A"

    };
  }
  return{
    "city": currentCity,
    "recentWeatherStatus":  "N/A",
    "recentMinTemp":  "N/A",
    "recentMaxTemp":  "N/A"

  };

}