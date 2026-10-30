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

import '../../../const/app_colors.dart';
import '../../../const/surface_decoration.dart';
import '../../../firebase/analytics_service.dart';
import '../../../widget/app_custom_bar.dart';


String _localizedRailName(dynamic names, {required bool isEnglish}) {
  if (names is! Map) return names?.toString() ?? '';
  final preferred = names[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;
  return names[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
}

String _localizedRailField(dynamic record,
    {required String englishKey,
      required String chineseKey,
      required bool isEnglish,
      String fallback = ''}) {
  if (record is! Map) return '';
  final preferred =
      record[isEnglish ? englishKey : chineseKey]?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;
  final alternate =
      record[isEnglish ? chineseKey : englishKey]?.toString() ?? '';
  return alternate.isNotEmpty ? alternate : fallback;
}

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

int _calcDurationMinutes(String? dep, String? arr) {
  return _mod1440(_timeToMinutesSafe(arr) - _timeToMinutesSafe(dep));
}

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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppCustomBar(
        title: l10n.text_826,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.infoContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.directions_bus, color: colors.info, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                l10n.text_826,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: colors.info,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.text_145),
            Tab(text: l10n.text_146),
            Tab(text: l10n.text_147),
          ],
          labelColor: colors.info,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.info,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          dividerColor: colors.border,
          overlayColor: WidgetStatePropertyAll(colors.info.withOpacity(0.06)),
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

class TrainMainPage extends StatefulWidget {
  const TrainMainPage({super.key});
  @override
  State<TrainMainPage> createState() => _TrainMainPageState();
}

class _TrainMainPageState extends State<TrainMainPage> {
  @override
  Widget build(BuildContext context) => const Placeholder();
}

// ─────────────────────────────────────────────────────
// TripNumberSearchPage
// ─────────────────────────────────────────────────────

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
    final colors = context.appColors;
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
              primary: colors.info,
              onPrimary: colors.cardBackground,
              surface: colors.cardBackground,
              onSurface: colors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: colors.info),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colors.cardBackground,
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
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
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
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.search_rounded,
                            size: 40, color: colors.info),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.text_830,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colors.info)),
                      const SizedBox(height: 8),
                      Text(l10n.text_831,
                          style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration:
                  SurfaceDecoration.cardShadow(context, radius: 20),
                  child: Column(
                    children: [
                      Container(
                        decoration: SurfaceDecoration.outlined(
                          context,
                          radius: 12,
                          borderColor: colors.border,
                        ),
                        child: TextField(
                          controller: widget.controller,
                          decoration: InputDecoration(
                            hintText: l10n.text_832,
                            hintStyle: TextStyle(color: colors.textHint),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(Icons.train_rounded,
                                  color: colors.info),
                            ),
                          ),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          splashColor: colors.info.withOpacity(0.1),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: SurfaceDecoration.muted(
                                context, radius: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colors.infoContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: colors.info),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(selectedDate),
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colors.info),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down_rounded,
                                    color: colors.info),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.info,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colors.info.withOpacity(0.3),
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
                                    content: Text(l10n.text_833),
                                    backgroundColor: colors.danger,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }
                              final trainNo =
                              _parseTrainNoDigits(widget.controller.text);
                              if (trainNo == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    // TODO: i18n
                                    content: const Text('請輸入有效的車次編號'),
                                    backgroundColor: colors.danger,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }
                              try {
                                trainData =
                                await fetchTrain(trainNo, selectedDate);
                                if (trainData == null || trainData.isEmpty) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.text_834),
                                      backgroundColor: colors.warning,
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
                                    content: Text(l10n.text_834),
                                    backgroundColor: colors.warning,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor:
                            colors.cardBackground.withOpacity(0.2),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded,
                                      size: 20, color: colors.cardBackground),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.text_153,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: colors.cardBackground),
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
                  decoration: SurfaceDecoration.outlined(
                    context,
                    radius: 16,
                    borderColor: colors.border,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline_rounded,
                            size: 16, color: colors.info),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.text_835,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.info)),
                            const SizedBox(height: 4),
                            Text(l10n.text_836,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500)),
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

