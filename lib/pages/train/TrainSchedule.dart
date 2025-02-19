import 'package:flutter/material.dart';

import '../../database/Train/getTrain.dart';
import '../../widget/map.dart';

class TrainSchedulePage extends StatelessWidget {
  // 顏色常數定義
  static const Color primaryColor = Color(0xFF2A5CAA);     // 主色調
  static const Color surfaceColor = Color(0xFFF3F5F7);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);    // 次要文字

  final Map<String, dynamic> trainData;
  final String type;

  const TrainSchedulePage({
    Key? key,
    required this.trainData,
    required this.type,
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
                
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0, // 固定在底部
            child: FutureBuilder<Widget>(
              future: _buildDelayInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(

                  );
                } else if (snapshot.hasError) {
                  return Container(

                  );
                } else {
                  return snapshot.data ?? Container(); // 顯示延遲資訊
                }
              },
            ),
          )
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
    // 假設 fetchLiveTrainDelay 會回傳一個 Map 或延遲資訊資料
    List<dynamic> delayData = await fetchLiveTrainDelay(trainData['DailyTrainInfo']['TrainNo']);
print(delayData);
    // 這裡建立一個 Container，並用 Align 固定在底部
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
       height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10.0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '延遲資訊',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 假設 delayData 內含 'delay' 鍵
            Text(
              '延遲時間：${delayData != null && delayData[0]['DelayTime'] != null ? delayData[0]['DelayTime'] : '無延遲'}',
              style: const TextStyle(fontSize: 16),
            ),
            // 如果需要可以顯示更多延遲相關的資訊
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