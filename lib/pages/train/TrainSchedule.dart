import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../database/Train/getTrain.dart';
import '../../database/SQL/schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../widget/map.dart';
import '../../widget/train/RoutePalnner.dart';

// E500 電力機車 (PP自強號牽引)
const List<int> E500 = [
  101, 103, 105, 107, 109,
  111, 113, 115, 117, 119,
  121, 123, 125, 127, 129,
  131, 133, 135, 137, 139,
  141, 143, 145, 147, 149,
  150, 151, 152,
];

// EMU3000 新自強號
const List<int> EMU3000 = [
  101,103,105,107,109,
  111,113,115,117,119,
  121,123,125,127,129,
  131,133,135,137,139,
  141,143,145,147,149,
  151,153,155,157,159,
  161,163,165,167,169,
  171,173,175,177,179,
  181,183,185,187,189,
  191,193,195,197,199,
  201,203,205,207,209,
  211,213,215,217,219,
  221,223,225,227,229,
  231,233,235,237,239,
  241,243,245,247,249,
  251,253,255,257,259,
  261,263,265,267,269,
  271,273,275,277,279,
  281,283,285,287,289,
  291,293,295
];final List EMU900 = [123, 135, 145, 155, 165, 175, 185, 195, 205, 215, 225, 235, 245, 255, 265, 275, 285, 295];
final List TzeChiangLimited = [105, 110, 115, 120, 125, 130, 135, 140, 145, 150];

late Set<Polyline> allLines;
final ScrollController _stopTimesScrollController = ScrollController();
Map<String, dynamic> trainData={};
String? _currentStationId;
int _liveDelayMinutes = 0;

class TrainSchedulePage extends StatefulWidget {

  final String type;
  final DateTime time;
  final int trainNo;

  const TrainSchedulePage({
    Key? key,

    required this.type,
    required this.time, required this.trainNo,
  }) : super(key: key);

  @override
  State<TrainSchedulePage> createState() => _TrainSchedulePageState();
}

class _TrainSchedulePageState extends State<TrainSchedulePage> {
  // 通知中心主題色
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceColor = Color(0xFFEEF3FB);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  String? _currentStationId;
  int _liveDelayMinutes = 0;
  String? _trainModel; // 列車車型
  String? _trainModelDescription; // 車型說明

  final ScrollController _stopTimesScrollController = ScrollController();
  Timer? _liveBoardTimer;

  @override
  void initState() {
    super.initState();
     _fetchTrain();

  }
  Future<Map<String, dynamic> > _fetchTrain() async {
    trainData = await fetchTrain(
     widget.trainNo,
      widget.time,
    );

    if (mounted) {
      setState(() {});

    }fetchLiveBoardIfToday();
    _getTrainModel();
    return trainData;
  }
  @override
  void dispose() {
    _liveBoardTimer?.cancel();
    super.dispose();
  }

  // 獲取列車車型
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

    final stops = (_trainData['StopTimes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    String? findDeparture(String stationZh) {
      final stop = stops.firstWhere(
            (s) => s['StationName']['Zh_tw'] == stationZh,
        orElse: () => <String, dynamic>{},
      );
      return stop.isNotEmpty ? stop['DepartureTime'] as String : null;
    }

    final startDeparture = findDeparture(startZh);
    final endDeparture = findDeparture(endZh);

    return {
      "startDeparture": startDeparture,
      "endDeparture": endDeparture
    };
  }

