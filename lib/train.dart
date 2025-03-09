import 'dart:convert';

import 'package:com.rsmn574.app/pages/train/TrainSchedule.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/widget/SelectView.dart';
import 'package:com.rsmn574.app/widget/train/StationDialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Const/regularConst.dart';
import 'database/getData.dart';
import 'database/Train/getTrain.dart';

const Color primaryColor = Color(0xFF2A5CAA);
const Color accentColor = Color(0xFFFF9F1C);
const Color textPrimary = Color(0xFF2D3748);
const Color textSecondary = Color(0xFF718096);
const Color surfaceColor = Color(0xFFF3F5F7);

class Train extends StatefulWidget {
  const Train({super.key});

  @override
  _TrainState createState() => _TrainState();
}

class _TrainState extends State<Train> with SingleTickerProviderStateMixin {
  // 顏色常數定義
  static const Color primaryColor = Color(0xFF2A5CAA); // 主色調
  static const Color surfaceColor = Color(0xFFF3F5F7); // 背景色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '火車查詢系統',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: textPrimary),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            // Tab(text: '首頁'),
            Tab(text: '按車次查詢'),
            Tab(text: '按出發地和目的地查詢'),
            Tab(text: '按車站查詢'),
          ],
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
        ),
        actions: [
          PopupMenuButton<String>(
            iconColor: textPrimary,
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              SelectView(
                icon: Icons.train,
                text: '線路資訊',
                id: 'line',
              ),
            ],
            onSelected: (String action) async {
              switch (action) {
                case "line":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          elevation: 3,
                          backgroundColor: primaryColor,
                          title: const Text(
                            "線路資訊",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          centerTitle: true,
                        ),
                        body: FutureBuilder(
                          future:
                              mysqlSelect("SELECT * FROM Train.Train_Line;"),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                    color: primaryColor),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "加載失敗: ${snapshot.error}",
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                (snapshot.data as List).isEmpty) {
                              return Center(
                                child: Text(
                                  "沒有數據",
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 16),
                                ),
                              );
                            } else {
                              var lineData = snapshot.data as List;
                              return Container(
                                color: Colors.white,
                                child: ListView.builder(
                                  itemCount: lineData.length,
                                  itemBuilder: (context, index) {
                                    var line = lineData[index];
                                    var lineNameZh = line['LineNameZh'] ?? '未知';
                                    var lineNameEn =
                                        line['LineNameEn'] ?? 'Unknown';
                                    var sectionNameZh =
                                        line['LineSectionNameZh'] ?? '未知區間';

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          lineNameZh,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "$lineNameEn\n區間: $sectionNameZh",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textSecondary,
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
                    ),
                  );
                  break;
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TrainMainPage(),
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

class TrainMainPage extends StatefulWidget {
  const TrainMainPage({super.key});

  @override
  State<TrainMainPage> createState() => _TrainMainPageState();
}

class _TrainMainPageState extends State<TrainMainPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TripNumberSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const TripNumberSearchPage({Key? key, required this.controller})
      : super(key: key);

  @override
  _TripNumberSearchPageState createState() => _TripNumberSearchPageState();
}

class _TripNumberSearchPageState extends State<TripNumberSearchPage> {
  // 顏色常數定義
  static const Color primaryColor = Color(0xFF2A5CAA); // 主色調
  static const Color surfaceColor = Color(0xFFF3F5F7); // 背景色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字

  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: textPrimary,
            ),
            dialogBackgroundColor: surfaceColor,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 車次輸入框
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: '輸入車次',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: surfaceColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
                filled: true,
                fillColor: surfaceColor,
                prefixIcon: Icon(Icons.train, color: textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // 日期選擇按鈕
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => _selectDate(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '選擇日期: ${dateFormat.format(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 查詢按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (widget.controller.text == '') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請輸入車次')),
                    );
                  }
                  var trainData = await fetchTrain(
                    int.parse(widget.controller.text),
                    selectedDate,
                  );
                  if (trainData == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('無此車次')),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainSchedulePage(
                          trainData: trainData,
                          type: 'trainNo',
                          time: selectedDate,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: const Text(
                  '立即查詢',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2),
                ),
              ),
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
  Map<String, dynamic> departureSelectedStation = {};
  Map<String, dynamic> destinationSelectedStation = {};
  // 縣市和對應站名資料
  final Map<String, List<String>> stationData = {
    '台北市': ['台北車站', '松山車站', '板橋車站'],
    '新北市': ['中和車站', '新莊車站', '蘆洲車站'],
    '高雄市': ['高雄車站', '鳳山車站', '新左營車站'],
  };

  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH時mm分');

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor, // 主色調
              onPrimary: Colors.white, // 主色調上的文字
              surface: surfaceColor, // 對話框背景
              onSurface: textPrimary, // 對話框文字
            ),
            dialogBackgroundColor: surfaceColor, // 背景色
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // 按鈕文字
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                surface: surfaceColor,
                onSurface: textPrimary,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: surfaceColor,
                hourMinuteTextColor: textPrimary,
                dayPeriodTextColor: textPrimary, // AM/PM 文字顏色
                dayPeriodColor: surfaceColor.withOpacity(0.5), // AM/PM 背景色
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // AM/PM 圓角
                  side: BorderSide(
                    color: primaryColor.withOpacity(0.3), // AM/PM 邊框
                    width: 1,
                  ),
                ),
                hourMinuteColor: surfaceColor.withOpacity(0.8), // 小時/分鐘背景色
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 小時/分鐘圓角
                  side: BorderSide(
                    color: primaryColor.withOpacity(0.3), // 小時/分鐘邊框
                    width: 1,
                  ),
                ),
                dialBackgroundColor: surfaceColor.withOpacity(0.8), // 時鐘背景色
                dialTextColor: textPrimary, // 時鐘文字顏色
                entryModeIconColor: primaryColor, // 切換圖標顏色
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 出發地輸入框
            TextField(
              readOnly: true,
              controller: widget.departureController,
              decoration: InputDecoration(
                labelText: '出發地',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: surfaceColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
                filled: true,
                fillColor: surfaceColor,
                prefixIcon: Icon(Icons.train, color: textSecondary),
              ),
              onTap: () async {
                departureSelectedStation =
                    (await StationDialog.showStationDialog(context))!;
                widget.departureController.text =
                    departureSelectedStation['StationName']['Zh_tw'];
              },
            ),
            const SizedBox(height: 24),

            // 目的地輸入框
            TextField(
              readOnly: true,
              controller: widget.destinationController,
              decoration: InputDecoration(
                labelText: '目的地',
                labelStyle: TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: surfaceColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
                filled: true,
                fillColor: surfaceColor,
                prefixIcon: Icon(Icons.flag, color: textSecondary),
              ),
              onTap: () async {
                destinationSelectedStation =
                    (await StationDialog.showStationDialog(context))!;
                if (widget.departureController.text ==
                    destinationSelectedStation['StationName']['Zh_tw']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('出發地和目的地不能相同')),
                  );
                }
                widget.destinationController.text =
                    destinationSelectedStation['StationName']['Zh_tw'];
              },
            ),
            const SizedBox(height: 24),

            // 日期選擇按鈕
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => _selectDateTime(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '選擇日期: ${selectedDate != null ? dateFormat.format(selectedDate!) : "現在時間"}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 查詢按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (departureSelectedStation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請選擇出發地')),
                    );
                    return;
                  }

                  if (destinationSelectedStation.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請選擇目的地')),
                    );
                    return;
                  }

                  if (selectedDate == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutePage(
                            departure: departureSelectedStation,
                            destination: destinationSelectedStation,
                            date: DateTime.now()),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutePage(
                            departure: departureSelectedStation,
                            destination: destinationSelectedStation,
                            date: selectedDate!),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: const Text(
                  '立即查詢',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const StationSearchPage({super.key, required this.controller});

  @override
  _StationSearchPageState createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {
  // 顏色常數定義
  static const Color primaryColor = Color(0xFF2A5CAA); // 主色調
  static const Color surfaceColor = Color(0xFFF3F5F7); // 背景色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字

  final TextEditingController _controller = TextEditingController();
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

  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH時mm分');

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor, // 主色調
              onPrimary: Colors.white, // 主色調上的文字
              surface: surfaceColor, // 對話框背景
              onSurface: textPrimary, // 對話框文字
            ),
            dialogBackgroundColor: surfaceColor, // 背景色
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // 按鈕文字
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                surface: surfaceColor,
                onSurface: textPrimary,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: surfaceColor,
                hourMinuteTextColor: textPrimary,
                dayPeriodTextColor: textPrimary, // AM/PM 文字顏色
                dayPeriodColor: surfaceColor.withOpacity(0.5), // AM/PM 背景色
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // AM/PM 圓角
                  side: BorderSide(
                    color: primaryColor.withOpacity(0.3), // AM/PM 邊框
                    width: 1,
                  ),
                ),
                hourMinuteColor: surfaceColor.withOpacity(0.8), // 小時/分鐘背景色
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 小時/分鐘圓角
                  side: BorderSide(
                    color: primaryColor.withOpacity(0.3), // 小時/分鐘邊框
                    width: 1,
                  ),
                ),
                dialBackgroundColor: surfaceColor.withOpacity(0.8), // 時鐘背景色
                dialTextColor: textPrimary, // 時鐘文字顏色
                entryModeIconColor: primaryColor, // 切換圖標顏色
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 車站名稱輸入框
            TextField(
              controller: _controller,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '輸入車站名稱',
                labelStyle: const TextStyle(color: textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: surfaceColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor),
                ),
                filled: true,
                fillColor: surfaceColor,
                prefixIcon: const Icon(Icons.train, color: textSecondary),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onTap: () async {
                selectedStation =
                    await StationDialog.showStationDialog(context);
                if (selectedStation != null) {
                  _controller.text = selectedStation?['StationName']['Zh_tw'];
                }
              },
            ),
            const SizedBox(height: 24),

            // 日期選擇按鈕
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => _selectDateTime(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '選擇日期: ${selectedDate != null ? dateFormat.format(selectedDate!) : "現在時間"}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 查詢按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedStation != null) {
                    if (selectedDate == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StationPage(
                              stationName: selectedStation?['StationName']
                                  ['Zh_tw'],
                              stationID: selectedStation?["StationID"],
                              datetime: DateTime.now()),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StationPage(
                              stationName: selectedStation?['StationName']
                                  ['Zh_tw'],
                              stationID: selectedStation?["StationID"],
                              datetime: selectedDate!),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('請選擇車站')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: const Text(
                  '立即查詢',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
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
  final DateTime datetime;
  const StationPage({
    Key? key,
    required this.stationName,
    required this.stationID,
    required this.datetime,
  }) : super(key: key);

  @override
  _StationPageState createState() => _StationPageState();
}

class _StationPageState extends State<StationPage>
    with SingleTickerProviderStateMixin {
  late String displayedStationName;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    displayedStationName = widget.stationName;
    _tabController = TabController(length: 2, vsync: this);
  }

  void updateStationName(String newStationName) {
    setState(() {
      displayedStationName = newStationName;
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
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          tabs: const [
            Tab(text: "主頁"),
            Tab(text: "列車資訊"),
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
          return Center(child: CircularProgressIndicator(color: primaryColor));
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              '載入失敗: ${snapshot.error}',
              style: TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '無車站資訊',
              style: TextStyle(fontSize: 16, color: textSecondary),
            ),
          );
        } else {
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1295,h_720,f_auto/w_80,x_15,y_15,g_south_west,l_klook_water/activities/zdmg5rjnbvgaubuqzoxz/%E8%8A%B1%E8%93%AE%E5%A4%9A%E8%89%AF%E8%BB%8A%E7%AB%99%E7%91%9E%E7%A9%97%E7%89%A7%E5%A0%B4%E4%B8%83%E6%98%9F%E6%BD%AD%E4%B8%80%E6%97%A5%E9%81%8A%EF%BC%88%E5%A2%BE%E4%B8%81%E5%B1%8F%E6%9D%B1%E5%87%BA%E7%99%BC%EF%BC%89.jpg',
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
                            Text(
                              data[0]['StationNameZh_tw'] ?? '未知車站',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '車站地址',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              data[1]['StationAddress'] ?? '未知地址',
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '車站等級',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              _getStationClass(data[1]['StationClass']),
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '車站電話',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              data[1]['StationPhone'] ?? '未知電話',
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '車站ID',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              data[1]['StationID'] ?? '未知ID',
                              style: const TextStyle(
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...data.map((station) {
                  List<Map<String, String>> facilityMaps = [];
                  for (int i = 0; i < 5; i++) {
                    String? mapName =
                        station['FacilityMapURLs${i}MapNameZh_tw'] as String?;
                    String? mapURL =
                        station['FacilityMapURLs${i}MapURL'] as String?;
                    if (mapURL != null) {
                      facilityMaps.add({
                        'mapName': mapName ?? '',
                        'mapURL': mapURL,
                      });
                    }
                  }

                  String? elevatorInfo =
                      station['Elevators0Description'] as String?;

                  return Container(
                    margin: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        ...facilityMaps.map((facility) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                facility['mapName']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
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
                        if (elevatorInfo != null)
                          Text(
                            "電梯資訊: $elevatorInfo",
                            style: const TextStyle(
                              fontSize: 14,
                              color: textPrimary,
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
    late final ValueNotifier<double> itemHeightNotifier =
        ValueNotifier(12.0); // 初始高度

    final ScrollController scrollController = ScrollController();
    List<dynamic> trainData = []; // 這裡假設 trainData 已經載入
    /// 找出第一筆 DepartureTime 晚於 widget.datetime 的資料，並滾動到該項目
    void scrollToNearestTrain() {
      for (int i = 0; i < trainData.length; i++) {
        var train = trainData[i];
        // 假設 DepartureTime 為 "HH:mm" 格式
        String departureTimeStr =
            _formatTime(train['DepartureTime'] ?? '00:00');
        List<String> parts = train['DepartureTime'].split(':');

        int? depHour = int.tryParse(parts[0]);
        int? depMinute = int.tryParse(parts[1]);

        if (depHour == null || depMinute == null) {
          print("Error: Unable to parse time -> $departureTimeStr");
          continue;
        }
        // 以 widget.datetime 的日期組合發車時間
        DateTime trainDepTime = DateTime(
          widget.datetime.year,
          widget.datetime.month,
          widget.datetime.day,
          depHour,
          depMinute,
        );
        // 如果發車時間在參考時間之後，就滾動到這個項目
        if (trainDepTime.isAfter(widget.datetime)) {
          double itemHeight = 120.0 + 16; // 調整為你每個列表項目的高度

          double offset = i * itemHeight;
          scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
          );
          break;
        }
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: fetchTrainStation(widget.stationID, (widget.datetime)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '加載失敗: ${snapshot.error}',
                style: TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '無列車資訊',
                style: TextStyle(fontSize: 16, color: textSecondary),
              ),
            );
          } else {
            // 使用 addPostFrameCallback 確保 ListView 已經渲染完成
            WidgetsBinding.instance.addPostFrameCallback((_) {
              scrollToNearestTrain();
            });
            trainData = snapshot.data!;
            return ListView.builder(
              controller: scrollController,
              itemCount: trainData.length,
              itemBuilder: (context, index) {
                var train = trainData[index];
                String stationName = train['StationName']['Zh_tw'] ?? '無車站';
                String trainNo = (train['TrainNo']) ?? '未知';
                String trainType =
                    convertTrainType(train['TrainTypeName']['Zh_tw']);
                String DepartureTime =
                    _formatTime(train['DepartureTime'] ?? '未知');
                int delayTime = train['DelayTime'] ?? "";
                String endingStation =
                    train['EndingStationName']['Zh_tw'] ?? '未知';

                return GestureDetector(
                  onTap: () async {
                    // 這裡根據需要實作點擊後的行為
                    var fetchedTrainData = await fetchTrain(
                      int.parse(
                          train['TrainNo'].replaceAll(RegExp(r'[^0-9]'), '')),
                      widget.datetime,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainSchedulePage(
                          trainData: fetchedTrainData,
                          type: 'trainNo',
                          time: widget.datetime,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 120,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    padding: const EdgeInsets.all(16),
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
                        // 站名標題
                        Row(
                          children: [
                            Icon(Icons.train,
                                color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              stationName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 主要資訊橫向排列
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildHorizontalItem('車次', trainNo),
                              _buildDivider(),
                              _buildHorizontalItem('發車', DepartureTime),
                              _buildDivider(),
                              _buildHorizontalItem('車種', trainType),
                              _buildDivider(),
                              _buildHorizontalItem('終點', endingStation),
                              if (delayTime > 0) ...[
                                _buildDivider(),
                                _buildStatusIndicator(
                                    '延誤 $delayTime分鐘', Colors.redAccent),
                              ]
                              // else if (delayTime == 0)  ...[
                              //   _buildDivider(),
                              //   _buildStatusIndicator('準點', Colors.green),
                              // ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

// 自定義橫向項目元件
  Widget _buildHorizontalItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

// 分隔線元件
  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[300],
    );
  }

// 狀態指示器
  Widget _buildStatusIndicator(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final parsedTime = DateTime.parse('1970-01-01 $time');
      final formatter = DateFormat('hh:mm a');
      return formatter.format(parsedTime);
    } catch (e) {
      return time;
    }
  }
}

class RoutePage extends StatefulWidget {
  final Map<String, dynamic> departure;
  final Map<String, dynamic> destination;
  final DateTime date;
  const RoutePage(
      {super.key,
      required this.departure,
      required this.destination,
      required this.date});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  @override
  Widget build(BuildContext context) {
    // 将 JSON 字符串解析为 Map
    Map<String, dynamic> departureJsonData =
        jsonDecode(widget.departure["StationPosition"]);

    // 获取 PositionLat 和 PositionLon 并转换为 String
    String departurePositionLat = departureJsonData['PositionLat'].toString();
    String departurePositionLon = departureJsonData['PositionLon'].toString();
    Map<String, dynamic> destinationJsonData =
        jsonDecode(widget.destination["StationPosition"]);

    // 获取 PositionLat 和 PositionLon 并转换为 String
    String destinationPositionLat =
        destinationJsonData['PositionLat'].toString();
    String destinationPositionLon =
        destinationJsonData['PositionLon'].toString();
    final DateFormat dateFormatForRoutePage = DateFormat('yyyy-MM-ddTHH:mm:ss');
    print((widget.date));
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.departure["StationName"]["Zh_tw"]}-${widget.destination["StationName"]["Zh_tw"]}"),
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
                  '無列車資訊',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            } else {
              final data = snapshot.data!;
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final section = data[index];
                  final DateFormat dateFormat = DateFormat('HH:mm');
                  final travel_time = section["travel_time"];
                  final sections = section["sections"];
                  print(travel_time);
                  // 过滤出 type 为 "transit" 的段
                  List<dynamic> transitSections = section["sections"]
                      .where((section) => section['type'] == 'transit')
                      .toList();

                  // 提取并输出所有的 transport 数据
                  List<dynamic> transports =
                      transitSections.map((section) => section).toList();
                  List<dynamic> arrival = transitSections
                      .map((section) => section['arrival']["place"]["name"])
                      .toList();
                  final start_time = dateFormat.format(
                      DateTime.parse(transitSections[0]["departure"]["time"]));
                  final end_time = dateFormat.format(DateTime.parse(
                      transitSections[transitSections.length - 1]["arrival"]
                          ["time"]));
                  bool trainSit = transports.length > 1 ? true : false;
                  // // 输出结果final now = DateTime.now();
final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

// 將時間字串轉換為 DateTime 物件
final startDateTime = DateTime.parse('$todayDate $start_time');
final endDateTime = DateTime.parse('$todayDate $end_time');

// 計算總旅程時間
final duration = endDateTime.difference(startDateTime);
final hours = duration.inHours;
final minutes = duration.inMinutes.remainder(60);

                  // print(trainSit);
                  return Container(
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
                    margin: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
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
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.departure["StationName"]
                                        ["Zh_tw"], // 出发地点
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: transports.map((i) {
                                  return GestureDetector(
                                    onTap: () async {
                                      var trainData = await fetchTrain(
                                        int.parse(i['transport']["name"]
                                            .replaceAll(RegExp(r'[^0-9]'), '')),
                                        DateTime.parse(DateFormat('yyyy-MM-dd')
                                            .format(DateTime.parse(
                                                i['arrival']["time"]))),
                                      );

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TrainSchedulePage(
                                            trainData: trainData,
                                            type: 'trainNo',
                                            time: DateTime.parse(
                                                i['arrival']["time"]),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 12.0),
                                      margin:
                                          const EdgeInsets.only(bottom: 6.0),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            "${i['transport']["name"]}", // 车次名称
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${i['arrival']["place"]["name"]}   ${dateFormat.format(DateTime.parse(i['arrival']["time"]))}", // 到达地点和时间
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
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
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.destination["StationName"]
                                        ["Zh_tw"], // 到达地点
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: textSecondary,
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
                          color: Color(0xFFE2E8F0),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                               // 假設日期為當天

// 顯示總旅程時間
              Text("總旅程時間: ${hours}hr ${minutes}min",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            trainSit
                                ? const Text(
                                    "需轉乘",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE53E3E),
                                    ),
                                  )
                                : const Text(
                                    "直達車",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF38A169),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          }),
    );
  }
}
