import 'package:com.rsmn574.app/pages/train/TrainSchedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        title: Text('火車查詢系統'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '按車次查詢'),
            Tab(text: '按出發地和目的地查詢'),
            Tab(text: '按車站查詢'),
          ],
        ),
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
            TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                labelText: '輸入車次',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                selectedDate == null
                    ? '選擇日期'
                    : '選擇日期: ${dateFormat.format(selectedDate!)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // 查詢邏輯
               var trainData=await fetchTrain(int.parse(widget.controller.text),selectedDate!);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrainSchedulePage( trainData: trainData, type: 'trainNo',)),
                );
              },
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
  String? selectedStation;

  // 縣市和對應站名資料
  final Map<String, List<String>> stationData = {
    '台北市': ['台北車站', '松山車站', '板橋車站'],
    '新北市': ['中和車站', '新莊車站', '蘆洲車站'],
    '高雄市': ['高雄車站', '鳳山車站', '新左營車站'],
  };
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
            TextField(
              controller: widget.departureController,
              decoration: InputDecoration(
                labelText: '出發地',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: widget.destinationController,
              decoration: InputDecoration(
                labelText: '目的地',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                selectedDate == null
                    ? '選擇日期'
                    : '選擇日期: ${dateFormat.format(selectedDate!)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),


            ElevatedButton(
              onPressed: () {
                // 查詢邏輯
              },
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

  // final List<String> cities = ['台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市'];
  final Map<String, List<String>> stations = {
    '台北市': ['台北車站', '大安站', '松山站'],
    '新北市': ['板橋車站', '新店站', '淡水站'],
    '桃園市': ['桃園車站', '中壢站', '機場站'],
    '台中市': ['台中車站', '豐原站', '后里站'],
    '台南市': ['台南車站', '新營站', '善化站'],
    '高雄市': ['高雄車站', '左營站', '楠梓站'],
  };
  String? selectedCity;
  String? selectedStation;

  void _showStationDialog() {
    String _selectedCity = '台中市'; // 預設選中城市
    String? _selectedStation; // 預設無選中的車站
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent, // 去掉默认白框
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.white, // 改為淺色背景
                borderRadius: BorderRadius.circular(20), // 添加圆角
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 主内容部分
                    Row(
                      children: [
                        // 左側城市
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 300, // 限制高度
                            decoration: BoxDecoration(
                              color: Colors.grey[200], // 淺色背景
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.16),
                                  blurRadius: 1,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            child: ListView(
                              children: stations.keys.map((city) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCity = city;
                                      _selectedStation = null; // 切換城市時清空選中站點
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _selectedCity == city ? Colors.grey[800] : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      city,
                                      style: TextStyle(
                                        color: _selectedCity == city ? Colors.white : Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(width: 16), // 左右間距
                        // 右側車站
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 300, // 限制高度
                            decoration: BoxDecoration(

                              color: Colors.grey[200], // 淺色背景
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.16),
                                  blurRadius: 1,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            child: ListView(
                              children: stations[_selectedCity]!.map((station) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedStation = station;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _selectedStation == station ? Colors.grey[800] : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      station,
                                      style: TextStyle(
                                        color: _selectedStation == station ? Colors.white : Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // 按钮与内容间距
                    // 底部按钮部分
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // 關閉對話框
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('關閉',style:TextStyle(color: Colors.white) ,),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedStation != null) {
                              // 確認選擇並關閉
                              Navigator.of(context).pop();
                              print('選擇的站點: $_selectedStation');
                            } else {
                              // 如果未選擇站點，可以顯示提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('請選擇一個車站')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('確認',style:TextStyle(color: Colors.white) ,),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              readOnly: true, // 避免直接编辑，强制使用弹窗选择
              decoration: const InputDecoration(
                labelText: '輸入車站名稱',
                border: OutlineInputBorder(),
              ),
              onTap: _showStationDialog,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _selectDate(context),
              child: Text(
                selectedDate == null
                    ? '選擇日期'
                    : '選擇日期: ${dateFormat.format(selectedDate!)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 查詢邏輯
              },
              child: const Text('查詢'),
            ),
          ],
        ),
      ),
    );

  }

}

