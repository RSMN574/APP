import 'dart:async';
import 'dart:convert';
import 'package:com.rsmn574.app/widget/bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Const/regularClass.dart';
import '../Const/regularConst.dart';
import '../database/favorite_feature.dart';
import '../database/getBusTime.dart';
import '../database/getData.dart';
import '../widget/map.dart';
import 'busStopInfo.dart';

class Mark {
  final List<dynamic>? highlight;
  final int? direction;

  Mark({ this.highlight,  this.direction});
  // 從 Map 創建 Mark 的工廠構造函數
  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      highlight: map['highlight'] ?? [],
      direction: map['direction'] ?? 0,
    );
  }
}

class BusTime extends StatefulWidget {
  final routeName;
  final departureStopName;
  final destinationStopName;
  final operators;
  final routeMapImageUrl;
  final city;
  final int routeID;
  final Mark? mark;

  const BusTime({Key? key,required this.routeName,required  this.routeID, this.departureStopName, this.destinationStopName, this.operators,this.routeMapImageUrl,required this.city, this.mark })
      : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime>with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late var stopNamesWithTime1;
  late var stopNamesWithTime2;
  late final  TabController _tabController;
  final Set<Marker> markers = {};
  Timer? _timer;
  late Future<Map<String, dynamic>> _dataFuture;
  final ValueNotifier<Map<String, dynamic>?> _dataNotifier = ValueNotifier(null);
  ValueNotifier<bool> isTimerOn = ValueNotifier(false);
  @override
  void initState() {
    super.initState();

     _loadData(); // 初始加载数据
    _tabController = TabController(length: 2, vsync: this); // 兩個 Tab
// 添加监听器
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // 标签正在更改
        print("Changing to tab: ${_tabController.index}");
      } else {
        // 标签更改已完成
       if(_tabController.index==0){

         _loadMarkers("stopNamesWithTime1");
       }else  if(_tabController.index==1){
         _loadMarkers("stopNamesWithTime2");
       }
      }
    });

    // 根據 mark.direction 設定 _tabController 的 index
    if (widget.mark?.direction == 0) {
      _tabController.index = 1;
    } else if (widget.mark?.direction == 1) {
      _tabController.index = 0;
    }




  }


// 滚动到第一个高亮站点


