import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../l10n/app_localizations.dart';
import '../models/WeatherData.dart';

// --- 資料模型 ---

// --- 主元件 ---
class WeatherAlertCard extends StatefulWidget {
  final String cityName;

  const WeatherAlertCard({super.key, required this.cityName});

  @override
  State<WeatherAlertCard> createState() => _WeatherAlertCardState();
}

class _WeatherAlertCardState extends State<WeatherAlertCard> {
  bool _isExpanded = false;
  late Future<ComprehensiveWeatherData> _weatherDataFuture;

  @override
  void initState() {
    super.initState();
    _weatherDataFuture = fetchAllData();
  }

  String _formatCityName(String name) {
    String formatted = name
        .replaceAll(AppLocalizations.of(context)!.text_88, AppLocalizations.of(context)!.text_936)
        .replaceAll(AppLocalizations.of(context)!.text_85, AppLocalizations.of(context)!.text_937)
        .replaceAll(AppLocalizations.of(context)!.text_89, AppLocalizations.of(context)!.text_938)
        .replaceAll(AppLocalizations.of(context)!.text_77, AppLocalizations.of(context)!.text_939);
    if (!formatted.contains(AppLocalizations.of(context)!.text_940) && !formatted.contains(AppLocalizations.of(context)!.text_941)) {
      if (formatted == AppLocalizations.of(context)!.text_936) formatted = AppLocalizations.of(context)!.text_6;
    }
    return formatted;
  }

  IconData _getWeatherIcon(String wx) {
    if (wx.contains(AppLocalizations.of(context)!.text_111)) return Icons.wb_sunny_rounded;
    if (wx.contains(AppLocalizations.of(context)!.text_112)) return Icons.umbrella_rounded;
    if (wx.contains(AppLocalizations.of(context)!.text_113)) return Icons.cloud_rounded;
    if (wx.contains(AppLocalizations.of(context)!.text_942)) return Icons.cloud_queue_rounded;
    return Icons.wb_cloudy_rounded;
  }

  Color _getAlertColor(String title) {
    if (title.contains(AppLocalizations.of(context)!.text_943) || title.contains(AppLocalizations.of(context)!.text_944) || title.contains(AppLocalizations.of(context)!.text_945)) return const Color(0xFFFF3B30);
    if (title.contains(AppLocalizations.of(context)!.text_946) || title.contains(AppLocalizations.of(context)!.text_947) || title.contains(AppLocalizations.of(context)!.text_948)) return const Color(0xFFFF9500);
    return const Color(0xFFFFCC00);
  }

