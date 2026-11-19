import 'package:provider/provider.dart';
import 'package:com.rsmn574.app/features/railway/provider/railway_provider.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:com.rsmn574.app/database/sql/schedule.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/widget/map.dart';
import 'package:com.rsmn574.app/features/railway/widgets/route_planner.dart';

import '../../../const/app_colors.dart';
import '../../../widget/AppLoading.dart';
import '../../../widget/app_custom_bar.dart';

const List<int> E500 = [
  101, 103, 105, 107, 109, 111, 113, 115, 117, 119, 121, 123, 125, 127, 129,
  131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 150, 151, 152,
];

const List<int> EMU3000 = [
  101, 103, 105, 107, 109, 111, 113, 115, 117, 119, 121, 123, 125, 127, 129,
  131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 153, 155, 157, 159,
  161, 163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185, 187, 189,
  191, 193, 195, 197, 199, 201, 203, 205, 207, 209, 211, 213, 215, 217, 219,
  221, 223, 225, 227, 229, 231, 233, 235, 237, 239, 241, 243, 245, 247, 249,
  251, 253, 255, 257, 259, 261, 263, 265, 267, 269, 271, 273, 275, 277, 279,
  281, 283, 285, 287, 289, 291, 293, 295,
];

final List EMU900 = [
  123, 135, 145, 155, 165, 175, 185, 195, 205, 215, 225, 235, 245, 255, 265,
  275, 285, 295,
];

final List TzeChiangLimited = [
  105, 110, 115, 120, 125, 130, 135, 140, 145, 150,
];

late Set<Polyline> allLines;
Map<String, dynamic> trainData = {};

