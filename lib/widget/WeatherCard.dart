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

  // ==================== 通知中心主題色 ====================
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceColor = Color(0xFFEEF3FB);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);

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
    if (title.contains(AppLocalizations.of(context)!.text_943) ||
        title.contains(AppLocalizations.of(context)!.text_944) ||
        title.contains(AppLocalizations.of(context)!.text_945)) return errorRed;
    if (title.contains(AppLocalizations.of(context)!.text_946) ||
        title.contains(AppLocalizations.of(context)!.text_947) ||
        title.contains(AppLocalizations.of(context)!.text_948)) return warningOrange;
    return const Color(0xFFFFCC00);
  }

  IconData _getAlertIcon(String title) {
    if (title.contains(AppLocalizations.of(context)!.text_943) ||
        title.contains(AppLocalizations.of(context)!.text_944) ||
        title.contains(AppLocalizations.of(context)!.text_945)) return Icons.warning_amber_rounded;
    if (title.contains(AppLocalizations.of(context)!.text_946) ||
        title.contains(AppLocalizations.of(context)!.text_947) ||
        title.contains(AppLocalizations.of(context)!.text_948)) return Icons.umbrella_rounded;
    return Icons.info_outline_rounded;
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
              icon: _getAlertIcon(r['datasetInfo']?['datasetDescription'] ?? ""),
            ));
          }
        }
      }

      // C. 解析地震
      if (responses[2].statusCode == 200) {
        final data = json.decode(responses[2].body);
        final eqList = data['records']?['Earthquake'] as List<dynamic>? ?? [];

        final DateTime now = DateTime.now();
        int eqCount = 0;

        for (var eq in eqList) {
          if (eqCount >= 2) break;

          final eqInfo = eq['EarthquakeInfo'];
          if (eqInfo != null) {
            final String? originTimeStr = eqInfo['OriginTime'];
            if (originTimeStr != null) {
              try {
                final DateTime originTime = DateTime.parse(originTimeStr);
                final int diffDays = now.difference(originTime).inDays;

                if (diffDays < 7) {
                  final reportContent = eq['ReportContent'] ?? "";
                  final location = eqInfo['Epicenter']?['Location'] ?? AppLocalizations.of(context)!.text_321;
                  final magnitude = eqInfo['EarthquakeMagnitude']?['MagnitudeValue'] ?? AppLocalizations.of(context)!.text_321;

                  alerts.add(AlertInfo(
                    title: "顯著有感地震報告 (規模 $magnitude)",
                    description: "發生時間: $originTimeStr\n位置: $location\n\n$reportContent",
                    color: errorRed,
                    icon: Icons.sensors_rounded,
                  ));

                  eqCount++;
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
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alert.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(alert.icon, color: alert.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: TextStyle(
                        color: alert.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    alert.description.isEmpty ? AppLocalizations.of(context)!.text_952 : alert.description,
                    style: const TextStyle(
                      height: 1.6,
                      fontSize: 14,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [primaryBlue, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ComprehensiveWeatherData>(
      future: _weatherDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '載入天氣資訊中...',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  // ==================== 預警項目 ====================
  Widget _buildAlertItem(BuildContext context, AlertInfo alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAlertDetails(context, alert),
          splashColor: alert.color.withOpacity(0.1),
          highlightColor: alert.color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [alert.color, alert.color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    alert.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: alert.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: alert.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.text_953,
                              style: TextStyle(
                                fontSize: 10,
                                color: alert.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 天氣卡片 ====================
  Widget _buildExpandableWeatherCard(WeatherInfo weather) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          splashColor: primaryBlue.withOpacity(0.1),
          highlightColor: primaryBlue.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryBlue, primaryBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        weather.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${weather.minT}° - ${weather.maxT}°',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  weather.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cityName,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                size: 14,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${weather.pop}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: primaryBlue,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: textSecondary,
                          ),
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
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          height: 1,
                          color: surfaceColor,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(
                            Icons.thermostat_rounded,
                            AppLocalizations.of(context)!.text_954,
                            "${weather.minT}°C",
                            primaryBlue,
                          ),
                          _buildDetailItem(
                            Icons.sunny_snowing,
                            AppLocalizations.of(context)!.text_955,
                            "${weather.maxT}°C",
                            warningOrange,
                          ),
                          _buildDetailItem(
                            Icons.accessibility_new_rounded,
                            AppLocalizations.of(context)!.text_956,
                            weather.comfort,
                            successGreen,
                          ),
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

  // ==================== 詳細項目 ====================
  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}