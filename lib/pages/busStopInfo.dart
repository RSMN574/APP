
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../Const/regularConst.dart';
import '../database/favorite_feature.dart';
import '../database/getData.dart';
import '../database/getStationInfo.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../database/shared_perferences.dart';
import '../pages/bus_time.dart';
import '../widget/error.dart';
class BusStopInfo extends StatefulWidget {
  final String stop;

  const BusStopInfo(this.stop, {super.key});

  @override
  State<BusStopInfo> createState() => _BusStopInfoState();
}

class _BusStopInfoState extends State<BusStopInfo> {
  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController();

  List<Map<String, dynamic>> data = [];
  final ValueNotifier<Map<String, dynamic>?> _dataNotifier = ValueNotifier(null);
  // 构建 TabBar
  @override
  void initState() {
    super.initState();
    _loadData(); // 初次加载数据
  }
  @override
  void dispose() {
    _streamController.close(); // 关闭 StreamController
    super.dispose();
  }
  PreferredSize _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        child: const TabBar(
          indicatorColor: busBlue,
          labelColor: busBlue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 16),
          tabs: [
            Tab(icon: Icon(Icons.directions_bus), text: "A"),
            Tab(icon: Icon(Icons.directions_bus), text: "B"),
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

  Future<Widget> _buildTabContent(int direction, List<Map<String, dynamic>> stopEstimatedTime) async {
    List<Map<String, dynamic>> directionList = stopEstimatedTime.where((item) => item["Direction"] == direction).toList();

    for (var i in directionList) {
      // 根据方向查找去程或回程的目的地信息
      if (direction == 1) {
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");
        print(result);
        i["RouteID"]=result.isNotEmpty ? result[0]["RouteID"] : "未知";
        i["from"]=result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
        i["to"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";  // 赋值到 'to' 字段
      } else if (direction == 0) {
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");
        i["to"] = result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";  // 赋值到 'to' 字段
        i["from"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        i["RouteID"]=result.isNotEmpty ? result[0]["RouteID"] : "未知";
      }
    }

    // 对 stop["time"] 按照时间升序排序
    directionList.sort((a, b) {
      if (a["time"] == "即將到站") return -1;
      if (b["time"] == "即將到站") return 1;
      if (a["time"] == "班次結束") return 1;
      if (b["time"] == "班次結束") return -1;

      int aTimeInMinutes = _parseTimeToMinutes(a["time"]);
      int bTimeInMinutes = _parseTimeToMinutes(b["time"]);

      return aTimeInMinutes.compareTo(bTimeInMinutes);
    });

    return RefreshIndicator(
      onRefresh: () async {
       _loadData();
      },
      child: ListView.builder(
        itemCount: directionList.length,
        itemBuilder: (context, index) {
          final stop = directionList[index];

          final isRed = stop["isRed"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["isRed"] == '2' ? const Color.fromRGBO(235, 15, 41, 0.3) : Colors.white);

          return ListTile(
            onTap: () async {
              // 使用 Navigator.push 创建新的页面
              await GetBusInfo(int.parse(stop["RouteID"]), "Taichung");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusTime(
                    routeName:  stop["RouteName"]["Zh_tw"],
                    departureStopName:  stop["from"],
                    destinationStopName:  stop["to"],
                    operators: "",
                    routeMapImageUrl: "",
                    city: "Taichung", routeID: stop["RouteID"],

                  ),
                ),
              );

            },
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
                color: Color.fromRGBO(77, 77, 77, 1),
              ),
            ),
            subtitle: Text(
              stop["to"] ?? "未知目的地",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }


  // 解析时间格式，转换成相对于当前时间的分钟数
  int _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return -1;

    // 处理 "X 分鐘" 格式
    if (time.contains("分鐘")) {
      return int.tryParse(time.split(" ").first) ?? -1;
    }

    // 处理 "XX:XX" 格式
    if (time.contains(":")) {
      final parts = time.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;

        // 获取当前时间
        DateTime now = DateTime.now();
        DateTime parsedTime = DateTime(now.year, now.month, now.day, hour, minute);

        // 如果时间已经过去了，则认为是第二天的时间
        if (parsedTime.isBefore(now)) {
          parsedTime = parsedTime.add(const Duration(days: 1));
        }

        return parsedTime.difference(now).inMinutes;
      }
    }

    return -1;
  }

  // 获取公交站信息的异步方法
  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {

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

    return tempData;
  }
// 返回每个隐藏的菜单项
  SelectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: busBlue),
            Text(text),
          ],
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Colors.black,
                size: 40,
              ),
            );
          } else if (snapshot.hasError) {
            return ErrorPage();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ErrorPage();
          } else {
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(widget.stop),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadData, // 刷新数据
                    ),
                    PopupMenuButton<String>(
                      iconColor: Colors.black,
                      itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                        SelectView(Icons.info, '站牌資訊', 'A'),
                        SelectView(Icons.add, '加入收藏', 'B'),
                      ],
                      onSelected: (String action) async {
                        if (action == 'B') {
                          favorite_feature dbHelper = favorite_feature(); // 创建实例

                          final output = await dbHelper.addFavorite(StopName:widget.stop,table: "FavoritesStop", city: 'Taichung');


                          if (output==100) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              text: '${widget.stop}已儲存項目',
                            );
                          } else if (output==-1) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              text: '${widget.stop}已存在於列表中，不會重複添加',
                            );
                          } else if (output==200) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'Oops...',
                              text: '儲存項目時發生錯誤',
                            );
                          }

                        }
                      },
                    ),
                  ],
                  bottom: _buildTabBar(),
                ),
                body: TabBarView(
                  children: [
                    FutureBuilder(
                      future: _buildTabContent(0, snapshot.data!),
                      builder: (context, contentSnapshot) {
                        if (contentSnapshot.connectionState == ConnectionState.waiting) {
                          return  Center(child: LoadingAnimationWidget.stretchedDots(
                            color: Colors.black,
                            size: 40,
                          ));
                        }
                        return contentSnapshot.data as Widget;
                      },
                    ),
                    FutureBuilder(
                      future: _buildTabContent(1, snapshot.data!),
                      builder: (context, contentSnapshot) {
                        if (contentSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        return contentSnapshot.data as Widget;
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      )
    );
  } Future<void> _loadData() async {
    try {
      final data = await fetchBusStopInfo();
      _streamController.add(data); // 向数据流中添加新数据
    } catch (e) {
      _streamController.addError(e); // 向数据流中添加错误
    }
  }
}
