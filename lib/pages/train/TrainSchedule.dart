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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(
              stop['StationName']['Zh_tw'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            subtitle: Text(
              '到站: ${stop['ArrivalTime']} - 離站: ${stop['DepartureTime']}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            trailing: stop['SuspendedFlag'] == 1
                ? const Icon(Icons.block, color: Colors.redAccent)
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
