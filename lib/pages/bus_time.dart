import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:com.rsmn574.app/widget/bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Const/regularClass.dart';
import '../Const/regularConst.dart';
import '../database/SQL/favorite_feature.dart';
import '../database/bus/getBusTime.dart';
import '../database/getData.dart';
import '../task/task.dart';
import '../utils/convert.dart';
import '../widget/map.dart';
import 'busStopInfo.dart';
late String? nearestStop ;
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
int globalHighlightedIndex=0;
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

        markerId: MarkerId(stop['StopID']),
        position: LatLng(
          stop['StopPosition']['PositionLat'],
          stop['StopPosition']['PositionLon'],
        ),
        infoWindow: InfoWindow(
          title: stop['stopName'] ?? 'Unknown',
          snippet: stop['StopID'] ?? 'Unknown',
        ),
      );
      markers.add(marker);
    }
  }else   if(stopType=="stopNamesWithTime2"){

    for (var stop in stopNamesWithTime2) {


      final marker = Marker(
        markerId: MarkerId(stop['StopID']),
        position: LatLng(
          stop['StopPosition']['PositionLat'],
          stop['StopPosition']['PositionLon'],
        ),
        infoWindow: InfoWindow(
          title: stop['stopName'] ?? 'Unknown',
          snippet: stop['StopID'] ?? 'Unknown',
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

  Future<void> _loadData() async {
    try {
      // 🚍 下載站點與時間資料
      final List<Map<String, dynamic>> data = await GetBusInfo(
        city: widget.city,
        routeid: widget.routeID,
      );

      final routeInfo = [
        widget.routeName,
        widget.departureStopName,
        widget.destinationStopName,
      ];

      final busTimeData = await fetchBusTime(widget.routeName, widget.city);

      // 📌 包一個方法：主方向失敗時用備援方向
      Future<List<dynamic>> fetchStops(int primary, int fallback) async {
        final filterStops = (int dir) =>
            busTimeData.where((s) => s['Direction'] == dir).toList();

        try {
          return await fetchStopNamesWithTime(primary, filterStops(primary), data);
        } catch (_) {
          return await fetchStopNamesWithTime(fallback, filterStops(fallback), data);
        }
      }

      // 🔄 設定 Tab (根據 direction)
      final int? direction = widget.mark?.direction;
      if (direction != null) _tabController.animateTo(direction);

      // 📌 抓雙向資料
      stopNamesWithTime1 = await fetchStops(1, 0);
      stopNamesWithTime2 = await fetchStops(0, 1);

      final List<dynamic> stops = direction == 0 ? stopNamesWithTime1 : stopNamesWithTime2;
      final List<dynamic> nearStops = direction == 0 ? stopNamesWithTime2 : stopNamesWithTime1;

      // 📍 找最近站點
      int? nearestIndex;
      double? nearestDistance;
      try {
        final loc = Provider.of<LocationProvider>(context, listen: false);
        final userLat = loc.latitude, userLon = loc.longitude;

        double minDist = double.infinity;
        for (int i = 0; i < nearStops.length; i++) {
          final pos = nearStops[i]['StopPosition'];
          if (pos?['PositionLat'] != null && pos?['PositionLon'] != null) {
            final dist = calculateApproxDistance(
              userLat, userLon, pos['PositionLat'], pos['PositionLon'],
            );
            if (dist < minDist) {
              minDist = dist;
              nearestIndex = i;
            }
          }
        }

        if (nearestIndex != null && minDist <= 7000) {
          nearestStop = nearStops[nearestIndex]['stopName'];
          nearestDistance = minDist;
          if (kDebugMode) {
            print("📍 最近站點：$nearestStop，距離=${minDist.toStringAsFixed(1)}m");
          }
        } else {
          if (kDebugMode) print("❌ 沒有站點在 7 公里內");
        }
      } catch (e) {
        print("⚠️ 定位錯誤: $e");
      }

      // 🎯 滾動到 highlight 或最近站點
      void scrollTo(int index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(index);
        });
      }

      if (widget.mark?.highlight?.isNotEmpty ?? false) {
        final highlightStation = widget.mark!.highlight!.first;
        final stopNames = stops.map((e) => e["stopName"]).toList();
        final highlightedIndex = stopNames.indexOf(highlightStation);
        globalHighlightedIndex = highlightedIndex;

        if (highlightedIndex != -1) {
          scrollTo(highlightedIndex);
        } else {
          print("⚠️ 找不到 highlight 站點");
        }
      } else if (nearestIndex != null) {
        scrollTo(nearestIndex);
      }

      // ⏱ 啟動自動刷新
      if (isTimerOn.value) _startAutoReload();

      // 🗺 載入地圖標記
      _loadMarkers("stopNamesWithTime1");

      // 📢 通知 UI
      _dataNotifier.value = {
        'routeInfo': routeInfo,
        'stopNamesWithTime1': stopNamesWithTime1,
        'stopNamesWithTime2': stopNamesWithTime2,
      };
    } catch (e, s) {
      print("❌ _loadData 發生錯誤: $e\n$s");
    }
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
          isHighlighted = widget.mark!.highlight!.contains(stopName) && tabIndex != widget.mark!.direction;

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
               "StopID":stop['StopID'],
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
               "StopID":stop['StopID'],
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
             "StopID":stop['StopID'],
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
            "StopPosition":a[0]["StopPosition"]?? "" .toString(),
            "StopID":a[0]['StopID']};
        } else {
          int result = (a[0]["EstimateTime"] / 60).floor();


          isTimerOn.value=true;
            return {
              "time": result < 1 ? "即將到站" : "$result 分鐘",
              "color": result < 3 ? "2" : "min",
              "PlateNumb": result < 3 ?  a[0]["PlateNumb"] : "",
              "Estimates": a[0]["Estimates"],
              "StopPosition":a[0]["StopPosition"]?? "",
              "StopID":a[0]['StopID']
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
                "StopPosition":a[0]["StopPosition"]?? "",
                "StopID":a[0]['StopID']
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
              "StopPosition":a[0]["StopPosition"]?? "",
              "StopID":a[0]['StopID']
            };
          }

        } else {
          DateTime nextBusTime = DateTime.now().add(difference);
          return {
            "time": "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}",
            "color": '',
            "PlateNumb": "",
            "Estimates": a.isNotEmpty && a[0]["Estimates"] != null ? a[0]["Estimates"] : "",

            "StopPosition":a[0]["StopPosition"]?? "",
            "StopID":a[0]['StopID']
          };
        }
      } else {
        return {"time": "班次結束", "color": "班次結束", "PlateNumb": "","Estimates": a[0]["Estimates"],
          "StopPosition":a[0]["StopPosition"]?? "","StopID":a[0]['StopID']
};
      }
    }
    return {"time": "error", "color": "班次結束", "PlateNumb": "","Estimates":  "",

      "StopPosition": "", "StopID":''
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

// 美化彈出菜單項目
  PopupMenuItem<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 70,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A73E8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 美化開發中對話框
  void _showDevelopmentDialog(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    size: 30,
                    color: Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$featureName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '功能開發中',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '關閉',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A73E8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// 美化加入收藏功能
  Future<void> _addRouteToFavorites(List routeInfo) async {
    favorite_feature dbHelper = favorite_feature();

    final result = await dbHelper.addFavorite(
      DepartureStopNameZh: routeInfo[1],
      DestinationStopNameZh: routeInfo[2],
      routeName: routeInfo[0],
      city: "Taichung",
      routeID: widget.routeID,
      table: "FavoritesRoute",
    );

    // 顯示美化後的提示
    if (result == 100) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: '收藏成功',
        text: '${routeInfo[0]} 已加入收藏',
        confirmBtnColor: const Color(0xFF1A73E8),
        animType: QuickAlertAnimType.slideInUp,
      );
    } else if (result == -1) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: '已收藏',
        text: '${routeInfo[0]} 已在收藏列表中',
        confirmBtnColor: const Color(0xFFFF9500),
      );
    } else if (result == 200) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: '收藏失敗',
        text: '請稍後再試',
        confirmBtnColor: const Color(0xFFFF3B30),
      );
    }
  }