  Future<ComprehensiveWeatherData> fetchAllData() async {
    const String apiKey = 'CWA-5150C3FB-47F0-4156-8441-02FDEFC90A22';
    final formattedCity = _formatCityName(widget.cityName);

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

      // A. 解析一般天氣
      if (responses[0].statusCode == 200) {
        final data = json.decode(responses[0].body);
        final loc = data['records']?['location'] ?? [];
        if (loc.isNotEmpty) {
          final ele = loc[0]['weatherElement'];
          weatherInfo = WeatherInfo(
            description: ele[0]['time'][0]['parameter']['parameterName'],
            pop: ele[1]['time'][0]['parameter']['parameterName'],
            minT: ele[2]['time'][0]['parameter']['parameterName'],
            comfort: ele[3]['time'][0]['parameter']['parameterName'],
            maxT: ele[4]['time'][0]['parameter']['parameterName'],
            icon: _getWeatherIcon(ele[0]['time'][0]['parameter']['parameterName']),
          );
        }
      }

      // B. 解析警特報
      if (responses[1].statusCode == 200) {
        final data = json.decode(responses[1].body);
        final records = data['records']?['record'] as List<dynamic>? ?? [];

        for (var r in records) {
          String content = r['contents']?['content']?['contentText'] ?? "";
          if (content.contains(formattedCity) || r['datasetInfo']?['datasetDescription'] == AppLocalizations.of(context)!.text_949) {
            alerts.add(AlertInfo(
              title: r['datasetInfo']?['datasetDescription'] ?? AppLocalizations.of(context)!.text_950,
              description: content,
              color: _getAlertColor(r['datasetInfo']?['datasetDescription'] ?? ""),
              icon: Icons.warning_rounded,
            ));
          }
        }
      }

      // C. 解析地震 (新增時間判斷與數量限制)
      if (responses[2].statusCode == 200) {
        final data = json.decode(responses[2].body);
        final eqList = data['records']?['Earthquake'] as List<dynamic>? ?? [];

        final DateTime now = DateTime.now(); // 取得現在時間
        int eqCount = 0; // 用來計算已經加入了幾筆

        for (var eq in eqList) {
          if (eqCount >= 2) break; // 如果已經拿到 2 筆，就停止迴圈

          final eqInfo = eq['EarthquakeInfo'];
          if (eqInfo != null) {
            final String? originTimeStr = eqInfo['OriginTime']; // "2026-04-05 05:23:59"
            if (originTimeStr != null) {
              try {
                // 將字串轉為 DateTime 物件
                final DateTime originTime = DateTime.parse(originTimeStr);

                // 計算地震發生時間與現在時間相差的天數
                final int diffDays = now.difference(originTime).inDays;

                // 只有小於 7 天 (1星期內) 才顯示
                if (diffDays < 7) {
                  final reportContent = eq['ReportContent'] ?? "";
                  final location = eqInfo['Epicenter']?['Location'] ?? AppLocalizations.of(context)!.text_321;
                  final magnitude = eqInfo['EarthquakeMagnitude']?['MagnitudeValue'] ?? AppLocalizations.of(context)!.text_321;

                  alerts.add(AlertInfo(
                    title: "顯著有感地震報告 (規模 $magnitude)",
                    description: "發生時間: $originTimeStr\n位置: $location\n\n$reportContent",
                    color: const Color(0xFFFF3B30),
                    icon: Icons.sensors_rounded,
                  ));

                  eqCount++; // 成功加入一筆，計數器 +1
                }
              } catch (e) {
                debugPrint(AppLocalizations.of(context)!.text_951);
              }
            }
          }
        }
      }

      return ComprehensiveWeatherData(weather: weatherInfo, alerts: alerts);
    } catch (e) {
      debugPrint('API Error Detail: $e');
      return ComprehensiveWeatherData(alerts: []);
    }
  }

  void _showAlertDetails(BuildContext context, AlertInfo alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(alert.icon, color: alert.color),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title, style: TextStyle(color: alert.color, fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            alert.description.isEmpty ? AppLocalizations.of(context)!.text_952 : alert.description,
            style: const TextStyle(height: 1.5, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.text_44, style: const TextStyle(color: Color(0xFF1A73E8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ComprehensiveWeatherData>(
      future: _weatherDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        if (!snapshot.hasData || (snapshot.data!.weather == null && snapshot.data!.alerts.isEmpty)) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.alerts.isNotEmpty)
                ...data.alerts.map((alert) => _buildAlertItem(context, alert)),
              if (data.weather != null) _buildExpandableWeatherCard(data.weather!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertInfo alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: alert.color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAlertDetails(context, alert),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: alert.color, width: 4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(alert.icon, color: alert.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(color: alert.color, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                         Text(AppLocalizations.of(context)!.text_953, style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableWeatherCard(WeatherInfo weather) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(weather.icon, color: const Color(0xFF1A73E8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${weather.minT}° - ${weather.maxT}°',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(4)),
                                child: Text(weather.description, style: const TextStyle(fontSize: 11, color: Color(0xFF1A73E8))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(widget.cityName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF1A73E8)),
                            Text('${weather.pop}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE1E8F5)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(Icons.thermostat_rounded, AppLocalizations.of(context)!.text_954, "${weather.minT}°C"),
                          _buildDetailItem(Icons.sunny_snowing, AppLocalizations.of(context)!.text_955, "${weather.maxT}°C"),
                          _buildDetailItem(Icons.accessibility_new_rounded, AppLocalizations.of(context)!.text_956, weather.comfort),
                        ],
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
      ],
    );
  }
}