// ─────────────────────────────────────────────────────
// RouteSearchPage
// ─────────────────────────────────────────────────────

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
    final colors = context.appColors;
    final now = DateTime.now();
    final currentTheme = Theme.of(context);
    final surface = currentTheme.colorScheme.surface;
    final textColor = currentTheme.colorScheme.onSurface;
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    final pickerTheme = currentTheme.copyWith(
      colorScheme: currentTheme.colorScheme.copyWith(
        primary: colors.info,
        onPrimary: colors.cardBackground,
        surface: surface,
        onSurface: textColor,
      ),
      dialogTheme:
      DialogThemeData(backgroundColor: surface, shape: dialogShape),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colors.info)),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        hourMinuteTextColor: colors.info,
        hourMinuteColor: colors.info.withOpacity(0.20),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.info.withOpacity(0.5)),
        ),
        dayPeriodTextColor: textColor,
        dayPeriodColor: colors.info.withOpacity(0.25),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dialBackgroundColor: colors.mutedBackground,
        dialTextColor: textColor,
        dialHandColor: colors.info,
        entryModeIconColor: colors.info,
        helpTextStyle: currentTheme.textTheme.labelSmall,
        cancelButtonStyle:
        TextButton.styleFrom(foregroundColor: colors.info),
        confirmButtonStyle:
        TextButton.styleFrom(foregroundColor: colors.info),
      ),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate != null &&
          !selectedDate!
              .isBefore(DateTime(now.year, now.month, now.day))
          ? selectedDate!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2101),
      builder: (context, child) =>
          Theme(data: pickerTheme, child: child!),
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
      builder: (context, child) =>
          Theme(data: pickerTheme, child: child!),
    );

    if (pickedTime == null || !context.mounted) return;

    final result = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute);

    if (result.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // TODO: i18n
          content: const Text('不能選擇過去的時間，請重新選擇。'),
          backgroundColor: colors.danger,
        ),
      );
      return;
    }

    setState(() => selectedDate = result);
  }

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
            backgroundColor: context.appColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  Widget _buildPickerTile({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required Color accent,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accent.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(0.05)
                : colors.mutedBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accent.withOpacity(0.3)
                  : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? accent : accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isSelected ? colors.cardBackground : accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? accent : colors.textHint,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? accent
                                : colors.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              isSelected
                  ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.check_rounded,
                    size: 16, color: accent),
              )
                  : Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
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
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.route_rounded,
                            size: 40, color: colors.info),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.text_843,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colors.info)),
                      const SizedBox(height: 8),
                      Text(l10n.text_844,
                          style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration:
                  SurfaceDecoration.cardShadow(context, radius: 20),
                  child: Column(
                    children: [
                      _buildPickerTile(
                        context: context,
                        isSelected: _isDepartureSelected,
                        icon: Icons.train_rounded,
                        accent: colors.info,
                        label: l10n.text_845,
                        value: _isDepartureSelected
                            ? widget.departureController.text
                            : l10n.text_161,
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
                                    l10n.text_160;
                              }
                            });
                          }
                        },
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.infoContainer,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: colors.info.withOpacity(0.3),
                                  width: 1),
                            ),
                            child: Transform.rotate(
                              angle: 90 * (3.1415926535 / 180),
                              child: Icon(Icons.swap_vert_rounded,
                                  color: colors.info, size: 24),
                            ),
                          ),
                          onPressed: _swapStations,
                        ),
                      ),
                      _buildPickerTile(
                        context: context,
                        isSelected: _isDestinationSelected,
                        icon: Icons.flag_rounded,
                        accent: colors.success,
                        label: l10n.text_846,
                        value: _isDestinationSelected
                            ? widget.destinationController.text
                            : l10n.text_847,
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
                                    l10n.text_160;
                              }
                            });
                            if (widget.departureController.text ==
                                widget.destinationController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.text_157),
                                  backgroundColor: colors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPickerTile(
                        context: context,
                        isSelected: selectedDate != null,
                        icon: Icons.calendar_today_rounded,
                        accent: colors.warning,
                        label: l10n.text_164,
                        value: selectedDate != null
                            ? dateFormat.format(selectedDate!)
                            : l10n.text_165,
                        onTap: () => _selectDateTime(context),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.info,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colors.info.withOpacity(0.3),
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
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(l10n.text_848),
                                    backgroundColor: colors.danger,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12)),
                                  ));
                                  return;
                                }
                                if (!_isDestinationSelected) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(l10n.text_849),
                                    backgroundColor: colors.danger,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12)),
                                  ));
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoutePage(
                                      departure: departureSelectedStation,
                                      destination: destinationSelectedStation,
                                      date: selectedDate ??
                                          DateTime.now().add(
                                              const Duration(minutes: 1)),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              splashColor:
                              colors.cardBackground.withOpacity(0.2),
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_rounded,
                                        size: 20,
                                        color: colors.cardBackground),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.text_166,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: colors.cardBackground),
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
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: SurfaceDecoration.outlined(
                    context,
                    radius: 16,
                    borderColor: colors.border,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline_rounded,
                            size: 16, color: colors.info),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.text_154,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.info)),
                            const SizedBox(height: 4),
                            Text(l10n.text_850,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500)),
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