// 美化路線圖對話框
  void _showRouteMapDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    size: 30,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '路線圖',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Linkify(
                    onOpen: (link) async {
                      if (!await launchUrl(Uri.parse(link.url))) {
                        throw Exception('Could not launch ${link.url}');
                      }
                    },
                    text: widget.routeMapImageUrl,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w500,
                    ),
                    linkStyle: const TextStyle(
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          '關閉',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A73E8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// 導航到歷史時間頁面
  void _navigateToBusDetail() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BusDetailPage(
          routeId: widget.routeID.toString(),
          city: widget.city,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
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
                      backgroundColor: Colors.white,
                      elevation: 0,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                          color: const Color(0xFF1A73E8),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      title: Text(
                        routeInfo[0],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                          letterSpacing: -0.5,
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF3FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF1A73E8)),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                              _buildPopupMenuItem(
                                icon: Icons.info_outline_rounded,
                                title: '公車資訊',
                                subtitle: '查看詳細資訊',
                                value: 'A',
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.favorite_outline_rounded,
                                title: '加入收藏',
                                subtitle: '收藏此路線',
                                value: 'B',
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.map_rounded,
                                title: '路線圖',
                                subtitle: '查看路線地圖',
                                value: 'C',
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.history_rounded,
                                title: '歷史時間',
                                subtitle: '查看歷史班次',
                                value: 'D',
                              ),
                            ],
                            onSelected: (String action) async {
                              switch (action) {
                                case 'A':
                                  _showDevelopmentDialog('公車資訊');
                                  break;
                                case 'B':
                                  await _addRouteToFavorites(routeInfo);
                                  break;
                                case 'C':
                                  _showRouteMapDialog();
                                  break;
                                case 'D':
                                  _navigateToBusDetail();
                                  break;
                              }
                            },
                          ),
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
                              if (stopNamesWithTime1.isEmpty==false) _buildTabContent(stopNamesWithTime1),
                              if (stopNamesWithTime2.isEmpty==false) _buildTabContent(stopNamesWithTime2),
                            ],
                          ),

      )
                        ,
                        if (isTimerOn.value == false)
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700]!.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pause_circle_filled_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "已停止自動更新",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (isTimerOn.value == true)
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Center(
                              child: ValueListenableBuilder<int>(
                                valueListenable: remainingSecondsNotifier,
                                builder: (context, remainingTime, child) {
                                  final isWarning = remainingTime <= 10;

                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: (isWarning ? const Color(0xFFFF9500) : const Color(0xFF1A73E8)).withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isWarning ? Icons.warning_amber_rounded : Icons.autorenew_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "$remainingTime 秒",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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

  PreferredSize _buildTabBar(List routeInfo) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (stopNamesWithTime1.isNotEmpty)
              Expanded(
                child: _buildTabButton(
                  icon: Icons.directions_bus,
                  text: routeInfo[1],
                  isSelected: _tabController.index == 0,
                  onTap: () => _tabController.animateTo(0),
                ),
              ),
            if (stopNamesWithTime1.isNotEmpty && stopNamesWithTime2.isNotEmpty)
              const SizedBox(width: 12),
            if (stopNamesWithTime2.isNotEmpty)
              Expanded(
                child: _buildTabButton(
                  icon: Icons.swap_horiz,
                  text: routeInfo[2],
                  isSelected: _tabController.index == 1,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF3FB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
              color: const Color(0xFF1A73E8).withOpacity(0.3),
              width: 1.5,
            )
                : Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建每个 Tab 的内容
  Widget _buildTabContent(List stopNamesWithTime) {
    final List<GlobalKey> _itemKeys = [];
    return RefreshIndicator(

    onRefresh: () async {
      await _loadData(); // 刷新时重新加载数据
      _startAutoReload();
    },
    child: ListView.separated(
      padding: const EdgeInsets.only(bottom: 40), // ✅ 讓底部留空間
      controller: _scrollController,
      itemCount: stopNamesWithTime.length,
      itemBuilder: (context, index) {
        if (_itemKeys.length <= index) {
          _itemKeys.add(GlobalKey());
        }
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
            decoration:
               BoxDecoration(
              border: Border.all(
                width: 2,
                color: Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(10),
            ),

            height: 54.5, // 設置每個項目的固定高度
            child:ListTile(

              onTap: () {
                _dialogBuilder(context,PlateNumb,    stop["stopName"],stop["Estimates"],stop);

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
                      fontFamily: 'MiSans',
                      fontSize: stop["isHighlighted"] == true ? 18 : 17,
                      fontWeight: stop["isHighlighted"] == true
                          ? FontWeight.w900
                          : (stop["color"] == "0" ? FontWeight.w600 : FontWeight.normal),
                      color: stop["isHighlighted"] == true
                          ? Colors.blue[800]
                          : (stop["color"] == "班次結束"
                          ? const Color.fromRGBO(136, 136, 136, 1)
                          : Colors.black),
                      letterSpacing: stop["isHighlighted"] == true ? 1.0 : 0.5,
                      shadows: stop["isHighlighted"] == true
                          ? [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2.0,
                          color: Colors.blue.withOpacity(0.5),
                        )
                      ]
                          : [],
                    ),
                  ),
                  if (stop["stopName"] == nearestStop) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(13, 168, 255, 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color.fromRGBO(13, 168, 255, 0.6)),
                      ),
                      child: const Text(
                        '最近',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(13, 168, 255, 1),
                        ),
                      ),
                    ),
                  ],
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
        );
  }

  Future<void> _dialogBuilder(BuildContext context, plateNumb, stopName, estimates, stop) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題區域
                  _buildDialogHeader(stopName),
                  const SizedBox(height: 24),

                  // 選項列表
                  _buildDialogOptions(context, estimates, stopName, stop),
                  const SizedBox(height: 24),

                  // 關閉按鈕
                  _buildCloseButton(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(String stopName) {
    return Column(
      children: [
        // 圖標
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FB),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 30,
            color: Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(height: 16),
        // 站牌名稱
        Text(
          stopName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A73E8),
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // 副標題
        Text(
          '公車站牌選項',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogOptions(BuildContext context, estimates, stopName, stop) {
    return Column(
      children: [
        _buildDialogOption(
          context: context,
          icon: Icons.schedule_outlined,
          title: "下班車資訊",
          subtitle: "查看預計到站時間",
          type: "info",
          data: {'estimates': estimates},
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.place_outlined,
          title: "站牌查詢",
          subtitle: "查看詳細站牌資訊",
          type: "stop",
          data: {"stop": stopName},
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.notifications_outlined,
          title: "到站通知",
          subtitle: "設定公車到站提醒",
          type: "notification",
          data: stop,
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.favorite_outline,
          title: "加入收藏",
          subtitle: "收藏此站牌",
          type: "favorite",
          data: {"id": stopName},
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.route_outlined,
          title: "路線規劃",
          subtitle: "規劃乘車路線",
          type: "route",
          data: {},
        ),
      ],
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String type,
    required Map<String, dynamic> data,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleOptionTap(context, type, data),
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
        highlightColor: const Color(0xFFEEF3FB),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 圖標
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 16),
              // 文字內容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 箭頭
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1A73E8).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Text(
              '關閉',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

// 處理選項點擊
  void _handleOptionTap(BuildContext context, String type, Map<String, dynamic> data) {
    switch (type) {
      case "info":
      // 處理下班車資訊
        _showNextBusInfo(context, data['estimates']);
        break;
      case "stop":
      // 處理站牌查詢
        _navigateToStopInfo(context, data['stop']);
        break;
      case "notification":
      // 處理到站通知
        _setupArrivalNotification(context, data);
        break;
      case "favorite":
      // 處理加入收藏
        _addToFavorites(context, data['id']);
        break;
      case "route":
      // 處理路線規劃
        _navigateToRoutePlanning(context);
        break;
    }
  }

// 範例方法 - 您需要根據實際情況實現
  void _showNextBusInfo(BuildContext context, estimates) {
    List<Map<String, dynamic>> estimatesList=[];


// 使用 jsonDecode 将 JSON 字符串转换为 Dart 对象
    if (estimatesList != 'null') {
      try {
        // 自动修正 JSON 字符串
        String correctedJsonString = estimates
            .replaceAllMapped(RegExp(r'(\w+):'), (match) => '"${match[1]}":') // 为键添加双引号
            .replaceAllMapped(RegExp(r'(\d+)(?=,|\})'), (match) => '${match[0]}') // 保留数字
            .replaceAllMapped(RegExp(r'(\w+-\w+)'), (match) => '"${match[0]}"') // 为带连字符的值添加双引号
            .replaceAllMapped(RegExp(r'\"(?!\d)') , (match) => '"') // 移除不必要的连字符

            .replaceAllMapped(RegExp(r'\"(?!\w+-\w+)') , (match) => '"'); // 处理字符串带连字符的情况

        // 解析为 List<Map<String, dynamic>>
        estimatesList= List<Map<String, dynamic>>.from(jsonDecode(correctedJsonString));

        if (kDebugMode) {
          print("other" + estimates);
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
          body: estimatesList.isNotEmpty
              ? ListView.builder(
            itemCount: estimatesList.length, // 項目數
            itemBuilder: (context, index) {
              final bus = estimatesList[index]; // 獲取當前項目資料
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



    // 然後顯示下班車資訊
  }

  void _navigateToStopInfo(BuildContext context, String stopName) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BusStopInfo(stopName, city: widget.city,))
    );
    // 導航到站牌詳細資訊頁面
  }

  Future<void> _setupArrivalNotification(BuildContext context, stop) async {
    Navigator.of(context).pop();
    // 設定到站通知
    await startReminder(
    transportType: 'bus',
    routeName: widget.routeName,
    routeID: widget.routeID.toString(),
    city: widget.city,
    stopID: stop["StopID"],
    UserStartingStopName:'',
    UserDestinationStopName: stop["stopName"],
    );


  }

  Future<void> _addToFavorites(BuildContext context, String stopId) async {
    favorite_feature dbHelper = favorite_feature(); // 创建实例
    var output;
    final result = await dbHelper.addFavorite(StopName:stopId  ,city:"Taichung", table: 'FavoritesStop', routeID: null);

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

    // 加入收藏邏輯
  }

  void _navigateToRoutePlanning(BuildContext context) {
    Navigator.of(context).pop();
    // 導航到路線規劃頁面
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