// 滚动到指定索引
void _scrollToIndex(int index) {
  const itemHeight = 54.5;
  const separatorHeight = 9.0;
  final scrollPosition = (itemHeight + separatorHeight) * index;
  // 确保 setState 更新完成后调用滚动
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  });

}
  ValueNotifier<int> remainingSecondsNotifier = ValueNotifier(40);
  Future<void> _loadMarkers(String stopType) async {

    Set<Marker> markers = {};
  if(stopType=="stopNamesWithTime1"){

    for (var stop in stopNamesWithTime1) {

      final marker = Marker(

        markerId: MarkerId(stop['StopUID']),
        position: LatLng(
          stop['StopPosition']['PositionLat'],
          stop['StopPosition']['PositionLon'],
        ),
        infoWindow: InfoWindow(
          title: stop['stopName'] ?? 'Unknown',
          snippet: stop['StopUID'] ?? 'Unknown',
        ),
      );
      markers.add(marker);
    }
  }else   if(stopType=="stopNamesWithTime2"){

    for (var stop in stopNamesWithTime2) {


      final marker = Marker(
        markerId: MarkerId(stop['StopUID']),
        position: LatLng(
          stop['StopPosition']['PositionLat'],
          stop['StopPosition']['PositionLon'],
        ),
        infoWindow: InfoWindow(
          title: stop['stopName'] ?? 'Unknown',
          snippet: stop['StopUID'] ?? 'Unknown',
        ),
      );
      markers.add(marker);
    }
  }
    setState(() {
      Provider.of<MarkerProvider>(context, listen: false).setMarkers(markers);

    });

  }
  void _startAutoReload() {
    // 如果已有定时器正在运行，先取消它
    _timer?.cancel();
    remainingSecondsNotifier.value = 40; // 初始40秒
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSecondsNotifier.value > 1) {
        remainingSecondsNotifier.value = remainingSecondsNotifier.value- 1;
      } else {
        remainingSecondsNotifier.value = 40; // 重置倒计时
        _loadData(); // 加载数据
        print("更新中");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 停止定时器
    remainingSecondsNotifier.dispose(); // 释放 ValueNotifier
    _tabController.dispose(); // 释放 TabController
    super.dispose();

  }

  // 加载数据，包括站名和 NextBusTime
  Future<void> _loadData() async { //stop data
    List<Map<String, dynamic>> data =await GetBusInfo( city: widget.city, routeid: (widget.routeID), );

    final routeInfo = [widget.routeName, widget.departureStopName, widget.destinationStopName];
    final busTimeData = await fetchBusTime(widget.routeName, widget.city);

    try {
     stopNamesWithTime1  = await fetchStopNamesWithTime(
          1,
          busTimeData.where((stop) => stop['Direction'] == 1).toList(),data
      );

    }catch (e) {

      stopNamesWithTime1  = await fetchStopNamesWithTime(
          0,
          busTimeData.where((stop) => stop['Direction'] == 0).toList(),data
      );

      // 可以根据需要进一步处理异常，例如返回默认值或显示错误提示
    }


    try {
    // final stopNamesWithTime1 = await fetchStopNamesWithTime(1, busTimeData.where((stop) => stop['Direction'] == 1).toList());
     stopNamesWithTime2 = await fetchStopNamesWithTime(0, busTimeData.where((stop) => stop['Direction'] == 0).toList(),data);


    }catch (e) {

    stopNamesWithTime2=await fetchStopNamesWithTime(1, busTimeData.where((stop) => stop['Direction'] == 1).toList(),data);


    // 可以根据需要进一步处理异常，例如返回默认值或显示错误提示
    }
    // 根據 mark.direction 設定 _tabController 的 index
    if (widget.mark?.direction == 0) {
      List<dynamic> stopNames = stopNamesWithTime2.map((item) => item["stopName"] as String).toList();
      // 找出 highlight 的站
      List? highlightedStations = widget.mark?.highlight;


      // 找到第一個 isHighlighted 為 true 的站
      int highlightedStation =  stopNames.indexOf(highlightedStations?[0]);

      // 如果找到 highlightedStation，取得其 stopName
      if (highlightedStation != -1) {



        _scrollToIndex(highlightedStation);
      } else {
        print("No highlighted station found.");
      }


    } else if (widget.mark?.direction == 1) {
      List<dynamic> stopNames = stopNamesWithTime1.map((item) => item["stopName"] as String).toList();
      // 找出 highlight 的站
      List? highlightedStations = widget.mark?.highlight;


      // 找到第一個 isHighlighted 為 true 的站
      int highlightedStation =  stopNames.indexOf(highlightedStations?[0]);

      // 如果找到 highlightedStation，取得其 stopName
      if (highlightedStation != -1) {



        _scrollToIndex(highlightedStation);
      } else {
        print("No highlighted station found.");
      }



    }
    // 提取所有 stopName


    if(isTimerOn.value){
     _startAutoReload();
     if (kDebugMode) {
       print("定時更新啟動");
     }
   }else{
     if (kDebugMode) {
       print("定時更新不啟動");
     }
   }
     _loadMarkers("stopNamesWithTime1");
    // 更新数据时只更新 ValueNotifier
    _dataNotifier.value = {
      'routeInfo': routeInfo,
      'stopNamesWithTime1': stopNamesWithTime1,
      'stopNamesWithTime2': stopNamesWithTime2,
    };
  }

  // 获取每个站的站名和 NextBusTime
  Future<List<Map<String, dynamic>>> fetchStopNamesWithTime(int tabIndex, List<dynamic> busTimeData, List<Map<String, dynamic>> data) async {

    List<Map<String, dynamic>> stopNamesWithTime = [];
    String hasPlateNum="";
    if (tabIndex < data.length) {
      var stopData = json.decode(data[tabIndex]["Stops"]);

      for (var stop in stopData) {
        String stopName = stop["StopName"]["Zh_tw"];

        Map<String, dynamic> nextBusTime = await getTimeList(stopName, busTimeData); // 如果没有 NextBusTime，显示“尚無此車”
        bool isHighlighted = false;
        if (widget.mark != null && widget.mark!.highlight != null) {
          isHighlighted = widget.mark!.highlight!.contains(stopName) && tabIndex == widget.mark!.direction;
        }


         if(nextBusTime["PlateNumb"]!=''){

           if(hasPlateNum!=nextBusTime["PlateNumb"]){
             hasPlateNum=nextBusTime["PlateNumb"]?? "";
             stopNamesWithTime.add({
               "stopName": stopName,
               "nextBusTime": nextBusTime["time"],
               'color': nextBusTime["color"],
               "PlateNumb": nextBusTime["PlateNumb"],
               "Estimates":nextBusTime["Estimates"].toString(),
               "StopPosition":stop["StopPosition"],
               "StopUID":stop['StopUID'],
               "isHighlighted":isHighlighted
             });
           }else{
             stopNamesWithTime.add({
               "stopName": stopName,
               "nextBusTime": nextBusTime["time"],
               'color': nextBusTime["color"],
               "PlateNumb": '',
               "Estimates":nextBusTime["Estimates"].toString(),
               "StopPosition":stop["StopPosition"],
               "StopUID":stop['StopUID'],
               "isHighlighted":isHighlighted
             });
           }

       }else{

           stopNamesWithTime.add({
             "stopName": stopName,
             "nextBusTime": nextBusTime["time"],
             'color': nextBusTime["color"],
             "PlateNumb": '',
             "Estimates":nextBusTime["Estimates"].toString(),
             "StopPosition":stop["StopPosition"],
             "StopUID":stop['StopUID'],
             "isHighlighted":isHighlighted
           });
             }}


    }

    return stopNamesWithTime;
  }

  Future<Map<String, dynamic>> getTimeList(String stopName, List<dynamic> busTimeData) async {
    List<dynamic> a = busTimeData.where((stop) => stop['StopName']["Zh_tw"] == stopName).toList();

    if (a.isNotEmpty) {
      if (a[0]["EstimateTime"] != null) {
        if (a[0]["EstimateTime"] == 0) {
          String plateNumb = a[0]["PlateNumb"] ?? "";
          isTimerOn.value=true;
          return {"time": "即將到站", "color": '0', "PlateNumb": plateNumb,"Estimates": a[0]["Estimates"],
            "StopPosition":a[0]["StopPosition"].toString(),
            "StopUID":a[0]['StopUID']};
        } else {
          int result = (a[0]["EstimateTime"] / 60).floor();


          isTimerOn.value=true;
            return {
              "time": result < 1 ? "即將到站" : "$result 分鐘",
              "color": result < 3 ? "2" : "min",
              "PlateNumb": result < 3 ?  a[0]["PlateNumb"] : "",
              "Estimates": a[0]["Estimates"],
              "StopPosition":a[0]["StopPosition"],
              "StopUID":a[0]['StopUID']
            };


        }
      } else if (a[0]["NextBusTime"] != null) {
        Duration difference = DateTime.parse(a[0]["NextBusTime"]).difference(DateTime.now());

        if (difference.inHours == 0) {
          if(difference.inMinutes.remainder(60)<3 && difference.inMinutes.remainder(60)>0){

         if(difference.inMinutes.remainder(60) <= 0){

         }else{
           isTimerOn.value=true;
         }

              return {


                "time": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "${difference.inMinutes.remainder(60)} 分鐘",
                "color": '2',
                "PlateNumb": a[0]["PlateNumb"],
                "Estimates": a[0]["Estimates"],
                "StopPosition":a[0]["StopPosition"],
                "StopUID":a[0]['StopUID']
              };


          }else{
            if(difference.inMinutes.remainder(60) <= 0){

            }else{
              isTimerOn.value=true;
            }

            return {


              "time": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "${difference.inMinutes.remainder(60)} 分鐘",
              "color":  difference.inMinutes.remainder(60) <= 0 ? "班次結束" :"min",
            "PlateNumb": "",
              "Estimates": a[0]["Estimates"],
              "StopPosition":a[0]["StopPosition"],
              "StopUID":a[0]['StopUID']
            };
          }

        } else {
          DateTime nextBusTime = DateTime.now().add(difference);
          return {
            "time": "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}",
            "color": '',
            "PlateNumb": "",
            "Estimates": a.isNotEmpty && a[0]["Estimates"] != null ? a[0]["Estimates"] : "",

            "StopPosition":a[0]["StopPosition"],
            "StopUID":a[0]['StopUID']
          };
        }
      } else {
        return {"time": "班次結束", "color": "班次結束", "PlateNumb": "","Estimates": a[0]["Estimates"],
          "StopPosition":a[0]["StopPosition"],"StopUID":a[0]['StopUID']
};
      }
    }
    return {"time": "班次結束", "color": "班次結束", "PlateNumb": "","Estimates": a.isNotEmpty && a[0]["Estimates"] != null ? a[0]["Estimates"] : "",

      "StopPosition":a[0]["StopPosition"],"StopUID":a[0]['StopUID']
};
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

    return  PopScope(
      canPop: false,
      onPopInvoked: ( bool didPop ){
        if ( didPop ) {
          Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
        }
                 // really exit
        else {
          /*
            Insert your code
            */

          Navigator.of(context).pop();
        }
      },
      child: ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: _dataNotifier,
      builder: (context, data, child) {
        if (data == null) {
          return  Scaffold(
            body: Center(child: LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),),
          );
        }

        final routeInfo = data['routeInfo'] as List;
        final stopNamesWithTime1 = data['stopNamesWithTime1'] as List;
        final stopNamesWithTime2 = data['stopNamesWithTime2'] as List;


        return
        Stack(
          children: [

        const Positioned.fill(
        child: SizedBox(

            child: map()
        ),
        ),

            DraggableScrollableSheet(
            initialChildSize: 1,
            minChildSize: 0.2,
            maxChildSize: 1.0,
            builder: (BuildContext context, ScrollController scrollController) {
              return

                SingleChildScrollView(
                  controller: scrollController, // 使用 ScrollController 使内容可以滚动
                  child:
                      SizedBox(
                        height:MediaQuery.of(context).size.height,
                  child:
                  DefaultTabController(
                  length: 2,
                  child: Scaffold(

                    appBar: AppBar(
                      backgroundColor: busBlue,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white), // 返回图标
                        onPressed: () {
                          Navigator.pop(context); // 返回上一个页面
                        },
                      ),
                      title: Text(
                        routeInfo[0],
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      actions: [
                        PopupMenuButton<String>(
                          iconColor:   Colors.white,
                          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                            SelectView(Icons.info, '公車資訊', 'A'),
                            SelectView(Icons.favorite, '加入收藏', 'B'),
                            SelectView(Icons.location_on, '路線圖', 'C'),
                            SelectView(Icons.schedule, '歷史公車時間', 'D'),
                          ],
                          onSelected: (String action) async {
                            // 点击选项的时候
                            switch (action) {
                              case 'A':
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min, // 自适应内容的高度
                                            children: [
                                              Text(
                                                "開發中",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );});
                                break;
                              case 'B':
                                favorite_feature dbHelper = favorite_feature(); // 创建实例

                            final result = await dbHelper.addFavorite(DepartureStopNameZh:routeInfo[1],DestinationStopNameZh:routeInfo[2],routeName:routeInfo[0],city:"Taichung",routeID:(widget.routeID),table: "FavoritesRoute");

                                      // var output=await    saveList("favoritesBusRoute",'{"route":"${routeInfo[0]}","DepartureStopNameZh":"${routeInfo[1]}","DestinationStopNameZh":"${routeInfo[2]}"}');

                                // stationComparison=await  saveList('favoritesBusStopId',other["id"] );
                                // 顯示相應的 QuickAlert
                                if (result==100) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.success,
                                    text: '${routeInfo[0]}已儲存項目',
                                  );
                                } else if (result==-1) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.warning,
                                    text: '${routeInfo[0]}已存在於列表中，不會重複添加',
                                  );
                                } else if (result==200) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.error,
                                    title: 'Oops...',
                                    text: '儲存項目時發生錯誤',
                                  );
                                }


                                break;
                              case 'C':



                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min, // 自适应内容的高度
                                            children: [
                                              const Text(
                                                "路線圖",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),Linkify(
                                                onOpen: (link) async {
                                                  if (!await launchUrl(Uri.parse(link.url))) {
                                                    throw Exception('Could not launch ${link.url}');
                                                  }
                                                },
                                                text: widget.routeMapImageUrl,
                                              )
                                            ],
                                          ),
                                        ),
                                      );});break;
                              case 'D':
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => BusDetailPage(  routeId: (widget.routeID).toString(), city:widget.city ,),
                            ),
                            );

                                break;
                            }
                          },
                        ),
                      ],
                      bottom: _buildTabBar(routeInfo),
                    ),
                    body:

                    Stack(
                      children: [
      Container(
                          color: bgColorWhite,
                          child: TabBarView(
                            controller: _tabController,
                            children: [

                              _buildTabContent(stopNamesWithTime1), // Tab for direction 0
                              _buildTabContent(stopNamesWithTime2), // Tab for direction 1
                            ],
                          ),
                       ),
                      if (isTimerOn.value == false)
                    Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16), // 小的內邊距，確保高度合適
                        decoration: BoxDecoration(
                          color: busBlue, // 使用 busBlue 作為背景色
                          borderRadius: BorderRadius.circular(10), // 圓角設置
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4, // 輕微的模糊效果
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: busBlue, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center, // 水平居中
                          children: [
                            Icon(Icons.pause_circle_filled, color: Colors.white, size: 14), // 使用暂停图标，颜色为白色
                            SizedBox(width: 6), // 图标与文本间距
                            Text(
                              "已停止自動更新",
                              style: TextStyle(
                                fontSize: 12, // 字體較小
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // 字體顏色為白色
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                          else if (isTimerOn.value == true)
                  Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: remainingSecondsNotifier, // 监听 remainingSecondsNotifier
                      builder: (context, remainingTime, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16), // 小的內邊距，確保高度合適
                          decoration: BoxDecoration(
                            color: busBlue, // 使用 busBlue 作為背景色
                            borderRadius: BorderRadius.circular(10), // 圓角設置
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4, // 輕微的模糊效果
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: busBlue, width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // 水平居中
                            children: [
                              Icon(Icons.refresh, color: Colors.white, size: 14), // 使用更新图标，颜色为白色
                              SizedBox(width: 6), // 图标与文本间距
                              Text(
                                "剩餘時間: $remainingTime 秒", // 显示剩余时间
                                style: const TextStyle(
                                  fontSize: 12, // 字體較小
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // 字體顏色為白色
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )




              ],
                    ),
                  ),
                )));})

          ],

        );

      },
    ));
  }

  // 构建 TabBar
  PreferredSize _buildTabBar(List routeInfo) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          // controller:  _tabController ,
          indicatorColor: busBlue,
          labelColor: busBlue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: [
            Tab(icon: const Icon(Icons.directions_bus), text: routeInfo[1]),
            Tab(icon: const Icon(Icons.swap_horiz), text: routeInfo[2]),
          ],
        ),
      ),
    );
  }

  // 构建每个 Tab 的内容
  Widget _buildTabContent(List stopNamesWithTime) {
    return Container(
padding: const EdgeInsets.only(bottom: 25),
      child: RefreshIndicator(

      onRefresh: () async {
        await _loadData(); // 刷新时重新加载数据
        _startAutoReload();
      },
      child: ListView.separated(
        controller: _scrollController,
        itemCount: stopNamesWithTime.length,
        itemBuilder: (context, index) {

          final stop = stopNamesWithTime[index];
          final PlateNumb = stop["PlateNumb"];

          final color = stop["color"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["color"] == '2'
              ? const Color.fromRGBO(225, 85, 104, 0.1)
              : (stop["color"] == "班次結束"
              ? const Color.fromRGBO(69, 69, 69, 0.1)
              :(stop["color"] == "min"
              ? const Color.fromRGBO(13, 168, 255, 0.1)
              : const Color.fromRGBO(68, 68, 68, 0.1))));

          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0, ), // 外邊距
              decoration: stop["isHighlighted"] == true
                  ? BoxDecoration(
                border: Border.all(
                  width: 1.6, // 邊框粗細
                  color: Colors.blue, // 高亮時邊框顏色
                ),
                borderRadius: BorderRadius.circular(10), // 圓角
              )
                  : BoxDecoration(
                border: Border.all(
                  width: 2, // 邊框粗細
                  color: Colors.transparent, // 非高亮時邊框為透明
                ),
                borderRadius: BorderRadius.circular(10), // 圓角
              ),
              height: 54.5, // 設置每個項目的固定高度
              child:ListTile(

                onTap: () {
                  _dialogBuilder(context,PlateNumb,    stop["stopName"],stop["Estimates"]);

                },
                leading: Container(

                  padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 6),
                  decoration: BoxDecoration(
                    color: color,

                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    stop["nextBusTime"]!,
                    style: TextStyle(
                        fontFamily: 'MiSans-normal',
                        fontSize: 17,
                        color: stop["color"] == '0'
                            ? Colors.white
                            : (stop["color"] == '2'
                            ? const Color.fromRGBO(255, 85, 104, 1)
                            : (stop["color"] == "班次結束"
                            ? const Color.fromRGBO(149, 149, 149, 1.0)
                            :(stop["color"] == "min"
                            ? const Color.fromRGBO(13, 168, 255, 1)
                            : const Color.fromRGBO(68, 68, 68, 1))))
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      stop["stopName"]!,
                      style: TextStyle(
                        fontFamily: stop["color"] == "0" ? 'MiSans-Semibold' : 'MiSans-normal',
                        fontSize: 17,
                        color: stop["color"] == "班次結束"
                            ? const Color.fromRGBO(136, 136, 136, 1)
                            : Colors.black,
                      ),
                    ),
                  if (stop["stopName"]!.contains("車站"))
          Padding(
            padding: const EdgeInsets.only(left: 6), // 添加左侧间距
            child: SvgPicture.asset(
              'assets/icons/Taiwan_Railways_Logo.svg', // 自定义SVG路径
              width: 18, // 设置SVG图标的宽度
              height: 18, // 设置SVG图标的高度
            ),
          )
          else if (stop["stopName"]!.contains("捷運"))
          Padding(
          padding: const EdgeInsets.only(left: 6), // 添加左侧间距
          child: SvgPicture.asset(
          'assets/icons/tc_MRT.svg', // 自定义SVG路径
          width: 18, // 设置SVG图标的宽度
          height: 18, // 设置SVG图标的高度
          ),
          ),// 如果 stopName 包含 "火車站"，添加火车图标
                  ],
                ),

                trailing: PlateNumb != null ? bubble(plateNum: PlateNumb) : null,

              ));
        }, separatorBuilder: (BuildContext context, int index) {
        return const Divider(
          color: Color.fromRGBO(231, 231, 231, 1), // 分隔線的顏色
          height: 9, // 分隔線與上下元素的間距
          thickness: 1, // 分隔線的粗細
          indent: 20, // 分隔線距離左側的間距
          endIndent: 20, // 分隔線距離右側的間距
        );


      },

      ),
    ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context, plateNumb,stopName,  estimates,) {

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 自适应内容的高度
              children: [
                Text(
                  stopName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20), // 添加间距
                Column(
                  children: [
                    _buildDialogOption(context, Icons.info, "下班車資訊","info",{'estimates':estimates}),
                    _buildDialogOption(context, Icons.schedule, "站牌查詢","stop",{"stop":stopName}),
                    _buildDialogOption(context, Icons.notifications, "到站通知","notification",{}),
                    _buildDialogOption(context, Icons.favorite, "加入收藏","favorite",{"id":stopName}),
                    _buildDialogOption(context, Icons.route, "路線規劃","route",{}),
                  ],
                ),
                const SizedBox(height: 20), // 添加间距
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭对话框
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: busBlue, // 设置按钮背景色
                  ),
                  child: const Text('關閉',

                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15


                    ),),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildDialogOption (BuildContext context, IconData icon, String title, String id,Map other) {
    return InkWell(
      onTap: () async {
        var output;
        // var stationComparison;
        // 在这里可以添加对应的功能

        if(id=="favorite"){
          favorite_feature dbHelper = favorite_feature(); // 创建实例

          final result = await dbHelper.addFavorite(StopName:other["id"]  ,city:"Taichung", table: 'FavoritesStop', routeID: null);

          // output=await  saveList('favoritesBusStop',other["id"] );
          // stationComparison=await  saveList('favoritesBusStopId',other["id"] );
          // 顯示相應的 QuickAlert
          if (result==100) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              text: output,
            );

          } else if (result==-1) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              text: output,
            );
          } else if (result==200) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Oops...',
              text: output,
            );
          }
        }else if(id=='info'){
          List<Map<String, dynamic>> estimates=[];


// 使用 jsonDecode 将 JSON 字符串转换为 Dart 对象
          if (other["estimates"] != 'null') {
            try {
              // 自动修正 JSON 字符串
              String correctedJsonString = other["estimates"]
                  .replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match[1]}":') // 为键添加双引号
                  .replaceAllMapped(RegExp(r'(\d+)(?=,|\})'), (match) => '${match[0]}') // 保留数字
                  .replaceAllMapped(RegExp(r'(\w+-\w+)'), (match) => '"${match[0]}"') // 为带连字符的值添加双引号
                  .replaceAllMapped(RegExp(r'\"(?!\d)') , (match) => '"') // 移除不必要的连字符

                  .replaceAllMapped(RegExp(r'\"(?!\w+-\w+)') , (match) => '"'); // 处理字符串带连字符的情况

              // 解析为 List<Map<String, dynamic>>
              estimates= List<Map<String, dynamic>>.from(jsonDecode(correctedJsonString));

              if (kDebugMode) {
                print("other" +other["estimates"]);
              }
            } catch (e) {
              print("Error decoding JSON: $e");
            }
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 2,
                  title: const Text(
                    "下班車資訊",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  iconTheme: const IconThemeData(color: Colors.black), // 设置返回图标颜色
                ),
                body: estimates.isNotEmpty
                    ? ListView.builder(
                  itemCount: estimates.length, // 項目數
                  itemBuilder: (context, index) {
                    final bus = estimates[index]; // 獲取當前項目資料
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2), // 微弱的阴影
                            blurRadius: 8,
                            offset: const Offset(0, 4), // 阴影偏移量
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_bus, color: Colors.blue),
                        ),
                        title: Text(
                          '公車 ${bus["PlateNumb"] ?? "未知"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '預估時間: ${((bus["EstimateTime"] ?? 0) / 60).round()} 分鐘',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: (bus["IsLastBus"] ?? false)
                            ? const Icon(Icons.warning, color: Colors.red)
                            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ),
                    );
                  },
                )
                    : const Center(
                  child: Text(
                    "目前沒有公車預估時間",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );


        }else if(id=="stop"){

          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BusStopInfo(other["stop"], city: widget.city,))
          );
        }else if(id=="map"){



        }

      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10), // 添加上下间距
        child: Row(
          children: [
            Icon(icon, color: busBlue), // 设置图标颜色
            const SizedBox(width: 10), // 添加间距
            Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}




class BusDetailPage extends StatefulWidget {
  final String routeId;
  final String city;

  const BusDetailPage({
    super.key,
    required this.routeId,
    required this.city,
  });

  @override
  State<BusDetailPage> createState() => _BusDetailPageState();
}

class _BusDetailPageState extends State<BusDetailPage> {
  List<Map<String, dynamic>>? allBuses; // 所有公車資料
  List<Map<String, dynamic>>? filteredBuses; // 過濾後的公車資料
  final TextEditingController searchController = TextEditingController(); // 搜尋框控制器

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      List<Map<String, dynamic>> data =
      await getHistoryData(widget.city, widget.routeId, sum!)?? [];
      setState(() {
        allBuses = data;
        filteredBuses = List.from(data); // 初始時顯示所有數據
      });
    } catch (e) {
      setState(() {
        allBuses = [];
        filteredBuses = [];
      });
    }
  }

  // 搜尋功能
  void search(String query) {
    if (allBuses == null) return;

    setState(() {
      filteredBuses = allBuses!
          .where((bus) => bus['StopName']['Zh_tw']
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose(); // 釋放搜尋框控制器
    super.dispose();
  }

  String formatTime(String gpsTime) {
    try {
      DateTime dateTime = DateTime.parse(gpsTime).toLocal(); // 解析並轉換為本地時間
      return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime); // 格式化輸出
    } catch (e) {
      return '時間格式錯誤';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('公車歷史資料'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 搜尋框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜尋站點名稱',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged: search, // 輸入時觸發搜尋
            ),
          ),
          // 資料列表
          Expanded(
            child: filteredBuses == null
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : filteredBuses!.isEmpty
                ? const Center(
              child: Text(
                '沒有符合的資料',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredBuses!.length,
              itemBuilder: (context, index) {
                final bus = filteredBuses![index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '公車號碼: ${bus['PlateNumb']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '路線: ${bus['RouteName']['Zh_tw']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '站點: ${bus['StopName']['Zh_tw']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '時間: ${formatTime(bus['GPSTime'])}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '方向: ${bus['Direction'] == 0 ? '去程' : '回程'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