// ─────────────────────────────────────────────────────
// StationSearchPage
// ─────────────────────────────────────────────────────

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
    final colors = context.appColors;
    final now = DateTime.now();
    final currentTheme = Theme.of(context);
    final surface = currentTheme.colorScheme.surface;
    final textColor = currentTheme.colorScheme.onSurface;
    final dialogShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20));

    final pickerTheme = currentTheme.copyWith(
      colorScheme: currentTheme.colorScheme.copyWith(
        primary: colors.info,
        onPrimary: colors.cardBackground,
        surface: surface,
        onSurface: textColor,
      ),
      dialogTheme:
      DialogThemeData(backgroundColor: surface, shape: dialogShape),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colors.info)),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        hourMinuteTextColor: colors.info,
        hourMinuteColor: colors.info.withOpacity(0.20),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.info.withOpacity(0.5)),
        ),
        dayPeriodTextColor: textColor,
        dayPeriodColor: colors.info.withOpacity(0.25),
        dayPeriodShape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dialBackgroundColor: colors.mutedBackground,
        dialTextColor: textColor,
        dialHandColor: colors.info,
        entryModeIconColor: colors.info,
        helpTextStyle: currentTheme.textTheme.labelSmall,
        cancelButtonStyle:
        TextButton.styleFrom(foregroundColor: colors.info),
        confirmButtonStyle:
        TextButton.styleFrom(foregroundColor: colors.info),
      ),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate != null &&
          !selectedDate!
              .isBefore(DateTime(now.year, now.month, now.day))
          ? selectedDate!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2101),
      builder: (context, child) =>
          Theme(data: pickerTheme, child: child!),
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
      builder: (context, child) =>
          Theme(data: pickerTheme, child: child!),
    );

    if (pickedTime == null || !context.mounted) return;

    final result = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute);

    if (result.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // TODO: i18n
          content: const Text('不能選擇過去的時間，請重新選擇。'),
          backgroundColor: colors.danger,
        ),
      );
      return;
    }

    setState(() => selectedDate = result);
  }

  Widget _buildPickerTile({
    required BuildContext context,
    required bool isSelected,
    required IconData icon,
    required Color accent,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accent.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withOpacity(0.05)
                : colors.mutedBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
              isSelected ? accent.withOpacity(0.3) : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? accent : accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 20,
                    color: isSelected ? colors.cardBackground : accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? accent : colors.textHint,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? accent
                                : colors.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              isSelected
                  ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.check_rounded,
                    size: 16, color: accent),
              )
                  : Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
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
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.location_city_rounded,
                            size: 40, color: colors.info),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.text_851,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: colors.info)),
                      const SizedBox(height: 8),
                      Text(l10n.text_852,
                          style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration:
                  SurfaceDecoration.cardShadow(context, radius: 20),
                  child: Column(
                    children: [
                      _buildPickerTile(
                        context: context,
                        isSelected: selectedStation != null,
                        icon: Icons.train_rounded,
                        accent: colors.info,
                        label: l10n.text_853,
                        value: selectedStation != null
                            ? _controller.text
                            : l10n.text_200,
                        onTap: () async {
                          selectedStation =
                          await StationDialog.showStationDialog(context);
                          if (selectedStation != null) {
                            setState(() {
                              _controller.text = _localizedRailName(
                                selectedStation?['StationName'],
                                isEnglish:
                                Localizations.localeOf(context)
                                    .languageCode ==
                                    'en',
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPickerTile(
                        context: context,
                        isSelected: selectedDate != null,
                        icon: Icons.calendar_today_rounded,
                        accent: colors.warning,
                        label: l10n.text_164,
                        value: selectedDate != null
                            ? dateFormat.format(selectedDate!)
                            : l10n.text_165,
                        onTap: () => _selectDateTime(context),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.info,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: colors.info.withOpacity(0.3),
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
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(l10n.text_200),
                                    backgroundColor: colors.danger,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12)),
                                  ));
                                  return;
                                }
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
                                        stationName: zhName.isNotEmpty
                                            ? zhName
                                            : enName,
                                        stationNameEn: enName,
                                        stationID: selectedStation?[
                                        "StationID"]
                                            ?.toString() ??
                                            '',
                                        datetime:
                                        selectedDate ?? DateTime.now(),
                                      );
                                    },
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              splashColor:
                              colors.cardBackground.withOpacity(0.2),
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_rounded,
                                        size: 20,
                                        color: colors.cardBackground),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        l10n.text_854,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: colors.cardBackground),
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
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: SurfaceDecoration.outlined(
                      context, radius: 16, borderColor: colors.border),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline_rounded,
                            size: 16, color: colors.info),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.text_154,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.info)),
                            const SizedBox(height: 4),
                            Text(l10n.text_855,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500)),
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
                        padding:
                        const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(l10n.text_203,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.info)),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          l10n.text_175,
                          l10n.text_192,
                          l10n.text_185,
                          l10n.text_178,
                          l10n.text_193,
                          l10n.text_181,
                        ].map((stationName) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _controller.text = stationName,
                              borderRadius: BorderRadius.circular(20),
                              splashColor: colors.info.withOpacity(0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colors.infoContainer,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: colors.info.withOpacity(0.2),
                                      width: 1),
                                ),
                                child: Text(stationName,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: colors.info,
                                        fontWeight: FontWeight.w500)),
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