  void _scrollToCurrentStation() {
    if (_currentStationId == null) return;

    final stopTimes = trainData['StopTimes'] as List<dynamic>;
    final index = stopTimes.indexWhere((s) => s['StationID'] == _currentStationId);

    if (index == -1) return;

    _stopTimesScrollController.animateTo(
      index * 110.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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

  Future<void> fetchLiveBoardIfToday() async {

    final now = DateTime.now();

    if (!isSameDay(widget.time, now)) {
      if (!mounted) return;
      setState(() {
        _currentStationId = null;
        _liveDelayMinutes = 0;
      });
      return;
    }

    try {
      final result = await fetchTrainStationByTrainNo(
        trainData['DailyTrainInfo']['TrainNo'],
      );

      if (!mounted || result.isEmpty) return;

      final live = result.first;

      final String? stationId = live['StationID'];
      final int delay = (live['DelayTime'] is int) ? live['DelayTime'] : 0;

      setState(() {
        _currentStationId = stationId;
        _liveDelayMinutes = delay;
      });

      _scrollToCurrentStation();
    } catch (e) {
      debugPrint('fetchLiveBoardIfToday error: $e');
    }
  }

  void scrollToCurrentStation(List stopTimes) {
    if (_currentStationId == null) return;

    final index = stopTimes.indexWhere(
          (s) => s['StationID'] == _currentStationId,
    );

    if (index == -1) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopTimesScrollController.animateTo(
        index * 96.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  // 修正 bottomNavigationBar 顯示問題
  Widget _buildBottomBar() {
    return ValueListenableBuilder(
      valueListenable: ValueNotifier(_shouldShowDelayInfo()),
      builder: (context, showDelayInfo, child) {
        if (!showDelayInfo) return const SizedBox.shrink();
        return FutureBuilder<Widget>(
          future: _buildDelayInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 60,
                color: Colors.white,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryBlue,
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox.shrink();
            }
            return snapshot.data ?? const SizedBox.shrink();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SizedBox(
            child: FutureBuilder<Set<Polyline>>(
              future: fetchTrainNetworkLine(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: LoadingAnimationWidget.stretchedDots(
                      color: primaryBlue,
                      size: 40,
                    ),
                  );
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
    backgroundColor: Colors.white,
    appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title:  Text(
    AppLocalizations.of(context)!.text_654,
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: primaryBlue,
    letterSpacing: -0.5,
    ),
    ),
    centerTitle: true,
    iconTheme: const IconThemeData(color: primaryBlue),
    actions: [
    // 加入行程按鈕
    Container(
    margin: const EdgeInsets.only(right: 4),
    child: IconButton(
    onPressed: () async {
    List<dynamic> stationNames = trainData["StopTimes"]
        .map((stop) => stop["StationName"] as Map)
        .toList();

    final result = await showDialog(
    context: context,
    builder: (context) {
    return StationSelectionDialog(stationNames: stationNames);
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
    startingStopName: trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
    userStartingStopName: result['departure'],
    finalStopName: trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
    userDestinationStopName: result['destination'],
    time: widget.time.toString(),
    category: getCategory(result['category']),
    seatNumber: result['seatNumber'],
    other: {
    "DateTime": widget.time.toString(),
    "trainType": trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],
    "category": getCategory(result['category']),
    "seatNumber": result["seatNumber"],
    "startDeparture": timeMap["startDeparture"],
    "endDeparture": timeMap["endDeparture"]
    },
    );

    final output = await ScheduleService.instance.addSchedule(schedule);

    if (output == -1) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(AppLocalizations.of(context)!.text_395),
    backgroundColor: warningOrange,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    );
    } else if (output == 100) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content:  Text(AppLocalizations.of(context)!.text_396),
    backgroundColor: successGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    );
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content:  Text(AppLocalizations.of(context)!.text_397),
    backgroundColor: errorRed,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    );
    }
    }
    },
    icon: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.add_rounded, size: 20, color: primaryBlue),
    ),
    ),
    ),
    // 列車資訊按鈕
    Container(
    margin: const EdgeInsets.only(right: 8),
    child: IconButton(
    onPressed: () {
    showDialog(
    context: context,
    builder: (BuildContext context) {
    return Dialog(
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
    color: primaryBlue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(
    Icons.info_rounded,
    color: primaryBlue,
    size: 24,
    ),
    ),
    const SizedBox(width: 12),
    Text(
    AppLocalizations.of(context)!.text_655,
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: primaryBlue,
    ),
    ),
    ],
    ),
    const SizedBox(height: 20),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_405,
    trainData['DailyTrainInfo']['WheelchairFlag'] == 1,
    Icons.accessible_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_656,
    trainData['DailyTrainInfo']['PackageServiceFlag'] == 1,
    Icons.luggage_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_657,
    trainData['DailyTrainInfo']['DiningFlag'] == 1,
    Icons.restaurant_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_658,
    trainData['DailyTrainInfo']['BikeFlag'] == 1,
    Icons.directions_bike_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_659,
    trainData['DailyTrainInfo']['BreastFeedingFlag'] == 1,
    Icons.child_care_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_660,
    trainData['DailyTrainInfo']['DailyFlag'] == 1,
    Icons.calendar_today_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_661,
    trainData['DailyTrainInfo']['ServiceAddedFlag'] == 1,
    Icons.add_alert_rounded,
    ),
    _buildServiceItem(
    AppLocalizations.of(context)!.text_662,
    trainData['DailyTrainInfo']['SuspendedFlag'] == 1,
    Icons.block_rounded,
    isError: true,
    ),
    const SizedBox(height: 20),
    Center(
    child: TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child:  Text(
    AppLocalizations.of(context)!.text_44,
    style: TextStyle(
    color: primaryBlue,
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
    icon: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.info_outline_rounded, size: 20, color: primaryBlue),
    ),
    ),
    ),
    ],
    ),
    body: SingleChildScrollView(
    controller: scrollController,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    _buildTrainInfoCard(),
    const SizedBox(height: 32),
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 8.0),
    child: Row(
    children: [
    Icon(Icons.timeline_rounded, size: 20, color: primaryBlue),
    SizedBox(width: 8),
    Text(
    AppLocalizations.of(context)!.text_398,
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: primaryBlue,
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
    bottomNavigationBar: _buildBottomBar(), // 修正後的底部欄
    );
    },
    )

      ],
    );
  }

  Widget _buildServiceItem(String title, bool isAvailable, IconData icon, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isAvailable
                  ? (isError ? errorRed.withOpacity(0.1) : successGreen.withOpacity(0.1))
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isAvailable
                  ? (isError ? errorRed : successGreen)
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: isAvailable
                    ? (isError ? errorRed : Colors.black87)
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAvailable
                  ? (isError ? errorRed.withOpacity(0.1) : successGreen.withOpacity(0.1))
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAvailable ? AppLocalizations.of(context)!.text_663 : AppLocalizations.of(context)!.text_648,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAvailable
                    ? (isError ? errorRed : successGreen)
                    : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDelayInfo() {
    DateTime scheduleDate = widget.time;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return DateFormat('yyyy-MM-dd').format(scheduleDate) == today;
  }

  Widget _buildTrainInfoCard() {
    final stopTimes = trainData['StopTimes'] as List<dynamic>;
    bool isCrossDayVar = isCrossDay(stopTimes);
    final trainNo = trainData['DailyTrainInfo']['TrainNo'];
    final cleanTrainNo = int.parse(trainNo.replaceAll(RegExp(r'[^0-9]'), ''));
    final isE500 = E500.contains(cleanTrainNo);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 車次標題 + 列車車型
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, Color(0xFF0D47A1)],
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
                        trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_trainModel != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isE500 ? warningOrange.withOpacity(0.1) : purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _trainModel!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isE500 ? warningOrange : purple,
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
                                    color: Colors.grey[600],
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

            // 起站/終站
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
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
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                             Text(
                              AppLocalizations.of(context)!.text_409,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: primaryBlue,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                             Text(
                              AppLocalizations.of(context)!.text_410,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
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

            // 備註
            if (trainData['DailyTrainInfo']['Note']['Zh_tw'] != null ||
                isCrossDayVar)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCrossDayVar
                      ? warningOrange.withOpacity(0.1)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCrossDayVar
                        ? warningOrange.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCrossDayVar ? Icons.nights_stay_rounded : Icons.info_outline_rounded,
                      size: 18,
                      color: isCrossDayVar ? warningOrange : textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${trainData['DailyTrainInfo']['Note']['Zh_tw']}${isCrossDayVar ? AppLocalizations.of(context)!.text_664 : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isCrossDayVar ? warningOrange : textPrimary,
                          fontWeight: isCrossDayVar ? FontWeight.w600 : FontWeight.w500,
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

  Future<Widget> _buildDelayInfo() async {
    try {
      final delayData = await fetchLiveTrainDelay(trainData['DailyTrainInfo']['TrainNo']);
      final hasDelay = delayData.isNotEmpty &&
          (delayData[0]['DelayTime'] != null && delayData[0]['DelayTime'] != 0);
      final delayMinutes = hasDelay ? delayData[0]['DelayTime'] as int : 0;

      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                color: hasDelay ? errorRed.withOpacity(0.1) : successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasDelay ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                size: 18,
                color: hasDelay ? errorRed : successGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    hasDelay ? '延誤 $delayMinutes 分鐘' : AppLocalizations.of(context)!.text_665,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasDelay ? errorRed : successGreen,
                    ),
                  ),
                  Text(
                    '車次 ${trainData['DailyTrainInfo']['TrainNo']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context)!.text_666,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildStationInfoRow({
    required IconData icon,
    required String label,
    required String stationName,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label：',
          style: const TextStyle(
            fontSize: 15,
            color: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          stationName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
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
    if (isCurrent) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
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
        color: isPassed ? Colors.grey[400] : primaryBlue,
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

        final textColor = passed ? Colors.grey[400]! : textPrimary;
        final lineColor = passed
            ? Colors.grey[300]!
            : (current ? primaryBlue : primaryBlue.withOpacity(0.5));

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 時間
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: current
                            ? primaryBlue.withOpacity(0.1)
                            : (passed ? Colors.grey[100] : surfaceColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            formatTime(stop['ArrivalTime'], isFuture),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                              color: current ? primaryBlue : textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTime(stop['DepartureTime'], isFuture),
                            style: TextStyle(
                              fontSize: 13,
                              color: current
                                  ? primaryBlue.withOpacity(0.8)
                                  : textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_liveDelayMinutes > 0 && isFuture && !passed && !current)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+$_liveDelayMinutes',
                            style: const TextStyle(
                              fontSize: 10,
                              color: errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 時間軸
              Column(
                children: [
                  if (index > 0)
                    Container(
                      width: 2,
                      height: 24,
                      color: lineColor.withOpacity(passed ? 0.3 : 0.5),
                    ),
                  _buildTimelineIcon(current, isPassed: passed),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 24,
                      color: lineColor.withOpacity(passed ? 0.3 : 0.5),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // 車站
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop['StationName']['Zh_tw'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                        color: current ? primaryBlue : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_currentStationId != null && current)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:  Text(
                          AppLocalizations.of(context)!.text_637,
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 延誤標記
              if (_liveDelayMinutes > 0 && current)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: errorRed,
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

  // 通知中心主題色
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceColor = Color(0xFFEEF3FB);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  const TrainInfoWidget({super.key, required this.trainData});

  @override
  Widget build(BuildContext context) {
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
          (train) => train['TrainTypeName'] == trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],
      orElse: () => {},
    );

    if (trainInfo.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.train_rounded,
                    size: 20,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                 Text(
                  AppLocalizations.of(context)!.text_671,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
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
                  primaryBlue.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(context,trainInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(context,Map<String, dynamic> trainInfo) {
    final trainNo = trainData['DailyTrainInfo']['TrainNo'].replaceAll(RegExp(r'[^0-9]'), '');
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
        _buildInfoRow(AppLocalizations.of(context)!.text_672, trainInfo['TrainTypeName'],
          icon: Icons.directions_railway_rounded,
          color: primaryBlue,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(AppLocalizations.of(context)!.text_399, trainInfo['formation'],
          icon: Icons.train_rounded,
          color: textPrimary,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(AppLocalizations.of(context)!.text_400, length,
          icon: Icons.straighten_rounded,
          color: textPrimary,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(AppLocalizations.of(context)!.text_401, trainInfo['maxSpeed'],
          icon: Icons.speed_rounded,
          color: warningOrange,
          isHighlighted: true,
        ),
        const SizedBox(height: 16),
        _buildDivider(),
        const SizedBox(height: 16),

        // 車廂配置
        Row(
          children: [
            Expanded(
              child: _buildCompartmentInfo(
                title: AppLocalizations.of(context)!.text_673,
                value: trainInfo['accessibleCar'] ?? '-',
                icon: Icons.accessible_rounded,
                color: successGreen,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildCompartmentInfo(
                title: AppLocalizations.of(context)!.text_407,
                value: trainInfo['nursingCar'] ?? '-',
                icon: Icons.child_care_rounded,
                color: purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDivider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildCompartmentInfo(
                title: AppLocalizations.of(context)!.text_674,
                value: trainInfo['officeCar'] ?? '-',
                icon: Icons.business_center_rounded,
                color: warningOrange,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[200]),
            Expanded(
              child: _buildCompartmentInfo(
                title: trainInfo['Parent-childCarriage'] != null ? AppLocalizations.of(context)!.text_675 : AppLocalizations.of(context)!.text_658,
                value: trainInfo['Parent-childCarriage'] ?? trainInfo['bicycle'] ?? '-',
                icon: trainInfo['Parent-childCarriage'] != null
                    ? Icons.family_restroom_rounded
                    : Icons.directions_bike_rounded,
                color: trainInfo['Parent-childCarriage'] != null
                    ? const Color(0xFFFF9500)
                    : const Color(0xFF34C759),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value,
      {required IconData icon, required Color color, bool isHighlighted = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? color : textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompartmentInfo({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey[300]!,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}