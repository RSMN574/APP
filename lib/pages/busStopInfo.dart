
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../Const/regularConst.dart';
import '../database/SQL/favorite_feature.dart';
import '../database/getData.dart';
import '../database/bus/getStationInfo.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../pages/bus_time.dart';
import '../widget/bubble.dart';
import '../widget/error.dart';
ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
class BusStopInfo extends StatefulWidget {
  final String stop;
  final String city;
  const BusStopInfo(this.stop, {super.key, required this.city});
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
    // _loadData(); // 初次加载数据
  }
  @override
  void dispose() {
    _streamController.close(); // 关闭 StreamController
    super.dispose();
  }


  // 获取到站时间列表的异步方法
  Future<Map<String, dynamic>> getTimeList(stopData) async {
    if (stopData["EstimateTime"] != null) {
      if (stopData["EstimateTime"] == 0) {
        List PlateNumb = [];
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }
        return {"color": '0',"time": "即將到站", "isRed": '0', "PlateNumb": PlateNumb.toString()};
      } else {
        int result = (stopData["EstimateTime"] / 60).floor();
        List PlateNumb = [];
        if (stopData['Estimates'] != null) {
          for (var estimate in stopData['Estimates']) {
            PlateNumb.add(estimate["PlateNumb"]);
          }
        }

        return {
          "color": result < 3 ? "2" : "min",
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
          "PlateNumb": "",
          "color":  difference.inMinutes.remainder(60) <= 0 ? "班次結束" :"min",
        };
      } else {
        DateTime NextBusTime = DateTime.now().add(Duration(hours: difference.inHours, minutes: difference.inMinutes.remainder(60)));
        return {
          'time': "${NextBusTime.hour.toString().padLeft(2, '0')}:${NextBusTime.minute.toString().padLeft(2, '0')}",
          "isRed": '',
          "PlateNumb": "",
          "color": "班次結束"
        };
      }
    } else {
      return {"time": "班次結束", "isRed": '', "PlateNumb": "","color": "班次結束"};
    }
  }

  Future<Widget> _buildTabContent(String direction, List<Map<String, dynamic>> stopEstimatedTime) async {
    List<Map<String, dynamic>> directionList = stopEstimatedTime.where((item) => item["Direction"] == direction).toList();
    // 使用 Map 來確保每個路線只出現一次
    List<Map<String, dynamic>> uniqueList;
    final Map<String, Map<String, dynamic>> uniqueRoutes = {};
    for (var item in stopEstimatedTime) {
      final routeKey = "${item["RouteName"]["Zh_tw"]}_${item["Direction"]}";
      if (!uniqueRoutes.containsKey(routeKey) ||
          _parseTimeToMinutes(item["time"]) < _parseTimeToMinutes(uniqueRoutes[routeKey]!["time"])) {
        uniqueRoutes[routeKey] = item;
      }
    }

    uniqueList= uniqueRoutes.values.toList();

    List<Map<String, dynamic>> finalList=[];

    // 按 StationID 分类
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in uniqueList) {
      String stationID = item["StationID"];
      groupedData.putIfAbsent(stationID, () => []).add(item);
    }

    // 打印分组后的结果
    groupedData.forEach((stationID, items) {
      if(stationID==direction){
        finalList=items;
        // print("finalList");
        // print(finalList);
      }
      // print("StationID: $stationID");
      // print("Data: $items");
    });

    for (var i in finalList) {

      // 根据方向查找去程或回程的目的地信息
      if (i['Direction'] == 1) {
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_${widget.city}_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");

        i["RouteID"]=result.isNotEmpty ? result[0]["RouteID"] : "未知";
        i["from"]=result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
        i["to"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";  // 赋值到 'to' 字段
        i["DepartureStopName"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        i["DestinationStopName"] = result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
      } else if (i['Direction'] == 0) {
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_${widget.city}_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");
        i["to"] = result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";  // 赋值到 'to' 字段
        i["from"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        i["RouteID"]=result.isNotEmpty ? result[0]["RouteID"] : "未知";
        i["DepartureStopName"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        i["DestinationStopName"] = result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
      }
    }

    // 对 stop["time"] 按照时间升序排序
    finalList.sort((a, b) {
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

        },
        child:




        Container(
          margin: const EdgeInsets.only(bottom: 25), // 设置底部间距
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadData(); // 刷新时重新加载数据
            },
            child: ListView.separated(
              itemCount: finalList.length,
              itemBuilder: (context, index) {
                final stop = finalList[index];
                final PlateNumb = stop["PlateNumb"];

                final color = stop["color"] == '0'
                    ? const Color.fromRGBO(235, 15, 41, 0.85)
                    : (stop["color"] == '2'
                    ? const Color.fromRGBO(225, 85, 104, 0.1)
                    : (stop["color"] == "班次結束"
                    ? const Color.fromRGBO(69, 69, 69, 0.1)
                    : (stop["color"] == "min"
                    ? const Color.fromRGBO(13, 168, 255, 0.1)
                    : const Color.fromRGBO(68, 68, 68, 0.1))));

                return Container(
                  height: 53.0, // 每个列表项的固定高度
                  child: ListTile(
                    onTap: () async {
                      await GetBusInfo( routeid: int.parse(stop["RouteID"]), city: widget.city);
                      print(stop);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusTime(
                            routeName:  stop["RouteName"]["Zh_tw"],
                            departureStopName:  stop["DepartureStopName"],
                            destinationStopName:  stop["DestinationStopName"],
                            operators: "",
                            routeMapImageUrl: "",
                            city: widget.city, routeID: int.parse(stop["RouteID"]),
                            mark: Mark.fromMap({
                              "highlight": [
                                widget.stop
                              ],
                              "direction": stop["Direction"],
                            }),
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        stop["time"] ?? "未知",
                        style: TextStyle(
                          fontFamily: 'MiSans-normal',
                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? Colors.white
                              : (stop["color"] == '2'
                              ? const Color.fromRGBO(255, 85, 104, 1)
                              : (stop["color"] == "班次結束"
                              ? const Color.fromRGBO(149, 149, 149, 1.0)
                              : (stop["color"] == "min"
                              ? const Color.fromRGBO(13, 168, 255, 1)
                              : const Color.fromRGBO(68, 68, 68, 1)))),
                        ),
                      ),
                    ),
                    title:  Row(
                      children: [
                        Text(
                          stop["RouteName"]["Zh_tw"] ?? "未知站名",
                          style: TextStyle(
                            fontFamily: stop["color"] == "0" ? 'MiSans-Semibold' : 'MiSans-normal',
                            fontSize: 17,
                            color: stop["color"] == "班次結束"
                                ? const Color.fromRGBO(136, 136, 136, 1)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8), // 增加站名和方向之間的間距
                        Text(
                          "往 ${stop["to"] ?? "未知方向"}",
                          style: TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: const Color.fromRGBO(136, 136, 136, 1),
                          ),
                        ),
                        if (stop["RouteName"]["Zh_tw"]!.contains("車站"))
                          Padding(
                            padding: const EdgeInsets.only(left: 6), // 左侧间距
                            child: SvgPicture.asset(
                              'assets/icons/Taiwan_Railways_Logo.svg', // 自定义SVG路径
                              width: 18, // SVG图标宽度
                              height: 18, // SVG图标高度
                            ),
                          )
                        else if (stop["RouteName"]["Zh_tw"]!.contains("捷運"))
                          Padding(
                            padding: const EdgeInsets.only(left: 6), // 左侧间距
                            child: SvgPicture.asset(
                              'assets/icons/tc_MRT.svg', // 自定义SVG路径
                              width: 18, // SVG图标宽度
                              height: 18, // SVG图标高度
                            ),
                          ),
                      ],
                    ),

                    trailing: PlateNumb != null ? bubble(plateNum: PlateNumb) : null,

                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: Color.fromRGBO(231, 231, 231, 1), // 分隔线颜色
                  height: 9, // 分隔线与上下元素间距
                  thickness: 1, // 分隔线粗细
                  indent: 20, // 分隔线左间距
                  endIndent: 20, // 分隔线右间距
                );
              },
            ),
          ),
        )
    );
  }
  Future<void> _loadData() async {



      final data = await fetchBusStopInfo();

      _streamController.add(data); // 向数据流中添加新数据

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

    List<dynamic> info = await GetBusStopInfo(widget.stop, widget.city);
    List<Map<String, dynamic>> tempData = [];

    _stationIDs.value= info.map((station) => station["StationID"] as String).toList();// 提取 StationID

    if (info != null) {
      for (var i in info) {
        var stationInfo = await fetchStationInfo(_stationIDs.value, widget.city);
        for (var stop in stationInfo) {
          var timeData = await getTimeList(stop);
          stop["time"] = timeData["time"];
          stop["isRed"] = timeData["isRed"];
          stop["color"] = timeData["color"];
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
    _loadData();
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
              print(snapshot.error);
              return ErrorPage();
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              print('snapshot.has not Data');
              return ErrorPage();
            } else {
              return DefaultTabController(
                length: 2,
                child: Scaffold(
                    appBar: PreferredSize(
                      preferredSize: const Size.fromHeight(120), // 自定义高度
                      child: Container(
                        decoration: BoxDecoration(

                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),

                          color: Colors.white,

                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2), // 微弱阴影
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            AppBar(

                              backgroundColor: Colors.transparent, // 设置透明背景
                              elevation: 0, // 移除默认阴影
                              title: Text(
                                widget.stop,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              actions: [
                                IconButton(
                                  icon: Icon(Icons.refresh, color: Colors.black),
                                  onPressed: _loadData, // 刷新数据
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.black),
                                  itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                                    SelectView(Icons.info, '站牌資訊', 'A'),
                                    SelectView(Icons.add, '加入收藏', 'B'),
                                  ],
                                  onSelected: (String action) async {
                                    if (action == 'B') {
                                      favorite_feature dbHelper = favorite_feature();

                                      final output = await dbHelper.addFavorite(
                                        StopName: widget.stop,
                                        table: "FavoritesStop",
                                        city: widget.city,
                                      );

                                      if (output == 100) {
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.success,
                                          text: '${widget.stop}已儲存項目',
                                        );
                                      } else if (output == -1) {
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.warning,
                                          text: '${widget.stop}已存在於列表中，不會重複添加',
                                        );
                                      } else if (output == 200) {
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
                              bottom: _buildTabBar(snapshot.data!),
                            ),
                            Positioned(
                              top: 8, // 提示线距离顶部的位置
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    body: TabBarView(
                      // controller: _tabController,  // 加入 controller 綁定
                      children: List.generate(_stationIDs.value.length, (index) {
                        String label = String.fromCharCode(65 + index); // A, B, C...
                        return FutureBuilder(
                          future: _buildTabContent(_stationIDs.value[index], snapshot.data!), // 傳入 A, B, C...
                          builder: (context, contentSnapshot) {

                            if (contentSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: LoadingAnimationWidget.stretchedDots(
                                  color: Colors.black,
                                  size: 40,
                                ),
                              );
                            }

                            if (contentSnapshot.hasError) {
                              return Center(
                                child: Text('Error: ${contentSnapshot.error}'),
                              );
                            }

                            if (contentSnapshot.data == null) {
                              return Center(
                                child: Text("No content available"),
                              );
                            }
                            return contentSnapshot.data is Widget
                                ? contentSnapshot.data as Widget
                                : Center(child: Text("Invalid content"));
                          },
                        );
                      }),
                    )

                ),
              );
            }
          },
        )
    );
  }
  PreferredSize _buildTabBar(List<Map<String, dynamic>> station) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // 使用白色背景
        ),
        child: TabBar(


          indicatorColor: Colors.black, // 使用黑色作为指示器颜色
          labelColor: Colors.black, // 黑色文字
          unselectedLabelColor: Colors.grey, // 灰色未选中文字
          indicatorWeight: 2.0, // 更细的指示器
          indicatorSize: TabBarIndicatorSize.label, // 窄指示器
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 略轻的加粗，显得现代
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15, // 未选中标签稍小字体
          ),

          tabs: List.generate(_stationIDs.value.length, (index) {
            String label = String.fromCharCode(65 + index); // 將索引轉為字母 A, B, C...
            return Tab(
              icon: Icon(Icons.directions_bus, size: 24),
              text: _stationIDs.value[index],

            );
          }),

        ),
      ),
    );
  }

}
