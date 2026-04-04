import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/WeatherData.dart';

Future<WeatherInfo?> fetchWeather(String cityName) async {
  const String apiKey = 'CWA-5150C3FB-47F0-4156-8441-02FDEFC90A22';
  // 以「今明三十六小時天氣預報」為例
  final url = Uri.parse(
      'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001?Authorization=$apiKey&locationName=$cityName'
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['records']['location'][0];
      final elements = location['weatherElement'];

      // 取得天氣現象、降雨機率、氣溫
      String wx = elements[0]['time'][0]['parameter']['parameterName']; // Wx
      String pop = elements[1]['time'][0]['parameter']['parameterName']; // PoP
      String minT = elements[2]['time'][0]['parameter']['parameterName']; // MinT
      String maxT = elements[4]['time'][0]['parameter']['parameterName']; // MaxT

      return WeatherInfo(
        description: wx,
        pop: pop,
        temperature: '$minT° - $maxT°',
        icon: _getWeatherIcon(wx),
      );
    }
  } catch (e) {
    print('Weather Error: $e');
  }
  return null;
}

// 根據文字對應圖示
IconData _getWeatherIcon(String wx) {
  if (wx.contains('晴')) return Icons.wb_sunny_rounded;
  if (wx.contains('雨')) return Icons.umbrella_rounded;
  if (wx.contains('雲')) return Icons.cloud_rounded;
  return Icons.wb_cloudy_rounded;
}