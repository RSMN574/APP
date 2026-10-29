import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:com.rsmn574.app/config/app_config.dart';

import 'package:com.rsmn574.app/features/weather/state/weather_provider.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/models/weather_data.dart';

import '../../../const/app_colors.dart';

class WeatherAlertCard extends StatefulWidget {
  final String cityName;
  @visibleForTesting
  final Future<ComprehensiveWeatherData> Function(String cityName)?
  loadWeatherData;

  const WeatherAlertCard({
    super.key,
    required this.cityName,
    this.loadWeatherData,
  });

  @override
  State<WeatherAlertCard> createState() => _WeatherAlertCardState();
}

class _WeatherAlertCardState extends State<WeatherAlertCard> {
  bool _isExpanded = false;
  late Future<ComprehensiveWeatherData> _weatherDataFuture;

  bool _hasInitializedWeatherData = false;
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (!_hasInitializedWeatherData || locale != _lastLocale) {
      _hasInitializedWeatherData = true;
      _lastLocale = locale;
      _weatherDataFuture = _loadWeatherData();
    }
  }

  @override
  void didUpdateWidget(covariant WeatherAlertCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityName != widget.cityName) {
      _weatherDataFuture = _loadWeatherData();
    }
  }

  Future<ComprehensiveWeatherData> _loadWeatherData() =>
      widget.loadWeatherData?.call(widget.cityName) ?? fetchAllData();

  // ==================== 城市名稱正規化 ====================

  /// 將「台/臺」等異體字統一，方便比對。
  String _normalizeCity(String name) {
    return name
        .replaceAll('台', '臺')
        .replaceAll('台北', '臺北')
        .replaceAll('台中', '臺中')
        .replaceAll('台南', '臺南')
        .replaceAll('台東', '臺東')
        .trim();
  }

  String _formatCityName(String name, AppLocalizations localizations) {
    // 先做異體字統一，再用 l10n key 做語言相關替換。
    var formatted = _normalizeCity(name);
    formatted = formatted
        .replaceAll(localizations.text_88, localizations.text_936)
        .replaceAll(localizations.text_85, localizations.text_937)
        .replaceAll(localizations.text_89, localizations.text_938)
        .replaceAll(localizations.text_77, localizations.text_939);
    if (!formatted.contains(localizations.text_940) &&
        !formatted.contains(localizations.text_941)) {
      if (formatted == localizations.text_936) {
        formatted = localizations.text_6;
      }
    }
    return formatted;
  }

  // ==================== 圖示 / 顏色 ====================

  IconData _getWeatherIcon(String wx, AppLocalizations localizations) {
    if (wx.contains(localizations.text_111)) {
      return Icons.wb_sunny_rounded;
    }
    if (wx.contains(localizations.text_112)) {
      return Icons.umbrella_rounded;
    }
    if (wx.contains(localizations.text_113)) {
      return Icons.cloud_rounded;
    }
    if (wx.contains(localizations.text_942)) {
      return Icons.cloud_queue_rounded;
    }
    return Icons.wb_cloudy_rounded;
  }

  Color _getAlertColor(
      String title, AppLocalizations localizations, AppColors colors) {
    if (title.contains(localizations.text_943) ||
        title.contains(localizations.text_944) ||
        title.contains(localizations.text_945)) {
      return colors.danger;
    }
    if (title.contains(localizations.text_946) ||
        title.contains(localizations.text_947) ||
        title.contains(localizations.text_948)) {
      return colors.warning;
    }
    return colors.warning;
  }

  IconData _getAlertIcon(String title, AppLocalizations localizations) {
    if (title.contains(localizations.text_943) ||
        title.contains(localizations.text_944) ||
        title.contains(localizations.text_945)) {
      return Icons.warning_amber_rounded;
    }
    if (title.contains(localizations.text_946) ||
        title.contains(localizations.text_947) ||
        title.contains(localizations.text_948)) {
      return Icons.umbrella_rounded;
    }
    return Icons.info_outline_rounded;
  }

  // ==================== 資料取得 ====================

  Future<ComprehensiveWeatherData> fetchAllData() async {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    const String apiKey = AppConfig.weatherApiKey;

    if (apiKey.isEmpty) {
      return ComprehensiveWeatherData(
        alerts: const [],
        errorMessage: '天氣服務尚未設定 API 金鑰（WEATHER_API_KEY）。',
      );
    }

    final formattedCity = _formatCityName(widget.cityName, localizations);

    if (kDebugMode) {
      debugPrint('WeatherAlertCard: city=${widget.cityName} '
          'formatted=$formattedCity '
          'locale=${Localizations.localeOf(context)}');
    }

    try {
      final raw = await context.read<WeatherProvider>().rawFor(formattedCity);

      if (kDebugMode) {
        debugPrint('WeatherAlertCard: forecastNull=${raw.forecast == null} '
            'warningsNull=${raw.warnings == null} '
            'earthquakesNull=${raw.earthquakes == null}');
      }

      WeatherInfo? weatherInfo;
      final List<AlertInfo> alerts = [];

      // A. 一般天氣（用 elementName 取值，避免欄位順序/缺少導致 null）
      final forecast = raw.forecast;
      if (forecast != null) {
        final records = forecast['records'];
        final loc = records is Map ? records['location'] as List<dynamic>? : null;
        if (loc != null && loc.isNotEmpty) {
          // 優先找 locationName 與 formattedCity 相符的；否則用第一筆。
          Map<String, dynamic>? target;
          for (final item in loc) {
            if (item is Map &&
                _normalizeCity(item['locationName']?.toString() ?? '') ==
                    _normalizeCity(formattedCity)) {
              target = Map<String, dynamic>.from(item);
              break;
            }
          }
          target ??= loc.first is Map
              ? Map<String, dynamic>.from(loc.first as Map)
              : null;

          if (target != null) {
            final ele =
                target['weatherElement'] as List<dynamic>? ?? const [];

            String readElement(String name) {
              for (final e in ele) {
                if (e is Map && e['elementName'] == name) {
                  final times = e['time'];
                  if (times is List && times.isNotEmpty) {
                    final parameter = times[0]['parameter'];
                    if (parameter is Map) {
                      return parameter['parameterName']?.toString() ?? '';
                    }
                  }
                }
              }
              return '';
            }

            final wx = readElement('Wx');
            weatherInfo = WeatherInfo(
              description: wx,
              pop: readElement('PoP'),
              minT: readElement('MinT'),
              comfort: readElement('CI'),
              maxT: readElement('MaxT'),
              icon: _getWeatherIcon(wx, localizations),
            );
          }
        }
      }

      // B. 警特報
      final warningData = raw.warnings;
      if (warningData != null) {
        final records =
            warningData['records']?['record'] as List<dynamic>? ?? [];
        for (final r in records) {
          if (r is! Map) continue;
          final content = r['contents']?['content']?['contentText'] ?? '';
          final desc = r['datasetInfo']?['datasetDescription'] ?? '';
          if (content.toString().contains(formattedCity) ||
              desc == localizations.text_949) {
            alerts.add(AlertInfo(
              title: desc.isNotEmpty ? desc : localizations.text_950,
              description: content.toString(),
              color: _getAlertColor(desc, localizations, colors),
              icon: _getAlertIcon(desc, localizations),
            ));
          }
        }
      }

      // C. 地震（只保留「今天」）
      final earthquakeData = raw.earthquakes;
      if (earthquakeData != null) {
        final eqList =
            earthquakeData['records']?['Earthquake'] as List<dynamic>? ?? [];
        final now = DateTime.now();
        int eqCount = 0;

        for (final eq in eqList) {
          if (eqCount >= 2) break;
          if (eq is! Map) continue;
          final eqInfo = eq['EarthquakeInfo'];
          if (eqInfo is! Map) continue;
          final originTimeStr = eqInfo['OriginTime']?.toString();
          if (originTimeStr == null || originTimeStr.isEmpty) continue;

          try {
            final originTime = DateTime.parse(originTimeStr);
            final bool isToday = originTime.year == now.year &&
                originTime.month == now.month &&
                originTime.day == now.day;
            if (!isToday) continue;

            final reportContent = eq['ReportContent']?.toString() ?? '';
            final location =
                eqInfo['Epicenter']?['Location'] ?? localizations.text_321;
            final magnitude =
                eqInfo['EarthquakeMagnitude']?['MagnitudeValue'] ??
                    localizations.text_321;

            alerts.add(AlertInfo(
              title: '顯著有感地震報告 (規模 $magnitude)',
              description:
              '發生時間: $originTimeStr\n位置: $location\n\n$reportContent',
              color: colors.danger,
              icon: Icons.sensors_rounded,
            ));
            eqCount++;
          } catch (e) {
            debugPrint(localizations.text_951);
          }
        }
      }

      return ComprehensiveWeatherData(
        weather: weatherInfo,
        alerts: alerts,
        errorMessage: null,
      );
    } catch (e, s) {
      debugPrint('WeatherAlertCard API Error: $e\n$s');
      return ComprehensiveWeatherData(
        alerts: const [],
        errorMessage: '目前無法取得天氣資訊，請稍後重試。',
      );
    }
  }

  // ==================== 詳情 Dialog ====================

  void _showAlertDetails(BuildContext context, AlertInfo alert) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colors.cardBackground,
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
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    alert.description.isEmpty
                        ? AppLocalizations.of(context)!.text_952
                        : alert.description,
                    style: TextStyle(
                      height: 1.6,
                      fontSize: 14,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: colors.info,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: colors.cardBackground.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: TextStyle(
                            color: colors.cardBackground,
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

  // ==================== build ====================

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colors.info,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '載入天氣資訊中...',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return _buildUnavailableCard(
            context,
            '目前無法取得天氣資訊，請稍後重試。',
          );
        }

        final data = snapshot.data!;
        if (data.weather == null && data.alerts.isEmpty) {
          return _buildUnavailableCard(
            context,
            data.errorMessage ?? '目前無法取得天氣資訊，請稍後重試。',
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.alerts.isNotEmpty)
                ...data.alerts.map((alert) => _buildAlertItem(context, alert)),
              if (data.weather != null)
                _buildExpandableWeatherCard(context, data.weather!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUnavailableCard(BuildContext context, String message) {
    final colors = context.appColors;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _weatherDataFuture = _loadWeatherData();
                });
              },
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertInfo alert) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: alert.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(alert.icon, color: alert.color, size: 20),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableWeatherCard(
      BuildContext context, WeatherInfo weather) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
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
          splashColor: colors.info.withOpacity(0.1),
          highlightColor: colors.info.withOpacity(0.05),
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
                        color: colors.infoContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        weather.icon,
                        color: colors.info,
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
                              Flexible(
                                child: Text(
                                  '${weather.minT}° - ${weather.maxT}°',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  weather.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.info,
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
                              color: colors.textSecondary,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.water_drop_rounded,
                                size: 14,
                                color: colors.info,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${weather.pop}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colors.info,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.mutedBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: colors.textSecondary,
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
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          height: 1,
                          color: colors.divider,
                        ),
                      ),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(
                            context,
                            Icons.thermostat_rounded,
                            AppLocalizations.of(context)!.text_954,
                            '${weather.minT}°C',
                            colors.info,
                          ),
                          _buildDetailItem(
                            context,
                            Icons.sunny_snowing,
                            AppLocalizations.of(context)!.text_955,
                            '${weather.maxT}°C',
                            colors.warning,
                          ),
                          _buildDetailItem(
                            context,
                            Icons.accessibility_new_rounded,
                            AppLocalizations.of(context)!.text_956,
                            weather.comfort,
                            colors.success,
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

  Widget _buildDetailItem(BuildContext context, IconData icon, String label,
      String value, Color color) {
    final colors = context.appColors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}