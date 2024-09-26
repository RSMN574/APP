import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../Const/regularConst.dart';
import '../database/getBusTime.dart';
import '../database/getData.dart';
import '../widget/bubble.dart';

class BusTime extends StatefulWidget {
  final routeName;
  final departureStopName;
  final destinationStopName;
  const BusTime({Key? key,this.routeName ,this.departureStopName, this.destinationStopName}) : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime> {
  Timer? _timer;
  late Future<Map<String, dynamic>> _dataFuture;
  @override
  void initState() {
    super.initState();
 _dataFuture = _loadData();

    // _startAutoReload();
  }

  // @override
  // void dispose() {
  //   _timer?.cancel();  // 銷毀時取消定時器
  //   super.dispose();
  // }

  // 啟動定時器，每 1 分鐘觸發一次
  // void _startAutoReload() {
  //   _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
  //     print(60);
  //     setState(() {
  //       _dataFuture = _loadData(); // 重新加载数据
  //     });
  //   });
  // }
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // _startAutoReload();
  //   // 每次依赖变化时重新加载数据
  //   _dataFuture = _loadData();
  // }

  // 加载数据，包括站名和 NextBusTime
  Future<Map<String, dynamic>> _loadData() async {
    final routeInfo = [widget.routeName,widget.departureStopName,widget.destinationStopName];
  final busTimeData=  await fetchBusTime(widget.routeName.toString(), "Taichung");
  print(busTimeData);
    final stopNamesWithTime1 = await fetchStopNamesWithTime(1, busTimeData.where((stop) => stop['Direction'] == 1).toList());
    final stopNamesWithTime2 = await fetchStopNamesWithTime(0,  busTimeData.where((stop) => stop['Direction'] == 0).toList());
    return {
      'routeInfo': routeInfo,
      'stopNamesWithTime1': stopNamesWithTime1,
      'stopNamesWithTime2': stopNamesWithTime2,
    };
  }

  // 获取每个站的站名和 NextBusTime
  Future<List<Map<String, String>>> fetchStopNamesWithTime(int tabIndex,BusTimeData) async {
    List stops = await getInfo("routeInfo");
    List<Map<String, String>> stopNamesWithTime = [];

    if (tabIndex < stops.length) {
      var stopData = json.decode(stops[tabIndex]["Stops"]);
      for (var stop in stopData) {
        String stopName = stop["StopName"]["Zh_tw"];
        Map nextBusTime = await getTimeList(stopName,BusTimeData); // 如果没有 NextBusTime，显示“尚無此車”

        stopNamesWithTime.add({
          "stopName": stopName,
          "nextBusTime": nextBusTime["time"],
       'isRed':nextBusTime["isRed"],
        "PlateNumb": nextBusTime["PlateNumb"]
        });

      }
    }


    return stopNamesWithTime;
  }
Future<Map<String, dynamic>> getTimeList(StopName,BusTimeData) async{

List a= await BusTimeData.where((stop) => stop['StopName']["Zh_tw"] == StopName).toList();



if(a[0]["EstimateTime"] !=null ){
  if(a[0]["EstimateTime"] ==0) {
    List PlateNumb = [];

      for (var estimate in a[0]['Estimates']) {

        PlateNumb.add(estimate["PlateNumb"]); // 将每个 estimate 转换为字符串，并拼接到 PlateNumb 中


    }

    return {"time": "即將到站", "isRed": '0' ,"PlateNumb": PlateNumb.toString() };

  }else{
    int result=(a[0]["EstimateTime"] / 60).floor();

    List PlateNumb = [];
    for (var estimate in a[0]['Estimates']) {

      PlateNumb.add(estimate["PlateNumb"]); // 将每个 estimate 转换为字符串，并拼接到 PlateNumb 中
    }


    return {
      "time": result < 1 ? "即將到站" : "$result 分鐘",
      "isRed": result < 3 ? "2" : "",
      "PlateNumb": result < 20 ? PlateNumb.toString() : ""
    };
  }


}else if(a[0]["NextBusTime"] !=null ){
  Duration difference =DateTime.parse(a[0]["NextBusTime"]).difference(DateTime.now());

  if(difference.inHours==0){
    return {
      "time": difference.inMinutes.remainder(60) <= 0
          ?  "班次結束"
          : "${difference.inMinutes.remainder(60)} 分鐘",
      "isRed": '',
      "PlateNumb": ""
    };

  }else {
    Duration duration = Duration(hours: difference.inHours,minutes:difference.inMinutes.remainder(60) ); // 設定要加上的時間長度

    DateTime NextBusTime = DateTime.now().add(duration);
    return {'time':"${NextBusTime.hour.toString().padLeft(2, '0')}:${NextBusTime.minute.toString().padLeft(2, '0')}", "isRed": '',"PlateNumb":""};

  }

}else{
  return {"time": "班次結束", "isRed": '',"PlateNumb":""};
  }

}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // if (snapshot.hasError) {
        //   return Scaffold(
        //     body: Center(child: Text('发生错误: ${snapshot.error}')),
        //   );
        // }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('無法加載數據')),
          );
        }
        final data = snapshot.data!;
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
                icon: Icon(Icons.arrow_back,color: Colors.white,), // 返回图标
                onPressed: () {
                  Navigator.pop(context); // 返回上一个页面
                },
              ),
              title: Text(
                routeInfo[0],
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),actions: [
              IconButton(
                icon: Icon(Icons.more_vert,color: Colors.white,),
                onPressed: () {
                  // 添加更多选项功能
                  print('更多按钮被点击');
                },
              ),
                
            ],

              bottom: _buildTabBar(routeInfo),
            ),
            body: Container (
              color: bgColorWhite,
              child:TabBarView(

              children: [
                _buildTabContent(stopNamesWithTime1), // Tab for direction 0
                _buildTabContent(stopNamesWithTime2), // Tab for direction 1
              ],
            ),)
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
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 16),
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
        setState(() {
          _dataFuture = _loadData(); // 刷新时重新加载数据
        });
      },
      child:ListView.builder(

        itemCount: stopNamesWithTime.length,
        itemBuilder: (context, index) {
          final stop = stopNamesWithTime[index];
           final PlateNumb=stop["PlateNumb"];
           // final hasPlateNumb=PlateNumb.isNotEmpty;
         final  isRed = stop["isRed"]== '0' ? Color.fromRGBO(235,15,41,0.85) : ( stop["isRed"] == '2' ? Color.fromRGBO(235,15,41,0.3) : Colors.white);

              return ListTile(
                onTap: () {
                  _dialogBuilder(context,PlateNumb,    stop["stopName"]);
                },
                leading: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isRed,
                    border: Border.all(
                      width: 1.0,
                      color: stop["isRed"] == '0'
                          ? Color.fromRGBO(235, 15, 41, 0.85)
                          : (stop["isRed"] == '2'
                          ? Color.fromRGBO(235, 15, 41, 0.35)
                          : busBlue),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    stop["nextBusTime"]!,
                    style: TextStyle(
                      fontFamily: 'MiSans-Semibold',
                      fontSize: 18,
                      color: stop["isRed"] == '0'
                          ? Colors.white
                          : (stop["isRed"] == '2' ? Color.fromRGBO(235,15,41,0.7) : Color.fromRGBO(90, 107, 107, 1)),
                    ),
                  ),
                ),
                title: Text(
                  stop["stopName"]!,
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


              )
              ;












        },
      ),




    );
  }
}
Future<void> _dialogBuilder(BuildContext context, plateNumb,stopName) {
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20), // 添加间距
              Column(
                children: [

                  _buildDialogOption(context, Icons.schedule, "發車時刻表"),
                  _buildDialogOption(context, Icons.notifications, "到站通知"),
                  _buildDialogOption(context, Icons.favorite, "加入收藏"),
                  _buildDialogOption(context, Icons.route, "路線規劃"),
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
Widget _buildDialogOption(BuildContext context, IconData icon, String title) {
  return InkWell(
    onTap: () {
      // 在这里可以添加对应的功能
      print('$title 被点击了');
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