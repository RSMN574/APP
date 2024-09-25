import 'dart:convert';
import 'package:flutter/material.dart';

import '../Const/regularConst.dart';
import '../database/getBusTime.dart';
import '../database/getData.dart';

class BusTime extends StatefulWidget {
  const BusTime({Key? key}) : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次依赖变化时重新加载数据
    _dataFuture = _loadData();
  }

  // 加载数据，包括站名和 NextBusTime
  Future<Map<String, dynamic>> _loadData() async {
    final routeInfo = ModalRoute.of(context)!.settings.arguments as List;
  final busTimeData=  await fetchBusTime(routeInfo[0], "Taichung");
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
        print(nextBusTime["isRed"]);
        stopNamesWithTime.add({
          "stopName": stopName,
          "nextBusTime": nextBusTime["time"],
       'isRed':nextBusTime["isRed"]
        });
      }
    }

    print(stopNamesWithTime);
    return stopNamesWithTime;
  }
Future<Map<String, dynamic>> getTimeList(StopName,BusTimeData) async{

List a= await BusTimeData.where((stop) => stop['StopName']["Zh_tw"] == StopName).toList();


if(a[0]["EstimateTime"] !=null){
  if(a[0]["EstimateTime"] ==0) {
    return {"time": "即將到站", "isRed": 'red'};

  }else{
    int result=(a[0]["EstimateTime"] / 60).floor();
    return {"time": "$result分鐘", "isRed": result < 2 ? "red" : "" };;
  }


}else if(a[0]["NextBusTime"] !=null){
  Duration difference =DateTime.parse(a[0]["NextBusTime"]).difference(DateTime.now());
  if(difference.inHours==0){
    return {"time": "${difference.inMinutes.remainder(60)}分鐘", "isRed": ''};

  }else {
    Duration duration = Duration(hours: difference.inHours,minutes:difference.inMinutes.remainder(60) ); // 設定要加上的時間長度

    DateTime NextBusTime = DateTime.now().add(duration);
    return {'time':"${NextBusTime.hour.toString().padLeft(2, '0')}:${NextBusTime.minute.toString().padLeft(2, '0')}", "isRed": ''};

  }

}else{
  return {"time": "班次結束", "isRed": ''};
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
              elevation: 0,
              title: Text(
                routeInfo[0],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

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
          print(stop["isRed"]);
         final  isRed = stop["isRed"]=="red" ?  Color.fromRGBO(235,15,41,0.85) :  Colors.white;
          return
            ListTile(
                leading:Container(
padding: const EdgeInsets.all(9),

          decoration: BoxDecoration(
      color:isRed,
            border: Border.all(width: 1.0, color: stop["isRed"]=="red" ?  Color.fromRGBO(235,15,41,0.89)  :  busBlue),
          borderRadius: BorderRadius.circular(16),),
                  child: Text(
                    stop["nextBusTime"]!,

                    style: TextStyle(
                        fontSize: 18,
                        color: stop["isRed"]=="red" ?  Colors.white :  Color.fromRGBO(90,101,107,1)),
                  ),
                ) ,
                title: Text(
                  stop["stopName"]!,
                  style: TextStyle(fontSize: 18, color: Color.fromRGBO(77,77,77,1)),
                ),


              );




        },
      ),




    );
  }
}
