import 'package:flutter/material.dart';

class TrainSchedulePage extends StatelessWidget {
  final Map<String, dynamic> trainData;
  final String type;
  const TrainSchedulePage({super.key, required this.trainData,required this.type});  // 添加构造函数参数

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('列車時刻表', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrainInfoCard(),
            SizedBox(height: 20),
            Text(
              'Stops',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(),
            _buildStopTimesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Train No: ${trainData['DailyTrainInfo']['TrainNo']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildStationInfoRow(
              icon: Icons.place,
              label: 'From',
              stationName: trainData['DailyTrainInfo']['StartingStationName']['Zh_tw'],
            ),
            _buildStationInfoRow(
              icon: Icons.flag,
              label: 'To',
              stationName: trainData['DailyTrainInfo']['EndingStationName']['Zh_tw'],
            ),
            SizedBox(height: 8),
            Text(
              'Type: ${trainData['DailyTrainInfo']['TrainTypeName']['Zh_tw']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Note: ${trainData['DailyTrainInfo']['Note']['Zh_tw']}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationInfoRow({required IconData icon, required String label, required String stationName}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        SizedBox(width: 8),
        Text(
          '$label: $stationName',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStopTimesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: trainData['StopTimes'].length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        var stop = trainData['StopTimes'][index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Text(
              '${stop['StopSequence']}',
              style: TextStyle(color: Colors.white),
            ),
          ),
          title: Text(stop['StationName']['Zh_tw']),
          subtitle: Text('Arrival: ${stop['ArrivalTime']} - Departure: ${stop['DepartureTime']}'),
          trailing: stop['SuspendedFlag'] == 1
              ? Icon(Icons.block, color: Colors.redAccent)
              : Icon(Icons.check_circle, color: Colors.green),
        );
      },
    );
  }
}
