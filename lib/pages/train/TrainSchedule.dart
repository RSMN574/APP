import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../database/Train/getTrain.dart';
import '../../database/SQL/schedule.dart';
import '../../widget/map.dart';
import '../../widget/train/RoutePalnner.dart';
 final List E500=[115, 121, 123, 125, 141, 144, 138, 150, 152, 114];
late Set<Polyline> allLines;
final ScrollController _stopTimesScrollController = ScrollController();

String? _currentStationId; // 目前車站 ID
int _liveDelayMinutes = 0;
class TrainSchedulePage extends StatefulWidget {
  final Map<String, dynamic> trainData;
  final String type;
  final DateTime time;

  const TrainSchedulePage({
    Key? key,
    required this.trainData,
    required this.type,
    required this.time,
  }) : super(key: key);

  @override
  State<TrainSchedulePage> createState() => _TrainSchedulePageState();
}

class  _TrainSchedulePageState extends State<TrainSchedulePage> {
  // 顏色常數定義
  static const Color primaryColor = Color(0xFF2A5CAA);     // 主色調
  static const Color surfaceColor = Color(0xFFF3F5F7);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);
  String? _currentStationId;
  int _liveDelayMinutes = 0;

  final ScrollController _stopTimesScrollController = ScrollController();
  Timer? _liveBoardTimer;
