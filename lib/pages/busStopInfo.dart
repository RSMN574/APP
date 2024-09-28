import 'package:flutter/material.dart';

import '../Const/regularConst.dart';
import '../database/getData.dart';
import '../database/getStationInfo.dart';


class BusStopInfo extends StatefulWidget {
  final String stop; // Store the stop parameter

  const BusStopInfo(this.stop, {super.key});

  @override
  State<BusStopInfo> createState() => _BusStopInfoState();
}

class _BusStopInfoState extends State<BusStopInfo> {
  // Asynchronous method to fetch bus stop information
  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {
    var info = await GetBusStopInfo(widget.stop, "Taichung");
    List<Map<String, dynamic>> data = [];

    // Check if info is not null and process the data
    if (info != null) {
      for (var i in info) {
        var stationInfo = await fetchStationInfo(i["StationID"], "Taichung");
         data.addAll(stationInfo) ;
        print(data);
      }
    }

    return data; // Return a list of lists containing station info
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: busBlue,
        elevation: 0,
        title: Text(
          widget.stop, // Access the stop parameter
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchBusStopInfo(), // Call the async method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text("发生错误: ${snapshot.error}")); // Handle error
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("没有找到相关信息")); // Handle no data case
          } else {
            // Flatten the data for displaying


            return ListView.builder(
              itemCount: snapshot.data?.length,
              itemBuilder: (context, index) {
                // Assuming each station map contains a "name" key
                return ListTile(
                  onTap: () {

                  },
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(

                      border: Border.all(
                        width: 1.0,

                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      snapshot.data?[index]["NextBusTime"]!,
                      style: TextStyle(
                        fontFamily: 'MiSans-Semibold',
                        fontSize: 18,
                         ),
                    ),
                  ),
                  title: Text(
                      snapshot.data?[index]["RouteName"]["Zh_tw"]!,
                    style: TextStyle(
                      fontFamily: 'MiSans-Demibold',
                      fontSize: 18,
                      color: Color.fromRGBO(77, 77, 77, 1),
                    ),
                  ),
                  // 添加 trailing，这里可以放 Bubble 小组件
                  //   trailing: stop["isRed"] == '0'
                  //       ? (hasPlateNumb ? bubble(plateNum: PlateNumb) : Container())
                  //       : (stop["isRed"] == '2' && hasPlateNumb ? bubble(plateNum: PlateNumb) : Container()),


                );
              },
            );
          }
        },
      ),
    );
  }
}
