import 'dart:async';

import 'package:provider/provider.dart';
import 'package:com.rsmn574.app/features/railway/state/railway_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:com.rsmn574.app/features/railway/pages/hsr_schedule_page.dart';

import 'package:com.rsmn574.app/features/railway/widgets/hsr_station_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:com.rsmn574.app/features/railway/data/get_hsr.dart';
import 'package:com.rsmn574.app/database/get_data.dart';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';

import '../../../firebase/analytics_service.dart';

// 高鐵主題色
const Color primaryColor = Color(0xFFDC5321); // 高鐵橘
const Color surfaceColor = Color(0xFFF8F9FA); // 背景色
const Color textPrimary = Color(0xFF2D3748); // 主要文字
const Color textSecondary = Color(0xFF718096); // 次要文字

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
    unawaited(AppAnalytics.logFeatureOpened('hsr'));
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
        title: Text(
          AppLocalizations.of(context)!.text_144,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: textPrimary),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.text_145),
            Tab(text: AppLocalizations.of(context)!.text_146),
            Tab(text: AppLocalizations.of(context)!.text_147),
          ],
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
        ),
        actions: [],
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

  const TripNumberSearchPage({Key? key, required this.controller})
      : super(key: key);

  @override
  _TripNumberSearchPageState createState() => _TripNumberSearchPageState();
}

class _TripNumberSearchPageState extends State<TripNumberSearchPage> {
  // 高鐵主題色 - 保留高鐵橘，但調整為通知中心風格
  static const Color primaryHSR = Color(0xFFDC5321); // 高鐵標準橘
  static const Color primaryLight = Color(0xFFFEF2E6); // 淺橘背景
  static const Color backgroundLight = Color(0xFFF8FAFD); // 通知中心背景色
  static const Color surfaceColor = Color(0xFFEEF3FB); // 通知中心表面色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字
  static const Color successGreen = Color(0xFF34C759); // 成功綠色
  static const Color errorRed = Color(0xFFFF3B30); // 錯誤紅色