// 次要文字


  @override
  void initState() {
    super.initState();

    fetchLiveBoardIfToday();


  }

  @override
  void dispose() {

    super.dispose();
  }

  Map printStartEndDepartureTimes(Map<String, dynamic> trainData) {
    // 1. 取出「起站」與「迄站」的中文站名
    final dailyInfo = trainData['DailyTrainInfo'] as Map<String, dynamic>;
    final startZh = dailyInfo['StartingStationName']['Zh_tw'] as String;
    final endZh   = dailyInfo['EndingStationName']['Zh_tw']   as String;

    // 2. 停靠時間列表（看你 API 回來叫什麼，這邊假設是 StopTimes）
    final stops = (trainData['StopTimes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // 3. 找到對應站名的那筆 stop，並回傳它的 DepartureTime
    String? findDeparture(String stationZh) {
      final stop = stops.firstWhere(
            (s) => s['StationName']['Zh_tw'] == stationZh,
        orElse: () => <String, dynamic>{},
      );
      return stop.isNotEmpty ? stop['DepartureTime'] as String : null;
    }

    final startDeparture = findDeparture(startZh);
    final endDeparture   = findDeparture(endZh);

    // 4. 印出來看看
    print('起站 $startZh 的 DepartureTime：$startDeparture');
    print('迄站 $endZh 的 DepartureTime：$startDeparture');
    return {
      "startDeparture":startDeparture,
      "endDeparture":endDeparture

    };
  }

  void _scrollToCurrentStation() {
    if (_currentStationId == null) return;

    final stopTimes = widget.trainData['StopTimes'] as List<dynamic>;
    final index =
    stopTimes.indexWhere((s) => s['StationID'] == _currentStationId);

    if (index == -1) return;

    _stopTimesScrollController.animateTo(
      index * 110.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  bool isToday(dynamic serviceDay) {
    try {
      // 情況 1：ServiceDay 是 API 給的 bool（TDX 常見）
      if (serviceDay is bool) return serviceDay;

      // 情況 2：ServiceDay 是 Map（含日期資訊）
      if (serviceDay is Map<String, dynamic>) {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final start = serviceDay['StartDate'];
        final end = serviceDay['EndDate'];

        if (start == null || end == null) return false;

        return today.compareTo(start) >= 0 &&
            today.compareTo(end) <= 0;
      }

      // 情況 3：ServiceDay 是 String（yyyy-MM-dd）
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
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Future<void> fetchLiveBoardIfToday() async {
    // 不是今天 → 清空即時狀態
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
        widget.trainData['DailyTrainInfo']['TrainNo'],
      );

      if (!mounted || result.isEmpty) return;

      final live = result.first;

      final String? stationId = live['StationID'];
      final int delay =
      (live['DelayTime'] is int) ? live['DelayTime'] : 0;

      setState(() {
        _currentStationId = stationId;
        _liveDelayMinutes = delay;
      });

      // 自動捲動到目前車站
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
        index * 96.0, // ⚠️ 單列高度（依你 UI 微調）
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
        children: [

    Positioned.fill(
    child: SizedBox(

        child:   FutureBuilder<Set<Polyline>>(
          future: fetchTrainNetworkLine(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return   Center( child:
            LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),
            );
            final lines = snapshot.data!;

            return map(polylines: lines);
          },
        ),

    ),
    ),

          DraggableScrollableSheet(
            initialChildSize: 1,
            minChildSize: 0.2,
            maxChildSize: 1.0,
            builder: (BuildContext context, ScrollController scrollController) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text(
                    '列車時刻表',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  elevation: 1,
                  backgroundColor: Colors.white,
                  iconTheme: const IconThemeData(color: textPrimary),
                  actions: [
                    IconButton(onPressed: () async {

// 提取 StationName (中文)
// List<String> stationNamesZh = widget.trainData["StopTimes"]
//     .map((stop) => stop["StationName"]["Zh_tw"] as String)
//     .toList();
//
// // 提取 StationName (英文)
// List<String> stationNamesEn = widget.trainData["StopTimes"]
//     .map((stop) => stop["StationName"]["En"] as String)
//     .toList();
                      // 提取 StationName (英文)
List<dynamic> stationNames = widget.trainData["StopTimes"]
    .map((stop) => stop["StationName"] as Map)
    .toList();

// 顯示彈窗並等待用戶輸入
              final result = await showDialog(
              context: context,
              builder: (context) {
              return StationSelectionDialog(stationNames:stationNames);
              },
              );


              // 處理用戶選擇的結果
              if (result != null) {
              print('出發站: ${result['departure']}');
              print('到達站: ${result['destination']}');
              print('類型: ${result['category']}');
              }

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
                      Map timeMap=printStartEndDepartureTimes(widget.trainData);
                      final schedule = ScheduleModel(
                        type: 'train',
                        route: widget.trainData['DailyTrainInfo']['TrainNo'],
                        startingStopName: widget.trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
                        userStartingStopName: result['departure'],
                        finalStopName: widget.trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
                        userDestinationStopName: result['destination'],
                        time: widget.time.toString(),
                        category: getCategory(result['category']),
                        seatNumber: result['seatNumber'],
                        other: {
                          "DateTime": widget.time.toString(),
                          "trainType": widget.trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],
                          "category": getCategory(result['category']),
                          "seatNumber": result["seatNumber"],
                          "startDeparture": timeMap["startDeparture"],
                          "endDeparture": timeMap["endDeparture"]
                        },
                      );

                      final output = await ScheduleService.instance.addSchedule(schedule);


// 根据 addSchedule 方法返回的结果进行处理
                      if (output == -1) {
                        // 如果已经存在相同的记录，提示用户
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('該行程已經存在。'))
                        );
                      } else if (output == 100) {
                        // 成功添加行程，提示用户
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('行程添加成功！'))
                        );
                      } else {
                        // 添加行程失败，提示用户
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('添加行程失敗。'))
                        );
                      }
                    }, icon: const Icon(Icons.add)),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("列車資訊"),
                              content: SizedBox(
                                height: 400,
                                child: Column(
                                  children: [
                                    const Text("列車服務:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (widget.trainData['DailyTrainInfo']['WheelchairFlag'] == 1) const Text("✅ 無障礙設施"),
                                    if (widget.trainData['DailyTrainInfo']['PackageServiceFlag'] == 1) const Text("✅ 行李服務"),
                                    if (widget.trainData['DailyTrainInfo']['DiningFlag'] == 1) const Text("✅ 餐飲服務"),
                                    if (widget.trainData['DailyTrainInfo']['BikeFlag'] == 1) const Text("✅ 自行車車廂"),
                                    if (widget.trainData['DailyTrainInfo']['BreastFeedingFlag'] == 1) const Text("✅ 哺乳設施"),
                                    if (widget.trainData['DailyTrainInfo']['DailyFlag'] == 1) const Text("✅ 每日行駛"),
                                    if (widget.trainData['DailyTrainInfo']['ServiceAddedFlag'] == 1) const Text("✅ 加班列車"),
                                    if (widget.trainData['DailyTrainInfo']['SuspendedFlag'] == 1) const Text("❌ 停駛"),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("確定"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.info),
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  controller: scrollController, // 使用 DraggableScrollableSheet 的滾動控制器
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrainInfoCard(),
                      const SizedBox(height: 32),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '停靠站資訊',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStopTimesList(),
                      TrainInfoWidget(trainData: widget.trainData,)
                    ],
                  ),
                ),
                backgroundColor: Colors.white,
                bottomNavigationBar:FutureBuilder<Widget>(
                  future: _shouldShowDelayInfo() ? _buildDelayInfo() : Future.value(SizedBox.shrink()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 10,
                        color: Colors.white,
                      );
                    } else if (snapshot.hasError) {
                      return Container(
                        height: 10,
                        color: Colors.red[100],
                      );
                    } else {
                      return Container(
                        constraints: const BoxConstraints(
                          maxHeight: 40,
                        ),
                        child: snapshot.data ?? SizedBox.shrink(),
                      );
                    }
                  },
                ),



              );
            },
          ),


        ]);

  }
  bool _shouldShowDelayInfo() {
    DateTime? scheduleDate = (widget.time);

    // 取得今天的日期（格式化為 yyyy-MM-dd）
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return DateFormat('yyyy-MM-dd').format(scheduleDate) == today;
  }
  Widget _buildTrainInfoCard() {
    final stopTimes = widget.trainData['StopTimes'] as List<dynamic>;
    bool isCrossDayVar=isCrossDay(stopTimes);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '車次 ${widget.trainData['DailyTrainInfo']['TrainNo']}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildStationInfoRow(
              icon: Icons.place_outlined,
              label: '起站',
              stationName: widget.trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
            ),
            const SizedBox(height: 12),
            _buildStationInfoRow(
              icon: Icons.flag_outlined,
              label: '終站',
              stationName: widget.trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              '列車種類',
              "${widget.trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw']}"
                  "${E500.contains( int.parse(widget.trainData['DailyTrainInfo']['TrainNo'] .replaceAll(RegExp(r'[^0-9]'), ''))) ? '（E500 車頭）' : ''}",
            ),

            const SizedBox(height: 8),
            _buildInfoItem(
              '備註',
              "${widget.trainData['DailyTrainInfo']['Note']['Zh_tw']}  ${isCrossDayVar? "跨日" :""}",
            ),
          ],
        ),
      ),
    );
  }
  Future<Widget> _buildDelayInfo() async {
    final delayData = await fetchLiveTrainDelay(widget.trainData['DailyTrainInfo']['TrainNo']);
    final hasDelay = delayData.isNotEmpty &&
        (delayData[0]['DelayTime'] != null && delayData[0]['DelayTime'] != 0);

    final delayMinutes = hasDelay ? delayData[0]['DelayTime'] as int : 0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 極小padding
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 狀態標籤
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasDelay ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasDelay ? Colors.amber.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasDelay ? Icons.warning_amber_rounded : Icons.check_circle,
                    size: 12, // 極小圖示
                    color: hasDelay ? Colors.orange[600] : Colors.teal[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasDelay ? '延誤 $delayMinutes 分鐘' : '準點',
                    style: TextStyle(
                      fontSize: 10, // 極小字體
                      fontWeight: FontWeight.w500,
                      color: hasDelay ? Colors.orange[600] : Colors.teal[600],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 車次編號
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.train, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    widget.trainData['DailyTrainInfo']['TrainNo'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
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
  Widget _buildStationInfoRow({
    required IconData icon,
    required String label,
    required String stationName,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          '$label：',
          style: const TextStyle(
            fontSize: 16,
            color: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          stationName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
  bool isCrossDay(List<dynamic> stopTimes) {
    int? previousTimeInMinutes;

    for (final stop in stopTimes) {
      // 這裡以 DepartureTime 為例，如果需要，也可以使用 ArrivalTime
      final timeStr = stop['DepartureTime'] as String;
      final parts = timeStr.split(':');
      if (parts.length != 2) continue; // 若格式不正確，就略過

      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final currentTimeInMinutes = hours * 60 + minutes;

      if (previousTimeInMinutes != null &&
          currentTimeInMinutes < previousTimeInMinutes) {
        // 如果當前的分鐘數小於上一站的分鐘數，則可能跨天了
        return true;
      }
      previousTimeInMinutes = currentTimeInMinutes;
    }
    return false;
  }
  Widget _buildTimelineIcon(bool isCurrent) {
  if (isCurrent) {
  return const Icon(
  Icons.train,
  color: primaryColor,
  size: 18,
  );
  }

  return Container(
  width: 12,
  height: 12,
  decoration: const BoxDecoration(
  color: primaryColor,
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

  bool isCurrentStation(Map stop) =>
  stop['StationID'] == _currentStationId;


  String formatTime(String? time, bool isFuture) {
  if (time == null) return '--:--';
  if (!isFuture || _liveDelayMinutes <= 0) return time;
  return '$time +$_liveDelayMinutes';
  }

  Widget _buildStopTimesList() {
    final stopTimes = widget.trainData['StopTimes'] as List<dynamic>;

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

        final textColor = passed
            ? textSecondary.withOpacity(0.4)
            : textPrimary;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: current ? primaryColor.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: current
                ? Border.all(color: primaryColor, width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                // ⏱ 時間
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Text(
                        formatTime(stop['ArrivalTime'], isFuture),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTime(stop['DepartureTime'], isFuture),
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // 🚆 時間軸
                Column(
                  children: [
                    if (index > 0)
                      Container(width: 2, height: 24, color: primaryColor.withOpacity(0.3)),
                    _buildTimelineIcon(current),
                    if (!isLast)
                      Container(width: 2, height: 24, color: primaryColor.withOpacity(0.3)),
                  ],
                ),

                const SizedBox(width: 24),

                // 車站
                Expanded(
                  child: Text(
                    stop['StationName']['Zh_tw'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}

class TrainInfoWidget extends StatelessWidget {
  final Map<String, dynamic> trainData;

  // 火车风格配色
  static const Color primaryColor = Color(0xFF2A5CAA);
  static const Color surfaceColor = Color(0xFFF3F5F7);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  const TrainInfoWidget({super.key, required this.trainData});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> listTrainInfo = [
      {
        'TrainTypeName': '自強(推拉式自強號且無自行車車廂)',
        'formation': '12節車廂（2M12T）',
        'length': '278.02m',
        'maxSpeed': '130km/h',
        'nursingCar': '1、7',
        'officeCar': '1、7',
        'accessibleCar': '3、8',
        'Parent-childCarriage': '12',
      },
      {
        'TrainTypeName': '自強(推拉式自強號且有自行車車廂)',
        'formation': '12節車廂（2M12T）',
        'length': '278.02m',
        'maxSpeed': '130km/h',
        'nursingCar': '1、7',
        'officeCar': '1、7',
        'accessibleCar': '3、8',
        'bicycle': '12',
      },
      {
        'TrainTypeName': '太魯閣(太魯閣)',
        'formation': '8節車廂（4M4T）',
        'length': '166.99m',
        'maxSpeed': '130km/h',
        'nursingCar': '1、8',
        'officeCar': '1、8',
        'accessibleCar': '1、8',
      },
      {
        'TrainTypeName': '普悠瑪(普悠瑪)',
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildContent(trainInfo),
    );
  }

  Widget _buildContent(Map<String, dynamic> trainInfo) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 新增列车型号显示
          _buildInfoRow("列車型號", trainInfo['TrainTypeName']),
          _buildDivider(),  // 保持分割线样式一致

          _buildInfoRow("列車編組", trainInfo['formation']),
          _buildDivider(),
          _buildInfoRow("列車長度", _getTrainLength(trainInfo)),
          _buildDivider(),
          _buildInfoRow("最高時速", trainInfo['maxSpeed'], isHighlighted: true),

          if (trainInfo['Parent-childCarriage'] != null || trainInfo['bicycle'] != null) ...[
            _buildDivider(),
            _buildCombinedRow([
              _buildSpecialCarriage(trainInfo),
              _buildItem("車長室", trainInfo['officeCar']),
            ]),
          ],

          if (trainInfo['Parent-childCarriage'] == null && trainInfo['bicycle'] == null) ...[
            _buildDivider(),
            _buildInfoRow("車長室", trainInfo['officeCar']),
          ],

          _buildDivider(),
          _buildCombinedRow([
            _buildItem("無障礙車廂", trainInfo['accessibleCar']),
            _buildItem("哺集乳室", trainInfo['nursingCar']),
          ]),
        ],
      ),
    );
  }
  String _getTrainLength(Map<String, dynamic> trainInfo) {
    final trainNo = trainData['DailyTrainInfo']['TrainNo'].replaceAll(RegExp(r'[^0-9]'), '');
    return (E500.contains(int.parse(trainNo))) ? '285.14m' : trainInfo['length'];
  }

  Widget _buildSpecialCarriage(Map<String, dynamic> trainInfo) {
    return trainInfo['Parent-childCarriage'] == null
        ? _buildItem('自行車車廂', trainInfo['bicycle'])
        : _buildItem("親子車廂", trainInfo['Parent-childCarriage']);
  }

  Widget _buildInfoRow(String title, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _titleStyle),
          Text(value, style: isHighlighted ? _highlightValueStyle : _normalValueStyle),
        ],
      ),
    );
  }

  Widget _buildCombinedRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }

  Widget _buildItem(String title, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _titleStyle),
          Text(value, style: _normalValueStyle),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[200],
    );
  }

  // 文字樣式
  TextStyle get _titleStyle => const TextStyle(
    fontSize: 16,
    color: textSecondary,
  );

  TextStyle get _normalValueStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  TextStyle get _highlightValueStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );
}
