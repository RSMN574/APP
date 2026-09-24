import 'dart:convert';
import 'package:com.rsmn574.app/pages/train/TrainSchedule.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/widget/SelectView.dart';
import 'package:com.rsmn574.app/widget/train/StationDialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../database/getData.dart';
import '../../database/Train/getTrain.dart';
import '../../l10n/app_localizations.dart';

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
        elevation: 0,  // 改為無陰影
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_bus,  // 使用公車圖示
                color: Color(0xFF1A73E8),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.text_826,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),  // 改為藍色
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.text_145),
            Tab(text: AppLocalizations.of(context)!.text_146),
            Tab(text: AppLocalizations.of(context)!.text_147),
          ],
          labelColor: const Color(0xFF1A73E8),  // 改為精緻藍
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF1A73E8),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1A73E8)),
            iconColor: const Color(0xFF1A73E8),
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              PopupMenuItem<String>(
                value: 'line',
                child: Row(
                  children: [
                    const Icon(Icons.train, color: Color(0xFF1A73E8), size: 20),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.text_827),
                  ],
                ),
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
                          elevation: 0,  // 內頁也改成無陰影
                          backgroundColor: Colors.white,
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.train,
                                  color: Color(0xFF1A73E8),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.text_827,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                            ],
                          ),
                          centerTitle: true,
                          iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
                        ),
                        body: FutureBuilder(
                          future: mysqlSelect("SELECT * FROM Train.Train_Line;"),
                          builder: (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFF1A73E8),
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "加載失敗: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red, fontSize: 16),
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                (snapshot.data as List).isEmpty) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context)!.text_828,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
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
                                    var lineNameZh = line['LineNameZh'] ?? AppLocalizations.of(context)!.text_321;
                                    var lineNameEn = line['LineNameEn'] ?? 'Unknown';
                                    var sectionNameZh = line['LineSectionNameZh'] ?? AppLocalizations.of(context)!.text_829;

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 16,
                                      ),
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
  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A73E8),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A73E8),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF1A73E8),
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.text_830,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.text_831,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 查詢卡片
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 車次輸入框
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEEF3FB),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: widget.controller,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.text_832,
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.train_rounded,
                                color: const Color(0xFF1A73E8),
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 日期選擇按鈕
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEEF3FB),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: Color(0xFF1A73E8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Color(0xFF1A73E8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 查詢按鈕
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A73E8).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              if (widget.controller.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.text_833),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                trainData = await fetchTrain(
                                  int.parse(widget.controller.text.replaceAll(RegExp(r'[^0-9]'), ''))
                                  ,
                                  selectedDate,
                                );
                                if (trainData==null||trainData.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.text_834),
                                      backgroundColor: const Color(0xFFFF9500),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrainSchedulePage(

                                        type: 'trainNo',
                                        time: selectedDate,
                                        trainNo: int.parse(widget.controller.text.replaceAll(RegExp(r'[^0-9]'), ''))
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.text_834),
                                    backgroundColor: const Color(0xFFFF9500),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.text_153,
                                    style: const TextStyle(
                                      fontSize: 16,
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
                    ],
                  ),
                ),

                // 提示資訊
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEEF3FB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.text_835,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_836,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  // 縣市和對應站名資料
  late final Map<String, List<String>> stationData = {
    AppLocalizations.of(context)!.text_174: [AppLocalizations.of(context)!.text_175, AppLocalizations.of(context)!.text_837, AppLocalizations.of(context)!.text_178],
    AppLocalizations.of(context)!.text_8: [AppLocalizations.of(context)!.text_838, AppLocalizations.of(context)!.text_839, AppLocalizations.of(context)!.text_840],
    AppLocalizations.of(context)!.text_11: [AppLocalizations.of(context)!.text_192, AppLocalizations.of(context)!.text_841, AppLocalizations.of(context)!.text_842],
  };

  Map<String, dynamic> departureSelectedStation = {};
  Map<String, dynamic> destinationSelectedStation = {};
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH:mm');

  // 新增：追蹤選擇狀態
  bool _isDepartureSelected = false;
  bool _isDestinationSelected = false;

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A73E8),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A73E8),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF1A73E8),
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
                primary: Color(0xFF1A73E8),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1A73E8),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: const Color(0xFF1A73E8),
                dayPeriodTextColor: const Color(0xFF1A73E8),
                dayPeriodColor: const Color(0xFF1A73E8).withOpacity(0.1),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFF1A73E8).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                hourMinuteColor: const Color(0xFF1A73E8).withOpacity(0.05),
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFF1A73E8).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                dialBackgroundColor: const Color(0xFFF8FAFD),
                dialTextColor: const Color(0xFF1A73E8),
                entryModeIconColor: const Color(0xFF1A73E8),
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

  void _swapStations() {
    if (departureSelectedStation.isEmpty && destinationSelectedStation.isEmpty) {
      return;
    }

    setState(() {
      // 交換控制器內容
      final tempController = TextEditingController();
      tempController.text = widget.departureController.text;
      widget.departureController.text = widget.destinationController.text;
      widget.destinationController.text = tempController.text;

      // 交換車站資料
      final tempStation = departureSelectedStation;
      departureSelectedStation = destinationSelectedStation;
      destinationSelectedStation = tempStation;

      // 交換選擇狀態
      final tempSelected = _isDepartureSelected;
      _isDepartureSelected = _isDestinationSelected;
      _isDestinationSelected = tempSelected;

      if (widget.departureController.text == widget.destinationController.text &&
          widget.departureController.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.text_157),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題區域
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.text_843,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.text_844,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 查詢卡片
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 出發地
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final selectedStation = await StationDialog.showStationDialog(context);
                            if (selectedStation != null) {
                              setState(() {
                                departureSelectedStation = selectedStation;
                                _isDepartureSelected = true;
                                widget.departureController.text =
                                    departureSelectedStation['StationName']['Zh_tw'] ??
                                        departureSelectedStation['StationName'] ??
                                        AppLocalizations.of(context)!.text_160;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _isDepartureSelected
                                  ? const Color(0xFF1A73E8).withOpacity(0.05)
                                  : const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDepartureSelected
                                    ? const Color(0xFF1A73E8).withOpacity(0.3)
                                    : const Color(0xFFEEF3FB),
                                width: _isDepartureSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isDepartureSelected
                                        ? const Color(0xFF1A73E8)
                                        : const Color(0xFF1A73E8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.train_rounded,
                                    size: 20,
                                    color: _isDepartureSelected
                                        ? Colors.white
                                        : const Color(0xFF1A73E8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_845,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isDepartureSelected
                                              ? const Color(0xFF1A73E8)
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isDepartureSelected
                                            ? widget.departureController.text
                                            : AppLocalizations.of(context)!.text_161,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _isDepartureSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _isDepartureSelected
                                              ? const Color(0xFF1A73E8)
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isDepartureSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 交換按鈕
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF1A73E8).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Transform.rotate(
                              angle: 90 * (3.1415926535 / 180),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: Color(0xFF1A73E8),
                                size: 24,
                              ),
                            ),
                          ),
                          onPressed: _swapStations,
                        ),
                      ),

                      // 目的地
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final selectedStation = await StationDialog.showStationDialog(context);
                            if (selectedStation != null) {
                              setState(() {
                                destinationSelectedStation = selectedStation;
                                _isDestinationSelected = true;
                                widget.destinationController.text =
                                    destinationSelectedStation['StationName']['Zh_tw'] ??
                                        destinationSelectedStation['StationName'] ??
                                        AppLocalizations.of(context)!.text_160;
                              });

                              // 檢查是否與出發地相同
                              if (widget.departureController.text == widget.destinationController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.text_157),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFF34C759).withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _isDestinationSelected
                                  ? const Color(0xFF34C759).withOpacity(0.05)
                                  : const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDestinationSelected
                                    ? const Color(0xFF34C759).withOpacity(0.3)
                                    : const Color(0xFFEEF3FB),
                                width: _isDestinationSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isDestinationSelected
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFF34C759).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.flag_rounded,
                                    size: 20,
                                    color: _isDestinationSelected
                                        ? Colors.white
                                        : const Color(0xFF34C759),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_846,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isDestinationSelected
                                              ? const Color(0xFF34C759)
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isDestinationSelected
                                            ? widget.destinationController.text
                                            : AppLocalizations.of(context)!.text_847,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _isDestinationSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _isDestinationSelected
                                              ? const Color(0xFF34C759)
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isDestinationSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34C759).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Color(0xFF34C759),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 日期時間選擇
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectDateTime(context),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFFFF9500).withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDate != null
                                  ? const Color(0xFFFF9500).withOpacity(0.05)
                                  : const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedDate != null
                                    ? const Color(0xFFFF9500).withOpacity(0.3)
                                    : const Color(0xFFEEF3FB),
                                width: selectedDate != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedDate != null
                                        ? const Color(0xFFFF9500)
                                        : const Color(0xFFFF9500).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: selectedDate != null
                                        ? Colors.white
                                        : const Color(0xFFFF9500),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_164,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selectedDate != null
                                              ? const Color(0xFFFF9500)
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedDate != null
                                            ? dateFormat.format(selectedDate!)
                                            : AppLocalizations.of(context)!.text_165,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selectedDate != null
                                              ? const Color(0xFFFF9500)
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedDate != null)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9500).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.edit_calendar_rounded,
                                      size: 18,
                                      color: Color(0xFFFF9500),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 20,
                                    color: Color(0xFFFF9500),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 查詢按鈕
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A73E8).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (!_isDepartureSelected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:  Text(AppLocalizations.of(context)!.text_848),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (!_isDestinationSelected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:  Text(AppLocalizations.of(context)!.text_849),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoutePage(
                                    departure: departureSelectedStation,
                                    destination: destinationSelectedStation,
                                    date: selectedDate ?? DateTime.now().add(const Duration(minutes: 1)),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child:  Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.text_166,
                                    style: TextStyle(
                                      fontSize: 16,
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
                    ],
                  ),
                ),

                // 提示資訊
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEEF3FB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(width: 12),
                       Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.text_154,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_850,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
  final TextEditingController _controller = TextEditingController();
  late final Map<String, List<String>> stations = {
    AppLocalizations.of(context)!.text_174: [AppLocalizations.of(context)!.text_175, AppLocalizations.of(context)!.text_176, AppLocalizations.of(context)!.text_177],
    AppLocalizations.of(context)!.text_8: [AppLocalizations.of(context)!.text_178, AppLocalizations.of(context)!.text_179, AppLocalizations.of(context)!.text_180],
    AppLocalizations.of(context)!.text_9: [AppLocalizations.of(context)!.text_181, AppLocalizations.of(context)!.text_182, AppLocalizations.of(context)!.text_183],
    AppLocalizations.of(context)!.text_184: [AppLocalizations.of(context)!.text_185, AppLocalizations.of(context)!.text_186, AppLocalizations.of(context)!.text_187],
    AppLocalizations.of(context)!.text_188: [AppLocalizations.of(context)!.text_189, AppLocalizations.of(context)!.text_190, AppLocalizations.of(context)!.text_191],
    AppLocalizations.of(context)!.text_11: [AppLocalizations.of(context)!.text_192, AppLocalizations.of(context)!.text_193, AppLocalizations.of(context)!.text_194],
  };

  String? selectedCity;
  Map<String, dynamic>? selectedStation;
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH:mm');

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A73E8),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A73E8),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF1A73E8),
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
                primary: Color(0xFF1A73E8),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Color(0xFF1A73E8),
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: const Color(0xFF1A73E8),
                dayPeriodTextColor: const Color(0xFF1A73E8),
                dayPeriodColor: const Color(0xFF1A73E8).withOpacity(0.1),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFF1A73E8).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                hourMinuteColor: const Color(0xFF1A73E8).withOpacity(0.05),
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFF1A73E8).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                dialBackgroundColor: const Color(0xFFF8FAFD),
                dialTextColor: const Color(0xFF1A73E8),
                entryModeIconColor: const Color(0xFF1A73E8),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題區域
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                       Text(
                        AppLocalizations.of(context)!.text_851,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.text_852,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 查詢卡片
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 車站名稱選擇
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            selectedStation = await StationDialog.showStationDialog(context);
                            if (selectedStation != null) {
                              setState(() {
                                _controller.text = selectedStation?['StationName']['Zh_tw'] ?? '';
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selectedStation != null
                                  ? const Color(0xFF1A73E8).withOpacity(0.05)
                                  : const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedStation != null
                                    ? const Color(0xFF1A73E8).withOpacity(0.3)
                                    : const Color(0xFFEEF3FB),
                                width: selectedStation != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedStation != null
                                        ? const Color(0xFF1A73E8)
                                        : const Color(0xFF1A73E8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.train_rounded,
                                    size: 20,
                                    color: selectedStation != null
                                        ? Colors.white
                                        : const Color(0xFF1A73E8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_853,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selectedStation != null
                                              ? const Color(0xFF1A73E8)
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedStation != null
                                            ? _controller.text
                                            : AppLocalizations.of(context)!.text_200,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedStation != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: selectedStation != null
                                              ? const Color(0xFF1A73E8)
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedStation != null)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 日期時間選擇
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectDateTime(context),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFFFF9500).withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDate != null
                                  ? const Color(0xFFFF9500).withOpacity(0.05)
                                  : const Color(0xFFF8FAFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedDate != null
                                    ? const Color(0xFFFF9500).withOpacity(0.3)
                                    : const Color(0xFFEEF3FB),
                                width: selectedDate != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedDate != null
                                        ? const Color(0xFFFF9500)
                                        : const Color(0xFFFF9500).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: selectedDate != null
                                        ? Colors.white
                                        : const Color(0xFFFF9500),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_164,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selectedDate != null
                                              ? const Color(0xFFFF9500)
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedDate != null
                                            ? dateFormat.format(selectedDate!)
                                            : AppLocalizations.of(context)!.text_165,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selectedDate != null
                                              ? const Color(0xFFFF9500)
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 20,
                                  color: selectedDate != null
                                      ? const Color(0xFFFF9500)
                                      : Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 查詢按鈕
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A73E8).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (selectedStation == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:  Text(AppLocalizations.of(context)!.text_200),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StationPage(
                                    stationName: selectedStation?['StationName']['Zh_tw'],
                                    stationID: selectedStation?["StationID"],
                                    datetime: selectedDate ?? DateTime.now(),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child:  Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.text_854,
                                    style: TextStyle(
                                      fontSize: 16,
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
                    ],
                  ),
                ),

                // 提示資訊
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEEF3FB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                      ),
                      const SizedBox(width: 12),
                       Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.text_154,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_855,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 熱門車站快速選擇
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          AppLocalizations.of(context)!.text_203,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A73E8),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppLocalizations.of(context)!.text_175,
                          AppLocalizations.of(context)!.text_192,
                          AppLocalizations.of(context)!.text_185,
                          AppLocalizations.of(context)!.text_178,
                          AppLocalizations.of(context)!.text_193,
                          AppLocalizations.of(context)!.text_181,
                        ].map((stationName) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: 設置熱門車站
                                _controller.text = stationName;
                                // 這裡可以設置對應的 selectedStation
                              },
                              borderRadius: BorderRadius.circular(20),
                              splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF3FB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF1A73E8).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  stationName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1A73E8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "${widget.stationName} 車站",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1A73E8),
          labelColor: const Color(0xFF1A73E8),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.text_856),
            Tab(text: AppLocalizations.of(context)!.text_655),
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
        '0': AppLocalizations.of(context)!.text_857,
        '1': AppLocalizations.of(context)!.text_858,
        '2': AppLocalizations.of(context)!.text_859,
        '3': AppLocalizations.of(context)!.text_860,
        '4': AppLocalizations.of(context)!.text_861,
        '5': AppLocalizations.of(context)!.text_862,
      };
      return stationClassMap[stationClass] ?? AppLocalizations.of(context)!.text_863;
    }

    return FutureBuilder<List<dynamic>>(
      future: fetchTrainStationFacility(widget.stationID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                color: const Color(0xFF1A73E8),
                strokeWidth: 3,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF3B30).withOpacity(0.1),
                          const Color(0xFFFF3B30).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    AppLocalizations.of(context)!.text_205,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A73E8).withOpacity(0.1),
                          const Color(0xFF1A73E8).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.train_outlined,
                      size: 50,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 24),
                   Text(
                    AppLocalizations.of(context)!.text_864,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.text_865,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // 車站基本資訊卡片
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1295,h_720,f_auto/w_80,x_15,y_15,g_south_west,l_klook_water/activities/zdmg5rjnbvgaubuqzoxz/%E8%8A%B1%E8%93%AE%E5%A4%9A%E8%89%AF%E8%BB%8A%E7%AB%99%E7%91%9E%E7%A9%97%E7%89%A7%E5%A0%B4%E4%B8%83%E6%98%9F%E6%BD%AD%E4%B8%80%E6%97%A5%E9%81%8A%EF%BC%88%E5%A2%BE%E4%B8%81%E5%B1%8F%E6%9D%B1%E5%87%BA%E7%99%BC%EF%BC%89.jpg',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 車站名稱
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF3FB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.train_rounded,
                                    size: 20,
                                    color: Color(0xFF1A73E8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    data[0]['StationNameZh_tw'] ?? AppLocalizations.of(context)!.text_160,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 資訊項目
                            _buildInfoItem(
                              icon: Icons.location_on_rounded,
                              label: AppLocalizations.of(context)!.text_866,
                              value: data[1]['StationAddress'] ?? AppLocalizations.of(context)!.text_867,
                            ),
                            _buildInfoItem(
                              icon: Icons.grade_rounded,
                              label: AppLocalizations.of(context)!.text_868,
                              value: _getStationClass(data[1]['StationClass']),
                            ),
                            _buildInfoItem(
                              icon: Icons.phone_rounded,
                              label: AppLocalizations.of(context)!.text_869,
                              value: data[1]['StationPhone'] ?? AppLocalizations.of(context)!.text_870,
                            ),
                            _buildInfoItem(
                              icon: Icons.qr_code_rounded,
                              label: AppLocalizations.of(context)!.text_871,
                              value: data[1]['StationID'] ?? AppLocalizations.of(context)!.text_872,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 設施地圖和電梯資訊
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
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        ...facilityMaps.map((facility) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF3FB),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.map_rounded,
                                          size: 18,
                                          color: Color(0xFF1A73E8),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        facility['mapName']!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    facility['mapURL']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Text(
                                            AppLocalizations.of(context)!.text_873,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        if (elevatorInfo != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF34C759).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.elevator_rounded,
                                    size: 20,
                                    color: Color(0xFF34C759),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "電梯資訊: $elevatorInfo",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        final dep = train['DepartureTime'];
        if (dep == null) continue;

        final parts = dep.split(':');
        if (parts.length < 2) continue;

        int? depHour = int.tryParse(parts[0]);
        int? depMinute = int.tryParse(parts[1]);
        if (depHour == null || depMinute == null) continue;

        final trainDepTime = DateTime(
          widget.datetime.year,
          widget.datetime.month,
          widget.datetime.day,
          depHour,
          depMinute,
        );

        if (trainDepTime.isAfter(widget.datetime)) {
          // 根據新卡片設計計算滾動位置 (140px 卡片高度 + 12px 間距)
          double offset = i * 152.0;

          scrollController.animateTo(
            offset.clamp(0.0, scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          break;
        }
      }
    }


    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: fetchTrainStation(widget.stationID, widget.datetime),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.train_rounded,
                      size: 28,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.text_874,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 28,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.text_875,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.text_206,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 28,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    AppLocalizations.of(context)!.text_876,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ],
              ),
            );
          } else {
            trainData = snapshot.data!;

            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Future.delayed(const Duration(milliseconds: 60));
              scrollToNearestTrain();
            });

            return Column(
              children: [
                // 標題欄 - 放在頂部只顯示一次
                // _buildHeaderRow(),
                // const SizedBox(height: 16),

                // 列車列表
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: trainData.length,
                    itemBuilder: (context, index) {
                      var train = trainData[index];
                      String trainNo = (train['TrainNo']) ?? AppLocalizations.of(context)!.text_321;
                      String trainType = convertTrainType(train['TrainTypeName']['Zh_tw']);
                      String departureTime = _formatTime(train['DepartureTime'] ?? AppLocalizations.of(context)!.text_321);
                      int? delayTime = train['DelayTime'];
                      String endingStation = train['EndingStationName']['Zh_tw'] ?? AppLocalizations.of(context)!.text_321;


                      // 判斷是否為未讀/重要狀態（延誤的列車）
                      bool isDelayed = delayTime != null && delayTime > 0;
                      bool isExpress = trainType.contains(AppLocalizations.of(context)!.text_877) || trainType.contains(AppLocalizations.of(context)!.text_878) || trainType.contains(AppLocalizations.of(context)!.text_879);

                      return Transform.translate(
                        offset: Offset(0, index * 0.3), // 微妙的層次感
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrainSchedulePage(

                                    type: 'trainNo',
                                    time: widget.datetime,trainNo: int.parse(train['TrainNo'].replaceAll(RegExp(r'[^0-9]'), '')),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
                            highlightColor: const Color(0xFFEEF3FB).withOpacity(0.5),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDelayed ? 0.08 : 0.04),
                                    blurRadius: isDelayed ? 20 : 12,
                                    offset: Offset(0, isDelayed ? 6 : 3),
                                  ),
                                ],
                                border: isDelayed
                                    ? Border.all(
                                  color: const Color(0xFFFF3B30).withOpacity(0.2),
                                  width: 1.5,
                                )
                                    : isExpress
                                    ? Border.all(
                                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                                  width: 1,
                                )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  // 左側裝飾線（延誤列車）
                                  if (isDelayed)
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 4,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFFF3B30),
                                              const Color(0xFFFF3B30).withOpacity(0.7),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft: Radius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ),

                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isDelayed ? 20 : 24,
                                      right: 24,
                                      top: 20,
                                      bottom: 20,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 車次圖標區域
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: _getTrainTypeGradient(trainType),
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getTrainTypeColor(trainType).withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _getTrainTypeIcon(trainType),
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // 內容區域
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // 車次和時間
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '車次 $trainNo',
                                                          style: TextStyle(
                                                            fontSize: 17,
                                                            fontWeight: FontWeight.w700,
                                                            color: isDelayed ? Colors.black87 : Colors.grey[700],
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        // const SizedBox(height: 4),
                                                        // Text(
                                                        //   trainType,
                                                        //   style: TextStyle(
                                                        //     fontSize: 14,
                                                        //     color: Colors.grey[600],
                                                        //     fontWeight: FontWeight.w500,
                                                        //   ),
                                                        // ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: isDelayed
                                                          ? const Color(0xFFFF3B30).withOpacity(0.1)
                                                          : const Color(0xFF1A73E8).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      departureTime,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDelayed
                                                            ? const Color(0xFFFF3B30)
                                                            : const Color(0xFF1A73E8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              // 終點站和狀態
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '往 $endingStation',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                        height: 1.4,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),

                                                  // 狀態標籤
                                                  if (isDelayed)
                                                    _buildStatusBadge('延誤 ${delayTime}分', const Color(0xFFFF3B30))
                                                  // else if (isExpress)
                                                  //   _buildStatusBadge('快速', const Color(0xFF1A73E8))
                                                  // else
                                                  //   _buildStatusBadge('準點', const Color(0xFF34C759)),
                                                ],
                                              ),

                                              // 類型標籤
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getTrainTypeColor(trainType).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: _getTrainTypeColor(trainType).withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      (trainType),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _getTrainTypeColor(trainType),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  // 導航箭頭
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Icon(
                                                      Icons.arrow_forward_ios_rounded,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            );
          }
        },
      ),
    );

  }
