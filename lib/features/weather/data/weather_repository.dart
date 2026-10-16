import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:com.rsmn574.app/config/app_config.dart';

import 'package:com.rsmn574.app/models/weather_data.dart';

Future<WeatherInfo?> fetchWeather(String cityName) async {
  const String apiKey = AppConfig.weatherApiKey;
  // 以「今明三十六小時天氣預報」為例
  final url = Uri.parse(
      'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001?Authorization=$apiKey&locationName=$cityName');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['records']['location'][0];
      final elements = location['weatherElement'];

      // 取得天氣現象、降雨機率、氣溫
      String wx = elements[0]['time'][0]['parameter']['parameterName']; // Wx
      String pop = elements[1]['time'][0]['parameter']['parameterName']; // PoP
      String minT =
          elements[2]['time'][0]['parameter']['parameterName']; // MinT
      String maxT =
          elements[4]['time'][0]['parameter']['parameterName']; // MaxT

      return WeatherInfo(
        description: wx,
        pop: pop,
        icon: _getWeatherIcon(wx),
        minT: '$minT°',
        maxT: ' $maxT°',
        comfort: '',
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

/// Decoded CWA responses; a field is null when its request failed.
class WeatherRawData {
  const WeatherRawData({this.forecast, this.warnings, this.earthquakes});

  final Map<String, dynamic>? forecast;
  final Map<String, dynamic>? warnings;
  final Map<String, dynamic>? earthquakes;
}

class WeatherRepository {
  const WeatherRepository();

  static const String _base = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore';

  Future<WeatherRawData> fetchRaw(String cityName) async {
    const apiKey = AppConfig.weatherApiKey;
    final results = await Future.wait([
      _get('$_base/F-C0032-001?Authorization=$apiKey&locationName=$cityName',
          'forecast'),
      _get('$_base/W-C0033-001?Authorization=$apiKey', 'warnings'),
      _get('$_base/E-A0015-001?Authorization=$apiKey', 'earthquakes'),
    ]);
    return WeatherRawData(
      forecast: results[0],
      warnings: results[1],
      earthquakes: results[2],
    );
  }

  Future<Map<String, dynamic>?> _get(String url, String source) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('$source API returned HTTP ${response.statusCode}');
        return null;
      }
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (error) {
      debugPrint('$source API request failed: $error');
      return null;
    }
  }
}
