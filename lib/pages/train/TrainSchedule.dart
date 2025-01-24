import 'package:flutter/material.dart';

class TrainSchedulePage extends StatelessWidget {
  final Map<String, dynamic> trainData;
  final String type;

  const TrainSchedulePage({
    Key? key,
    required this.trainData,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '列車時刻表',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrainInfoCard(),
            const SizedBox(height: 24),
            const Text(
              '停靠站',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _buildStopTimesList(),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildTrainInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8, // 柔和的阴影
            offset: const Offset(0, 4), // 阴影稍微下移
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '車次: ${trainData['DailyTrainInfo']['TrainNo']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildStationInfoRow(
              icon: Icons.place_outlined,
              label: '起站',
              stationName: trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
            ),
            const SizedBox(height: 8),
            _buildStationInfoRow(
              icon: Icons.flag_outlined,
              label: '終站',
              stationName: trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
            ),
            const SizedBox(height: 16),
            Text(
              '列車種類: ${trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw']}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              '備註: ${trainData['DailyTrainInfo']['Note']['Zh_tw']}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
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
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: $stationName',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12), // 調整項目間距
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側時間
              SizedBox(
                width: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stop['ArrivalTime'] ?? '--:--',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8), // 調整到站與離站間距
                    Text(
                      stop['DepartureTime'] ?? '--:--',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ), const SizedBox(width: 25), // 調整左中右的間距
              // 中間時間軸
              Column(
                children: [
                  if (index > 0) // 上方連線
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.blue,
                    ),
                  // 圓點
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast) // 下方連線
                    Container(
                      width: 2,
                      height: 30,
                      color: Colors.blue,
                    ),
                ],
              ),
              const SizedBox(width: 25), // 調整左中右的間距
              // 右側車站名稱與狀態
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop['StationName']['Zh_tw'] ?? '未知車站',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8), // 車站名稱與狀態間距
                    if (stop['SuspendedFlag'] == 1)
                      const Text(
                        '此站暫停停靠',
                        style: TextStyle(fontSize: 16, color: Colors.redAccent),
                      )
                    else
                      const Text(
                        '正常停靠',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



}
