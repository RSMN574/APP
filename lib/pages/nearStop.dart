import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import '../Const/regularClass.dart';
import '../Const/regularConst.dart';
import '../database/favorite_feature.dart';
import '../database/getBusTime.dart';
import '../database/getData.dart';
import '../database/getStationInfo.dart';
import '../models/Station.dart';
import '../widget/error.dart';
import '../widget/map.dart';
import 'busStopInfo.dart';
import 'bus_time.dart';

class NearbyStationsPage extends StatefulWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  _NearbyStationsPageState createState() => _NearbyStationsPageState();
}

class _NearbyStationsPageState extends State<NearbyStationsPage> {
  int _index=0;
  ValueNotifier<Set<Marker>> _markers = ValueNotifier<Set<Marker>>({});
  ValueNotifier<String> _stopName = ValueNotifier<String>('');
  @override
  void dispose() {

    super.dispose(); // 确保调用父类的 dispose 方法
    Provider.of<MarkerProvider>(context, listen: false).setMarker({});

  }
  // 加载标记
  Future<void> _loadMarkers(BuildContext context, List<Station>? stations) async {
    if (stations == null || stations.isEmpty) {
      debugPrint('Stations data is empty.');
      return;
    }

    Set<Marker> markers = {};

    for (var station in stations) {
      if (station.positionLat == null || station.positionLon == null) {
        debugPrint('Invalid latitude or longitude for station: ${station.stationNameZh}');
        continue;
      }

      final marker = Marker(
        markerId: MarkerId(station.stationUID),
        position: LatLng(
          station.positionLat,
          station.positionLon,
        ),
        infoWindow: InfoWindow(
          title: station.stationNameZh ?? 'Unknown',
          snippet: station.stationUID ?? 'Unknown',
        ),onTap: () {

        _stopName.value=station.stationNameZh;
        setState(() {
          _index = 1; // 切换到搜索内容
        });

      }
      );
      markers.add(marker);
    }
    _markers.value=markers;  // 添加新标记
    _markers.notifyListeners();  // 通知监听器更新 UI


    // Provider.of<MarkerProvider>(context, listen: false).setMarker(markers);

    debugPrint('Markers loaded: ${markers.length}');
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight = screenHeight - (screenHeight * 0.2) - appBarHeight - bottomNavBarHeight;

    return WillPopScope(
        onWillPop: () async {
      if (_index > 0) {
        setState(() {
          _index--; // 返回到上一个索引
        });
        return false; // 阻止默认返回导航
      }
      return true; // 在索引为0时允许默认返回导航
    },
    child:Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SizedBox(
              height: mapHeight,
              child:
              ValueListenableBuilder<Set<Marker>>(
                valueListenable: _markers,
                builder: (context, markers, child) {
                  return  map( markers:_markers.value,  onMapCreated: (controller) {
                    // 自定义逻辑
                    print("NearbyStationsPage Map Created");
                  },);
                },
              )



            ),
          ),

      DraggableScrollableSheet(
        initialChildSize: 0.43,
        minChildSize: 0.4,
        maxChildSize: 1.0,
        builder: (BuildContext context, ScrollController scrollController) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 提示线放置在 Stack 的最上层
              Positioned(
                top: 0, // 让提示线在最顶部
                left: MediaQuery.of(context).size.width / 2 - 20, // 居中提示线
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // 滚动内容区域
              Container(
                height: 800,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      Container(
                        height: 700,
                        child: IndexedStack(
                          index: _index,
                          children: <Widget>[
                            FutureBuilder<List<Station>>(
                              future: getNearStation(
                                "${locationProvider.latitude}%2C${locationProvider.longitude}",
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return const Center(
                                    child: Text(
                                      "找不到附近的站牌",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                } else if (snapshot.hasData &&
                                    snapshot.data != null &&
                                    snapshot.data!.isNotEmpty) {
                                  final seenNames = <String>{};
                                  final uniqueStations = snapshot.data!.where((station) {
                                    final name = station.stationNameZh;
                                    if (seenNames.contains(name)) {
                                      return false;
                                    } else {
                                      seenNames.add(name);
                                      return true;
                                    }
                                  }).toList();

                                  // 加载标记
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _loadMarkers(context, snapshot.data!);
                                  });
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: uniqueStations.length,
                                      itemBuilder: (context, index) {
                                        final station = uniqueStations[index];
                                        return _stationCard(station: station);
                                      },
                                    ),
                                  );
                                } else {
                                  return const Center(
                                    child: Text(
                                      "找不到附近的站牌",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                }
                              },
                            ),
                            DraggableScrollableSheetPageTwo()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // 重載按鈕
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                // 重新加載附近站點數據
                final stations = await getNearStation("${locationProvider.latitude}%2C${locationProvider.longitude}");
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadMarkers(context, stations);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _stationCard ({ station }) {
    return GestureDetector(
      onTap: () {

        _stopName.value=station.stationNameZh;
        setState(() {
          _index = 1; // 切换到搜索内容
        });


        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => BusStopInfo(station.stationNameZh),
        //   ),
        // );
      },
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) { // 向左滑动
          setState(() {
            if (_index > 0) {
              _index--; // 返回上一页
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.stationNameZh,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 8),
            // 确保返回的每个元素是一个 Widget
            Column(
              children: station.stops.map<Widget>((stop) { // 明确声明为 List<Widget>
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stop.routeNameZh,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        stop.stopNameZh,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget DraggableScrollableSheetPageTwo() {
    print(_stopName.value); // 打印当前的站点信息

    return Container(

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          // 在这里直接使用 BusStopInfo 组件
      BusStopList(_stopName.value, key: ValueKey(_stopName.value),), // 传递 stopName 作为参数给 BusStopInfo

    );
  }


}
class BusStopList extends StatefulWidget {
  final String stop;

  const BusStopList(this.stop, {super.key});
  @override
  State<StatefulWidget> createState() {
    return _BusStopListState();
  }
}

class _BusStopListState extends State<BusStopList> {
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
  } Future<void> _loadData() async {
    try {
      final data = await fetchBusStopInfo();
      _streamController.add(data); // 向数据流中添加新数据
    } catch (e) {
      _streamController.addError(e); // 向数据流中添加错误
    }
  }
  Future<Widget> _buildTabContent(int direction, List<Map<String, dynamic>> stopEstimatedTime) async {
    List<Map<String, dynamic>> directionList = stopEstimatedTime.where((item) => item["Direction"] == direction).toList();

    for (var i in directionList) {
      // 根据方向查找去程或回程的目的地信息
      if (direction == 1) {
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");

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
      child:




      Container(
        margin: const EdgeInsets.only(bottom: 25), // 设置底部间距
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadData(); // 刷新时重新加载数据
          },
          child: ListView.separated(
            itemCount: directionList.length,
            itemBuilder: (context, index) {
              final stop = directionList[index];
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
                  title: Row(
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



  PreferredSize _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // 使用白色背景
        ),
        child: const TabBar(
          indicatorColor: Colors.black, // 使用黑色作为指示器颜色
          labelColor: Colors.black, // 黑色文字
          unselectedLabelColor: Colors.grey, // 灰色未选中文字
          indicatorWeight: 2.0, // 更细的指示器
          indicatorSize: TabBarIndicatorSize.label, // 窄指示器
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 略轻的加粗，显得现代
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 15, // 未选中标签稍小字体
          ),
          tabs: [
            Tab(
              icon: Icon(Icons.directions_bus, size: 24),
              text: "A",
            ),
            Tab(
              icon: Icon(Icons.directions_bus, size: 24),
              text: "B",
            ),
          ],
        ),
      ),
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
                                      city: 'Taichung',
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
                            bottom: _buildTabBar(),
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
                    children: [
                      FutureBuilder(
                        future: _buildTabContent(0, snapshot.data!),
                        builder: (context, contentSnapshot) {
                          if (contentSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.stretchedDots(
                                color: Colors.black,
                                size: 40,
                              ),
                            );
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
  }
}


