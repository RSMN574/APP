import 'dart:convert';

import 'package:com.rsmn574.app/pages/train/TrainSchedule.dart';
import 'package:com.rsmn574.app/widget/SelectView.dart';
import 'package:com.rsmn574.app/widget/train/StationDialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Const/regularConst.dart';
import 'database/getData.dart';
import 'database/getTrain.dart';

class Train extends StatefulWidget {
  @override
  _TrainState createState() => _TrainState();
}

class _TrainState extends State<Train> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _trainNoController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _stationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trainNoController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    _stationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 白色背景
      appBar: AppBar(
        title: const Text('火車查詢系統', style: TextStyle(color: Colors.black)), // 黑色文字
        backgroundColor: Colors.white, // 白色背景
        elevation: 2, // 微弱阴影效果
        iconTheme: const IconThemeData(color: Colors.black), // 使图标为黑色
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '按車次查詢'),
            Tab(text: '按出發地和目的地查詢'),
            Tab(text: '按車站查詢'),
          ],
          labelColor: Colors.black, // 选中的标签文字为黑色
          unselectedLabelColor: Colors.grey, // 未选中的标签文字为灰色
          indicatorColor: Colors.black, // 指示器颜色为黑色
        ),actions: [   PopupMenuButton<String>(
        iconColor:   Colors.black,
        itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
          SelectView( icon: Icons.train, text: '線路資訊', id: 'line',),

        ],
        onSelected: (String action) async {
          // 点击选项的时候
          switch (action) {
            case "line":
              Navigator.push(
                context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        elevation: 3, // 增加微弱阴影效果
                        backgroundColor:blue, // 设置背景色
                        title: const Text(
                          "線路資訊",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        centerTitle: true, // 标题居中
                      ),
                      body: FutureBuilder(
                        future: mysqlSelect("SELECT * FROM Train.Train_Line;"), // 异步加载数据
                        builder: (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(), // 显示加载中状态
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "加载失败: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            );
                          } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                            return const Center(
                              child: Text(
                                "没有数据",
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            );
                          } else {
                            var lineData = snapshot.data as List;
                            return Container(
                              color: Colors.white, // 背景色为白色
                              child: ListView.builder(
                                itemCount: lineData.length,
                                itemBuilder: (context, index) {
                                  var line = lineData[index];
                                  var lineNameZh = line['LineNameZh'] ?? '未知';
                                  var lineNameEn = line['LineNameEn'] ?? 'Unknown';
                                  var sectionNameZh = line['LineSectionNameZh'] ?? '未知區間';

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12), // 圆角效果
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05), // 微弱阴影效果
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        lineNameZh,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "$lineNameEn\n區間: $sectionNameZh",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );

                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  )

              );
              break;

          }
        },
      ),],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TripNumberSearchPage(controller: _trainNoController),
          RouteSearchPage(
            departureController: _departureController,
            destinationController: _destinationController,
          ),
          StationSearchPage(controller: _stationController),
        ],
      ),
    );

  }
}

class TripNumberSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const TripNumberSearchPage({Key? key, required this.controller}) : super(key: key);

  @override
  _TripNumberSearchPageState createState() => _TripNumberSearchPageState();
}

class _TripNumberSearchPageState extends State<TripNumberSearchPage> {
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 車次輸入框
              TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  labelText: '輸入車次',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // 日期選擇按鈕
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  selectedDate == null
                      ? '選擇日期'
                      : '選擇日期: ${dateFormat.format(selectedDate!)}',
                  style: const TextStyle(fontSize: 16, color: Colors.black), // 黑色文字
                ),
              ),
              const SizedBox(height: 16),
              // 查詢按鈕
              ElevatedButton(
                onPressed: () async {
                  // 查詢邏輯
                  var trainData = await fetchTrain(
                    int.parse(widget.controller.text),
                    selectedDate!,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainSchedulePage(
                        trainData: trainData,
                        type: 'trainNo',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black, // 白色文字
                ),
                child: const Text('查詢'),
              ),
            ],
          ),
        ),
      );

  }
}

