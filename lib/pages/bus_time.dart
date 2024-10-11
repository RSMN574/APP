import 'dart:async';
import 'dart:convert';
import 'package:com.rsmn574.app/widget/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Const/regularConst.dart';
import '../database/getBusTime.dart';
import '../database/getData.dart';
import '../database/shared_perferences.dart';


class BusTime extends StatefulWidget {
  final routeName;
  final departureStopName;
  final destinationStopName;
  final operators;
  final routeMapImageUrl;
  const BusTime({Key? key, this.routeName, this.departureStopName, this.destinationStopName, this.operators,this.routeMapImageUrl})
      : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime> {
  Timer? _timer;
  late Future<Map<String, dynamic>> _dataFuture;
  final ValueNotifier<Map<String, dynamic>?> _dataNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _loadData(); // 初始加载数据
    _startAutoReload(); // 开始定时器
  }

  // 定义自动更新数据的方法
  void _startAutoReload() {
    _timer = Timer.periodic(Duration(seconds: 20), (timer) {
      _loadData(); // 每20秒更新数据
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 停止定时器，避免内存泄漏
    super.dispose();
  }

  // 加载数据，包括站名和 NextBusTime
  Future<void> _loadData() async { //stop data
    final routeInfo = [widget.routeName, widget.departureStopName, widget.destinationStopName];
    final busTimeData = await fetchBusTime(widget.routeName.toString(), "Taichung");
    print(busTimeData);
    final stopNamesWithTime1 = await fetchStopNamesWithTime(1, busTimeData.where((stop) => stop['Direction'] == 1).toList());
    final stopNamesWithTime2 = await fetchStopNamesWithTime(0, busTimeData.where((stop) => stop['Direction'] == 0).toList());

    // 更新数据时只更新 ValueNotifier
    _dataNotifier.value = {
      'routeInfo': routeInfo,
      'stopNamesWithTime1': stopNamesWithTime1,
      'stopNamesWithTime2': stopNamesWithTime2,
    };
  }

  // 获取每个站的站名和 NextBusTime
  Future<List<Map<String, String>>> fetchStopNamesWithTime(int tabIndex, List<dynamic> busTimeData) async {
    List stops = await getInfo("routeInfo");
    List<Map<String, String>> stopNamesWithTime = [];
    String hasPlateNum="";
    if (tabIndex < stops.length) {
      var stopData = json.decode(stops[tabIndex]["Stops"]);
      for (var stop in stopData) {
        String stopName = stop["StopName"]["Zh_tw"];

        Map<String, dynamic> nextBusTime = await getTimeList(stopName, busTimeData); // 如果没有 NextBusTime，显示“尚無此車”


         if(nextBusTime["PlateNumb"]!=''){

           if(hasPlateNum!=nextBusTime["PlateNumb"]){
             hasPlateNum=nextBusTime["PlateNumb"];
             stopNamesWithTime.add({
               "stopName": stopName,
               "nextBusTime": nextBusTime["time"],
               'color': nextBusTime["color"],
               "PlateNumb": nextBusTime["PlateNumb"],
               "Estimates":nextBusTime["Estimates"].toString()
             });
           }else{
             stopNamesWithTime.add({
               "stopName": stopName,
               "nextBusTime": nextBusTime["time"],
               'color': nextBusTime["color"],
               "PlateNumb": '',
               "Estimates":nextBusTime["Estimates"].toString()
             });
           }

       }else{
           print(nextBusTime["Estimates"]);
           stopNamesWithTime.add({
             "stopName": stopName,
             "nextBusTime": nextBusTime["time"],
             'color': nextBusTime["color"],
             "PlateNumb": '',
             "Estimates":nextBusTime["Estimates"].toString()
           });
             }

      }
    }

    return stopNamesWithTime;
  }

  Future<Map<String, dynamic>> getTimeList(String stopName, List<dynamic> busTimeData) async {
    List<dynamic> a = busTimeData.where((stop) => stop['StopName']["Zh_tw"] == stopName).toList();

    if (a.isNotEmpty) {
      if (a[0]["EstimateTime"] != null) {
        if (a[0]["EstimateTime"] == 0) {
          String plateNumb = a[0]["PlateNumb"];

          return {"time": "即將到站", "color": '0', "PlateNumb": plateNumb,"Estimates": a[0]["Estimates"]};
        } else {
          int result = (a[0]["EstimateTime"] / 60).floor();



            return {
              "time": result < 1 ? "即將到站" : "$result 分鐘",
              "color": result < 3 ? "2" : "min",
              "PlateNumb": result < 3 ?  a[0]["PlateNumb"] : "",
              "Estimates": a[0]["Estimates"]
            };


        }
      } else if (a[0]["NextBusTime"] != null) {
        Duration difference = DateTime.parse(a[0]["NextBusTime"]).difference(DateTime.now());

        if (difference.inHours == 0) {
          if(difference.inMinutes.remainder(60)<3 && difference.inMinutes.remainder(60)>0){



              return {


                "time": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "${difference.inMinutes.remainder(60)} 分鐘",
                "color": '2',
                "PlateNumb": a[0]["PlateNumb"],
                "Estimates": a[0]["Estimates"]
              };


          }else{

            return {


              "time": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "${difference.inMinutes.remainder(60)} 分鐘",
              "color":  difference.inMinutes.remainder(60) <= 0 ? "班次結束" :"min",
            "PlateNumb": "",
              "Estimates": a[0]["Estimates"]
            };
          }

        } else {
          DateTime nextBusTime = DateTime.now().add(difference);
          return {
            "time": "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}",
            "color": '',
            "PlateNumb": "",
            "Estimates": a[0]["Estimates"]
          };
        }
      } else {
        return {"time": "班次結束", "color": "班次結束", "PlateNumb": "","Estimates": a[0]["Estimates"]};
      }
    }
    return {"time": "班次結束", "color": "班次結束", "PlateNumb": "","Estimates": a[0]["Estimates"]};
  }
// 返回每个隐藏的菜单项
  SelectView(IconData icon, String text, String id) {
    return new PopupMenuItem<String>(
        value: id,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new Icon(icon, color: busBlue),
            new Text(text),
          ],
        )
    );
  }


  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<Map<String, dynamic>?>(
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

        return DefaultTabController(
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
               new PopupMenuButton<String>(
            iconColor:   Colors.white,
                  itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    this.SelectView(Icons.info, '公車資訊', 'A'),
                    this.SelectView(Icons.add, '加入收藏', 'B'),
                    this.SelectView(Icons.schedule, '發車時刻表', 'C'),
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

                        var output=await    saveList("favoritesBusRoute",'{"route":"${routeInfo[0]}","DepartureStopNameZh":"${routeInfo[1]}","DestinationStopNameZh":"${routeInfo[2]}"}');

                        // stationComparison=await  saveList('favoritesBusStopId',other["id"] );
                        // 顯示相應的 QuickAlert
                        if (output.contains('已儲存項目')) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            text: '${routeInfo[0]}已儲存項目',
                          );
                        } else if (output.contains('已存在於列表中，不會重複添加')) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.warning,
                            text: '${routeInfo[0]}已存在於列表中，不會重複添加',
                          );
                        } else if (output.contains('儲存項目時發生錯誤')) {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.error,
                            title: 'Oops...',
                            text: '儲存項目時發生錯誤',
                          );
                        }


                        break;
                      case 'C':
                        print(widget.routeMapImageUrl);


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
                    }
                  },
                ),
              ],
              bottom: _buildTabBar(routeInfo),
            ),
            body: Container(
              color: bgColorWhite,
              child: TabBarView(
                children: [
                  _buildTabContent(stopNamesWithTime1), // Tab for direction 0
                  _buildTabContent(stopNamesWithTime2), // Tab for direction 1
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建 TabBar
  PreferredSize _buildTabBar(List routeInfo) {
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
    return RefreshIndicator(
      onRefresh: () async {
        await _loadData(); // 刷新时重新加载数据
      },
      child: ListView.separated(

        itemCount: stopNamesWithTime.length,
        itemBuilder: (context, index) {

          final stop = stopNamesWithTime[index];
          final PlateNumb = stop["PlateNumb"];
          print(stop["Estimates"]);
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
              height: 53.0, // 設置每個項目的固定高度
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
            title: Text(
              stop["stopName"]!,
              style: TextStyle(
                fontFamily: stop["color"]=="0"?'MiSans-Semibold':'MiSans-normal',
                fontSize: 17,
                color: stop["color"]=="班次結束"? const Color.fromRGBO(136, 136, 136, 1):Colors.black
              ),
            ),
            trailing: bubble(plateNum: PlateNumb),
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
                    _buildDialogOption(context, Icons.info, "資訊","info",{'estimates':estimates}),
                    _buildDialogOption(context, Icons.schedule, "發車時刻表","time",{}),
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
}
Widget _buildDialogOption (BuildContext context, IconData icon, String title, String id,Map other) {
  return InkWell(
    onTap: () async {
      var output;
      // var stationComparison;
      // 在这里可以添加对应的功能

      if(id=="favorite"){
        output=await  saveList('favoritesBusStop',other["id"] );
        // stationComparison=await  saveList('favoritesBusStopId',other["id"] );
        // 顯示相應的 QuickAlert
        if (output.contains('已儲存項目')) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: output,
          );
        } else if (output.contains('已存在於列表中，不會重複添加')) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.warning,
            text: output,
          );
        } else if (output.contains('儲存項目時發生錯誤')) {
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

            print("other" +other["estimates"]);
          } catch (e) {
            print("Error decoding JSON: $e");
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                backgroundColor: busBlue,
                elevation: 0,
                title: const Text(
                  "資訊",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              body: estimates.isNotEmpty // 使用 .isNotEmpty 判断列表是否为空
                  ? ListView.builder(
                itemCount: estimates.length, // 项目数
                itemBuilder: (context, index) {
                  final bus = estimates[index]; // 获取当前项目数据
                  return ListTile(
                    leading: Icon(Icons.directions_bus),
                    title: Text('Bus ${bus["PlateNumb"] ?? "Unknown"}'),
                    subtitle: Text('Estimate Time: ${((bus["EstimateTime"] ?? 0) / 60).round()} 分鐘'),
                    trailing: (bus["IsLastBus"] ?? false)
                        ? Icon(Icons.warning, color: Colors.red) // 最后一班车的标记
                        : null,
                  );
                },
              )
                  : const Center(
                child: Text("No bus estimates available."),
              ),
            ),
          ),
        );
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
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    ),
  );
}