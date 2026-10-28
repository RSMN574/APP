import 'dart:async';

import 'package:provider/provider.dart';
import 'package:com.rsmn574.app/features/railway/state/railway_provider.dart';
import 'dart:convert';
import 'package:com.rsmn574.app/features/railway/pages/train_schedule_page.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/widget/select_view.dart';
import 'package:com.rsmn574.app/features/railway/widgets/train_station_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/features/railway/data/get_train.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';

import '../../../firebase/analytics_service.dart';

const Color primaryColor = Color(0xFF2A5CAA);
const Color accentColor = Color(0xFFFF9F1C);
const Color textPrimary = Color(0xFF2D3748);
const Color textSecondary = Color(0xFF718096);
const Color surfaceColor = Color(0xFFF3F5F7);

String _localizedRailName(dynamic names, {required bool isEnglish}) {
  if (names is! Map) return names?.toString() ?? '';

  final preferred = names[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;

  return names[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
}

String _localizedRailField(
    dynamic record, {
      required String englishKey,
      required String chineseKey,
      required bool isEnglish,
      String fallback = '',
    }) {
  if (record is! Map) return '';

  final preferred =
      record[isEnglish ? englishKey : chineseKey]?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;

  final alternate =
      record[isEnglish ? chineseKey : englishKey]?.toString() ?? '';
  return alternate.isNotEmpty ? alternate : fallback;
}

// ==========================================
// 跨日時間 / 車次編號 工具（全局）
// ==========================================
int _mod1440(int n) => ((n % 1440) + 1440) % 1440;

int _timeToMinutesSafe(String? time) {
  if (time == null || time.isEmpty) return 0;
  final parts = time.split(':');
  if (parts.length < 2) return 0;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return 0;
  return h * 60 + m;
}

/// 計算 dep → arr 的旅行分鐘數，跨午夜回傳正數。
int _calcDurationMinutes(String? dep, String? arr) {
  return _mod1440(_timeToMinutesSafe(arr) - _timeToMinutesSafe(dep));
}

/// 將輸入（"110A"、"自強 110" 等）解析為純數字車次；失敗回傳 null。
int? _parseTrainNoDigits(String? raw) {
  if (raw == null) return null;
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class Train extends StatefulWidget {
  const Train({super.key});

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const lightPrimary = Color(0xFF1A73E8);
    const darkPrimary = Color(0xFF64B5F6);

    final primaryColor = isDark ? darkPrimary : lightPrimary;
    final backgroundColor =
    isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFD);
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor =
    isDark ? const Color(0xFF343438) : const Color(0xFFE5ECF6);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary =
    isDark ? const Color(0xFFB0B7C3) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceColor,
        foregroundColor: primaryColor,
        iconTheme: IconThemeData(color: primaryColor),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_bus,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.text_826,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
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
          labelColor: primaryColor,
          unselectedLabelColor: textSecondary,
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          dividerColor: borderColor,
          overlayColor: WidgetStatePropertyAll(
            primaryColor.withOpacity(0.06),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: primaryColor,
            ),
            iconColor: primaryColor,
            color: surfaceColor,
            surfaceTintColor: Colors.transparent,
            elevation: isDark ? 4 : 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'line',
                child: Row(
                  children: [
                    Icon(
                      Icons.train,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.text_827,
                      style: TextStyle(color: textPrimary),
                    ),
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
                        backgroundColor: backgroundColor,
                        appBar: AppBar(
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          backgroundColor: surfaceColor,
                          foregroundColor: primaryColor,
                          iconTheme: IconThemeData(
                            color: primaryColor,
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.train,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.of(context)!.text_827,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          centerTitle: true,
                        ),
                        body: FutureBuilder(
                          future: mysqlSelect(
                            "SELECT * FROM Train.Train_Line;",
                          ),
                          builder: (
                              BuildContext context,
                              AsyncSnapshot snapshot,
                              ) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    "載入失敗: ${snapshot.error}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFFFF8A80)
                                          : const Color(0xFFD32F2F),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                (snapshot.data as List).isEmpty) {
                              return Center(
                                child: Text(
                                  AppLocalizations.of(context)!.text_828,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }

                            final lineData = snapshot.data as List;

                            return Container(
                              color: backgroundColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: lineData.length,
                                itemBuilder: (context, index) {
                                  final line = lineData[index];

                                  final lineNameZh =
                                      line['LineNameZh'] ??
                                          AppLocalizations.of(context)!
                                              .text_321;

                                  final lineNameEn =
                                      line['LineNameEn'] ?? 'Unknown';

                                  final sectionNameZh =
                                      line['LineSectionNameZh'] ??
                                          AppLocalizations.of(context)!
                                              .text_829;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: borderColor,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            isDark ? 0.10 : 0.035,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 6,
                                      ),
                                      title: Text(
                                        lineNameZh.toString(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                        ),
                                        child: Text(
                                          "$lineNameEn\n區間：$sectionNameZh",
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.5,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
                            );
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
          TripNumberSearchPage(
            controller: _trainNoController,
          ),
          RouteSearchPage(
            departureController: _departureController,
            destinationController: _destinationController,
          ),
          StationSearchPage(
            controller: _stationController,
          ),
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

  // ✅ 修正 1：firstDate 用純日期，避免時分秒把「今天」排除
  Future<void> _selectDate(BuildContext context) async {
    final today = _dateOnly(DateTime.now());
    final initialDate =
    selectedDate.isBefore(today) ? today : _dateOnly(selectedDate);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF1A73E8),
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: const Color(0xFF1A73E8),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                                    color: const Color(0xFF1A73E8)
                                        .withOpacity(0.1),
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
                                    content: Text(
                                        AppLocalizations.of(context)!.text_833),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              // ✅ 修正 6：解析失敗即中止，不再 int.parse 崩潰
                              final trainNo =
                              _parseTrainNoDigits(widget.controller.text);
                              if (trainNo == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('請輸入有效的車次編號'),
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
                                  trainNo,
                                  selectedDate,
                                );
                                if (trainData == null || trainData.isEmpty) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          AppLocalizations.of(context)!
                                              .text_834),
                                      backgroundColor: const Color(0xFFFF9500),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrainSchedulePage(
                                        type: 'trainNo',
                                        time: selectedDate,
                                        trainNo: trainNo,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppLocalizations.of(context)!.text_834),
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
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.text_153,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
  late final Map<String, List<String>> stationData = {
    AppLocalizations.of(context)!.text_174: [
      AppLocalizations.of(context)!.text_175,
      AppLocalizations.of(context)!.text_837,
      AppLocalizations.of(context)!.text_178
    ],
    AppLocalizations.of(context)!.text_8: [
      AppLocalizations.of(context)!.text_838,
      AppLocalizations.of(context)!.text_839,
      AppLocalizations.of(context)!.text_840
    ],
    AppLocalizations.of(context)!.text_11: [
      AppLocalizations.of(context)!.text_192,
      AppLocalizations.of(context)!.text_841,
      AppLocalizations.of(context)!.text_842
    ],
  };

  Map<String, dynamic> departureSelectedStation = {};
  Map<String, dynamic> destinationSelectedStation = {};
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH:mm');

  bool _isDepartureSelected = false;
  bool _isDestinationSelected = false;

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final currentTheme = Theme.of(context);
    final isDark = currentTheme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF1A73E8);

    final surfaceColor = currentTheme.colorScheme.surface;
    final textColor = currentTheme.colorScheme.onSurface;

    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final pickerTheme = currentTheme.copyWith(
      colorScheme: currentTheme.colorScheme.copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: dialogShape,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surfaceColor,
        hourMinuteTextColor: primaryColor,
        hourMinuteColor: primaryColor.withOpacity(
          isDark ? 0.20 : 0.07,
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryColor.withOpacity(
              isDark ? 0.50 : 0.25,
            ),
          ),
        ),
        dayPeriodTextColor: textColor,
        dayPeriodColor: primaryColor.withOpacity(
          isDark ? 0.25 : 0.10,
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dialBackgroundColor: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF1F5FC),
        dialTextColor: textColor,
        dialHandColor: primaryColor,
        entryModeIconColor: primaryColor,
        helpTextStyle: currentTheme.textTheme.labelSmall,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate != null &&
          !selectedDate!.isBefore(
            DateTime(now.year, now.month, now.day),
          )
          ? selectedDate!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: pickerTheme,
          child: child!,
        );
      },
    );

    if (pickedDate == null || !context.mounted) return;

    final isToday = pickedDate.year == now.year &&
        pickedDate.month == now.month &&
        pickedDate.day == now.day;

    final previousDateTime = selectedDate ?? now;
    final previousTime = TimeOfDay.fromDateTime(previousDateTime);

    final initialTime = isToday &&
        (previousTime.hour < now.hour ||
            (previousTime.hour == now.hour &&
                previousTime.minute < now.minute))
        ? TimeOfDay.fromDateTime(now)
        : previousTime;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: pickerTheme,
          child: child!,
        );
      },
    );

    if (pickedTime == null || !context.mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (result.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不能選擇過去的時間，請重新選擇。'),
        ),
      );
      return;
    }

    setState(() {
      selectedDate = result;
    });
  }

  // ✅ 修正 3：用暫存字串交換，避免每次新建 TextEditingController 造成泄漏
  void _swapStations() {
    if (departureSelectedStation.isEmpty &&
        destinationSelectedStation.isEmpty) {
      return;
    }

    setState(() {
      final tempText = widget.departureController.text;
      widget.departureController.text = widget.destinationController.text;
      widget.destinationController.text = tempText;

      final tempStation = departureSelectedStation;
      departureSelectedStation = destinationSelectedStation;
      destinationSelectedStation = tempStation;

      final tempSelected = _isDepartureSelected;
      _isDepartureSelected = _isDestinationSelected;
      _isDestinationSelected = tempSelected;

      if (widget.departureController.text ==
          widget.destinationController.text &&
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                                    _localizedRailName(
                                      departureSelectedStation['StationName'],
                                      isEnglish: Localizations.localeOf(context)
                                          .languageCode ==
                                          'en',
                                    );
                                if (widget.departureController.text.isEmpty) {
                                  widget.departureController.text =
                                      AppLocalizations.of(context)!.text_160;
                                }
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
                                        : const Color(0xFF1A73E8)
                                        .withOpacity(0.1),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                            : AppLocalizations.of(context)!
                                            .text_161,
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
                                      color: const Color(0xFF1A73E8)
                                          .withOpacity(0.1),
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
                                    _localizedRailName(
                                      destinationSelectedStation['StationName'],
                                      isEnglish: Localizations.localeOf(context)
                                          .languageCode ==
                                          'en',
                                    );
                                if (widget.destinationController.text.isEmpty) {
                                  widget.destinationController.text =
                                      AppLocalizations.of(context)!.text_160;
                                }
                              });

                              if (widget.departureController.text ==
                                  widget.destinationController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppLocalizations.of(context)!.text_157),
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
                                        : const Color(0xFF34C759)
                                        .withOpacity(0.1),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                            : AppLocalizations.of(context)!
                                            .text_847,
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
                                      color: const Color(0xFF34C759)
                                          .withOpacity(0.1),
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
                                        : const Color(0xFFFF9500)
                                        .withOpacity(0.1),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                            : AppLocalizations.of(context)!
                                            .text_165,
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
                                      color: const Color(0xFFFF9500)
                                          .withOpacity(0.1),
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
                                    content: Text(
                                        AppLocalizations.of(context)!.text_848),
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
                                    content: Text(
                                        AppLocalizations.of(context)!.text_849),
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
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.text_166,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_850,
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

class StationSearchPage extends StatefulWidget {
  final TextEditingController controller;

  const StationSearchPage({super.key, required this.controller});

  @override
  _StationSearchPageState createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {
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
  DateTime? selectedDate;
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH:mm');

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final currentTheme = Theme.of(context);
    final isDark = currentTheme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF1A73E8);

    final surfaceColor = currentTheme.colorScheme.surface;
    final textColor = currentTheme.colorScheme.onSurface;

    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final pickerTheme = currentTheme.copyWith(
      colorScheme: currentTheme.colorScheme.copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: dialogShape,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surfaceColor,
        hourMinuteTextColor: primaryColor,
        hourMinuteColor: primaryColor.withOpacity(
          isDark ? 0.20 : 0.07,
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primaryColor.withOpacity(
              isDark ? 0.50 : 0.25,
            ),
          ),
        ),
        dayPeriodTextColor: textColor,
        dayPeriodColor: primaryColor.withOpacity(
          isDark ? 0.25 : 0.10,
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dialBackgroundColor: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF1F5FC),
        dialTextColor: textColor,
        dialHandColor: primaryColor,
        entryModeIconColor: primaryColor,
        helpTextStyle: currentTheme.textTheme.labelSmall,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate != null &&
          !selectedDate!.isBefore(
            DateTime(now.year, now.month, now.day),
          )
          ? selectedDate!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: pickerTheme,
          child: child!,
        );
      },
    );

    if (pickedDate == null || !context.mounted) return;

    final isToday = pickedDate.year == now.year &&
        pickedDate.month == now.month &&
        pickedDate.day == now.day;

    final previousDateTime = selectedDate ?? now;
    final previousTime = TimeOfDay.fromDateTime(previousDateTime);

    final initialTime = isToday &&
        (previousTime.hour < now.hour ||
            (previousTime.hour == now.hour &&
                previousTime.minute < now.minute))
        ? TimeOfDay.fromDateTime(now)
        : previousTime;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: pickerTheme,
          child: child!,
        );
      },
    );

    if (pickedTime == null || !context.mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (result.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不能選擇過去的時間，請重新選擇。'),
        ),
      );
      return;
    }

    setState(() {
      selectedDate = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        style: const TextStyle(
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
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            selectedStation =
                            await StationDialog.showStationDialog(context);
                            if (selectedStation != null) {
                              setState(() {
                                _controller.text = _localizedRailName(
                                  selectedStation?['StationName'],
                                  isEnglish: Localizations.localeOf(context)
                                      .languageCode ==
                                      'en',
                                );
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
                                        : const Color(0xFF1A73E8)
                                        .withOpacity(0.1),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                            : AppLocalizations.of(context)!
                                            .text_200,
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
                                      color: const Color(0xFF1A73E8)
                                          .withOpacity(0.1),
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
                                        : const Color(0xFFFF9500)
                                        .withOpacity(0.1),
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                            : AppLocalizations.of(context)!
                                            .text_165,
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
                                    content: Text(
                                        AppLocalizations.of(context)!.text_200),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }

                              // ✅ 修正 4：同時傳入中英文名與非空 stationID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    final names =
                                    selectedStation?['StationName'];
                                    final zhName = (names is Map)
                                        ? (names['Zh_tw']?.toString() ?? '')
                                        : (names?.toString() ?? '');
                                    final enName = (names is Map)
                                        ? (names['En']?.toString() ?? '')
                                        : '';
                                    return StationPage(
                                      stationName:
                                      zhName.isNotEmpty ? zhName : enName,
                                      stationNameEn: enName,
                                      stationID: selectedStation?["StationID"]
                                          ?.toString() ??
                                          '',
                                      datetime: selectedDate ?? DateTime.now(),
                                    );
                                  },
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
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!.text_854,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context)!.text_855,
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
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          AppLocalizations.of(context)!.text_203,
                          style: const TextStyle(
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
                                _controller.text = stationName;
                              },
                              borderRadius: BorderRadius.circular(20),
                              splashColor:
                              const Color(0xFF1A73E8).withOpacity(0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF3FB),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF1A73E8)
                                        .withOpacity(0.2),
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
  final String stationNameEn;
  final String stationID;
  final DateTime datetime;
  const StationPage({
    Key? key,
    required this.stationName,
    this.stationNameEn = '',
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

  // ✅ 修正 4：將 ScrollController 提升到 State
  final ScrollController _trainListScrollController = ScrollController();
  // ✅ 用 GlobalKey 定位「最近班次」，取代硬編碼 i*152
  final Map<int, GlobalKey> _trainItemKeys = {};
  // ✅ 記錄上次滾動的資料簽章，避免閉包捕捉舊資料
  String? _lastScrolledSig;

  @override
  void initState() {
    super.initState();
    unawaited(
      AppAnalytics.logFeatureOpened('railway'),
    );
    displayedStationName = widget.stationName;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didUpdateWidget(StationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.datetime != oldWidget.datetime ||
        widget.stationID != oldWidget.stationID) {
      _lastScrolledSig = null;
      _trainItemKeys.clear();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trainListScrollController.dispose(); // ✅ 釋放
    super.dispose();
  }

  // ✅ 資料簽章：只要長度/首末時刻/目標時間一致，就視為同一批結果
  String _trainSig(List<dynamic> trains) {
    if (trains.isEmpty) return 'empty';
    final first = trains.first['DepartureTime']?.toString() ?? '';
    final last = trains.last['DepartureTime']?.toString() ?? '';
    return '${trains.length}|$first|$last'
        '|${widget.datetime.millisecondsSinceEpoch}';
  }

  // ✅ 定位到「第一班晚於 widget.datetime 的車次」，跨日亦可
  void _scrollToNearestTrain(List<dynamic> trains) {
    if (trains.isEmpty) return;
    final base = widget.datetime.hour * 60 + widget.datetime.minute;
    int? targetIdx;
    for (int i = 0; i < trains.length; i++) {
      final depMin =
      _timeToMinutesSafe(trains[i]['DepartureTime']?.toString());
      final effectiveDep = depMin >= base ? depMin : depMin + 1440;
      if (effectiveDep >= base) {
        targetIdx = i;
        break;
      }
    }
    targetIdx ??= trains.length - 1;

    final key = _trainItemKeys[targetIdx];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  void updateStationName(String newStationName) {
    setState(() {
      displayedStationName = newStationName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? '${widget.stationNameEn.trim().isNotEmpty ? widget.stationNameEn : widget.stationName} Station'
              : '${widget.stationName} 車站',
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
      return stationClassMap[stationClass] ??
          AppLocalizations.of(context)!.text_863;
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
                      color: const Color(0xFFFF3B30),
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
                      color: const Color(0xFF1A73E8),
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
                                    _localizedRailField(
                                      data[0],
                                      englishKey: 'StationNameEn',
                                      chineseKey: 'StationNameZh_tw',
                                      isEnglish: Localizations.localeOf(context)
                                          .languageCode ==
                                          'en',
                                      fallback: AppLocalizations.of(context)!
                                          .text_160,
                                    ),
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
                            _buildInfoItem(
                              icon: Icons.location_on_rounded,
                              label: AppLocalizations.of(context)!.text_866,
                              value: data[1]['StationAddress'] ??
                                  AppLocalizations.of(context)!.text_867,
                            ),
                            _buildInfoItem(
                              icon: Icons.grade_rounded,
                              label: AppLocalizations.of(context)!.text_868,
                              value: _getStationClass(data[1]['StationClass']),
                            ),
                            _buildInfoItem(
                              icon: Icons.phone_rounded,
                              label: AppLocalizations.of(context)!.text_869,
                              value: data[1]['StationPhone'] ??
                                  AppLocalizations.of(context)!.text_870,
                            ),
                            _buildInfoItem(
                              icon: Icons.qr_code_rounded,
                              label: AppLocalizations.of(context)!.text_871,
                              value: data[1]['StationID'] ??
                                  AppLocalizations.of(context)!.text_872,
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
                    final isEnglish =
                        Localizations.localeOf(context).languageCode == 'en';
                    String? mapName = _localizedRailField(
                      station,
                      englishKey: 'FacilityMapURLs${i}MapNameEn',
                      chineseKey: 'FacilityMapURLs${i}MapNameZh_tw',
                      isEnglish: isEnglish,
                    );
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
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.map_rounded,
                                          size: 18,
                                          color: Color(0xFF1A73E8),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          facility['mapName']!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        height: 120,
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .text_873,
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
                                    color: const Color(0xFF34C759)
                                        .withOpacity(0.1),
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

  // ✅ 修正 4 + 6：不再每次 build 新建 Controller、用 GlobalKey、修正閉包
  Widget _buildTrainInfoPage() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<dynamic>>(
        future: context
            .read<RailwayProvider>()
            .trainStation(widget.stationID, widget.datetime),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF3FB),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFEEEE),
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
                    style: const TextStyle(
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF3FB),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ],
              ),
            );
          }

          // ✅ 用局部 final 抓資料，避免閉包捕捉舊值
          final trainData = snapshot.data!;
          final sig = _trainSig(trainData);

          if (_lastScrolledSig != sig) {
            _lastScrolledSig = sig;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _scrollToNearestTrain(trainData);
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _trainListScrollController,
                  itemCount: trainData.length,
                  itemBuilder: (context, index) {
                    final train = trainData[index];

                    // ✅ 用 GlobalKey 定位
                    final itemKey = _trainItemKeys.putIfAbsent(
                        index, () => GlobalKey());

                    String trainNo = (train['TrainNo'])?.toString() ??
                        AppLocalizations.of(context)!.text_321;
                    final trainTypeName = _localizedRailName(
                      train['TrainTypeName'],
                      isEnglish:
                      Localizations.localeOf(context).languageCode == 'en',
                    );
                    String trainType =
                    Localizations.localeOf(context).languageCode == 'en'
                        ? trainTypeName
                        : convertTrainType(trainTypeName);
                    String departureTime = _formatTime(
                        train['DepartureTime'] ??
                            AppLocalizations.of(context)!.text_321);
                    int? delayTime = train['DelayTime'];
                    String endingStation = _localizedRailName(
                      train['EndingStationName'],
                      isEnglish:
                      Localizations.localeOf(context).languageCode == 'en',
                    );
                    if (endingStation.isEmpty) {
                      endingStation =
                          AppLocalizations.of(context)!.text_321;
                    }

                    bool isDelayed = delayTime != null && delayTime > 0;
                    bool isExpress = trainType.contains(
                        AppLocalizations.of(context)!.text_877) ||
                        trainType.contains(
                            AppLocalizations.of(context)!.text_878) ||
                        trainType
                            .contains(AppLocalizations.of(context)!.text_879);

                    return KeyedSubtree(
                      key: itemKey,
                      child: Transform.translate(
                        offset: Offset(0, index * 0.3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              // ✅ 修正 6：車次號碼合法性檢查
                              final trainNoInt = _parseTrainNoDigits(trainNo);
                              if (trainNoInt == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('車次號碼無效：$trainNo'),
                                    backgroundColor: const Color(0xFFFF3B30),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrainSchedulePage(
                                    type: 'trainNo',
                                    time: widget.datetime,
                                    trainNo: trainNoInt,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            splashColor:
                            const Color(0xFF1A73E8).withOpacity(0.1),
                            highlightColor:
                            const Color(0xFFEEF3FB).withOpacity(0.5),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 20),
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDelayed ? 0.08 : 0.04),
                                    blurRadius: isDelayed ? 20 : 12,
                                    offset: Offset(0, isDelayed ? 6 : 3),
                                  ),
                                ],
                                border: isDelayed
                                    ? Border.all(
                                  color: const Color(0xFFFF3B30)
                                      .withOpacity(0.2),
                                  width: 1.5,
                                )
                                    : isExpress
                                    ? Border.all(
                                  color: const Color(0xFF1A73E8)
                                      .withOpacity(0.1),
                                  width: 1,
                                )
                                    : null,
                              ),
                              child: Stack(
                                children: [
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
                                              const Color(0xFFFF3B30)
                                                  .withOpacity(0.7),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius:
                                          const BorderRadius.only(
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
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: _getTrainTypeGradient(
                                                trainType),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getTrainTypeColor(
                                                    trainType)
                                                    .withOpacity(0.3),
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          '車次 $trainNo',
                                                          style: TextStyle(
                                                            fontSize: 17,
                                                            fontWeight:
                                                            FontWeight.w700,
                                                            color: isDelayed
                                                                ? Colors
                                                                .black87
                                                                : Colors
                                                                .grey[700],
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: isDelayed
                                                          ? const Color(
                                                          0xFFFF3B30)
                                                          .withOpacity(0.1)
                                                          : const Color(
                                                          0xFF1A73E8)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                    ),
                                                    child: Text(
                                                      departureTime,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                        FontWeight.w700,
                                                        color: isDelayed
                                                            ? const Color(
                                                            0xFFFF3B30)
                                                            : const Color(
                                                            0xFF1A73E8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '往 $endingStation',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        color:
                                                        Colors.grey[600],
                                                        fontWeight:
                                                        FontWeight.w500,
                                                        height: 1.4,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (isDelayed)
                                                    _buildStatusBadge(
                                                        '延誤 ${delayTime}分',
                                                        const Color(0xFFFF3B30)),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getTrainTypeColor(
                                                          trainType)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                      border: Border.all(
                                                        color:
                                                        _getTrainTypeColor(
                                                            trainType)
                                                            .withOpacity(
                                                            0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      (trainType),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                        _getTrainTypeColor(
                                                            trainType),
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                    const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
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
    if (trainType.contains(AppLocalizations.of(context)!.text_877) ||
        trainType.contains(AppLocalizations.of(context)!.text_878) ||
        trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return const Color(0xFF1A73E8);
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return const Color(0xFF34C759);
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883) ||
        trainType.contains(AppLocalizations.of(context)!.text_884)) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFFAF52DE);
    }
  }

  IconData _getTrainTypeIcon(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) ||
        trainType.contains(AppLocalizations.of(context)!.text_878) ||
        trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return Icons.directions_railway_filled_rounded;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return Icons.train_rounded;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883) ||
        trainType.contains(AppLocalizations.of(context)!.text_884)) {
      return Icons.directions_subway_rounded;
    } else {
      return Icons.directions_transit_rounded;
    }
  }

  String _getTrainTypeCategory(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) ||
        trainType.contains(AppLocalizations.of(context)!.text_878) ||
        trainType.contains(AppLocalizations.of(context)!.text_879)) {
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

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_887,
                Icons.confirmation_number_rounded),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderItem(
                AppLocalizations.of(context)!.text_888,
                Icons.schedule_rounded),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderItem(
                AppLocalizations.of(context)!.text_889, Icons.train_rounded),
          ),
          Expanded(
            flex: 3,
            child: _buildHeaderItem(
                AppLocalizations.of(context)!.text_57, Icons.flag_rounded),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderItem(AppLocalizations.of(context)!.text_890,
                Icons.info_outline_rounded),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF1A73E8),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A73E8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  final ItemPositionsListener _itemPositionsListener =
  ItemPositionsListener.create();

  // =============================
  // 滾動狀態追蹤
  // =============================
  bool _shouldAutoScroll = true;
  DateTime? _lastScrollTime;
  DateTime? _previousDate;

  // ✅ 修正 7：快取 future，避免 rebuild 時重複發請求
  Future<Map<String, dynamic>>? _routeFuture;

  // 通知中心主題色
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color successGreen = Color(0xFF34C759);
  static const Color warningOrange = Color(0xFFFF9500);
  static const Color errorRed = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);
  static const Color backgroundLight = Color(0xFFF8FAFD);
  static const Color surfaceColor = Color(0xFFEEF3FB);

  @override
  void initState() {
    super.initState();
    _previousDate = widget.date;
    _routeFuture = queryTrainList();
  }

  @override
  void didUpdateWidget(RoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final odChanged =
        widget.departure['StationID']?.toString() !=
            oldWidget.departure['StationID']?.toString() ||
            widget.destination['StationID']?.toString() !=
                oldWidget.destination['StationID']?.toString();
    final dateChanged = widget.date != oldWidget.date;

    if (odChanged || dateChanged) {
      _routeFuture = queryTrainList();
    }
    if (dateChanged) {
      _shouldAutoScroll = true;
      _previousDate = oldWidget.date;
    }
  }

  // =============================
  // API
  // =============================
  Future<Map<String, dynamic>> queryTrainList() async {
    final weekday = widget.date.weekday % 7;
    final url = 'http://hidden.rsmn574.com:3920/api/train'
        '?from=${widget.departure["StationID"]}'
        '&to=${widget.destination["StationID"]}'
        '&day=$weekday';

    final res =
    await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  // =============================
  // 時間處理
  // =============================
  int _timeToMinutes(String? hhmm) {
    // ✅ 修正 5：空值/格式錯誤不再崩潰
    return _timeToMinutesSafe(hhmm);
  }

  int _selectedMinutes() {
    return widget.date.hour * 60 + widget.date.minute;
  }

  int trainDepMinutes(dynamic t) {
    // 1) 非 Map 直接視為無效，排到最後
    if (t is! Map) return 1440;

    // 2) 明確判斷是否轉乘：transfer == true 才算轉乘
    final isTransfer = t['transfer'] == true;

    String? timeStr;
    if (isTransfer) {
      final leg1 = t['leg1'];
      if (leg1 is Map) {
        timeStr = leg1['depTime']?.toString();
      }
    } else {
      timeStr = t['depTime']?.toString();
    }

    // 3) 空值/格式錯誤：回傳 1440（排在當日最後），避免蓋過有效班次
    if (timeStr == null || timeStr.isEmpty) return 1440;
    final minutes = _timeToMinutesSafe(timeStr);
    // _timeToMinutesSafe 對 "abc" 之類會回 0，這裡再補一層：
    if (minutes == 0 && timeStr != '00:00' && timeStr != '0:00') {
      return 1440;
    }
    return minutes;
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
  // 找最接近選擇時間的 index（O(n)，只在 build 呼叫一次）
  // ✅ 修正 8：空列表回傳 -1
  // =============================
  int findClosestTrainIndex(List<dynamic> trains) {
    if (trains.isEmpty) return -1;
    final base = _selectedMinutes();
    for (int i = 0; i < trains.length; i++) {
      if (trainDepMinutes(trains[i]) >= base) {
        return i;
      }
    }
    return trains.length - 1;
  }

  bool _shouldScrollToClosest() {
    if (_shouldAutoScroll) return true;
    if (_previousDate != null && widget.date != _previousDate) return true;
    if (_lastScrollTime == null ||
        DateTime.now().difference(_lastScrollTime!) >
            const Duration(seconds: 2)) {
      return true;
    }
    return false;
  }

  Color _getTrainTypeColor(String trainType) {
    if (trainType.contains(AppLocalizations.of(context)!.text_877) ||
        trainType.contains(AppLocalizations.of(context)!.text_878) ||
        trainType.contains(AppLocalizations.of(context)!.text_879)) {
      return primaryBlue;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_882)) {
      return successGreen;
    } else if (trainType.contains(AppLocalizations.of(context)!.text_883) ||
        trainType.contains(AppLocalizations.of(context)!.text_884)) {
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
        // ✅ 修正 6：車次號碼合法性檢查
        final trainNoInt = _parseTrainNoDigits(trainNo?.toString());
        if (trainNoInt == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('車次號碼無效：$trainNo'),
              backgroundColor: errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }

        try {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrainSchedulePage(
                  type: 'trainNo',
                  time: widget.date,
                  trainNo: trainNoInt,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.text_67,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_railway_rounded,
                        size: 16, color: successGreen),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.text_892,
                      style: const TextStyle(
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
                  Text(AppLocalizations.of(context)!.text_68,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
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
                  child: const Icon(Icons.train_rounded,
                      size: 18, color: Colors.white),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getTravelTime(
                        t['depTime']?.toString() ?? '',
                        t['arrTime']?.toString() ?? ''),
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
  // 計算旅行時間（✅ 修正 5：跨日 mod1440）
  // =============================
  String _getTravelTime(String dep, String arr) {
    final diff = _calcDurationMinutes(dep, arr);
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tight
                    ? errorRed.withOpacity(0.1)
                    : warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tight
                      ? errorRed.withOpacity(0.3)
                      : warningOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tight
                        ? Icons.warning_amber_rounded
                        : Icons.timeline_rounded,
                    size: 16,
                    color: tight ? errorRed : warningOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t['totalTimeHuman'] ??
                        '${totalMin ~/ 60}小時${totalMin % 60}分',
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _navigateToTrainDetail(
                            trainNo1?.toString() ?? '');
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: _getTrainTypeColor(leg1['TrainTypeName'])
                          .withOpacity(0.1),
                      child: _buildLegCard(leg1, isFirst: true),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTransferStationCard(t['transferStation'], tight),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _navigateToTrainDetail(
                            trainNo2?.toString() ?? '');
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: _getTrainTypeColor(leg2['TrainTypeName'])
                          .withOpacity(0.1),
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

  // ✅ 修正 6：車次號碼合法性檢查
  Future<void> _navigateToTrainDetail(String trainNo) async {
    final trainNoInt = _parseTrainNoDigits(trainNo);
    if (trainNoInt == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('車次號碼無效：$trainNo'),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    try {
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainSchedulePage(
              type: 'trainNo',
              time: widget.date,
              trainNo: trainNoInt,
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
                    Flexible(
                      child: Text(
                        '${leg['depTime']} → ${leg['arrTime']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
        color: tight
            ? errorRed.withOpacity(0.05)
            : warningOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tight
              ? errorRed.withOpacity(0.2)
              : warningOrange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tight
                  ? errorRed.withOpacity(0.1)
                  : warningOrange.withOpacity(0.1),
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
                    style: const TextStyle(
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

  String _formatDate(DateTime date) {
    final weekday = [
      AppLocalizations.of(context)!.text_306,
      AppLocalizations.of(context)!.text_307,
      AppLocalizations.of(context)!.text_308,
      AppLocalizations.of(context)!.text_309,
      AppLocalizations.of(context)!.text_310,
      AppLocalizations.of(context)!.text_311,
      AppLocalizations.of(context)!.text_312
    ][date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日 週$weekday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.train_rounded, size: 20, color: primaryBlue),
            const SizedBox(width: 8),
            Text(
              _localizedRailName(
                widget.departure['StationName'],
                isEnglish: isEnglish,
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: primaryBlue),
            ),
            Text(
              _localizedRailName(
                widget.destination['StationName'],
                isEnglish: isEnglish,
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      // ✅ 修正 7：使用快取 future
      body: FutureBuilder<Map<String, dynamic>>(
        future: _routeFuture,
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
                    const CircularProgressIndicator(
                        color: primaryBlue, strokeWidth: 3),
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
                          colors: [
                            errorRed.withOpacity(0.1),
                            errorRed.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded,
                          size: 40, color: errorRed),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.text_205,
                      style: const TextStyle(
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
          final trains =
          buildTrains(data['direct'] ?? [], data['transfer'] ?? []);

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
                          colors: [
                            primaryBlue.withOpacity(0.1),
                            primaryBlue.withOpacity(0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.train_outlined,
                          size: 50, color: primaryBlue),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.text_207,
                      style: const TextStyle(
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

          // ✅ 修正 8：只計算一次 closestIndex
          final closestIndex = findClosestTrainIndex(trains);

          if (_shouldScrollToClosest() && closestIndex >= 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (closestIndex < trains.length) {
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
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      child: const Icon(Icons.calendar_today_rounded,
                          size: 16, color: primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _formatDate(widget.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: trains.length,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemBuilder: (_, i) {
                    final t = trains[i];
                    // ✅ 修正 8：O(1) 比較，不再每次呼叫 O(n)
                    final isClosest = i == closestIndex;
                    final isAfterSelectedTime =
                        trainDepMinutes(t) >= _selectedMinutes();

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
                            ? Border.all(color: primaryBlue, width: 2)
                            : !isAfterSelectedTime
                            ? Border.all(
                            color: Colors.grey[300]!, width: 1)
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          splashColor: primaryBlue.withOpacity(0.1),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: t['transfer']
                                ? transferTimeline(t)
                                : directCard(t),
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