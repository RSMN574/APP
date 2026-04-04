import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/WeatherData.dart';

// --- 資料模型 ---


// --- 主元件 ---
class WeatherAlertCard extends StatelessWidget {
  final String cityName;

  const WeatherAlertCard({super.key, required this.cityName});

  // 格式化城市名稱 (API 需要「臺」)
  String _formatCityName(String name) {
    String formatted = name.replaceAll('台中', '臺中').replaceAll('台北', '臺北').replaceAll('台南', '臺南').replaceAll('台東', '臺東');
    if (!formatted.contains('市') && !formatted.contains('縣')) {
      // 簡單處理，若無市/縣則補上市 (實務上建議根據外部傳入正確名稱)
      if (formatted == "臺中") formatted = "臺中市";
    }
    return formatted;
  }

  // 取得天氣圖示
  IconData _getWeatherIcon(String wx) {
    if (wx.contains('晴')) return Icons.wb_sunny_rounded;
    if (wx.contains('雨')) return Icons.umbrella_rounded;
    if (wx.contains('雲')) return Icons.cloud_rounded;
    return Icons.wb_cloudy_rounded;
  }

  // 警報顏色邏輯
  Color _getAlertColor(String title) {
    if (title.contains('地震') || title.contains('海嘯') || title.contains('豪雨')) return Colors.red;
    if (title.contains('大雨') || title.contains('強風') || title.contains('低溫')) return Colors.orange;
    return Colors.amber;
  }

  Future<ComprehensiveWeatherData> fetchAllData() async {
    const String apiKey = 'CWA-5150C3FB-47F0-4156-8441-02FDEFC90A22';
    final formattedCity = _formatCityName(cityName);

    final weatherUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001?Authorization=$apiKey&locationName=$formattedCity';
    final warningUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/W-C0033-001?Authorization=$apiKey';
    final earthquakeUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/E-A0015-001?Authorization=$apiKey';

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(weatherUrl)),
        http.get(Uri.parse(warningUrl)),
        http.get(Uri.parse(earthquakeUrl)),
      ]);

      WeatherInfo? weatherInfo;
      List<AlertInfo> alerts = [];

      // --- A. 解析一般天氣 (加入空值檢查) ---
      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        final loc = data['records']?['location'] ?? []; // 使用 ? 和 ?? []
        if (loc.isNotEmpty) {
          final ele = loc[0]['weatherElement'];
          weatherInfo = WeatherInfo(
            description: ele[0]['time'][0]['parameter']['parameterName'],
            pop: ele[1]['time'][0]['parameter']['parameterName'],
            temperature: "${ele[2]['time'][0]['parameter']['parameterName']}°-${ele[4]['time'][0]['parameter']['parameterName']}°",
            icon: _getWeatherIcon(ele[0]['time'][0]['parameter']['parameterName']),
          );
        }
      }

      // --- B. 解析警特報 (關鍵修正點：避免 Iterable 錯誤) ---
      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        // 確保 records 內的 record 不是 null 才能跑迴圈
        final records = data['records']?['record'] as List<dynamic>? ?? [];

        for (var r in records) {
          String content = r['contents']?['content']?['contentText'] ?? "";
          if (content.contains(formattedCity)) {
            alerts.add(AlertInfo(
              title: r['datasetInfo']?['datasetDescription'] ?? "天氣警報",
              description: content,
              color: _getAlertColor(r['datasetInfo']?['datasetDescription'] ?? ""),
              icon: Icons.warning_rounded,
            ));
          }
        }
      }

      // --- C. 解析地震 (關鍵修正點) ---
      if (responses[2].statusCode == 200) {
        final data = json.decode(responses[2].body);
        final eqList = data['records']?['Earthquake'] as List<dynamic>? ?? [];

        if (eqList.isNotEmpty) {
          final latestEq = eqList[0]['EarthquakeInfo'];
          if (latestEq != null) {
            alerts.add(AlertInfo(
              title: "最近地震報告",
              description: "位置: ${latestEq['EarthquakeLocation']}, 規模: ${latestEq['EarthquakeMagnitude']?['MagnitudeValue'] ?? '未知'}",
              color: Colors.redAccent,
              icon: Icons.sensors_rounded,
            ));
          }
        }
      }

      return ComprehensiveWeatherData(weather: weatherInfo, alerts: alerts);
    } catch (e) {
      // 這裡會抓到之前的 Null 錯誤，現在修正後就不會進來了
      debugPrint('API Error Detail: $e');
      return ComprehensiveWeatherData(alerts: []);
    }
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ComprehensiveWeatherData>(
      future: fetchAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        if (!snapshot.hasData || (snapshot.data!.weather == null && snapshot.data!.alerts.isEmpty)) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // 1. 警特報列表 (有資料才顯示)
              if (data.alerts.isNotEmpty)
                ...data.alerts.map((alert) => _buildAlertItem(alert)),

              // 2. 一般天氣卡片
              if (data.weather != null) _buildWeatherCard(data.weather!),
            ],
          ),
        );
      },
    );
  }

  // 警報 UI
  Widget _buildAlertItem(AlertInfo alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: alert.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(alert.icon, color: alert.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.title,
              style: TextStyle(color: alert.color, fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  // 一般天氣 UI
  Widget _buildWeatherCard(WeatherInfo weather) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8F5)),
      ),
      child: Row(
        children: [
          Icon(weather.icon, color: const Color(0xFF1A73E8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.description}  ${weather.temperature}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(cityName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.water_drop, size: 14, color: Color(0xFF1A73E8)),
              Text(' ${weather.pop}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
            ],
          ),
        ],
      ),
    );
  }
}