// 輔助方法
  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  LinearGradient _getTrainTypeGradient(String trainType) {
    final color = _getTrainTypeColor(trainType);
    return LinearGradient(
      colors: [
        color,
        color.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getTrainTypeColor(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) || trainType.contains(AppLocalizations.of(context)!.text_878) || trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return const Color(0xFF1A73E8); // 藍色 - 特快車
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return const Color(0xFF34C759); // 綠色 - 普通快車
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883) || trainType.contains(AppLocalizations.of(context)!.text_884)) {
      return const Color(0xFFFF9500); // 橙色 - 區間車
    } else {
      return const Color(0xFFAF52DE); // 紫色 - 其他
    }
  }

  IconData _getTrainTypeIcon(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) || trainType.contains(AppLocalizations.of(context)!.text_878) || trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return Icons.directions_railway_filled_rounded;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return Icons.train_rounded;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883) || trainType.contains(AppLocalizations.of(context)!.text_884)) {
      return Icons.directions_subway_rounded;
    } else {
      return Icons.directions_transit_rounded;
    }
  }

  String _getTrainTypeCategory(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) || trainType.contains(AppLocalizations.of(context)!.text_878) || trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return AppLocalizations.of(context)!.text_885;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return AppLocalizations.of(context)!.text_886;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883)) {
      return AppLocalizations.of(context)!.text_65;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_884)) {
      return AppLocalizations.of(context)!.text_137;
    } else {
      return AppLocalizations.of(context)!.text_542;
    }
  }