// ─────────────────────────────────────────────────────
// StationPage（車站詳情）
// ─────────────────────────────────────────────────────

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
  final ScrollController _trainListScrollController = ScrollController();
  final Map<int, GlobalKey> _trainItemKeys = {};
  String? _lastScrolledSig;

  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.logFeatureOpened('railway'));
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
    _trainListScrollController.dispose();
    super.dispose();
  }

  String _trainSig(List<dynamic> trains) {
    if (trains.isEmpty) return 'empty';
    final first = trains.first['DepartureTime']?.toString() ?? '';
    final last = trains.last['DepartureTime']?.toString() ?? '';
    return '${trains.length}|$first|$last'
        '|${widget.datetime.millisecondsSinceEpoch}';
  }

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
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.2);
    }
  }

  void updateStationName(String newStationName) {
    setState(() => displayedStationName = newStationName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        title: Text(
          isEnglish
              ? '${widget.stationNameEn.trim().isNotEmpty ? widget.stationNameEn : widget.stationName} Station'
          // TODO: i18n（車站）
              : '${widget.stationName} 車站',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.info,
              letterSpacing: -0.5),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.info),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.info,
          labelColor: colors.info,
          unselectedLabelColor: colors.textSecondary,
          labelStyle:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            Tab(text: l10n.text_856),
            Tab(text: l10n.text_655),
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    String _getStationClass(String? stationClass) {
      final map = {
        '0': l10n.text_857,
        '1': l10n.text_858,
        '2': l10n.text_859,
        '3': l10n.text_860,
        '4': l10n.text_861,
        '5': l10n.text_862,
      };
      return map[stationClass] ?? l10n.text_863;
    }

    return FutureBuilder<List<dynamic>>(
      future: fetchTrainStationFacility(widget.stationID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration:
              SurfaceDecoration.cardShadow(context, radius: 20),
              child: CircularProgressIndicator(
                  color: colors.info, strokeWidth: 3),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(20),
              decoration:
              SurfaceDecoration.cardShadow(context, radius: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.dangerContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded,
                        size: 40, color: colors.danger),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.text_205,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.danger)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}',
                      style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
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
                      color: colors.infoContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.train_outlined,
                        size: 50, color: colors.info),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.text_864,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.info)),
                  const SizedBox(height: 8),
                  Text(l10n.text_865,
                      style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500)),
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
                  decoration:
                  SurfaceDecoration.cardShadow(context, radius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
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
                                  decoration:
                                  SurfaceDecoration.muted(context,
                                      radius: 12),
                                  child: Icon(Icons.train_rounded,
                                      size: 20, color: colors.info),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _localizedRailField(data[0],
                                        englishKey: 'StationNameEn',
                                        chineseKey: 'StationNameZh_tw',
                                        isEnglish: Localizations.localeOf(
                                            context)
                                            .languageCode ==
                                            'en',
                                        fallback: l10n.text_160),
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildInfoItem(
                              icon: Icons.location_on_rounded,
                              label: l10n.text_866,
                              value: data[1]['StationAddress'] ??
                                  l10n.text_867,
                            ),
                            _buildInfoItem(
                              icon: Icons.grade_rounded,
                              label: l10n.text_868,
                              value:
                              _getStationClass(data[1]['StationClass']),
                            ),
                            _buildInfoItem(
                              icon: Icons.phone_rounded,
                              label: l10n.text_869,
                              value: data[1]['StationPhone'] ??
                                  l10n.text_870,
                            ),
                            _buildInfoItem(
                              icon: Icons.qr_code_rounded,
                              label: l10n.text_871,
                              value: data[1]['StationID'] ?? l10n.text_872,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...data.map((station) {
                  final facilityMaps = <Map<String, String>>[];
                  for (int i = 0; i < 5; i++) {
                    final isEnglish =
                        Localizations.localeOf(context).languageCode == 'en';
                    final mapName = _localizedRailField(station,
                        englishKey: 'FacilityMapURLs${i}MapNameEn',
                        chineseKey: 'FacilityMapURLs${i}MapNameZh_tw',
                        isEnglish: isEnglish);
                    final mapURL =
                    station['FacilityMapURLs${i}MapURL'] as String?;
                    if (mapURL != null) {
                      facilityMaps.add(
                          {'mapName': mapName, 'mapURL': mapURL});
                    }
                  }
                  final elevatorInfo =
                  station['Elevators0Description'] as String?;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        ...facilityMaps.map((facility) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: SurfaceDecoration.cardShadow(
                                context,
                                radius: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration:
                                        SurfaceDecoration.muted(context,
                                            radius: 10),
                                        child: Icon(Icons.map_rounded,
                                            size: 18, color: colors.info),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(facility['mapName']!,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary),
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis),
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
                                        color: colors.mutedBackground,
                                        child: Center(
                                          child: Text(l10n.text_873,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: colors
                                                      .textSecondary,
                                                  fontWeight:
                                                  FontWeight.w500)),
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
                            decoration: SurfaceDecoration.cardShadow(
                                context,
                                radius: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.successContainer,
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.elevator_rounded,
                                      size: 20, color: colors.success),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    // TODO: i18n（電梯資訊:）
                                    "電梯資訊: $elevatorInfo",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w500),
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
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: SurfaceDecoration.muted(context, radius: 8),
            child: Icon(icon, size: 16, color: colors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainInfoPage() {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.cardBackground,
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
                    decoration: BoxDecoration(
                      color: colors.infoContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.train_rounded,
                        size: 28, color: colors.info),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.text_874,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.info)),
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
                      color: colors.dangerContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline_rounded,
                        size: 28, color: colors.danger),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.text_875,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.danger)),
                  const SizedBox(height: 8),
                  Text(l10n.text_206,
                      style: TextStyle(
                          fontSize: 14, color: colors.textSecondary)),
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
                      color: colors.infoContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        size: 28, color: colors.info),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.text_876,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.info)),
                ],
              ),
            );
          }

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
                    final itemKey =
                    _trainItemKeys.putIfAbsent(index, () => GlobalKey());

                    final trainNo = (train['TrainNo'])?.toString() ??
                        l10n.text_321;
                    final trainTypeName = _localizedRailName(
                      train['TrainTypeName'],
                      isEnglish: Localizations.localeOf(context)
                          .languageCode ==
                          'en',
                    );
                    final trainType = Localizations.localeOf(context)
                        .languageCode ==
                        'en'
                        ? trainTypeName
                        : convertTrainType(trainTypeName);
                    final departureTime =
                    _formatTime(train['DepartureTime'] ?? l10n.text_321);
                    final delayTime = train['DelayTime'];
                    var endingStation = _localizedRailName(
                      train['EndingStationName'],
                      isEnglish: Localizations.localeOf(context)
                          .languageCode ==
                          'en',
                    );
                    if (endingStation.isEmpty) endingStation = l10n.text_321;

                    final isDelayed = delayTime != null && delayTime > 0;
                    final isExpress = trainType.contains(l10n.text_877) ||
                        trainType.contains(l10n.text_878) ||
                        trainType.contains(l10n.text_879);

                    return KeyedSubtree(
                      key: itemKey,
                      child: Transform.translate(
                        offset: Offset(0, index * 0.3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final trainNoInt =
                              _parseTrainNoDigits(trainNo);
                              if (trainNoInt == null) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  // TODO: i18n（車次號碼無效：）
                                  content: Text('車次號碼無效：$trainNo'),
                                  backgroundColor: colors.danger,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                ));
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
                            splashColor: colors.info.withOpacity(0.1),
                            highlightColor:
                            colors.mutedBackground.withOpacity(0.5),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 20),
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.shadow,
                                    blurRadius: isDelayed ? 20 : 12,
                                    offset: Offset(
                                        0, isDelayed ? 6 : 3),
                                  ),
                                ],
                                border: isDelayed
                                    ? Border.all(
                                    color: colors.danger
                                        .withOpacity(0.2),
                                    width: 1.5)
                                    : isExpress
                                    ? Border.all(
                                    color:
                                    colors.info.withOpacity(0.1),
                                    width: 1)
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
                                          color: colors.danger,
                                          borderRadius:
                                          const BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            bottomLeft:
                                            Radius.circular(20),
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
                                            color: _getTrainTypeColor(
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
                                            color: colors.cardBackground,
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
                                                CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      // TODO: i18n（車次）
                                                      '車次 $trainNo',
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                        FontWeight.w700,
                                                        color: isDelayed
                                                            ? colors
                                                            .textPrimary
                                                            : colors
                                                            .textPrimary,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: isDelayed
                                                          ? colors
                                                          .dangerContainer
                                                          : colors
                                                          .infoContainer,
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(10),
                                                    ),
                                                    child: Text(
                                                      departureTime,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                        FontWeight.w700,
                                                        color: isDelayed
                                                            ? colors.danger
                                                            : colors.info,
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
                                                      // TODO: i18n（往）
                                                      '往 $endingStation',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        color: colors
                                                            .textSecondary,
                                                        fontWeight:
                                                        FontWeight.w500,
                                                        height: 1.4,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (isDelayed)
                                                    _buildStatusBadge(
                                                      // TODO: i18n（延誤 X分）
                                                        '延誤 ${delayTime}分',
                                                        colors.danger),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: _getTrainTypeColor(
                                                          trainType)
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(8),
                                                      border: Border.all(
                                                        color: _getTrainTypeColor(
                                                            trainType)
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      trainType,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _getTrainTypeColor(
                                                            trainType),
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                    const EdgeInsets
                                                        .all(6),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: colors
                                                          .mutedBackground,
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(10),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
                                                      size: 14,
                                                      color: colors
                                                          .textSecondary,
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
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _getTrainTypeColor(String trainType) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    if (trainType.contains(l10n.text_877) ||
        trainType.contains(l10n.text_878) ||
        trainType.contains(l10n.text_879)) {
      return colors.info;
    } else if (trainType.contains(l10n.text_882)) {
      return colors.success;
    } else if (trainType.contains(l10n.text_883) ||
        trainType.contains(l10n.text_884)) {
      return colors.warning;
    } else {
      return colors.info;
    }
  }

  IconData _getTrainTypeIcon(String trainType) {
    final l10n = AppLocalizations.of(context)!;
    if (trainType.contains(l10n.text_877) ||
        trainType.contains(l10n.text_878) ||
        trainType.contains(l10n.text_879)) {
      return Icons.directions_railway_filled_rounded;
    } else if (trainType.contains(l10n.text_882)) {
      return Icons.train_rounded;
    } else if (trainType.contains(l10n.text_883) ||
        trainType.contains(l10n.text_884)) {
      return Icons.directions_subway_rounded;
    } else {
      return Icons.directions_transit_rounded;
    }
  }

  String _formatTime(String time) {
    try {
      final parsedTime = DateTime.parse('1970-01-01 $time');
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }
}

// ─────────────────────────────────────────────────────
// RoutePage（路線結果）
// ─────────────────────────────────────────────────────

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
  bool onlyDirect = false;
  bool onlyTransfer = false;
  int maxTotalMinutes = 999;
  Set<String> allowedTrainTypes = {};

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
  ItemPositionsListener.create();

  bool _shouldAutoScroll = true;
  DateTime? _lastScrollTime;
  DateTime? _previousDate;

  Future<Map<String, dynamic>>? _routeFuture;

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
    if (odChanged || dateChanged) _routeFuture = queryTrainList();
    if (dateChanged) {
      _shouldAutoScroll = true;
      _previousDate = oldWidget.date;
    }
  }

  Future<Map<String, dynamic>> queryTrainList() async {
    final weekday = widget.date.weekday % 7;
    final url = 'http://hidden.rsmn574.com:3920/api/train'
        '?from=${widget.departure["StationID"]}'
        '&to=${widget.destination["StationID"]}'
        '&day=$weekday';
    final res =
    await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('API ${res.statusCode}');
    return jsonDecode(res.body);
  }

  int _timeToMinutes(String? hhmm) => _timeToMinutesSafe(hhmm);

  int _selectedMinutes() =>
      widget.date.hour * 60 + widget.date.minute;

  int trainDepMinutes(dynamic t) {
    if (t is! Map) return 1440;
    final isTransfer = t['transfer'] == true;
    String? timeStr;
    if (isTransfer) {
      final leg1 = t['leg1'];
      if (leg1 is Map) timeStr = leg1['depTime']?.toString();
    } else {
      timeStr = t['depTime']?.toString();
    }
    if (timeStr == null || timeStr.isEmpty) return 1440;
    final minutes = _timeToMinutesSafe(timeStr);
    if (minutes == 0 && timeStr != '00:00' && timeStr != '0:00') {
      return 1440;
    }
    return minutes;
  }

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
          t['totalTimeMin'] > maxTotalMinutes) return false;
      final types = t['transfer']
          ? [t['leg1']['TrainTypeName'], t['leg2']['TrainTypeName']]
          : [t['TrainTypeName']];
      if (allowedTrainTypes.isNotEmpty &&
          !types.any((e) => allowedTrainTypes.contains(e))) return false;
      return true;
    }).toList()
      ..sort((a, b) =>
          trainDepMinutes(a).compareTo(trainDepMinutes(b)));
  }

  int findClosestTrainIndex(List<dynamic> trains) {
    if (trains.isEmpty) return -1;
    final base = _selectedMinutes();
    for (int i = 0; i < trains.length; i++) {
      if (trainDepMinutes(trains[i]) >= base) return i;
    }
    return trains.length - 1;
  }

  bool _shouldScrollToClosest() {
    if (_shouldAutoScroll) return true;
    if (_previousDate != null && widget.date != _previousDate) return true;
    if (_lastScrollTime == null ||
        DateTime.now().difference(_lastScrollTime!) >
            const Duration(seconds: 2)) return true;
    return false;
  }

  Color _getTrainTypeColor(String trainType) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    if (trainType.contains(l10n.text_877) ||
        trainType.contains(l10n.text_878) ||
        trainType.contains(l10n.text_879)) {
      return colors.info;
    } else if (trainType.contains(l10n.text_882)) {
      return colors.success;
    } else if (trainType.contains(l10n.text_883) ||
        trainType.contains(l10n.text_884)) {
      return colors.warning;
    }
    return colors.info;
  }

  Widget directCard(dynamic t) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final trainType = t['TrainTypeName'] ?? '';
    final typeColor = _getTrainTypeColor(trainType);
    final trainNo = t['TrainNo'];

    return InkWell(
      onTap: () async {
        final trainNoInt = _parseTrainNoDigits(trainNo?.toString());
        if (trainNoInt == null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            // TODO: i18n（車次號碼無效：）
            content: Text('車次號碼無效：$trainNo'),
            backgroundColor: colors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
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
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              // TODO: i18n（查詢車次 X 失敗）
              content: Text('查詢車次 $trainNo 失敗'),
              backgroundColor: colors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
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
                  Text(l10n.text_67,
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                  Text(t['depTime'],
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_railway_rounded,
                        size: 16, color: colors.success),
                    const SizedBox(width: 4),
                    Text(l10n.text_892,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.success)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.text_68,
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                  Text(t['arrTime'],
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: SurfaceDecoration.muted(context, radius: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.train_rounded,
                      size: 18, color: colors.cardBackground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // TODO: i18n（車次）
                        '車次 $trainNo',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(trainType,
                          style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getTravelTime(t['depTime']?.toString() ?? '',
                        t['arrTime']?.toString() ?? ''),
                    style: TextStyle(
                        fontSize: 12,
                        color: typeColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTravelTime(String dep, String arr) {
    final diff = _calcDurationMinutes(dep, arr);
    return '${diff ~/ 60}小時${diff % 60}分';
  }

  Widget transferTimeline(dynamic t) {
    final colors = context.appColors;
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tight
                    ? colors.dangerContainer
                    : colors.warningContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: tight
                        ? colors.danger.withOpacity(0.3)
                        : colors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    tight
                        ? Icons.warning_amber_rounded
                        : Icons.timeline_rounded,
                    size: 16,
                    color: tight ? colors.danger : colors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t['totalTimeHuman'] ??
                        '${totalMin ~/ 60}小時${totalMin % 60}分',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                        tight ? colors.danger : colors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: SurfaceDecoration.muted(context, radius: 20),
              child: Text(
                // TODO: i18n（轉乘 X 分）
                '轉乘 ${t['waitMin']} 分',
                style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600),
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
                _buildTimelineDot(colors.success),
                _buildTimelineLine(),
                _buildTimelineDot(tight ? colors.danger : colors.warning),
                _buildTimelineLine(),
                _buildTimelineDot(colors.info),
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
                      onTap: () async => _navigateToTrainDetail(
                          trainNo1?.toString() ?? ''),
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
                      onTap: () async => _navigateToTrainDetail(
                          trainNo2?.toString() ?? ''),
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

  Future<void> _navigateToTrainDetail(String trainNo) async {
    final colors = context.appColors;
    final trainNoInt = _parseTrainNoDigits(trainNo);
    if (trainNoInt == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('車次號碼無效：$trainNo'),
        backgroundColor: colors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('查詢車次 $trainNo 失敗'),
          backgroundColor: colors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Widget _buildTimelineDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildTimelineLine() {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: 2,
      height: 24,
      color: colors.border,
    );
  }

  Widget _buildLegCard(dynamic leg, {required bool isFirst}) {
    final colors = context.appColors;
    final trainType = leg['TrainTypeName'] ?? '';
    final typeColor = _getTrainTypeColor(trainType);
    final trainNo = leg['TrainNo'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: SurfaceDecoration.cardShadow(context, radius: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFirst ? Icons.departure_board_rounded : Icons.train_rounded,
              size: 16,
              color: colors.cardBackground,
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
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary),
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
                        // TODO: i18n（車次）
                        '車次 $trainNo',
                        style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(trainType,
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferStationCard(dynamic station, bool tight) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tight
            ? colors.danger.withOpacity(0.05)
            : colors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tight
              ? colors.danger.withOpacity(0.2)
              : colors.warning.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tight
                  ? colors.danger.withOpacity(0.1)
                  : colors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.transfer_within_a_station_rounded,
                size: 16, color: tight ? colors.danger : colors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // TODO: i18n（轉乘站）
                  '轉乘站 ${station['name']}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tight ? colors.danger : colors.warning),
                ),
                if (tight)
                  Text(
                    AppLocalizations.of(context)!.text_893,
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.danger,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final weekday = [
      l10n.text_306,
      l10n.text_307,
      l10n.text_308,
      l10n.text_309,
      l10n.text_310,
      l10n.text_311,
      l10n.text_312
    ][date.weekday - 1];
    // TODO: i18n（年月日 週）
    return '${date.year}年${date.month}月${date.day}日 週$weekday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final isEnglish =
        Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.train_rounded, size: 20, color: colors.info),
            const SizedBox(width: 8),
            Text(
              _localizedRailName(widget.departure['StationName'],
                  isEnglish: isEnglish),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 16, color: colors.info),
            ),
            Text(
              _localizedRailName(widget.destination['StationName'],
                  isEnglish: isEnglish),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.info),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _routeFuture,
        builder: (_, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration:
                SurfaceDecoration.cardShadow(context, radius: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: colors.info, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text(l10n.text_894,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.info)),
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
                decoration:
                SurfaceDecoration.cardShadow(context, radius: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: colors.dangerContainer,
                          shape: BoxShape.circle),
                      child: Icon(Icons.error_outline_rounded,
                          size: 40, color: colors.danger),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.text_205,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.danger)),
                    const SizedBox(height: 8),
                    Text(l10n.text_206,
                        style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary)),
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
                          color: colors.infoContainer,
                          shape: BoxShape.circle),
                      child: Icon(Icons.train_outlined,
                          size: 50, color: colors.info),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.text_207,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.info)),
                    const SizedBox(height: 8),
                    Text(l10n.text_895,
                        style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary)),
                  ],
                ),
              ),
            );
          }

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                margin: const EdgeInsets.all(20),
                decoration: SurfaceDecoration.outlined(context,
                    radius: 16, borderColor: colors.info.withOpacity(0.2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: colors.infoContainer,
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.calendar_today_rounded,
                          size: 16, color: colors.info),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _formatDate(widget.date),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.info),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemBuilder: (_, i) {
                    final t = trains[i];
                    final isClosest = i == closestIndex;
                    final isAfterSelectedTime =
                        trainDepMinutes(t) >= _selectedMinutes();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: isClosest ? 20 : 12,
                            offset: Offset(0, isClosest ? 6 : 4),
                          ),
                        ],
                        border: isClosest
                            ? Border.all(color: colors.info, width: 2)
                            : !isAfterSelectedTime
                            ? Border.all(
                            color: colors.border, width: 1)
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          splashColor: colors.info.withOpacity(0.1),
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