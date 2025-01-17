import 'dart:convert';

import 'package:com.rsmn574.app/pages/train/TrainSchedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            // 出發地輸入框
            TextField(
              controller: widget.departureController,
              decoration: const InputDecoration(
                labelText: '出發地',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 目的地輸入框
            TextField(
              controller: widget.destinationController,
              decoration: const InputDecoration(
                labelText: '目的地',
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
              onPressed: () {
                // 查詢邏輯
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
  // String? selectedStation;
  Map<String, dynamic>? selectedStation;



  Future<Map<String, dynamic>?> _showStationDialog() async {
    // 定义现代化橘色和蓝色
    const Color modernOrange = Color(0xFFFFA726); // 橘色
    const Color modernBlue = Color(0xFF42A5F5); // 蓝色
    List stationData = await mysqlSelect("SELECT StationID,StationClass,StationName,LocationCity FROM Train.Train_Station;");
    List<Map<String, dynamic>> stationDataMap = stationData.map((item) {
      return {
        'StationName': {
          'Zh_tw': json.decode(item["StationName"])['Zh_tw'],
          'En': json.decode(item["StationName"])['En']
        },
        'LocationCity': item['LocationCity'],
        'StationClass': item['StationClass'],
        'StationID': item['StationID'],
      };
    }).toList();

    final Map<String, List<String>> stationsList = {};
    for (var entry in stationDataMap) {
      String city = entry['LocationCity'];
      String stationName = entry['StationName']['Zh_tw'];
      if (!stationsList.containsKey(city)) {
        stationsList[city] = [];
      }
      stationsList[city]!.add(stationName);
    }

    String _selectedCity = '臺中市';
    String? _selectedStation;
    Map<String, dynamic>? selectedStationData;

    Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
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
                                children: stationsList.keys.map((city) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCity = city;
                                        _selectedStation = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedCity == city ? Colors.grey[800] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        city,
                                        style: TextStyle(
                                          color: _selectedCity == city ? Colors.white : Colors.grey[800],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
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
                                children: stationsList[_selectedCity]!.map((station) {
                                  var stationEntry = stationDataMap.firstWhere(
                                        (entry) => entry['StationName']['Zh_tw'] == station,

                                  );

                                  Color? textColor;

// 根据 StationClass 的值设置文字颜色
                                  switch (stationEntry['StationClass'].toString()) {
                                    case "0":
                                      textColor = modernOrange;
                                      break;
                                    case "1":
                                      textColor = modernBlue;
                                      break;
                                    default:
                                      textColor = Colors.grey[800]; // 默认颜色
                                      break;
                                  }


                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedStation = station;
                                        selectedStationData = stationEntry;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedStation == station ? Colors.grey[300] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        station,
                                        style: TextStyle(
                                          color: textColor, // 根据 StationClass 设置文字颜色
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭对话框，不返回任何值
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('關閉', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedStationData != null) {
                                Navigator.of(context).pop(selectedStationData); // 返回選中的車站資料
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('請選擇一個車站')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('確認', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result; // 返回選中的站點資料，或 null（用户未選擇）
  }





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
                selectedStation = await _showStationDialog();
                if (selectedStation != null) {
                  _controller.text = selectedStation?['StationName']['Zh_tw']; // 將選擇的車站名稱顯示在輸入框中
                }
  
              },
            ),
            const SizedBox(height: 16),
            // 選擇日期的 TextButton
            // TextButton(
            //   onPressed: () => _selectDate(context),
            //   style: TextButton.styleFrom(
            //     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            //     backgroundColor: Colors.transparent,
            //     side: BorderSide(color: Colors.black.withOpacity(0.2)), // 淡黑色邊框
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //   ),
            //   child: Text(
            //     selectedDate == null
            //         ? '選擇日期'
            //         : '選擇日期: ${dateFormat.format(selectedDate!)}',
            //     style: TextStyle(fontSize: 16, color: Colors.black),
            //   ),
            // ),
            // const SizedBox(height: 16),
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

class _StationPageState extends State<StationPage> {
  late String displayedStationName;

  @override
  void initState() {
    super.initState();
    displayedStationName = widget.stationName; // 初始化显示的车站名称
  }

  void updateStationName(String newStationName) {
    setState(() {
      displayedStationName = newStationName; // 更新车站名称
    });
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
        elevation: 1, // 微弱的阴影效果
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
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
                  var scheduledArrivalTime = _formatTime(
                      train['ScheduledArrivalTime'] ?? '未知');
                  var scheduledDepartureTime = _formatTime(
                      train['ScheduledDepartureTime'] ?? '未知');
                  var delayTime = train['DelayTime'] ?? 0;

                  return  GestureDetector(
                      onTap: () async {
                        DateTime today = DateTime.now();

                        // 点击事件处理
                        var trainData = await fetchTrain(
                          int.parse(trainNo),
                          today,
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
                      onLongPress: () {
                        // 长按事件处理
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('您長按了 $stationName 的列車')),
                        );
                      },
                      child:Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                        _buildDetailRow('列車編號', trainNo),
                        const SizedBox(height: 6),
                        _buildDetailRow('列車類型', trainType),
                        const SizedBox(height: 6),
                        _buildDetailRow('到達時間', scheduledArrivalTime,
                            isHighlighted: true),
                        const SizedBox(height: 6),
                        _buildDetailRow('離開時間', scheduledDepartureTime,
                            isHighlighted: true),
                        const SizedBox(height: 6),
                        _buildDetailRow(
                          '延遲',
                          delayTime > 0
                              ? '${delayTime}分鐘'
                              : '準時',
                          isHighlighted: true,
                          highlightColor:
                          delayTime > 0 ? Colors.redAccent : Colors.green,
                        ),
                      ],
                    ),
                  ));
                },
              );
            }
          },
        ),
      ),
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

  /// 建立每行的詳細資料
  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false, Color? highlightColor}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? (highlightColor ?? Colors.black) : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

}