// 標題欄 - 放在頂部只顯示一次
  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 車次標題
          Expanded(
            flex: 2,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_887, Icons.confirmation_number_rounded),
          ),

          // 發車時間標題
          Expanded(
            flex: 2,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_888, Icons.schedule_rounded),
          ),

          // 車種標題
          Expanded(
            flex: 2,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_889, Icons.train_rounded),
          ),

          // 終點站標題
          Expanded(
            flex: 3,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_57, Icons.flag_rounded),
          ),

          // 狀態標題
          Expanded(
            flex: 2,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_890, Icons.info_outline_rounded),
          ),

          // 空白對齊箭頭
          const SizedBox(width: 16),
        ],
      ),
    );
  }

// 標題項目
  Widget _buildHeaderItem(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF1A73E8),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A73E8),
          ),
        ),
      ],
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
  // =============================
  // 篩選條件
  // =============================
  bool onlyDirect = false;
  bool onlyTransfer = false;
  int maxTotalMinutes = 999;
  Set<String> allowedTrainTypes = {};

  // =============================
  // 滾動控制器
  // =============================
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // =============================
  // 滾動狀態追蹤
  // =============================
  bool _shouldAutoScroll = true;
  DateTime? _lastScrollTime;
  DateTime? _previousDate;

  // 通知中心主題色
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceColor = Color(0xFFEEF3FB);

  @override
  void didUpdateWidget(RoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _shouldAutoScroll = true;
      _previousDate = oldWidget.date;
    }
  }

  @override
  void initState() {
    super.initState();
    _previousDate = widget.date;
  }

  // =============================
  // API
  // =============================
  Future<Map<String, dynamic>> queryTrainList() async {
    final weekday = widget.date.weekday % 7;
    final url =
        'http://hidden.rsmn574.com:3920/api/train'
        '?from=${widget.departure["StationID"]}'
        '&to=${widget.destination["StationID"]}'
        '&day=$weekday';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  // =============================
  // 時間處理
  // =============================
  int _timeToMinutes(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  int _selectedMinutes() {
    return widget.date.hour * 60 + widget.date.minute;
  }

  int trainDepMinutes(dynamic t) {
    final timeStr = t['transfer'] == true
        ? t['leg1']['depTime']
        : t['depTime'];
    return _timeToMinutes(timeStr);
  }

  // =============================
  // 合併、排序、篩選
  // =============================
  List<dynamic> buildTrains(List direct, List transfer) {
    final all = [
      ...direct.map((e) => {...e, 'transfer': false}),
      ...transfer.map((e) => {...e, 'transfer': true}),
    ];

    return all.where((t) {
      if (onlyDirect && t['transfer']) return false;
      if (onlyTransfer && !t['transfer']) return false;

      if (t['transfer'] &&
          t['totalTimeMin'] != null &&
          t['totalTimeMin'] > maxTotalMinutes) {
        return false;
      }

      final types = t['transfer']
          ? [
        t['leg1']['TrainTypeName'],
        t['leg2']['TrainTypeName'],
      ]
          : [t['TrainTypeName']];

      if (allowedTrainTypes.isNotEmpty &&
          !types.any((e) => allowedTrainTypes.contains(e))) {
        return false;
      }

      return true;
    }).toList()
      ..sort(
            (a, b) => trainDepMinutes(a).compareTo(trainDepMinutes(b)),
      );
  }

  // =============================
  // 找最接近選擇時間的 index
  // =============================
  int findClosestTrainIndex(List<dynamic> trains) {
    final base = _selectedMinutes();
    for (int i = 0; i < trains.length; i++) {
      if (trainDepMinutes(trains[i]) >= base) {
        return i;
      }
    }
    return trains.isNotEmpty ? trains.length - 1 : 0;
  }

  // =============================
  // 檢查是否需要滾動
  // =============================
  bool _shouldScrollToClosest() {
    if (_shouldAutoScroll) return true;
    if (_previousDate != null && widget.date != _previousDate) return true;
    if (_lastScrollTime == null ||
        DateTime.now().difference(_lastScrollTime!) > const Duration(seconds: 2)) {
      return true;
    }
    return false;
  }

  // =============================
  // 取得車種顏色
  // =============================
  Color _getTrainTypeColor(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) || trainType.contains(AppLocalizations.of(context)!.text_878) || trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return primaryBlue;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return successGreen;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883) || trainType.contains(AppLocalizations.of(context)!.text_884)) {
      return warningOrange;
    } else {
      return purple;
    }
  }

  // =============================
  // UI 卡片 - 直達車
  // =============================
  Widget directCard(dynamic t) {
    final trainType = t['TrainTypeName'] ?? '';
    final typeColor = _getTrainTypeColor(trainType);
    final trainNo = t['TrainNo'];

    return InkWell(
      onTap: () async {
        try {

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainSchedulePage(

                  type: 'trainNo',
                  time: widget.date,trainNo:trainNo
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint(AppLocalizations.of(context)!.text_891);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('查詢車次 $trainNo 失敗'),
                backgroundColor: errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時間區
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(AppLocalizations.of(context)!.text_67, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    t['depTime'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_railway_rounded, size: 16, color: successGreen),
                    const SizedBox(width: 4),
                     Text(
                      AppLocalizations.of(context)!.text_892,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(AppLocalizations.of(context)!.text_68, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    t['arrTime'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 車次資訊
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [typeColor, typeColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.train_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '車次 $trainNo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trainType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getTravelTime(t['depTime'], t['arrTime']),
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // 計算旅行時間
  // =============================
  String _getTravelTime(String dep, String arr) {
    final depMin = _timeToMinutes(dep);
    final arrMin = _timeToMinutes(arr);
    final diff = arrMin - depMin;
    return '${diff ~/ 60}小時${diff % 60}分';
  }

  // =============================
  // UI 卡片 - 轉乘車
  // =============================
  Widget transferTimeline(dynamic t) {
    final tight = t['isTight'] == true;
    final totalMin = t['totalTimeMin'] ?? 0;
    final leg1 = t['leg1'];
    final leg2 = t['leg2'];
    final trainNo1 = leg1['TrainNo'];
    final trainNo2 = leg2['TrainNo'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 總時間標籤
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tight ? errorRed.withOpacity(0.1) : warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tight ? errorRed.withOpacity(0.3) : warningOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tight ? Icons.warning_amber_rounded : Icons.timeline_rounded,
                    size: 16,
                    color: tight ? errorRed : warningOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t['totalTimeHuman'] ?? '${totalMin ~/ 60}小時${totalMin % 60}分',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tight ? errorRed : warningOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '轉乘 ${t['waitMin']} 分',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 時間軸
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 時間軸圖標
            Column(
              children: [
                _buildTimelineDot(successGreen),
                _buildTimelineLine(),
                _buildTimelineDot(tight ? errorRed : warningOrange),
                _buildTimelineLine(),
                _buildTimelineDot(primaryBlue),
              ],
            ),
            const SizedBox(width: 12),

            // 行程內容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一段車程 - 可點擊
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _navigateToTrainDetail(trainNo1);
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: _getTrainTypeColor(leg1['TrainTypeName']).withOpacity(0.1),
                      child: _buildLegCard(leg1, isFirst: true),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTransferStationCard(t['transferStation'], tight),
                  const SizedBox(height: 8),
                  // 第二段車程 - 可點擊
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _navigateToTrainDetail(trainNo2);
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: _getTrainTypeColor(leg2['TrainTypeName']).withOpacity(0.1),
                      child: _buildLegCard(leg2, isFirst: false),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

// 新增：車次詳情導航方法
  Future<void> _navigateToTrainDetail(String trainNo) async {
    try {

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainSchedulePage(

              type: 'trainNo',
              time: widget.date, trainNo: int.parse(trainNo.replaceAll(RegExp(r'[^0-9]'), ''),)
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(AppLocalizations.of(context)!.text_891);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('查詢車次 $trainNo 失敗'),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTimelineDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: 2,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[300]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildLegCard(dynamic leg, {required bool isFirst}) {
    final trainType = leg['TrainTypeName'] ?? '';
    final typeColor = _getTrainTypeColor(trainType);
    final trainNo = leg['TrainNo'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [typeColor, typeColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFirst ? Icons.departure_board_rounded : Icons.train_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${leg['depTime']} → ${leg['arrTime']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '車次 $trainNo',
                        style: TextStyle(
                          fontSize: 11,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  trainType,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTransferStationCard(dynamic station, bool tight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tight ? errorRed.withOpacity(0.05) : warningOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tight ? errorRed.withOpacity(0.2) : warningOrange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tight ? errorRed.withOpacity(0.1) : warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.transfer_within_a_station_rounded,
              size: 16,
              color: tight ? errorRed : warningOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '轉乘站 ${station['name']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tight ? errorRed : warningOrange,
                  ),
                ),
                if (tight)
                  Text(
                    AppLocalizations.of(context)!.text_893,
                    style: TextStyle(
                      fontSize: 11,
                      color: errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // 顯示日期的格式
  // =============================
  String _formatDate(DateTime date) {
    final weekday = [AppLocalizations.of(context)!.text_306, AppLocalizations.of(context)!.text_307, AppLocalizations.of(context)!.text_308, AppLocalizations.of(context)!.text_309, AppLocalizations.of(context)!.text_310, AppLocalizations.of(context)!.text_311, AppLocalizations.of(context)!.text_312][date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日 週$weekday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // =============================
  // 畫面
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.train_rounded, size: 20, color: primaryBlue),
            const SizedBox(width: 8),
            Text(
              '${widget.departure["StationName"]["Zh_tw"]}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: primaryBlue),
            ),
            Text(
              '${widget.destination["StationName"]["Zh_tw"]}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: queryTrainList(),
        key: ValueKey('${widget.date.day}-${widget.date.hour}-${widget.date.minute}'),
        builder: (_, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.text_894,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (s.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [errorRed.withOpacity(0.1), errorRed.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded, size: 40, color: errorRed),
                    ),
                    const SizedBox(height: 16),
                     Text(
                      AppLocalizations.of(context)!.text_205,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: errorRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.text_206,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = s.data!;
          final trains = buildTrains(data['direct'] ?? [], data['transfer'] ?? []);

          if (trains.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryBlue.withOpacity(0.1), primaryBlue.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.train_outlined, size: 50, color: primaryBlue),
                    ),
                    const SizedBox(height: 24),
                     Text(
                      AppLocalizations.of(context)!.text_207,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.text_895,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_shouldScrollToClosest() && trains.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final closestIndex = findClosestTrainIndex(trains);
              if (closestIndex >= 0 && closestIndex < trains.length) {
                _itemScrollController.scrollTo(
                  index: closestIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: 0.2,
                );
                _lastScrollTime = DateTime.now();
                _shouldAutoScroll = false;
                _previousDate = widget.date;
              }
            });
          }

          return Column(
            children: [
              // 日期時間標籤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryBlue.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 16, color: primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(widget.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // 列表
              Expanded(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: trains.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemBuilder: (_, i) {
                    final t = trains[i];
                    final isClosest = i == findClosestTrainIndex(trains);
                    final isAfterSelectedTime = trainDepMinutes(t) >= _selectedMinutes();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isClosest ? 0.1 : 0.04),
                            blurRadius: isClosest ? 20 : 12,
                            offset: Offset(0, isClosest ? 6 : 4),
                          ),
                        ],
                        border: isClosest
                            ? Border.all(color: primaryBlue, width: 2)
                            : !isAfterSelectedTime
                            ? Border.all(color: Colors.grey[300]!, width: 1)
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(

                          borderRadius: BorderRadius.circular(20),
                          splashColor: primaryBlue.withOpacity(0.1),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: t['transfer'] ? transferTimeline(t) : directCard(t),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