class RouteSearchPage extends StatefulWidget {
  final TextEditingController departureController;
  final TextEditingController destinationController;

  const RouteSearchPage({
    Key? key,
    required this.departureController,
    required this.destinationController,
  }) : super(key: key);

  @override
  _RouteSearchPageState createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  // 定義縣市和站名選擇
  String? selectedCity;
  late Map<String, dynamic> departureSelectedStation;
  late Map<String, dynamic> destinationSelectedStation;
  // 縣市和對應站名資料
  final Map<String, List<String>> stationData = {
    '台北市': ['台北車站', '松山車站', '板橋車站'],
    '新北市': ['中和車站', '新莊車站', '蘆洲車站'],
    '高雄市': ['高雄車站', '鳳山車站', '新左營車站'],
  };
   DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH時mm分');

  Future<void> _selectDateTime(BuildContext context) async {
    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // 选择时间
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        // 合并日期和时间
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          print(selectedDate);
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 出發地輸入框
            TextField(
              controller: widget.departureController,
              decoration: const InputDecoration(
                labelText: '出發地',
                border: OutlineInputBorder(),
              ),onTap: () async {

              departureSelectedStation = (await StationDialog.showStationDialog(context))!;
              widget.departureController.text = departureSelectedStation['StationName']['Zh_tw']; // 將選擇的車站名稱顯示在輸入框中

            },
            ),
            const SizedBox(height: 16),
            // 目的地輸入框
            TextField(
              controller: widget.destinationController,
              decoration: const InputDecoration(
                labelText: '目的地',
                border: OutlineInputBorder(),
              ),    onTap: () async {

              destinationSelectedStation = (await StationDialog.showStationDialog(context))!;
              if(widget.departureController.text== destinationSelectedStation['StationName']['Zh_tw']){
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('出發地和目的地不能相同')),
                );
              }
              widget.destinationController.text = destinationSelectedStation['StationName']['Zh_tw']; // 將選擇的車站名稱顯示在輸入框中

            },
            ),
            const SizedBox(height: 16),
            // 日期選擇按鈕
            TextButton(
              onPressed: () => _selectDateTime(context),
              child: Text(
                selectedDate == null
                    ? '選擇時間'
                    : '選擇時間: ${dateFormat.format(selectedDate!)}',
                style: const TextStyle(fontSize: 16, color: Colors.black), // 黑色文字
              ),
            ),
            const SizedBox(height: 16),
            // 查詢按鈕
            ElevatedButton(
              onPressed: () {
                // 查詢邏輯
                if(selectedDate != null){

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutePage(departure:departureSelectedStation,destination:destinationSelectedStation,date: selectedDate!),
                    ),
                  );
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請選擇日期'))
                  );
                }


              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black, // 白色文字
              ),
              child: const Text('查詢'),
            ),
          ],
        ),
      ),
    );
  }
 
}

class StationSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const StationSearchPage({Key? key, required this.controller}) : super(key: key);

  @override
  _StationSearchPageState createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  } final TextEditingController _controller = TextEditingController();


  final Map<String, List<String>> stations = {
    '台北市': ['台北車站', '大安站', '松山站'],
    '新北市': ['板橋車站', '新店站', '淡水站'],
    '桃園市': ['桃園車站', '中壢站', '機場站'],
    '台中市': ['台中車站', '豐原站', '后里站'],
    '台南市': ['台南車站', '新營站', '善化站'],
    '高雄市': ['高雄車站', '左營站', '楠梓站'],
  };
  String? selectedCity;

  Map<String, dynamic>? selectedStation;






  @override
  Widget build(BuildContext context) {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 輸入車站名稱 TextField
            TextField(
              controller: _controller,
              readOnly: true, // 避免直接編輯，強制使用彈窗選擇
              decoration: InputDecoration(
                labelText: '輸入車站名稱',
                labelStyle: TextStyle(color: Colors.black), // 標籤文字為黑色
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // 圓角邊框
                ),
                filled: true,
                fillColor: Colors.white, // 背景顏色為白色
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onTap: () async {

                selectedStation = await StationDialog.showStationDialog(context);
                if (selectedStation != null) {
                  _controller.text = selectedStation?['StationName']['Zh_tw']; // 將選擇的車站名稱顯示在輸入框中
                }
  
              },
            ),
            const SizedBox(height: 16),

            // 查詢按鈕
            ElevatedButton(
              onPressed: () {

                // 查詢邏輯
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StationPage(stationName:selectedStation?['StationName']['Zh_tw'] , stationID: selectedStation?["StationID"]),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 藍色背景
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 圓角
                ),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                shadowColor: Colors.black.withOpacity(0.2), // 微弱陰影
                elevation: 4,
              ),
              child: const Text(
                '查詢',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // 白色文字
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

}
class StationPage extends StatefulWidget {
  final String stationName;
  final String stationID;

  const StationPage({Key? key, required this.stationName, required this.stationID, }) : super(key: key);

  @override
  _StationPageState createState() => _StationPageState();
}

class _StationPageState extends State<StationPage> with SingleTickerProviderStateMixin  {
  late String displayedStationName;
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    displayedStationName = widget.stationName; // 初始化显示的车站名称
    _tabController = TabController(length: 2, vsync: this); // 两个 Tab 页
  }

  void updateStationName(String newStationName) {
    setState(() {
      displayedStationName = newStationName; // 更新车站名称
    });
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.stationName} 車站",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // 微弱阴影
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "主頁"),
            Tab(text: "列車信息"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomePage(),
          _buildTrainInfoPage(),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    String _getStationClass(String? stationClass) {
      Map<String, String> stationClassMap = {
        '0': '特等站',
        '1': '一等站',
        '2': '二等站',
        '3': '三等站',
        '4': '簡易站',
        '5': '招呼站',
      };

      return stationClassMap[stationClass] ?? '未知等級';
    }
    return FutureBuilder<List<dynamic>>(
      future: fetchTrainStationFacility(widget.stationID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '載入失敗: ${snapshot.error}',
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '無車站資訊',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        } else {
          final data = snapshot.data!;



          return

            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // 圆角效果
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05), // 微弱阴影效果
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 背景图片
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1295,h_720,f_auto/w_80,x_15,y_15,g_south_west,l_klook_water/activities/zdmg5rjnbvgaubuqzoxz/%E8%8A%B1%E8%93%AE%E5%A4%9A%E8%89%AF%E8%BB%8A%E7%AB%99%E7%91%9E%E7%A9%97%E7%89%A7%E5%A0%B4%E4%B8%83%E6%98%9F%E6%BD%AD%E4%B8%80%E6%97%A5%E9%81%8A%EF%BC%88%E5%A2%BE%E4%B8%81%E5%B1%8F%E6%9D%B1%E5%87%BA%E7%99%BC%EF%BC%89.jpg', // 替换为实际图片链接
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 车站名称和天气信息
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    data[0]['StationNameZh_tw'] ?? '未知車站',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Row(
                                  //   children: [
                                  //     Icon(
                                  //       Icons.cloud,
                                  //       color: Colors.grey,
                                  //     ),
                                  //     SizedBox(width: 4),
                                  //     Text(
                                  //       '12 - 17°C',
                                  //       style: TextStyle(fontSize: 16),
                                  //     ),
                                  //   ],
                                  // ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // 地址
                              Text(
                                '車站地址',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                data[1]['StationAddress'] ?? '未知地址',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              // 营业时间
                              Text(
                                '車站等級',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _getStationClass(data[1]['StationClass']),
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              // 售票时间
                              Text(
                                '車站電話',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                data[1]['StationPhone'] ?? '未知電話',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '車站ID',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                data[1]['StationID'] ?? '未知ID',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              // 天气来源
                              // Text(
                              //   '*天氣資訊來源：中央氣象署',
                              //   style: TextStyle(
                              //     fontSize: 12,
                              //     color: Colors.grey[600],
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...data.map((station) {
                    // 动态提取 FacilityMap 数据
                    List<Map<String, String>> facilityMaps = [];
                    for (int i = 0; i < 5; i++) {
                      String? mapName =
                      station['FacilityMapURLs${i}MapNameZh_tw'] as String?;
                      String? mapURL = station['FacilityMapURLs${i}MapURL'] as String?;
                      if (mapURL != null) {
                        facilityMaps.add({
                          'mapName': mapName ?? '',
                          'mapURL': mapURL,
                        });
                      }
                    }

                    // 提取电梯信息（如果有）
                    String? elevatorInfo = station['Elevators0Description'] as String?;

                    return Container(

                      margin: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 显示设施信息
                          ...facilityMaps.map((facility) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facility['mapName']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    facility['mapURL']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text(
                                        '圖片載入失敗',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.redAccent,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),

                          // 显示电梯信息（如果有）
                          if (elevatorInfo != null)
                            Text(
                              "電梯資訊: $elevatorInfo",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );








        }
      },
    );


  }



  Widget _buildTrainInfoPage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: fetchTrainStation(widget.stationID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '加載失敗: ${snapshot.error}',
                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '無列車信息',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          } else {
            List<dynamic> trainData = snapshot.data!;
            return ListView.builder(
              itemCount: trainData.length,
              itemBuilder: (context, index) {
                var train = trainData[index];
                var stationName = train['StationName']['Zh_tw'] ?? '無車站';
                var trainNo = train['TrainNo'] ?? '未知';
                var trainType = train['TrainTypeName']['Zh_tw'] ?? '未知';
                var scheduledArrivalTime =
                _formatTime(train['ScheduledArrivalTime'] ?? '未知');
                var scheduledDepartureTime =
                _formatTime(train['ScheduledDepartureTime'] ?? '未知');
                var delayTime = train['DelayTime'] ?? 0;
                var endingStation =
                    train['EndingStationName']['Zh_tw'] ?? '未知';
                var direction = train['Direction'] == 0 ? '順行' : '逆行';

                return Container(
                  margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey[300], thickness: 0.5),
                      const SizedBox(height: 8),
                      _buildDetailRow('車次', trainNo),
                      const SizedBox(height: 6),
                      _buildDetailRow('列車類型', trainType),
                      const SizedBox(height: 6),
                      _buildDetailRow('方向', direction),
                      const SizedBox(height: 6),
                      _buildDetailRow('終點站', endingStation),
                      const SizedBox(height: 6),
                      _buildDetailRow('到達時間', scheduledArrivalTime,
                          isHighlighted: true),
                      const SizedBox(height: 6),
                      _buildDetailRow('離開時間', scheduledDepartureTime,
                          isHighlighted: true),
                      const SizedBox(height: 6),
                      _buildDetailRow(
                        '延遲',
                        delayTime > 0 ? '${delayTime}分鐘' : '準時',
                        isHighlighted: true,
                        highlightColor: delayTime > 0
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String value,
      {bool isHighlighted = false, Color? highlightColor}) {
    return Row(
      children: [
        Text(
          "$title: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? highlightColor ?? Colors.blue : Colors.black,
          ),
        ),
      ],
    );
  }

  /// 格式化時間為12小時制
  String _formatTime(String time) {
    try {
      final parsedTime = DateTime.parse('1970-01-01 $time');
      final formatter = DateFormat('hh:mm a');
      return formatter.format(parsedTime);
    } catch (e) {
      return time; // 無法格式化則返回原時間
    }
  }



}


class RoutePage extends StatefulWidget {
    final Map<String, dynamic>  departure;
   final Map<String, dynamic>  destination;
   final  DateTime date;
    const RoutePage({super.key,required this.departure, required this.destination, required this.date});

    @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {

  @override
  Widget build(BuildContext context) {

    // 将 JSON 字符串解析为 Map
    Map<String, dynamic> departureJsonData = jsonDecode(widget.departure["StationPosition"]);

    // 获取 PositionLat 和 PositionLon 并转换为 String
    String departurePositionLat = departureJsonData['PositionLat'].toString();
    String departurePositionLon = departureJsonData['PositionLon'].toString();
    Map<String, dynamic> destinationJsonData = jsonDecode(widget.destination["StationPosition"]);

    // 获取 PositionLat 和 PositionLon 并转换为 String
    String destinationPositionLat = destinationJsonData['PositionLat'].toString();
    String destinationPositionLon = destinationJsonData['PositionLon'].toString();
    final DateFormat dateFormatForRoutePage = DateFormat('yyyy-MM-ddTHH:mm:ss');
    print((widget.date));
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.departure["StationName"]["Zh_tw"]}-${widget.destination["StationName"]["Zh_tw"]}"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchTrainRoute(
          "$departurePositionLat,$departurePositionLon",
          "$destinationPositionLat,$destinationPositionLon",
          dateFormatForRoutePage.format(widget.date),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '載入失敗: ${snapshot.error}',
                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '無車站資訊',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          } else {
            final data = snapshot.data!;
return

  ListView.builder(
    itemCount: data.length,
    itemBuilder: (context, index) {
      final section = data[index];
      final DateFormat dateFormat = DateFormat('HH:mm');
      final travel_time=section["travel_time"];
      final sections=section["sections"];


      // 过滤出 type 为 "transit" 的段
      List< dynamic> transitSections = section["sections"].where((section) => section['type'] == 'transit').toList();
      
      // 提取并输出所有的 transport 数据
      List< dynamic> transports = transitSections.map((section) => section).toList();
      List< dynamic> arrival = transitSections.map((section) => section['arrival']["place"]["name"]).toList();
// for(var i in transports ){
//    print(i);
// };

      final start_time=dateFormat.format(DateTime.parse(transitSections[0]["departure"]["time"]));
      final end_time=dateFormat.format(DateTime.parse(transitSections[transitSections.length-1]["arrival"]["time"]));
     bool trainSit=transports.length > 1 ? true : false;
      // 输出结果
      print(trainSit);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8, // 柔和的阴影
              offset: const Offset(0, 4), // 阴影稍微下移
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：时间和车次信息
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        start_time, // 出发时间
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.departure["StationName"]["Zh_tw"], // 出发地点
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: transports.map((i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Text(
                              i['transport']["name"], // 车次名称
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${i['arrival']["place"]["name"]}   ${dateFormat.format(DateTime.parse(i['arrival']["time"]))}", // 到达地点和时间
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        end_time, // 到达时间
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.destination["StationName"]["Zh_tw"], // 到达地点
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(
              height: 24,
              thickness: 1,
              color: Colors.grey,
            ),
            // 可选部分：票价信息 (如果需要)
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           "二等 ¥671", // 二等票信息
            //           style: const TextStyle(
            //             fontSize: 16,
            //             color: Colors.black87,
            //           ),
            //         ),
            //         const SizedBox(height: 4),
            //         Text(
            //           "一等 13张", // 一等票信息
            //           style: const TextStyle(
            //             fontSize: 14,
            //             color: Colors.black54,
            //           ),
            //         ),
            //       ],
            //     ),
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.end,
            //       children: [
            //         Text(
            //           "商务 7张", // 商务票信息
            //           style: const TextStyle(
            //             fontSize: 14,
            //             color: Colors.black54,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
          ],
        ),
      );




    },
  );


          }}
      ),
    );


  }
}


