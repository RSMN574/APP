import 'package:flutter/material.dart';

class HSRSchedulePage extends StatelessWidget {
  // 高鐵風格顏色定義
  static const Color primaryColor = Color(0xFFFF6600);     // 高鐵主色調
  static const Color surfaceColor = Color(0xFFF3F5F7);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);    // 次要文字

  final Map<String, dynamic> trainData;
  final String type;

  const HSRSchedulePage({
    Key? key,
    required this.trainData,
    required this.type,
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
              trainData['DailyTrainInfo']['TrainTypeName']?['Zh_tw'] ?? '無資料',
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              '備註',
              trainData['DailyTrainInfo']['Note']?['Zh_tw'] ?? '無備註',
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