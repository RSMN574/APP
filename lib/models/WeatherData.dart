import 'dart:ui';

import 'package:flutter/cupertino.dart';

class ComprehensiveWeatherData {
  final WeatherInfo? weather;
  final List<AlertInfo> alerts;
  ComprehensiveWeatherData({this.weather, required this.alerts});
}

class WeatherInfo {
  final String description;
  final String temperature;
  final String pop;
  final IconData icon;
  WeatherInfo({required this.description, required this.temperature, required this.pop, required this.icon});
}

class AlertInfo {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  AlertInfo({required this.title, required this.description, required this.color, required this.icon});
}