  DateTime selectedDate = DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');
  bool _isInputValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isInputValid = widget.controller.text.trim().isNotEmpty;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: primaryHSR,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryHSR,
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
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題區域 - 與火車查詢系統一致
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.directions_railway_filled_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.text_148,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: primaryHSR,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.text_149,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 查詢卡片 - 與火車查詢系統一致的卡片設計
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
                      // 車次輸入框 - 高鐵橘主題
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.controller.text.isEmpty
                                ? const Color(0xFFEEF3FB)
                                : primaryHSR.withOpacity(0.3),
                            width: widget.controller.text.isEmpty ? 1 : 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: widget.controller,
                          onChanged: (value) => _validateInput(),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.text_150,
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.directions_railway_filled_rounded,
                                color: primaryHSR,
                              ),
                            ),
                            suffixIcon: _isInputValid
                                ? Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryHSR.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: primaryHSR,
                                    ),
                                  )
                                : null,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 日期選擇按鈕 - 與火車查詢系統一致的設計
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: primaryHSR.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryHSR.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryHSR.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: primaryHSR,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(selectedDate),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryHSR,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: primaryHSR,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 查詢按鈕 - 高鐵橘漸層
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryHSR.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isInputValid
                                ? () async {
                                    try {
                                      var trainData = await fetchHSR(
                                        int.parse(widget.controller.text)
                                            .toString()
                                            .padLeft(4, '0'),
                                        selectedDate,
                                      );

                                      if (trainData == null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  AppLocalizations.of(context)!
                                                      .text_151),
                                              backgroundColor: errorRed,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HSRSchedulePage(
                                                trainData: trainData,
                                                type: 'trainNo',
                                                time: selectedDate,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                AppLocalizations.of(context)!
                                                    .text_152),
                                            backgroundColor: errorRed,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(child: Text(
                                    AppLocalizations.of(context)!.text_153,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ), maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 提示資訊 - 與火車查詢系統一致
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
                          color: primaryHSR.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: primaryHSR,
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
                                color: primaryHSR,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_155,
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

                // 快速選擇 - 高鐵常見車次
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          AppLocalizations.of(context)!.text_156,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryHSR,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          '0813',
                          '0618',
                          '0624',
                          '0826',
                          '0636',
                        ].map((trainNo) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.controller.text = trainNo;
                                _validateInput();
                              },
                              borderRadius: BorderRadius.circular(20),
                              splashColor: primaryHSR.withOpacity(0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryHSR.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryHSR.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  trainNo,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryHSR,
                                    fontWeight: FontWeight.w600,
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
  // 高鐵主題色 - 保留高鐵橘
  static const Color primaryHSR = Color(0xFFDC5321); // 高鐵標準橘
  static const Color backgroundLight = Color(0xFFF8FAFD); // 通知中心背景色
  static const Color surfaceColor = Color(0xFFEEF3FB); // 通知中心表面色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字
  static const Color successGreen = Color(0xFF34C759); // 成功綠色
  static const Color errorRed = Color(0xFFFF3B30); // 錯誤紅色

  Map<String, dynamic> departureSelectedStation = {};
  Map<String, dynamic> destinationSelectedStation = {};
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH:mm');

  // 選擇狀態
  bool _isDepartureSelected = false;
  bool _isDestinationSelected = false;

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)), // 高鐵可查90天
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: primaryHSR,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).colorScheme.surface,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryHSR,
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
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: primaryHSR,
                    onPrimary: Theme.of(context).colorScheme.onPrimary,
                    surface: Theme.of(context).colorScheme.surface,
                    onSurface: Theme.of(context).colorScheme.onSurface,
                  ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteTextColor: primaryHSR,
                dayPeriodTextColor: primaryHSR,
                dayPeriodColor: primaryHSR.withOpacity(0.1),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: primaryHSR.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                hourMinuteColor: primaryHSR.withOpacity(0.05),
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: primaryHSR.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                dialBackgroundColor: backgroundLight,
                dialTextColor: primaryHSR,
                entryModeIconColor: primaryHSR,
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
    if (departureSelectedStation.isEmpty &&
        destinationSelectedStation.isEmpty) {
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

      if (widget.departureController.text ==
              widget.destinationController.text &&
          widget.departureController.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.text_157),
            backgroundColor: errorRed,
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
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題區域 - 與火車查詢系統一致
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
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
                        AppLocalizations.of(context)!.text_158,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: primaryHSR,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.text_159,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 查詢卡片 - 與火車查詢系統一致的卡片設計
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
                            final selectedStation =
                                await StationDialog.showStationDialog(context);
                            if (selectedStation != null) {
                              setState(() {
                                departureSelectedStation = selectedStation;
                                _isDepartureSelected = true;
                                widget.departureController.text =
                                    departureSelectedStation['StationName']
                                            ['Zh_tw'] ??
                                        AppLocalizations.of(context)!.text_160;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: primaryHSR.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _isDepartureSelected
                                  ? primaryHSR.withOpacity(0.05)
                                  : backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDepartureSelected
                                    ? primaryHSR.withOpacity(0.3)
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
                                        ? primaryHSR
                                        : primaryHSR.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.departure_board_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_63,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isDepartureSelected
                                              ? primaryHSR
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isDepartureSelected
                                            ? widget.departureController.text
                                            : AppLocalizations.of(context)!
                                                .text_161,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _isDepartureSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _isDepartureSelected
                                              ? primaryHSR
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
                                      color: primaryHSR.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: primaryHSR,
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
                              color: primaryHSR.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primaryHSR.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Transform.rotate(
                              angle: 90 * (3.1415926535 / 180),
                              child: Icon(
                                Icons.swap_vert_rounded,
                                color: primaryHSR,
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
                            final selectedStation =
                                await StationDialog.showStationDialog(context);
                            if (selectedStation != null) {
                              setState(() {
                                destinationSelectedStation = selectedStation;
                                _isDestinationSelected = true;
                                widget.destinationController.text =
                                    destinationSelectedStation['StationName']
                                            ['Zh_tw'] ??
                                        AppLocalizations.of(context)!.text_160;
                              });

                              if (widget.departureController.text ==
                                  widget.destinationController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppLocalizations.of(context)!.text_157),
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
                          borderRadius: BorderRadius.circular(12),
                          splashColor: primaryHSR.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _isDestinationSelected
                                  ? primaryHSR.withOpacity(0.05)
                                  : backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isDestinationSelected
                                    ? primaryHSR.withOpacity(0.3)
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
                                        ? primaryHSR
                                        : primaryHSR.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.flag_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_162,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isDestinationSelected
                                              ? primaryHSR
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isDestinationSelected
                                            ? widget.destinationController.text
                                            : AppLocalizations.of(context)!
                                                .text_163,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _isDestinationSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _isDestinationSelected
                                              ? primaryHSR
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
                                      color: primaryHSR.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: primaryHSR,
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
                          splashColor: primaryHSR.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selectedDate != null
                                  ? primaryHSR.withOpacity(0.05)
                                  : backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedDate != null
                                    ? primaryHSR.withOpacity(0.3)
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
                                        ? primaryHSR
                                        : primaryHSR.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: selectedDate != null
                                        ? Colors.white
                                        : primaryHSR,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_164,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selectedDate != null
                                              ? primaryHSR
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedDate != null
                                            ? dateFormat.format(selectedDate!)
                                            : AppLocalizations.of(context)!
                                                .text_165,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: selectedDate != null
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selectedDate != null
                                              ? primaryHSR
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
                                      ? primaryHSR
                                      : Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 查詢按鈕 - 高鐵橘漸層
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryHSR.withOpacity(0.3),
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
                                    content: Text(
                                        AppLocalizations.of(context)!.text_161),
                                    backgroundColor: errorRed,
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
                                    content: Text(
                                        AppLocalizations.of(context)!.text_163),
                                    backgroundColor: errorRed,
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
                                    date: selectedDate ??
                                        DateTime.now()
                                            .add(const Duration(minutes: 1)),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(child: Text(
                                    AppLocalizations.of(context)!.text_166,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ), maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 提示資訊 - 與火車查詢系統一致
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
                          color: primaryHSR.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: primaryHSR,
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
                                color: primaryHSR,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_167,
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

                // 熱門路線快速選擇
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          AppLocalizations.of(context)!.text_168,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryHSR,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppLocalizations.of(context)!.text_169,
                          AppLocalizations.of(context)!.text_170,
                          AppLocalizations.of(context)!.text_171,
                          AppLocalizations.of(context)!.text_172,
                          AppLocalizations.of(context)!.text_173,
                        ].map((route) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                final stations = route.split('→');
                                // TODO: 設置熱門路線
                              },
                              borderRadius: BorderRadius.circular(20),
                              splashColor: primaryHSR.withOpacity(0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryHSR.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryHSR.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  route,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryHSR,
                                    fontWeight: FontWeight.w600,
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

class StationSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const StationSearchPage({Key? key, required this.controller})
      : super(key: key);

  @override
  _StationSearchPageState createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {
  // 高鐵主題色 - 保留高鐵橘
  static const Color primaryHSR = Color(0xFFDC5321); // 高鐵標準橘
  static const Color backgroundLight = Color(0xFFF8FAFD); // 通知中心背景色
  static const Color surfaceColor = Color(0xFFEEF3FB); // 通知中心表面色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字
  static const Color successGreen = Color(0xFF34C759); // 成功綠色
  static const Color errorRed = Color(0xFFFF3B30); // 錯誤紅色

  final DateFormat dateFormat = DateFormat('yyyy年MM月dd日');
  final TextEditingController _controller = TextEditingController();

  late final Map<String, List<String>> stations = {
    AppLocalizations.of(context)!.text_174: [
      AppLocalizations.of(context)!.text_175,
      AppLocalizations.of(context)!.text_176,
      AppLocalizations.of(context)!.text_177
    ],
    AppLocalizations.of(context)!.text_8: [
      AppLocalizations.of(context)!.text_178,
      AppLocalizations.of(context)!.text_179,
      AppLocalizations.of(context)!.text_180
    ],
    AppLocalizations.of(context)!.text_9: [
      AppLocalizations.of(context)!.text_181,
      AppLocalizations.of(context)!.text_182,
      AppLocalizations.of(context)!.text_183
    ],
    AppLocalizations.of(context)!.text_184: [
      AppLocalizations.of(context)!.text_185,
      AppLocalizations.of(context)!.text_186,
      AppLocalizations.of(context)!.text_187
    ],
    AppLocalizations.of(context)!.text_188: [
      AppLocalizations.of(context)!.text_189,
      AppLocalizations.of(context)!.text_190,
      AppLocalizations.of(context)!.text_191
    ],
    AppLocalizations.of(context)!.text_11: [
      AppLocalizations.of(context)!.text_192,
      AppLocalizations.of(context)!.text_193,
      AppLocalizations.of(context)!.text_194
    ],
  };

  String? selectedCity;
  Map<String, dynamic>? selectedStation;
  bool _isStationSelected = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_validateInput);
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isStationSelected = _controller.text.trim().isNotEmpty;
    });
  }

  Future<void> openURL(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('無效的 URL'),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final String encodedUrl = Uri.encodeFull(url);
    final Uri uri = Uri.parse(encodedUrl);

    try {
      final bool canOpen = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (canOpen) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.text_195),
            backgroundColor: errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.text_196),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 標題區域 - 與火車查詢系統一致
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
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
                        AppLocalizations.of(context)!.text_197,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: primaryHSR,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.text_198,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // 查詢卡片 - 與火車查詢系統一致的卡片設計
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
                      // 車站選擇
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final selected =
                                await StationDialog.showStationDialog(context);
                            if (selected != null) {
                              setState(() {
                                selectedStation = selected;
                                _controller.text =
                                    selected['StationName']['Zh_tw'] ?? '';
                                _isStationSelected = true;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: primaryHSR.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _isStationSelected
                                  ? primaryHSR.withOpacity(0.05)
                                  : backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isStationSelected
                                    ? primaryHSR.withOpacity(0.3)
                                    : const Color(0xFFEEF3FB),
                                width: _isStationSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isStationSelected
                                        ? primaryHSR
                                        : primaryHSR.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.train_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.text_199,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isStationSelected
                                              ? primaryHSR
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _isStationSelected
                                            ? _controller.text
                                            : AppLocalizations.of(context)!
                                                .text_200,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: _isStationSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _isStationSelected
                                              ? primaryHSR
                                              : Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isStationSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryHSR.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: primaryHSR,
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

                      const SizedBox(height: 24),

                      // 查詢按鈕 - 高鐵橘漸層
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryHSR.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isStationSelected
                                ? () async {
                                    if (selectedStation != null) {
                                      await openURL(
                                          selectedStation!["URL"], context);
                                    }
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(child: Text(
                                    AppLocalizations.of(context)!.text_201,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ), maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 提示資訊 - 與火車查詢系統一致
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
                          color: primaryHSR.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: primaryHSR,
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
                                color: primaryHSR,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_202,
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
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          AppLocalizations.of(context)!.text_203,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryHSR,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AppLocalizations.of(context)!.text_175,
                          AppLocalizations.of(context)!.text_185,
                          AppLocalizations.of(context)!.text_192,
                          AppLocalizations.of(context)!.text_193,
                          AppLocalizations.of(context)!.text_178,
                          AppLocalizations.of(context)!.text_181,
                        ].map((stationName) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // TODO: 設置熱門車站
                                setState(() {
                                  _controller.text = stationName;
                                  _isStationSelected = true;
                                });
                                // 這裡可以設置對應的 selectedStation
                              },
                              borderRadius: BorderRadius.circular(20),
                              splashColor: primaryHSR.withOpacity(0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryHSR.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryHSR.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  stationName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryHSR,
                                    fontWeight: FontWeight.w600,
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
  // 高鐵主題色 - 保留高鐵橘
  static const Color primaryHSR = Color(0xFFDC5321); // 高鐵標準橘
  static const Color backgroundLight = Color(0xFFF8FAFD); // 通知中心背景色
  static const Color surfaceColor = Color(0xFFEEF3FB); // 通知中心表面色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字
  static const Color successGreen = Color(0xFF34C759); // 成功綠色
  static const Color errorRed = Color(0xFFFF3B30); // 錯誤紅色
  static const Color warningOrange = Color(0xFFFF9500); // 警告橘色

  final ItemScrollController _itemScrollController = ItemScrollController();
  late ScrollController _scrollController;
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatForRoutePage = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.departure["StationName"]["Zh_tw"],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: primaryHSR,
              ),
            ),
            Text(
              widget.destination["StationName"]["Zh_tw"],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: context.read<RailwayProvider>().hsrRoute(
          widget.departure["StationID"],
          widget.destination["StationID"],
          dateFormatForRoutePage.format(widget.date),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                    const CircularProgressIndicator(
                      color: primaryHSR,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.text_204,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryHSR,
                      ),
                    ),
                  ],
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
                            errorRed.withOpacity(0.1),
                            errorRed.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: errorRed,
                      ),
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
                            primaryHSR.withOpacity(0.1),
                            primaryHSR.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.train_outlined,
                        size: 50,
                        color: primaryHSR,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.text_207,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryHSR,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.text_208,
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
            final dateFormat = DateFormat('HH:mm');
            final trainDateFormat = DateFormat('yy-MM-dd');

            // 找最近時間車次並捲動
            if (!_hasScrolled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                int closestIndex = 0;
                Duration minDiff = const Duration(days: 999);
                for (int i = 0; i < data.length; i++) {
                  final train = data[i];
                  final depTimeStr = train["TrainDate"] +
                      ' ' +
                      train["OriginStopTime"]["DepartureTime"];
                  final depTime = DateTime.tryParse(depTimeStr);
                  if (depTime != null) {
                    final diff = (depTime.difference(widget.date)).abs();
                    if (diff < minDiff) {
                      closestIndex = i;
                      minDiff = diff;
                    }
                  }
                }
                _itemScrollController.scrollTo(
                  index: closestIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _hasScrolled = true;
              });
            }

            return Column(
              children: [
                // 日期時間標籤
                Container(
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryHSR.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryHSR.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: primaryHSR,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(child: Text(
                        DateFormat('yyyy年MM月dd日 HH:mm').format(widget.date),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryHSR,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                    ],
                  ),
                ),

                // 列表
                Expanded(
                  child: ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemCount: data.length,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemBuilder: (context, index) {
                      final train = data[index];
                      final origin = train["OriginStopTime"];
                      final destination = train["DestinationStopTime"];
                      final info = train["DailyTrainInfo"];

                      final startTime = origin["DepartureTime"];
                      final endTime = destination["ArrivalTime"];
                      final trainNo = info["TrainNo"];

                      // 檢查是否為最接近的班次
                      final isClosest = _findClosestIndex(data) == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isClosest ? 0.1 : 0.04),
                              blurRadius: isClosest ? 20 : 12,
                              offset: Offset(0, isClosest ? 6 : 4),
                            ),
                          ],
                          border: isClosest
                              ? Border.all(
                                  color: primaryHSR,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              var trainData = await fetchHSR(
                                trainNo,
                                DateTime.parse(train["TrainDate"]),
                              );
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HSRSchedulePage(
                                      trainData: trainData,
                                      type: 'trainNo',
                                      time: DateTime.parse(train["TrainDate"]),
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            splashColor: primaryHSR.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 日期與車次
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: surfaceColor,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          trainDateFormat.format(DateTime.parse(
                                              train["TrainDate"])),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryHSR.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.train_rounded,
                                              size: 14,
                                              color: primaryHSR,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              trainNo,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: primaryHSR,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // 時間資訊
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // 出發站
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              startTime,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: primaryHSR
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .departure_board_rounded,
                                                    size: 14,
                                                    color: primaryHSR,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    origin["StationName"]
                                                        ["Zh_tw"],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 箭頭
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 12),
                                              decoration: BoxDecoration(
                                                color:
                                                    primaryHSR.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                                color: primaryHSR,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 到達站
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              endTime,
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                                // textAlign: TextAlign.end,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    destination["StationName"]
                                                        ["Zh_tw"],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.end,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: successGreen
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    Icons.flag_rounded,
                                                    size: 14,
                                                    color: successGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // 票價與座位資訊
                                  // FutureBuilder<Map<String, dynamic>>(
                                  //   future: _fetchSeatStatus(train),
                                  //   builder: (context, seatSnapshot) {
                                  //     if (!seatSnapshot.hasData) {
                                  //       return Container(
                                  //         padding: const EdgeInsets.symmetric(vertical: 8),
                                  //         child: const Center(
                                  //           child: SizedBox(
                                  //             width: 20,
                                  //             height: 20,
                                  //             child: CircularProgressIndicator(
                                  //               strokeWidth: 2,
                                  //               color: primaryHSR,
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       );
                                  //     }
                                  //
                                  //     final seatData = seatSnapshot.data!;
                                  //     final standardStatus = seatData["AvailableSeats"]?[0]?["StandardSeatStatus"] ?? 'N';
                                  //     final businessStatus = seatData["AvailableSeats"]?[0]?["BusinessSeatStatus"] ?? 'N';
                                  //
                                  //     return Container(
                                  //       padding: const EdgeInsets.all(16),
                                  //       decoration: BoxDecoration(
                                  //         color: surfaceColor,
                                  //         borderRadius: BorderRadius.circular(12),
                                  //       ),
                                  //       child: Row(
                                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //         children: [
                                  //           // 票價
                                  //           Column(
                                  //             crossAxisAlignment: CrossAxisAlignment.start,
                                  //             children: [
                                  //               const Text(
                                  //                 '標準車廂',
                                  //                 style: TextStyle(
                                  //                   fontSize: 12,
                                  //                   color: textSecondary,
                                  //                 ),
                                  //               ),
                                  //               const SizedBox(height: 4),
                                  //               Text(
                                  //                 _formatFare(train),
                                  //                 style: const TextStyle(
                                  //                   fontSize: 18,
                                  //                   fontWeight: FontWeight.w700,
                                  //                   color: textPrimary,
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //           // 座位狀態
                                  //           Row(
                                  //             children: [
                                  //               _buildSeatStatus(
                                  //                 '標準',
                                  //                 standardStatus == 'O',
                                  //               ),
                                  //               const SizedBox(width: 12),
                                  //               _buildSeatStatus(
                                  //                 '商務',
                                  //                 businessStatus == 'O',
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ],
                                  //       ),
                                  //     );
                                  //   },
                                  // ),
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

  // 尋找最接近的班次索引
  int _findClosestIndex(List<dynamic> data) {
    int closestIndex = 0;
    Duration minDiff = const Duration(days: 999);
    for (int i = 0; i < data.length; i++) {
      final train = data[i];
      final depTimeStr =
          train["TrainDate"] + ' ' + train["OriginStopTime"]["DepartureTime"];
      final depTime = DateTime.tryParse(depTimeStr);
      if (depTime != null) {
        final diff = (depTime.difference(widget.date)).abs();
        if (diff < minDiff) {
          closestIndex = i;
          minDiff = diff;
        }
      }
    }
    return closestIndex;
  }

  // 座位狀態元件
  Widget _buildSeatStatus(String label, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable
            ? successGreen.withOpacity(0.1)
            : errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? successGreen.withOpacity(0.3)
              : errorRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: isAvailable ? successGreen : errorRed,
          ),
          const SizedBox(width: 4),
          Flexible(child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isAvailable ? successGreen : errorRed,
              fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }

  // 格式化票價
  String _formatFare(Map<String, dynamic> train) {
    // TODO: 從API獲取實際票價
    return 'NT\$ 1,530';
  }

  // 獲取座位狀態
  Future<Map<String, dynamic>> _fetchSeatStatus(
      Map<String, dynamic> train) async {
    try {
      final origin = train["OriginStopTime"];
      final destination = train["DestinationStopTime"];
      final trainNo = train["DailyTrainInfo"]["TrainNo"];

      final d = await mysqlSelect(
          "SELECT * FROM HSR.HSR_Station WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '${origin["StationName"]["Zh_tw"]}';");
      final a = await mysqlSelect(
          "SELECT * FROM HSR.HSR_Station WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '${destination["StationName"]["Zh_tw"]}';");

      if (d.isEmpty || a.isEmpty) {
        return {
          "AvailableSeats": [
            {"StandardSeatStatus": "N", "BusinessSeatStatus": "N"}
          ]
        };
      }

      final data = await fetchAvailableSeatStatus(
        d[0]["StationID"],
        a[0]["StationID"],
        trainNo.replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0'),
        DateFormat('yyyy-MM-dd').format(DateTime.parse(train["TrainDate"])),
      );

      return data;
    } catch (e) {
      debugPrint(AppLocalizations.of(context)!.text_212);
      return {
        "AvailableSeats": [
          {"StandardSeatStatus": "N", "BusinessSeatStatus": "N"}
        ]
      };
    }
  }

  Future<List<Widget>> getTransportWidgets(transports) async {
    List<Future<Widget>> futures = transports.map<Future<Widget>>((i) async {
      try {
        var d = await mysqlSelect(
            "SELECT * FROM HSR.HSR_Station WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '${i["departure"]["place"]["name"]}';");
        var a = await mysqlSelect(
            "SELECT * FROM HSR.HSR_Station WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '${i["arrival"]["place"]["name"]}';");

        if (d.isEmpty || a.isEmpty) return const SizedBox.shrink();

        DateTime dateTime = DateTime.parse(i["departure"]["time"]);
        String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
        var data = await fetchAvailableSeatStatus(
          d[0]["StationID"],
          a[0]["StationID"],
          (i['transport']["name"].replaceAll(RegExp(r'[^0-9]'), ''))
              .toString()
              .padLeft(4, '0'),
          formattedDate,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryHSR.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryHSR.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_seat_rounded,
                      size: 16,
                      color: primaryHSR,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.text_213,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: data["AvailableSeats"]?[0]
                                  ?["StandardSeatStatus"] ==
                              'O'
                          ? successGreen.withOpacity(0.1)
                          : errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data["AvailableSeats"]?[0]?["StandardSeatStatus"] == 'O'
                          ? AppLocalizations.of(context)!.text_214
                          : AppLocalizations.of(context)!.text_215,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: data["AvailableSeats"]?[0]
                                    ?["StandardSeatStatus"] ==
                                'O'
                            ? successGreen
                            : errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryHSR.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: primaryHSR,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.text_216,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: data["AvailableSeats"]?[0]
                                  ?["BusinessSeatStatus"] ==
                              'O'
                          ? successGreen.withOpacity(0.1)
                          : errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data["AvailableSeats"]?[0]?["BusinessSeatStatus"] == 'O'
                          ? AppLocalizations.of(context)!.text_214
                          : AppLocalizations.of(context)!.text_215,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: data["AvailableSeats"]?[0]
                                    ?["BusinessSeatStatus"] ==
                                'O'
                            ? successGreen
                            : errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } catch (e) {
        debugPrint(AppLocalizations.of(context)!.text_217);
        return const SizedBox.shrink();
      }
    }).toList();

    final results = await Future.wait(futures);
    return results.where((w) => w is! SizedBox).toList();
  }
}