String _localizedRailName(dynamic names, BuildContext context) {
  if (names is! Map) return names?.toString() ?? '';

  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final preferred = names[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;

  return names[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
}

class TrainSchedulePage extends StatefulWidget {
  final String type;
  final DateTime time;
  final int trainNo;

  const TrainSchedulePage({
    Key? key,
    required this.type,
    required this.time,
    required this.trainNo,
  }) : super(key: key);

  @override
  State<TrainSchedulePage> createState() => _TrainSchedulePageState();
}

class _TrainSchedulePageState extends State<TrainSchedulePage> {
  // 靜態主題色仍保留供參考，但實際顏色改由 context.appColors 取得
  static const Color primaryBlue = AppColors.primaryBlue;
  static const Color successGreen = AppColors.successGreen;
  static const Color warningOrange = AppColors.warningOrange;
  static const Color errorRed = AppColors.errorRed;
  static const Color purple = AppColors.purple;

  String? _currentStationId;
  int _liveDelayMinutes = 0;
  DateTime? _liveDataFetchedAt;
  String? _liveDataStatus;
  bool _isFetchingLive = false;

  String? _trainModel;
  String? _trainModelDescription;

  final ScrollController _stopTimesScrollController = ScrollController();
  Timer? _liveBoardTimer;

  @override
  void initState() {
    super.initState();
    _fetchTrain();

    _liveBoardTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) loadLiveBoardIfToday();
    });
  }

  Future<Map<String, dynamic>> _fetchTrain() async {
    trainData = await context.read<RailwayProvider>().traTrain(
      widget.trainNo,
      widget.time,
    );

    if (mounted) {
      setState(() {});
    }
    await loadLiveBoardIfToday();
    _getTrainModel();
    return trainData;
  }

  @override
  void dispose() {
    _liveBoardTimer?.cancel();
    _stopTimesScrollController.dispose();
    super.dispose();
  }

  void _getTrainModel() {
    final trainNo = trainData['DailyTrainInfo']['TrainNo'];
    final cleanTrainNo = int.parse(trainNo.replaceAll(RegExp(r'[^0-9]'), ''));

    setState(() {
      if (E500.contains(cleanTrainNo)) {
        _trainModel = 'E500';
        _trainModelDescription = AppLocalizations.of(context)!.text_649;
      } else if (EMU3000.contains(cleanTrainNo)) {
        _trainModel = 'EMU3000';
        _trainModelDescription = AppLocalizations.of(context)!.text_650;
      } else if (EMU900.contains(cleanTrainNo)) {
        _trainModel = 'EMU900';
        _trainModelDescription = AppLocalizations.of(context)!.text_651;
      } else if (TzeChiangLimited.contains(cleanTrainNo)) {
        _trainModel = AppLocalizations.of(context)!.text_652;
        _trainModelDescription = AppLocalizations.of(context)!.text_653;
      } else {
        _trainModel = null;
        _trainModelDescription = null;
      }
    });
  }

  Map printStartEndDepartureTimes(Map<String, dynamic> _trainData) {
    final dailyInfo = _trainData['DailyTrainInfo'] as Map<String, dynamic>;
    final startZh = dailyInfo['StartingStationName']['Zh_tw'] as String;
    final endZh = dailyInfo['EndingStationName']['Zh_tw'] as String;

    final stops =
    (_trainData['StopTimes'] as List<dynamic>).cast<Map<String, dynamic>>();

    String? findDeparture(String stationZh) {
      final stop = stops.firstWhere(
            (s) => s['StationName']['Zh_tw'] == stationZh,
        orElse: () => <String, dynamic>{},
      );
      return stop.isNotEmpty ? stop['DepartureTime'] as String : null;
    }

    final startDeparture = findDeparture(startZh);
    final endDeparture = findDeparture(endZh);

    return {"startDeparture": startDeparture, "endDeparture": endDeparture};
  }

  void _scrollToCurrentStation() {
    if (_currentStationId == null) return;

    final stopTimes = trainData['StopTimes'] as List<dynamic>;
    final index =
    stopTimes.indexWhere((s) => s['StationID'] == _currentStationId);

    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stopTimesScrollController.hasClients) return;
      _stopTimesScrollController.animateTo(
        index * 110.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  bool isToday(dynamic serviceDay) {
    try {
      if (serviceDay is bool) return serviceDay;
      if (serviceDay is Map<String, dynamic>) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final start = serviceDay['StartDate'];
        final end = serviceDay['EndDate'];
        if (start == null || end == null) return false;
        return today.compareTo(start) >= 0 && today.compareTo(end) <= 0;
      }
      if (serviceDay is String) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        return serviceDay == today;
      }
    } catch (e) {
      debugPrint('isToday error: $e');
    }
    return false;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isPlausibleLive(String? stationId, int delayMinutes) {
    if (stationId == null || stationId.isEmpty) return false;

    final stopTimes = trainData['StopTimes'] as List<dynamic>?;
    if (stopTimes == null || stopTimes.isEmpty) return false;

    final idx = stopTimes.indexWhere((s) => s['StationID'] == stationId);
    if (idx == -1) return false;

    if (delayMinutes < -5 || delayMinutes > 180) return false;

    final dep = stopTimes[idx]['DepartureTime'] as String?;
    if (dep != null && dep != '--:--') {
      final parts = dep.split(':');
      if (parts.length == 2) {
        final depMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        final now = DateTime.now();
        final nowMin = now.hour * 60 + now.minute;
        final rawDiff = nowMin - depMin;
        final diff = rawDiff < 0 ? rawDiff + 24 * 60 : rawDiff;
        if (diff > 120) return false;
      }
    }
    return true;
  }

  Future<void> loadLiveBoardIfToday() async {
    if (!mounted || _isFetchingLive) return;
    _isFetchingLive = true;

    try {
      final railway = context.read<RailwayProvider>();
      final now = DateTime.now();

      if (!isSameDay(widget.time, now)) {
        if (!mounted) return;
        setState(() {
          _currentStationId = null;
          _liveDelayMinutes = 0;
          _liveDataStatus = null;
          _liveDataFetchedAt = null;
        });
        return;
      }

      if (trainData.isEmpty) return;

      final result = await railway.traTrainLiveBoard(
        trainData['DailyTrainInfo']['TrainNo'],
      );

      if (!mounted) return;

      if (result.isEmpty) {
        setState(() {
          _liveDataStatus = 'no_data';
          if (_liveDataFetchedAt != null &&
              DateTime.now().difference(_liveDataFetchedAt!) >
                  const Duration(minutes: 10)) {
            _currentStationId = null;
            _liveDelayMinutes = 0;
          }
        });
        return;
      }

      final live = result.first;
      final stationId = live['StationID'] as String?;
      final delay = (live['DelayTime'] is int) ? live['DelayTime'] as int : 0;

      if (!_isPlausibleLive(stationId, delay)) {
        setState(() {
          _liveDataStatus = 'stale';
          _currentStationId = null;
          _liveDelayMinutes = 0;
        });
        return;
      }

      final bool shouldScroll = _currentStationId != stationId;

      setState(() {
        _currentStationId = stationId;
        _liveDelayMinutes = delay;
        _liveDataStatus = 'ok';
        _liveDataFetchedAt = DateTime.now();
      });

      if (shouldScroll) {
        _scrollToCurrentStation();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _liveDataStatus = 'error');
      debugPrint('fetchLiveBoardIfToday error: $e');
    } finally {
      _isFetchingLive = false;
    }
  }

  void scrollToCurrentStation(List stopTimes) {
    if (_currentStationId == null) return;

    final index = stopTimes.indexWhere(
          (s) => s['StationID'] == _currentStationId,
    );

    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stopTimesScrollController.hasClients) return;
      _stopTimesScrollController.animateTo(
        index * 96.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ============ 即時資料 UI（深色模式適配） ============

  Widget? _buildFreshnessChip() {
    if (_liveDataStatus != 'ok' || _liveDataFetchedAt == null) {
      return null;
    }

    final colors = context.appColors;
    final now = DateTime.now();
    final age = now.difference(_liveDataFetchedAt!);

    final bool isStale = age.inMinutes >= 5;
    final Color color = isStale ? colors.warning : colors.success;
    final IconData icon =
    isStale ? Icons.schedule_rounded : Icons.sync_rounded;
    final String text = isStale
        ? '即時資料可能已過期（${age.inMinutes} 分鐘前更新）'
        : '即時更新於 ${age.inMinutes} 分鐘前';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_shouldShowDelayInfo()) return const SizedBox.shrink();
    return _buildDelayInfo();
  }

  bool _shouldShowDelayInfo() {
    DateTime scheduleDate = widget.time;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return DateFormat('yyyy-MM-dd').format(scheduleDate) == today;
  }

  Widget _buildDelayInfo() {
    final colors = context.appColors;
    final hasData = _liveDataStatus == 'ok';
    final hasDelay = hasData && _liveDelayMinutes > 0;

    final Color toneColor;
    final IconData toneIcon;
    final String toneText;

    if (!hasData) {
      toneColor = colors.warning;
      toneIcon = Icons.hourglass_empty_rounded;
      toneText = '即時資料暫時無法取得';
    } else if (hasDelay) {
      toneColor = colors.danger;
      toneIcon = Icons.warning_amber_rounded;
      toneText = '延誤 $_liveDelayMinutes 分鐘';
    } else {
      toneColor = colors.success;
      toneIcon = Icons.check_circle_rounded;
      toneText = AppLocalizations.of(context)!.text_665;
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(toneIcon, size: 18, color: toneColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  toneText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: toneColor,
                  ),
                ),
                Text(
                  '車次 ${trainData['DailyTrainInfo']['TrainNo']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context)!.text_666,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============ 主 build ============

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final freshnessChip = _buildFreshnessChip();

    return Stack(
      children: [
        Positioned.fill(
          child: SizedBox(
            child: FutureBuilder<Set<Polyline>>(
              future: context.read<RailwayProvider>().trainNetworkLine(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const AppLoading();
                }
                final lines = snapshot.data!;
                return map(polylines: lines);
              },
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 1,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          builder: (BuildContext context, ScrollController scrollController) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppCustomBar(
                title: AppLocalizations.of(context)!.text_654,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      tooltip: '加入行程',
                      onPressed: () async {
                        final railway = context.read<RailwayProvider>();
                        List<dynamic> stationNames = trainData["StopTimes"]
                            .map((stop) => stop["StationName"] as Map)
                            .toList();

                        final result = await showDialog(
                          context: context,
                          builder: (context) {
                            return StationSelectionDialog(
                                stationNames: stationNames);
                          },
                        );

                        if (result != null) {
                          String getCategory(String category) {
                            switch (category) {
                              case '上班通勤':
                                return 'commute';
                              case '旅行':
                                return 'trip';
                              default:
                                return 'other';
                            }
                          }

                          Map timeMap = printStartEndDepartureTimes(trainData);
                          final schedule = ScheduleModel(
                            type: 'train',
                            route: trainData['DailyTrainInfo']['TrainNo'],
                            startingStopName: trainData['DailyTrainInfo']
                            ['StartingStationName']['Zh_tw'],
                            userStartingStopName: result['departure'],
                            finalStopName: trainData['DailyTrainInfo']
                            ['EndingStationName']['Zh_tw'],
                            userDestinationStopName: result['destination'],
                            time: widget.time.toString(),
                            category: getCategory(result['category']),
                            seatNumber: result['seatNumber'],
                            other: {
                              "DateTime": widget.time.toString(),
                              "trainType": trainData['DailyTrainInfo']
                              ['TrainTypeName']['Zh_tw'],
                              "category": getCategory(result['category']),
                              "seatNumber": result["seatNumber"],
                              "startDeparture": timeMap["startDeparture"],
                              "endDeparture": timeMap["endDeparture"]
                            },
                          );

                          final output = await railway.addSchedule(schedule);

                          if (!context.mounted) return;

                          if (output == -1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.text_395),
                                backgroundColor: colors.warning,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } else if (output == 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.text_396),
                                backgroundColor: colors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    AppLocalizations.of(context)!.text_397),
                                backgroundColor: colors.danger,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: colors.info,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      tooltip: '列車資訊',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            final dialogColors = context.appColors;
                            return Dialog(
                              backgroundColor: dialogColors.cardBackground,
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
                                            color: dialogColors.info
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.info_rounded,
                                            color: dialogColors.info,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .text_655,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: dialogColors.info,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_405,
                                      trainData['DailyTrainInfo']
                                      ['WheelchairFlag'] ==
                                          1,
                                      Icons.accessible_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_656,
                                      trainData['DailyTrainInfo']
                                      ['PackageServiceFlag'] ==
                                          1,
                                      Icons.luggage_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_657,
                                      trainData['DailyTrainInfo']['DiningFlag'] ==
                                          1,
                                      Icons.restaurant_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_658,
                                      trainData['DailyTrainInfo']['BikeFlag'] ==
                                          1,
                                      Icons.directions_bike_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_659,
                                      trainData['DailyTrainInfo']
                                      ['BreastFeedingFlag'] ==
                                          1,
                                      Icons.child_care_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_660,
                                      trainData['DailyTrainInfo']['DailyFlag'] ==
                                          1,
                                      Icons.calendar_today_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_661,
                                      trainData['DailyTrainInfo']
                                      ['ServiceAddedFlag'] ==
                                          1,
                                      Icons.add_alert_rounded,
                                    ),
                                    _buildServiceItem(
                                      AppLocalizations.of(context)!.text_662,
                                      trainData['DailyTrainInfo']
                                      ['SuspendedFlag'] ==
                                          1,
                                      Icons.block_rounded,
                                      isError: true,
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(
                                          AppLocalizations.of(context)!.text_44,
                                          style: TextStyle(
                                            color: dialogColors.info,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colors.info,
                      ),
                    ),
                  ),
                ],
              ),
              body: RefreshIndicator(
                color: colors.info,
                onRefresh: () async {
                  await _fetchTrain();
                },
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrainInfoCard(),
                      if (freshnessChip != null) ...[
                        const SizedBox(height: 16),
                        freshnessChip,
                      ],
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.timeline_rounded,
                                size: 20, color: colors.info),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.text_398,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: colors.info,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStopTimesList(),
                      TrainInfoWidget(trainData: trainData),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomBar(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceItem(String title, bool isAvailable, IconData icon,
      {bool isError = false}) {
    final colors = context.appColors;
    final bool active = isAvailable;
    final Color activeColor = isError ? colors.danger : colors.success;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.1)
                  : colors.mutedBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? activeColor : colors.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: active ? colors.textPrimary : colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.1)
                  : colors.mutedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAvailable
                  ? AppLocalizations.of(context)!.text_663
                  : AppLocalizations.of(context)!.text_648,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? activeColor : colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainInfoCard() {
    final colors = context.appColors;
    final stopTimes = trainData['StopTimes'] as List<dynamic>;
    bool isCrossDayVar = isCrossDay(stopTimes);
    final trainNo = trainData['DailyTrainInfo']['TrainNo'];
    final cleanTrainNo = int.parse(trainNo.replaceAll(RegExp(r'[^0-9]'), ''));
    final isE500 = E500.contains(cleanTrainNo);
    final note = _localizedRailName(
      trainData['DailyTrainInfo']['Note'],
      context,
    );

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.info, colors.info.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    trainNo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localizedRailName(
                          trainData['DailyTrainInfo']['TrainTypeName'],
                          context,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_trainModel != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isE500
                                    ? colors.warning.withValues(alpha: 0.1)
                                    : colors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _trainModel!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  isE500 ? colors.warning : colors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_trainModelDescription != null)
                              Expanded(
                                child: Text(
                                  _trainModelDescription!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: colors.info,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.text_409,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localizedRailName(
                            trainData['DailyTrainInfo']['StartingStationName'],
                            context,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: colors.info,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.text_410,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: colors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localizedRailName(
                            trainData['DailyTrainInfo']['EndingStationName'],
                            context,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (note.isNotEmpty || isCrossDayVar)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCrossDayVar
                      ? colors.warning.withValues(alpha: 0.1)
                      : colors.mutedBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCrossDayVar
                        ? colors.warning.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCrossDayVar
                          ? Icons.nights_stay_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color:
                      isCrossDayVar ? colors.warning : colors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$note${isCrossDayVar ? AppLocalizations.of(context)!.text_664 : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isCrossDayVar
                              ? colors.warning
                              : colors.textPrimary,
                          fontWeight: isCrossDayVar
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool isCrossDay(List<dynamic> stopTimes) {
    int? previousTimeInMinutes;

    for (final stop in stopTimes) {
      final timeStr = stop['DepartureTime'] as String;
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final currentTimeInMinutes = hours * 60 + minutes;

      if (previousTimeInMinutes != null &&
          currentTimeInMinutes < previousTimeInMinutes) {
        return true;
      }
      previousTimeInMinutes = currentTimeInMinutes;
    }
    return false;
  }

  Widget _buildTimelineIcon(bool isCurrent, {bool isPassed = false}) {
    final colors = context.appColors;
    if (isCurrent) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: colors.info,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.info.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.train_rounded,
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isPassed ? colors.textHint : colors.info,
        shape: BoxShape.circle,
      ),
    );
  }

  bool isPassedStation(int index, List stopTimes) {
    if (_currentStationId == null) return false;

    final currentIndex = stopTimes.indexWhere(
          (s) => s['StationID'] == _currentStationId,
    );

    if (currentIndex == -1) return false;
    return index < currentIndex;
  }

  bool isCurrentStation(Map stop) => stop['StationID'] == _currentStationId;

  String formatTime(String? time, bool isFuture) {
    if (time == null) return '--:--';
    if (!isFuture || _liveDelayMinutes <= 0) return time;
    return time;
  }

  Widget _buildStopTimesList() {
    final colors = context.appColors;
    final stopTimes = trainData['StopTimes'] as List<dynamic>;

    return ListView.builder(
      controller: _stopTimesScrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stopTimes.length,
      itemBuilder: (context, index) {
        final stop = stopTimes[index];
        final isLast = index == stopTimes.length - 1;

        final passed = isPassedStation(index, stopTimes);
        final current = isCurrentStation(stop);
        final isFuture = !passed && !current;

        final textColor = passed ? colors.textHint : colors.textPrimary;
        final lineColor = passed
            ? colors.border
            : (current ? colors.info : colors.info.withValues(alpha: 0.5));

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: current
                            ? colors.info.withValues(alpha: 0.1)
                            : (passed
                            ? colors.mutedBackground
                            : colors.cardBackground),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            formatTime(stop['ArrivalTime'], isFuture),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              current ? FontWeight.w700 : FontWeight.w600,
                              color: current ? colors.info : textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTime(stop['DepartureTime'], isFuture),
                            style: TextStyle(
                              fontSize: 13,
                              color: current
                                  ? colors.info.withValues(alpha: 0.8)
                                  : textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_liveDelayMinutes > 0 &&
                        _liveDataStatus == 'ok' &&
                        isFuture &&
                        !passed &&
                        !current)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+$_liveDelayMinutes',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  if (index > 0)
                    Container(
                      width: 2,
                      height: 24,
                      color: lineColor.withValues(alpha: passed ? 0.3 : 0.5),
                    ),
                  _buildTimelineIcon(current, isPassed: passed),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 24,
                      color: lineColor.withValues(alpha: passed ? 0.3 : 0.5),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedRailName(stop['StationName'], context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        current ? FontWeight.w700 : FontWeight.w600,
                        color: current ? colors.info : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_currentStationId != null && current)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_637,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_liveDelayMinutes > 0 &&
                  _liveDataStatus == 'ok' &&
                  current)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: colors.danger,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TrainInfoWidget extends StatelessWidget {
  final Map<String, dynamic> trainData;

  static const Color primaryBlue = AppColors.primaryBlue;
  static const Color successGreen = AppColors.successGreen;
  static const Color warningOrange = AppColors.warningOrange;
  static const Color purple = AppColors.purple;

  const TrainInfoWidget({super.key, required this.trainData});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final List<Map<String, dynamic>> listTrainInfo = [
      {
        'TrainTypeName': AppLocalizations.of(context)!.text_667,
        'formation': '12節車廂（2M12T）',
        'length': '278.02m',
        'maxSpeed': '130km/h',
        'nursingCar': '1、7',
        'officeCar': '1、7',
        'accessibleCar': '3、8',
        'Parent-childCarriage': '12',
      },
      {
        'TrainTypeName': AppLocalizations.of(context)!.text_668,
        'formation': '12節車廂（2M12T）',
        'length': '278.02m',
        'maxSpeed': '130km/h',
        'nursingCar': '1、7',
        'officeCar': '1、7',
        'accessibleCar': '3、8',
        'bicycle': '12',
      },
      {
        'TrainTypeName': AppLocalizations.of(context)!.text_669,
        'formation': '8節車廂（4M4T）',
        'length': '166.99m',
        'maxSpeed': '130km/h',
        'nursingCar': '1、8',
        'officeCar': '1、8',
        'accessibleCar': '1、8',
      },
      {
        'TrainTypeName': AppLocalizations.of(context)!.text_670,
        'formation': '8節車廂（4M4T）',
        'length': '168.39m',
        'maxSpeed': '130km/h',
        'nursingCar': '3、6',
        'officeCar': '1、8',
        'accessibleCar': '1、8',
        'bicycle': '1、8',
      }
    ];

    final trainInfo = listTrainInfo.firstWhere(
          (train) =>
      train['TrainTypeName'] ==
          trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],
      orElse: () => {},
    );

    if (trainInfo.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.train_rounded,
                    size: 20,
                    color: colors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.text_671,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.info,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.info.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(context, trainInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> trainInfo) {
    final colors = context.appColors;
    final trainNo = trainData['DailyTrainInfo']['TrainNo']
        .replaceAll(RegExp(r'[^0-9]'), '');
    final isE500 = E500.contains(int.parse(trainNo));
    final isEMU3000 = EMU3000.contains(int.parse(trainNo));
    final isEMU900 = EMU900.contains(int.parse(trainNo));

    String length = trainInfo['length'];
    if (isE500) {
      length = '285.14m';
    } else if (isEMU3000) {
      length = '298.5m';
    } else if (isEMU900) {
      length = '205.0m';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoRow(
          context,
          AppLocalizations.of(context)!.text_672,
          trainInfo['TrainTypeName'],
          icon: Icons.directions_railway_rounded,
          color: colors.info,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          AppLocalizations.of(context)!.text_399,
          trainInfo['formation'],
          icon: Icons.train_rounded,
          color: colors.textPrimary,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          AppLocalizations.of(context)!.text_400,
          length,
          icon: Icons.straighten_rounded,
          color: colors.textPrimary,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          context,
          AppLocalizations.of(context)!.text_401,
          trainInfo['maxSpeed'],
          icon: Icons.speed_rounded,
          color: colors.warning,
          isHighlighted: true,
        ),
        const SizedBox(height: 16),
        _buildDivider(colors),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCompartmentInfo(
                context,
                title: AppLocalizations.of(context)!.text_673,
                value: trainInfo['accessibleCar'] ?? '-',
                icon: Icons.accessible_rounded,
                color: colors.success,
              ),
            ),
            Container(width: 1, height: 40, color: colors.divider),
            Expanded(
              child: _buildCompartmentInfo(
                context,
                title: AppLocalizations.of(context)!.text_407,
                value: trainInfo['nursingCar'] ?? '-',
                icon: Icons.child_care_rounded,
                color: colors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDivider(colors),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCompartmentInfo(
                context,
                title: AppLocalizations.of(context)!.text_674,
                value: trainInfo['officeCar'] ?? '-',
                icon: Icons.business_center_rounded,
                color: colors.warning,
              ),
            ),
            Container(width: 1, height: 40, color: colors.divider),
            Expanded(
              child: _buildCompartmentInfo(
                context,
                title: trainInfo['Parent-childCarriage'] != null
                    ? AppLocalizations.of(context)!.text_675
                    : AppLocalizations.of(context)!.text_658,
                value: trainInfo['Parent-childCarriage'] ??
                    trainInfo['bicycle'] ??
                    '-',
                icon: trainInfo['Parent-childCarriage'] != null
                    ? Icons.family_restroom_rounded
                    : Icons.directions_bike_rounded,
                color: trainInfo['Parent-childCarriage'] != null
                    ? colors.warning
                    : colors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      String title,
      String value, {
        required IconData icon,
        required Color color,
        bool isHighlighted = false,
      }) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? color : colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompartmentInfo(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
      }) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colors.divider,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}