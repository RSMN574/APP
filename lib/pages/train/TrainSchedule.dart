import 'package:flutter/material.dart';

import '../../database/Train/getTrain.dart';
import '../../database/schedule.dart';
import '../../widget/map.dart';
import '../../widget/train/RoutePalnner.dart';

class TrainSchedulePage extends StatelessWidget {
  // 顏色常數定義
  static const Color primaryColor = Color(0xFF2A5CAA);     // 主色調
  static const Color surfaceColor = Color(0xFFF3F5F7);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);    // 次要文字

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
  Widget build(BuildContext context) {

    return Stack(
        children: [

    const Positioned.fill(
    child: SizedBox(

        child: map()
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
                  iconTheme: IconThemeData(color: textPrimary),
                  actions: [
                    IconButton(onPressed: () async {

// 提取 StationName (中文)
// List<String> stationNamesZh = trainData["StopTimes"]
//     .map((stop) => stop["StationName"]["Zh_tw"] as String)
//     .toList();
//
// // 提取 StationName (英文)
// List<String> stationNamesEn = trainData["StopTimes"]
//     .map((stop) => stop["StationName"]["En"] as String)
//     .toList();
                      // 提取 StationName (英文)
List<dynamic> stationNames = trainData["StopTimes"]
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

                      final schedule _schedule = schedule();
                      final output = await _schedule.addSchedule(

                          UserStartingStopName: result['departure'],
                          UserDestinationStopName: result['destination'],
                          StartingStopName:trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
                          FinalStopName:trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
                          route: trainData['DailyTrainInfo']['TrainNo'], type: 'train',
                          other:{"DateTime":  (time).toString(),"trainType":trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],"category":getCategory(result['category'])}
                      );

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
                                    if (trainData['DailyTrainInfo']['WheelchairFlag'] == 1) Text("✅ 無障礙設施"),
                                    if (trainData['DailyTrainInfo']['PackageServiceFlag'] == 1) Text("✅ 行李服務"),
                                    if (trainData['DailyTrainInfo']['DiningFlag'] == 1) Text("✅ 餐飲服務"),
                                    if (trainData['DailyTrainInfo']['BikeFlag'] == 1) Text("✅ 自行車車廂"),
                                    if (trainData['DailyTrainInfo']['BreastFeedingFlag'] == 1) Text("✅ 哺乳設施"),
                                    if (trainData['DailyTrainInfo']['DailyFlag'] == 1) Text("✅ 每日行駛"),
                                    if (trainData['DailyTrainInfo']['ServiceAddedFlag'] == 1) const Text("✅ 加班列車"),
                                    if (trainData['DailyTrainInfo']['SuspendedFlag'] == 1) const Text("❌ 停駛"),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("確定"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: Icon(Icons.info),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    ],
                  ),
                ),
                backgroundColor: Colors.white,
                bottomNavigationBar: FutureBuilder<Widget>(
                  future: _buildDelayInfo(),
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
                        constraints: BoxConstraints(
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

  Widget _buildTrainInfoCard() {
    final stopTimes = trainData['StopTimes'] as List<dynamic>;
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
              '車次 ${trainData['DailyTrainInfo']['TrainNo']}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildStationInfoRow(
              icon: Icons.place_outlined,
              label: '起站',
              stationName: trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
            ),
            const SizedBox(height: 12),
            _buildStationInfoRow(
              icon: Icons.flag_outlined,
              label: '終站',
              stationName: trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              '列車種類',
              trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw'],
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              '備註',
              "${trainData['DailyTrainInfo']['Note']['Zh_tw']}  ${isCrossDayVar? "跨日" :""}",
            ),
          ],
        ),
      ),
    );
  }
  Future<Widget> _buildDelayInfo() async {
    final delayData = await fetchLiveTrainDelay(trainData['DailyTrainInfo']['TrainNo']);
    final hasDelay = delayData.isNotEmpty == true && delayData[0]['DelayTime'] != null;
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
                  Icon(Icons.train, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    trainData['DailyTrainInfo']['TrainNo'],
                    style: TextStyle(
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
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          stationName,
          style: TextStyle(
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
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
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

  Widget _buildStopTimesList() {
    final stopTimes = trainData['StopTimes'] as List<dynamic>;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stopTimes.length,
      itemBuilder: (context, index) {
        final stop = stopTimes[index];
        final isLast = index == stopTimes.length - 1;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 時間區塊
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Text(
                        stop['ArrivalTime'] ?? '--:--',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop['DepartureTime'] ?? '--:--',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 時間軸
                Column(
                  children: [
                    if (index > 0)
                      Container(
                        width: 2,
                        height: 24,
                        color: primaryColor.withOpacity(0.3),
                      ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 24,
                        color: primaryColor.withOpacity(0.3),
                      ),
                  ],
                ),
                const SizedBox(width: 24),
                // 車站資訊
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop['StationName']['Zh_tw'] ?? '未知車站',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (stop['SuspendedFlag'] == 1)
                        Text(
                          '此站暫停停靠',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.redAccent,
                          ),
                        )
                      else
                        Text(
                          '正常停靠',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                    ],
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