import 'package:flutter/cupertino.dart';

class ComprehensiveWeatherData {
  final WeatherInfo? weather;
  final List<AlertInfo> alerts;
  final String? errorMessage;

  ComprehensiveWeatherData({
    this.weather,
    required this.alerts,
    this.errorMessage,
  });
}

class WeatherInfo {
  final String description;
  final String minT;
  final String maxT;
  final String pop;
  final String comfort; // 舒適度指數 (CI)
  final IconData icon;

  WeatherInfo({
    required this.description,
    required this.minT,
    required this.maxT,
    required this.pop,
    required this.comfort,
    required this.icon,
  });
}

class AlertInfo {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  AlertInfo({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}
