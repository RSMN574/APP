import 'package:flutter/material.dart';

import '../../database/SQL/schedule.dart';
import '../../widget/train/RoutePalnner.dart';

class HSRSchedulePage extends StatelessWidget {
  // 高鐵風格顏色定義
  static const Color primaryColor = Color(0xFFFF6600);     // 高鐵主色調
  static const Color surfaceColor = Color(0xFFF3F5F7);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);    // 次要文字

  final Map<String, dynamic> trainData;
  final String type;
  final DateTime time;
  const HSRSchedulePage({
    Key? key,
    required this.trainData,
    required this.type,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '高鐵列車時刻表',
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

            final schedule = ScheduleModel(
                userStartingStopName: result['departure'],
                userDestinationStopName: result['destination'],
                startingStopName:trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
                finalStopName:trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
                route: trainData['DailyTrainInfo']['TrainNo'], type: 'HSR',
                other:{"DateTime":  (time).toString(),"trainType":"台灣高鐵700T","category":getCategory(result['category'])}

            );

// 调用 updateSchedule 来更新现有的排程
            final output = await ScheduleService.instance.updateSchedule(schedule);

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

            },
            icon: Icon(Icons.info),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
      backgroundColor: surfaceColor,

    );
  }

  Widget _buildTrainInfoCard() {
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
              trainData['DailyTrainInfo']['TrainTypeName']?['Zh_tw'] ?? '台灣高鐵700T',
            ),
            if (trainData['DailyTrainInfo']['Note']?['Zh_tw'] != null)
              const SizedBox(height: 8),
            _buildInfoItem(
              trainData['DailyTrainInfo']['Note']?['Zh_tw'] != null
                  ? '備註: ${trainData['DailyTrainInfo']['Note']['Zh_tw']}'
                  : '',


              trainData['DailyTrainInfo']['Note']?['Zh_tw'] ?? '',
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