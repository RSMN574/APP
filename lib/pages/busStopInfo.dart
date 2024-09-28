import 'dart:convert';
import 'package:flutter/material.dart';
import '../Const/regularConst.dart';
import '../database/getData.dart';
import '../database/getStationInfo.dart';

class BusStopInfo extends StatefulWidget {
  final String stop;

  const BusStopInfo(this.stop, {super.key});

  @override
  State<BusStopInfo> createState() => _BusStopInfoState();
}

class _BusStopInfoState extends State<BusStopInfo> {
  List<Map<String, dynamic>> data = [];

  // 构建 TabBar
  PreferredSize _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        child: TabBar(
          indicatorColor: busBlue,
          labelColor: busBlue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [
            Tab(icon: Icon(Icons.directions_bus), text: "去程"),
            Tab(icon: Icon(Icons.directions_bus), text: "回程"),
          ],
        ),
      ),
    );
  }

  // 获取到站时间列表的异步方法
  Future<Map<String, dynamic>> getTimeList(stopData) async {
    if (stopData["EstimateTime"] != null) {
      if (stopData["EstimateTime"] == 0) {
        List PlateNumb = [];
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }
        return {"time": "即將到站", "isRed": '0', "PlateNumb": PlateNumb.toString()};
      } else {
        int result = (stopData["EstimateTime"] / 60).floor();
        List PlateNumb = [];
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }
        return {
          "time": result < 1 ? "即將到站" : "$result 分鐘",
          "isRed": result < 3 ? "2" : "",
          "PlateNumb": result < 20 ? PlateNumb.toString() : ""
        };
      }
    } else if (stopData["NextBusTime"] != null) {
      Duration difference = DateTime.parse(stopData["NextBusTime"]).difference(DateTime.now());
      if (difference.inHours == 0) {
        return {
          "time": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "${difference.inMinutes.remainder(60)} 分鐘",
          "isRed": '',
          "PlateNumb": ""
        };
      } else {
        DateTime NextBusTime = DateTime.now().add(Duration(hours: difference.inHours, minutes: difference.inMinutes.remainder(60)));
        return {
          'time': "${NextBusTime.hour.toString().padLeft(2, '0')}:${NextBusTime.minute.toString().padLeft(2, '0')}",
          "isRed": '',
          "PlateNumb": ""
        };
      }
    } else {
      return {"time": "班次結束", "isRed": '', "PlateNumb": ""};
    }
  }

  // 构建每个 Tab 的内容
  Widget _buildTabContent(int direction, List<Map<String, dynamic>> stopEstimatedTime) {
    List<Map<String, dynamic>> directionList = stopEstimatedTime.where((item) => item["Direction"] == direction).toList();
print(directionList);
    return RefreshIndicator(
      onRefresh: () async {
        await fetchBusStopInfo();
      },
      child: ListView.builder(
        itemCount: directionList.length,
        itemBuilder: (context, index) {
          final stop = directionList[index];

          final isRed = stop["isRed"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["isRed"] == '2' ? const Color.fromRGBO(235, 15, 41, 0.3) : Colors.white);

          return ListTile(
            onTap: () {},
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isRed,
                border: Border.all(
                  width: 1.0,
                  color: stop["isRed"] == '0'
                      ? const Color.fromRGBO(235, 15, 41, 0.85)
                      : (stop["isRed"] == '2'
                      ? const Color.fromRGBO(235, 15, 41, 0.35)
                      : busBlue),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                stop["time"] ?? "未知",
                style: TextStyle(
                  fontFamily: 'MiSans-Semibold',
                  fontSize: 18,
                  color: stop["isRed"] == '0'
                      ? Colors.white
                      : (stop["isRed"] == '2' ? const Color.fromRGBO(235, 15, 41, 0.7) : const Color.fromRGBO(90, 107, 107, 1)),
                ),
              ),
            ),
            title: Text(
              stop["RouteName"]["Zh_tw"] ?? "未知站名",
              style: const TextStyle(
                fontFamily: 'MiSans-Demibold',
                fontSize: 18,
                color: const Color.fromRGBO(77, 77, 77, 1),
              ),
            ),
          );
        },
      ),
    );
  }

  // 获取公交站信息的异步方法
  Future <List<Map<String, dynamic>>> fetchBusStopInfo() async {
    var info = await GetBusStopInfo(widget.stop, "Taichung");
    List<Map<String, dynamic>> tempData = [];

    if (info != null) {
      for (var i in info) {
        var stationInfo = await fetchStationInfo(i["StationID"], "Taichung");
        for (var stop in stationInfo) {
          var timeData = await getTimeList(stop);
          stop["time"] = timeData["time"];
          stop["isRed"] = timeData["isRed"];
        }
        tempData.addAll(stationInfo);
      }
    }
    //
    // setState(() {
    //   data = tempData;
    // });
print(tempData);
    return tempData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder <List<Map<String, dynamic>>>(
        future: fetchBusStopInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("发生错误: ${snapshot.error}"));
          } else if (snapshot.data ==[]) {
            return const Center(child: Text("没有找到相关信息"));
          } else {
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: busBlue,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text(
                    "站點資訊",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  bottom: _buildTabBar(),
                ),
                body: Container(
                  color: bgColorWhite,
                  child: TabBarView(
                    children: [
                      _buildTabContent(0, snapshot.data!),
                      _buildTabContent(1, snapshot.data!),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
