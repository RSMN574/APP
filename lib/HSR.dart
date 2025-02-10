import 'dart:convert';

import 'package:com.rsmn574.app/pages/HSR/HSRSchedulePage.dart';

import 'package:com.rsmn574.app/widget/HSR/StationDialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database/HSR/getHSR.dart';
import 'database/getData.dart';
import 'database/getTrain.dart';
// 高鐵主題色
 const Color primaryColor = Color(0xFFDC5321);     // 高鐵橘
 const Color surfaceColor = Color(0xFFF8F9FA);     // 背景色
 const Color textPrimary = Color(0xFF2D3748);      // 主要文字
 const Color textSecondary = Color(0xFF718096);    // 次要文字
class HSR extends StatefulWidget {
  @override
  _HSRState createState() => _HSRState();
}

class _HSRState extends State<HSR> with SingleTickerProviderStateMixin {


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
          '高鐵查詢系統',
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
            Tab(text: '按車次查詢'),
            Tab(text: '按出發地和目的地查詢'),
            Tab(text: '按車站查詢'),
          ],
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
        ),
        actions: [

        ],
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
  // 高鐵主題色
  static const Color primaryColor = Color(0xFFDC5321);     // 高鐵橘
  static const Color surfaceColor = Color(0xFFF8F9FA);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);    // 次要文字

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
            // 高鐵專屬輸入框
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: '輸入高鐵車次',
                labelStyle: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                floatingLabelStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.8), // 聚焦時高鐵橘邊框
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: surfaceColor.withOpacity(0.6), // 半透明淺灰背景
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.directions_railway_filled, // 高鐵專用圖標
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.controller.text.isEmpty ? 0 : 24,
                    height: widget.controller.text.isEmpty ? 0 : 24,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),
                hintText: '例：1120',
                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // 日期選擇按鈕
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white, // 白色背景
                border: Border.all(
                  color: primaryColor.withOpacity(0.3), // 高鐵橘邊框
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today, // 日曆圖標
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '選擇日期: ${dateFormat.format(selectedDate)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 查詢按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  var trainData = await fetchHSR(
                    int.parse(widget.controller.text),
                    selectedDate,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HSRSchedulePage(
                        trainData: trainData,
                        type: 'trainNo',
                      ),
                    ),
                  );
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

  DateTime selectedDate= DateTime.now();
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
            colorScheme: ColorScheme.light(
              primary: primaryColor,    // 主色調
              onPrimary: Colors.white,  // 主色調上的文字
              surface: surfaceColor,    // 對話框背景
              onSurface: textPrimary,   // 對話框文字
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
              colorScheme: ColorScheme.light(
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
                labelStyle: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                floatingLabelStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.8), // 聚焦時高鐵橘邊框
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: surfaceColor.withOpacity(0.6), // 半透明淺灰背景
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.directions_railway_filled,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.departureController.text.isEmpty ? 0 : 24,
                    height: widget.departureController.text.isEmpty ? 0 : 24,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),

                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
              onTap: () async {

                departureSelectedStation = (await StationDialog.showStationDialog(context))!;
                print(departureSelectedStation["StationID"]);
                widget.departureController.text = departureSelectedStation['StationName']['Zh_tw'];
              },
            ),
            const SizedBox(height: 24),

            // 目的地輸入框
            TextField(
              readOnly: true,
              controller: widget.destinationController,
              decoration: InputDecoration(
                labelText: '目的地',
                labelStyle: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                floatingLabelStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.8), // 聚焦時高鐵橘邊框
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: surfaceColor.withOpacity(0.6), // 半透明淺灰背景
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.flag,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.destinationController.text.isEmpty ? 0 : 24,
                    height: widget.destinationController.text.isEmpty ? 0 : 24,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),

                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
              onTap: () async {
                destinationSelectedStation = (await StationDialog.showStationDialog(context))!;
                if(widget.departureController.text == destinationSelectedStation['StationName']['Zh_tw']){
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('出發地和目的地不能相同')),
                  );
                }
                widget.destinationController.text = destinationSelectedStation['StationName']['Zh_tw'];
              },
            ),
            const SizedBox(height: 24),

            // 日期選擇按鈕
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white, // 白色背景
                border: Border.all(
                  color: primaryColor.withOpacity(0.3), // 高鐵橘邊框
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today, // 日曆圖標
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '選擇日期: ${dateFormat.format(selectedDate)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 查詢按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if(selectedDate != null){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoutePage(
                            departure: departureSelectedStation,
                            destination: destinationSelectedStation,
                            date: selectedDate!
                        ),
                      ),
                    );
                  }else{
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請選擇日期'))
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
                      letterSpacing: 1.2
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

class StationSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const StationSearchPage({Key? key, required this.controller}) : super(key: key);

  @override
  _StationSearchPageState createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {


  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
            // 車站名稱輸入框
            TextField(
              controller: _controller,
              readOnly: true,
              decoration: InputDecoration(
                labelText: '選擇高鐵車站',
                labelStyle: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                floatingLabelStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.8), // 聚焦時高鐵橘邊框
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: surfaceColor.withOpacity(0.6), // 半透明淺灰背景
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.train, // 車站專用圖標
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _controller.text.isEmpty ? 0 : 24,
                    height: _controller.text.isEmpty ? 0 : 24,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // 無邊框
                ),
                hintText: '輸入車站名稱', // 提示文字包含標籤內容

                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              onTap: () async {
                selectedStation = await StationDialog.showStationDialog(context);
                if (selectedStation != null) {
                  _controller.text = selectedStation?['StationName']['Zh_tw'];
                }
              },
            ),
            const SizedBox(height: 24),

            // 查詢按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedStation != null) {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => StationPage(
                    //       stationName: selectedStation?['StationName']['Zh_tw'],
                    //       stationID: selectedStation?["StationID"],
                    //     ),
                    //   ),
                    // );
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

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.departure["StationName"]["Zh_tw"]}-${widget.destination["StationName"]["Zh_tw"]}"),
      ),
      body: FutureBuilder<List<dynamic>>(
          future: fetchHSRRoute(
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
