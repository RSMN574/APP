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
import '../widget/bubble.dart';
import '../widget/error.dart';
import '../widget/map.dart';
import 'bus_time.dart';
ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
ValueNotifier<String> _selectStationID = ValueNotifier<String>('');
class NearbyStationsPage extends StatefulWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  _NearbyStationsPageState createState() => _NearbyStationsPageState();
}

class _NearbyStationsPageState extends State<NearbyStationsPage> {
  int _index=0;
  ValueNotifier<Set<Marker>> _markers = ValueNotifier<Set<Marker>>({});
  ValueNotifier<String> _stopName = ValueNotifier<String>('');
  final GlobalKey<_BusStopListState> _key = GlobalKey<_BusStopListState>();

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
          snippet: station.stationID ?? 'Unknown',
        ),onTap: () async {
        List<dynamic> data=await GetBusStopInfo(station.stationNameZh,"Taichung");
        // 使用 map 來提取 StationID 並轉換為字串
        List<String> stationIDs = data.map((station) {
          // 確保 StationID 存在並轉換為字串
          if (station.containsKey('StationID')) {
            return station['StationID'].toString();
          }
          return '';
        })
        // 過濾掉空字串
            .where((id) => id.isNotEmpty)
            .toList();
         _stationIDs.value=stationIDs;
        _stopName.value=station.stationNameZh;
        _selectStationID.value=station.stationID;

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
                                  // print( snapshot.data?[0].toString()  );
                                  // print( snapshot.data?[1].toString()  );





                                  // 使用 Map 分組
                                  Map<String, List<Map<String, dynamic>>> groupedStations = {};

                                  for (var station in   snapshot.data!) {
                                    String stationName = station.stationNameZh;
                                    if (!groupedStations.containsKey(stationName)) {
                                      groupedStations[stationName] = [];
                                    }
                                    groupedStations[stationName]!.add(station.toJson());
                                  }

                                  // 將分組後的資料轉換為指定格式
                                  List<Map<String, dynamic>> result = groupedStations.entries.map((entry) {
                                    return {
                                      "StationGroup": {
                                        "StationGroupName": {"Zh_tw": entry.key},
                                        "Stations": entry.value
                                      }
                                    };
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
                                      itemCount:result.length,
                                      itemBuilder: (context, index) {
                                        final station = result[index];
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

  Widget _stationCard ({ required Map<String, dynamic> station }) {
// print((station["StationGroup"]["Stations"]));
    return GestureDetector(
      onTap: () {

        List<String> stationIDs = (station["StationGroup"]["Stations"] as List<dynamic>?)
            ?.map((station) => station["stationID"].toString())
            .toList() ?? [];


        _stopName.value=station["StationGroup"]["StationGroupName"]["Zh_tw"];
        _stationIDs.value=stationIDs;

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
        station["StationGroup"]["StationGroupName"]["Zh_tw"],
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
              children: station["StationGroup"]["Stations"].map<Widget>((stationItem) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationItem["stationNameZh"], // 顯示站點名稱
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: (stationItem["stops"] as List<Stop>).map<Widget>((stop) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                stop.routeNameZh, // 顯示路線名稱
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                stop.stopNameZh, // 顯示站名
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
  final GlobalKey<_BusStopListState> _key = GlobalKey<_BusStopListState>();
  // 提供外部访问方法
  void changeTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 使用 _key 获取对应的 State
      final state = _key.currentState as _BusStopListState?;
      state?._changeTab(index);  // 调用 _changeTab 方法
    });
  }
   BusStopList(this.stop, {super.key});
  @override
  State<StatefulWidget> createState() {
    return _BusStopListState();
  }
}

class _BusStopListState extends State<BusStopList>with SingleTickerProviderStateMixin {
   StreamController<List<Map<String, dynamic>>> _streamController = StreamController();
   late TabController _tabController;
  List<Map<String, dynamic>> data = [];
  final ValueNotifier<Map<String, dynamic>?> _dataNotifier = ValueNotifier(null);
  // 构建 TabBar
   @override
   void initState() {
     super.initState();
     _loadData();
     // 初始化 TabController
     _tabController = TabController(
         length: _stationIDs.value.length, // 使用 stationIDs 的長度
         vsync: this
     );
     // 監聽 _stopName 的變化，根據值切換 Tab
     _selectStationID.addListener(() {
       String currentStop = _selectStationID.value;
       _stationIDs.value.sort(); // 對站點列表進行排序

       int index = _stationIDs.value.indexOf(currentStop); // 獲取 currentStop 在排序後列表中的索引
       _tabController.animateTo(index);

     });

   }

   // 監聽 _selectStationID 的變化
   Future<void> _onStationIDChanged() async {


     // 檢查 _stationIDs 是否已經有值
     if (_stationIDs.value.isNotEmpty) {
       _tabController.dispose(); // 销毁旧的 TabController
        _tabController = TabController(
         length: _stationIDs.value.length,
         vsync: this,
       );

     }
     _stationIDs.value.sort();

     String currentStop = _selectStationID.value;
     int index = _stationIDs.value.indexOf(currentStop);


     if (index != -1) {
       _tabController.animateTo(index); // 切換 Tab
     }
   }

  @override
  void dispose() {
    _selectStationID.removeListener(_onStationIDChanged); // 移除監聽器
    _streamController.close(); // 关闭 StreamController
    // 釋放 TabController
    _tabController.dispose();
    super.dispose();

  }
  Future<void> _loadData() async {

    try {

      final data = await fetchBusStopInfo();

      _streamController.add(data); // 向数据流中添加新数据
    } catch (e) {
      _streamController.addError(e); // 向数据流中添加错误
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
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");

        i["RouteID"]=result.isNotEmpty ? result[0]["RouteID"] : "未知";
        i["from"]=result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
        i["to"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";  // 赋值到 'to' 字段
      } else if (i['Direction'] == 0) {
        var result = await mysqlSelect("SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");
        i["to"] = result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";  // 赋值到 'to' 字段
        i["from"] = result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        i["RouteID"]=result.isNotEmpty ? result[0]["RouteID"] : "未知";
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

                  trailing: bubble(plateNum: PlateNumb),
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
        var stationInfo = await fetchStationInfo(_stationIDs.value, "Taichung");
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



  PreferredSize _buildTabBar(List<Map<String, dynamic>> station) {


    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // 使用白色背景
        ),
        child: TabBar(

          controller: _tabController, // 添加 controller
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
    void _changeTab(int index) {
    _tabController.index = index; // 控制 TabBarView 显示的 tab
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
                    controller: _tabController,  // 加入 controller 綁定
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
}


