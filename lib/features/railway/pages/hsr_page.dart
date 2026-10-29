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

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/surface_decoration.dart';

import 'package:com.rsmn574.app/features/railway/widgets/seat_status_badge.dart';
import '../../../firebase/analytics_service.dart';
import '../model/hsr_seat_status_model.dart';
import '../provider/hsr_seat_status_provider.dart';

/// 高鐵品牌色（固定語意、不隨主題變化）
const Color hsrBrandColor = Color(0xFFDC5321);

// 相容舊 import
const Color primaryColor = hsrBrandColor;
const Color surfaceColor = Color(0xFFF8F9FA);
const Color textPrimary = Color(0xFF2D3748);
const Color textSecondary = Color(0xFF718096);

String _formatYmd(BuildContext context, DateTime date) {
  final code = Localizations.localeOf(context).languageCode;
  return DateFormat(code == 'en' ? 'MMM dd, yyyy' : 'yyyy年MM月dd日')
      .format(date);
}

String _formatYmdHm(BuildContext context, DateTime date) {
  final code = Localizations.localeOf(context).languageCode;
  return DateFormat(
      code == 'en' ? 'MMM dd, yyyy HH:mm' : 'yyyy年M月d日 HH:mm')
      .format(date);
}

// ─────────────────────────────────────────────────────
// HSR 主頁
// ─────────────────────────────────────────────────────

class HSR extends StatefulWidget {
  const HSR({super.key});

  @override
  State<HSR> createState() => _HSRState();
}

class _HSRState extends State<HSR> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _trainNoController = TextEditingController();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _stationController = TextEditingController();

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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.text_144,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.text_145),
            Tab(text: l10n.text_146),
            Tab(text: l10n.text_147),
          ],
          labelColor: hsrBrandColor,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: hsrBrandColor,
          dividerColor: colors.divider,
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

// ─────────────────────────────────────────────────────
// 車次查詢
// ─────────────────────────────────────────────────────

class TripNumberSearchPage extends StatefulWidget {
  final TextEditingController controller;
  const TripNumberSearchPage({Key? key, required this.controller})
      : super(key: key);

  @override
  State<TripNumberSearchPage> createState() => _TripNumberSearchPageState();
}

class _TripNumberSearchPageState extends State<TripNumberSearchPage> {
  DateTime selectedDate = DateTime.now();
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

  void _validateInput() =>
      setState(() => _isInputValid = widget.controller.text.trim().isNotEmpty);

  Future<void> _selectDate(BuildContext context) async {
    final colors = context.appColors;
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: hsrBrandColor,
            surface: colors.cardBackground,
            onSurface: colors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: colors.cardBackground,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: hsrBrandColor),
          ),
        ),
        child: child!,
      ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
                icon: Icons.directions_railway_filled_rounded,
                title: l10n.text_148,
                subtitle: l10n.text_149,
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: SurfaceDecoration.cardShadow(context, radius: 20),
                child: Column(
                  children: [
                    // 車次輸入框
                    Container(
                      decoration: SurfaceDecoration.outlined(
                        context,
                        radius: 12,
                        borderColor: widget.controller.text.isEmpty
                            ? colors.border
                            : hsrBrandColor.withOpacity(0.3),
                        width: widget.controller.text.isEmpty ? 1 : 1.5,
                      ),
                      child: TextField(
                        controller: widget.controller,
                        onChanged: (_) => _validateInput(),
                        style: TextStyle(color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: l10n.text_150,
                          hintStyle: TextStyle(color: colors.textHint),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.directions_railway_filled_rounded,
                              color: hsrBrandColor,
                            ),
                          ),
                          suffixIcon: _isInputValid
                              ? Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: hsrBrandColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: hsrBrandColor,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 日期選擇
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        splashColor: hsrBrandColor.withOpacity(0.1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: SurfaceDecoration.muted(
                            context,
                            radius: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: hsrBrandColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: hsrBrandColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatYmd(context, selectedDate),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: hsrBrandColor,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded,
                                  color: hsrBrandColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 查詢按鈕
                    _buildPrimaryButton(
                      context,
                      label: l10n.text_153,
                      onTap: _isInputValid
                          ? () async {
                        try {
                          final trainData = await fetchHSR(
                            int.parse(widget.controller.text)
                                .toString()
                                .padLeft(4, '0'),
                            selectedDate,
                          );
                          if (!context.mounted) return;
                          if (trainData == null) {
                            _showSnack(context, l10n.text_151,
                                isError: true);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HSRSchedulePage(
                                  trainData: trainData,
                                  type: 'trainNo',
                                  time: selectedDate,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          _showSnack(context, l10n.text_152,
                              isError: true);
                        }
                      }
                          : null,
                    ),
                  ],
                ),
              ),
              _buildTipCard(
                context,
                title: l10n.text_154,
                body: l10n.text_155,
              ),
              // 快速選擇車次
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        l10n.text_156,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hsrBrandColor,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['0813', '0618', '0624', '0826', '0636']
                          .map((trainNo) => _buildChip(
                        context,
                        trainNo,
                        onTap: () {
                          widget.controller.text = trainNo;
                          _validateInput();
                        },
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 路線查詢
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
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  Map<String, dynamic> departureSelectedStation = {};
  Map<String, dynamic> destinationSelectedStation = {};
  DateTime? selectedDate;
  bool _isDepartureSelected = false;
  bool _isDestinationSelected = false;

  Future<void> _selectDateTime(BuildContext context) async {
    final colors = context.appColors;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: hsrBrandColor,
            surface: colors.cardBackground,
            onSurface: colors.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: colors.cardBackground,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: hsrBrandColor),
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: hsrBrandColor,
            surface: colors.cardBackground,
            onSurface: colors.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: colors.cardBackground,
            hourMinuteTextColor: hsrBrandColor,
            dayPeriodTextColor: hsrBrandColor,
            dayPeriodColor: hsrBrandColor.withOpacity(0.1),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: hsrBrandColor.withOpacity(0.3), width: 1),
            ),
            hourMinuteColor: hsrBrandColor.withOpacity(0.05),
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                  color: hsrBrandColor.withOpacity(0.2), width: 1),
            ),
            dialBackgroundColor: colors.mutedBackground,
            dialTextColor: hsrBrandColor,
            entryModeIconColor: hsrBrandColor,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

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

  void _swapStations() {
    if (departureSelectedStation.isEmpty &&
        destinationSelectedStation.isEmpty) {
      return;
    }
    setState(() {
      // 用暫存字串，避免 TextEditingController 洩漏
      final tempText = widget.departureController.text;
      widget.departureController.text = widget.destinationController.text;
      widget.destinationController.text = tempText;

      final tempStation = departureSelectedStation;
      departureSelectedStation = destinationSelectedStation;
      destinationSelectedStation = tempStation;

      final tempSelected = _isDepartureSelected;
      _isDepartureSelected = _isDestinationSelected;
      _isDestinationSelected = tempSelected;
    });

    if (widget.departureController.text ==
        widget.destinationController.text &&
        widget.departureController.text.isNotEmpty) {
      _showSnack(
          context, AppLocalizations.of(context)!.text_157,
          isError: true);
    }
  }

  Future<void> _pickStation({required bool isDeparture}) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await StationDialog.showStationDialog(context);
    if (selected == null) return;

    final stationName = selected['StationName']['Zh_tw'] ?? l10n.text_160;
    setState(() {
      if (isDeparture) {
        departureSelectedStation = selected;
        _isDepartureSelected = true;
        widget.departureController.text = stationName;
      } else {
        destinationSelectedStation = selected;
        _isDestinationSelected = true;
        widget.destinationController.text = stationName;
      }
    });

    if (!isDeparture &&
        widget.departureController.text ==
            widget.destinationController.text) {
      _showSnack(context, l10n.text_157, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
                icon: Icons.route_rounded,
                title: l10n.text_158,
                subtitle: l10n.text_159,
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: SurfaceDecoration.cardShadow(context, radius: 20),
                child: Column(
                  children: [
                    _PickerTile(
                      isSelected: _isDepartureSelected,
                      icon: Icons.departure_board_rounded,
                      label: l10n.text_63,
                      value: _isDepartureSelected
                          ? widget.departureController.text
                          : l10n.text_161,
                      onTap: () => _pickStation(isDeparture: true),
                    ),
                    // 交換按鈕
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: IconButton(
                        onPressed: _swapStations,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hsrBrandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: hsrBrandColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Transform.rotate(
                            angle: 90 * (3.1415926535 / 180),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: hsrBrandColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _PickerTile(
                      isSelected: _isDestinationSelected,
                      icon: Icons.flag_rounded,
                      label: l10n.text_162,
                      value: _isDestinationSelected
                          ? widget.destinationController.text
                          : l10n.text_163,
                      onTap: () => _pickStation(isDeparture: false),
                    ),
                    const SizedBox(height: 20),
                    _PickerTile(
                      isSelected: selectedDate != null,
                      icon: Icons.calendar_today_rounded,
                      label: l10n.text_164,
                      value: selectedDate != null
                          ? _formatYmdHm(context, selectedDate!)
                          : l10n.text_165,
                      onTap: () => _selectDateTime(context),
                    ),
                    const SizedBox(height: 24),
                    _buildPrimaryButton(
                      context,
                      label: l10n.text_166,
                      onTap: () {
                        if (!_isDepartureSelected) {
                          _showSnack(context, l10n.text_161,
                              isError: true);
                          return;
                        }
                        if (!_isDestinationSelected) {
                          _showSnack(context, l10n.text_163,
                              isError: true);
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
                    ),
                  ],
                ),
              ),
              _buildTipCard(
                context,
                title: l10n.text_154,
                body: l10n.text_167,
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        l10n.text_168,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hsrBrandColor,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        l10n.text_169,
                        l10n.text_170,
                        l10n.text_171,
                        l10n.text_172,
                        l10n.text_173,
                      ]
                          .map((route) => _buildChip(context, route))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 車站查詢
// ─────────────────────────────────────────────────────

class StationSearchPage extends StatefulWidget {
  final TextEditingController controller;
  const StationSearchPage({Key? key, required this.controller})
      : super(key: key);

  @override
  State<StationSearchPage> createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<StationSearchPage> {
  final _controller = TextEditingController();
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

  void _validateInput() => setState(
          () => _isStationSelected = _controller.text.trim().isNotEmpty);

  Future<void> openURL(String? url, BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (url == null || url.isEmpty) {
      _showSnack(context, '無效的 URL', isError: true); // TODO: i18n
      return;
    }
    final uri = Uri.parse(Uri.encodeFull(url));
    try {
      final canOpen =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!canOpen) {
        _showSnack(context, l10n.text_195, isError: true);
      }
    } catch (e) {
      _showSnack(context, l10n.text_196, isError: true);
    }
  }

  Future<void> _pickStation() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await StationDialog.showStationDialog(context);
    if (selected == null) return;
    setState(() {
      selectedStation = selected;
      _controller.text =
          selected['StationName']['Zh_tw'] ?? l10n.text_160;
      _isStationSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
                icon: Icons.location_city_rounded,
                title: l10n.text_197,
                subtitle: l10n.text_198,
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: SurfaceDecoration.cardShadow(context, radius: 20),
                child: Column(
                  children: [
                    _PickerTile(
                      isSelected: _isStationSelected,
                      icon: Icons.train_rounded,
                      label: l10n.text_199,
                      value: _isStationSelected
                          ? _controller.text
                          : l10n.text_200,
                      onTap: _pickStation,
                    ),
                    const SizedBox(height: 24),
                    _buildPrimaryButton(
                      context,
                      label: l10n.text_201,
                      onTap: _isStationSelected
                          ? () => openURL(selectedStation?["URL"], context)
                          : null,
                    ),
                  ],
                ),
              ),
              _buildTipCard(
                context,
                title: l10n.text_154,
                body: l10n.text_202,
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        l10n.text_203,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hsrBrandColor,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        l10n.text_175,
                        l10n.text_185,
                        l10n.text_192,
                        l10n.text_193,
                        l10n.text_178,
                        l10n.text_181,
                      ]
                          .map((name) => _buildChip(
                        context,
                        name,
                        onTap: () {
                          setState(() {
                            _controller.text = name;
                            _isStationSelected = true;
                          });
                        },
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 路線結果頁（含座位狀態系統）
// ─────────────────────────────────────────────────────

class RoutePage extends StatefulWidget {
  final Map<String, dynamic> departure;
  final Map<String, dynamic> destination;
  final DateTime date;

  const RoutePage({
    super.key,
    required this.departure,
    required this.destination,
    required this.date,
  });

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final _itemScrollController = ItemScrollController();
  bool _hasScrolled = false;

  // 座位狀態系統
  late final HsrSeatStatusProvider _seatProvider;

  @override
  void initState() {
    super.initState();
    _seatProvider = HsrSeatStatusProvider();
    _seatProvider.addListener(_onSeatChanged);
  }

  void _onSeatChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _seatProvider.removeListener(_onSeatChanged);
    _seatProvider.dispose();
    super.dispose();
  }

  // 只保留原始 API 作為備用，主流程走 _seatProvider
  Future<Map<String, dynamic>> _fetchSeatStatus(
      Map<String, dynamic> train) async {
    try {
      final origin = train["OriginStopTime"];
      final dest = train["DestinationStopTime"];
      final trainNo = train["DailyTrainInfo"]["TrainNo"];

      final d = await mysqlSelect(
          "SELECT * FROM HSR.HSR_Station WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '${origin["StationName"]["Zh_tw"]}';");
      final a = await mysqlSelect(
          "SELECT * FROM HSR.HSR_Station WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) = '${dest["StationName"]["Zh_tw"]}';");

      if (d.isEmpty || a.isEmpty) {
        return {
          "AvailableSeats": [
            {"StandardSeatStatus": "N", "BusinessSeatStatus": "N"}
          ]
        };
      }

      return await fetchAvailableSeatStatus(
        d[0]["StationID"],
        a[0]["StationID"],
        trainNo.replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0'),
        DateFormat('yyyy-MM-dd').format(DateTime.parse(train["TrainDate"])),
      );
    } catch (e) {
      debugPrint('fetchSeatStatus failed: $e');
      return {
        "AvailableSeats": [
          {"StandardSeatStatus": "N", "BusinessSeatStatus": "N"}
        ]
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.departure["StationName"]["Zh_tw"],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: hsrBrandColor),
            ),
            Text(
              widget.destination["StationName"]["Zh_tw"],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: context.read<RailwayProvider>().hsrRoute(
          widget.departure["StationID"],
          widget.destination["StationID"],
          DateFormat('yyyy-MM-dd').format(widget.date),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }
          if (snapshot.hasError) {
            return _buildErrorState(context);
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final data = snapshot.data!;
          final trainDateFormat = DateFormat('yy-MM-dd');

          // 座位狀態：一次查詢整個 OD（不阻塞路線顯示）
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _seatProvider.load(
              originStationId: widget.departure["StationID"],
              destinationStationId: widget.destination["StationID"],
              date: widget.date,
            );
          });

          final seatStatus = _seatProvider.statusFor(
            widget.departure["StationID"],
            widget.destination["StationID"],
            widget.date,
          );
          final isSeatLoading = _seatProvider.isLoadingFor(
            widget.departure["StationID"],
            widget.destination["StationID"],
            widget.date,
          );
          final seatError = _seatProvider.errorFor(
            widget.departure["StationID"],
            widget.destination["StationID"],
            widget.date,
          );

          // 只計算一次最近班次索引（避免每次 build 都 O(n)）
          final closestIndex = _findClosestIndex(data);

          // 自動滾動到最近班次
          if (!_hasScrolled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
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
              _buildDateBar(context, seatStatus, seatError, isSeatLoading),
              Expanded(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemCount: data.length,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemBuilder: (context, index) {
                    final train = data[index];
                    return _buildTrainCard(
                      context: context,
                      train: train,
                      trainNo: train["DailyTrainInfo"]["TrainNo"],
                      isClosest: index == closestIndex,
                      trainDateFormat: trainDateFormat,
                      seatStatus: seatStatus,
                      isSeatLoading: isSeatLoading,
                      seatError: seatError,
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

  Widget _buildLoadingState(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: SurfaceDecoration.cardShadow(context, radius: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: hsrBrandColor, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              l10n.text_204,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: hsrBrandColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: SurfaceDecoration.cardShadow(context, radius: 20),
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
            Text(
              l10n.text_205,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text_206,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                color: hsrBrandColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.train_outlined,
                  size: 50, color: hsrBrandColor),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.text_207,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: hsrBrandColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text_208,
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBar(
      BuildContext context,
      HsrOdSeatStatus? seatStatus,
      String? seatError,
      bool isSeatLoading,
      ) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: hsrBrandColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hsrBrandColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: hsrBrandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                size: 16, color: hsrBrandColor),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _formatYmdHm(context, widget.date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hsrBrandColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (seatStatus != null && !seatStatus.isEmpty) ...[
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 14,
              color: colors.border,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_seat_rounded,
                      size: 14, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '座位 ${DateFormat('HH:mm').format(seatStatus.updateTime)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isSeatLoading) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: colors.textSecondary,
              ),
            ),
          ] else if (seatError != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.error_outline_rounded,
                size: 14, color: colors.danger),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainCard({
    required BuildContext context,
    required dynamic train,
    required String trainNo,
    required bool isClosest,
    required DateFormat trainDateFormat,
    required HsrOdSeatStatus? seatStatus,
    required bool isSeatLoading,
    required String? seatError,
  }) {
    final colors = context.appColors;
    final origin = train["OriginStopTime"];
    final dest = train["DestinationStopTime"];

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
            ? Border.all(color: hsrBrandColor, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final trainData = await fetchHSR(
              trainNo,
              DateTime.parse(train["TrainDate"]),
            );
            if (!context.mounted) return;
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
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: hsrBrandColor.withOpacity(0.1),
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
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trainDateFormat
                            .format(DateTime.parse(train["TrainDate"])),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hsrBrandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.train_rounded,
                              size: 14, color: hsrBrandColor),
                          const SizedBox(width: 4),
                          Text(
                            trainNo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: hsrBrandColor,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin["DepartureTime"],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: hsrBrandColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.departure_board_rounded,
                                  size: 14,
                                  color: hsrBrandColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  origin["StationName"]["Zh_tw"],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: hsrBrandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              size: 20, color: hsrBrandColor),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dest["ArrivalTime"],
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  dest["StationName"]["Zh_tw"],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colors.successContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.flag_rounded,
                                    size: 14, color: colors.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 座位狀態
                _buildSeatRow(
                  context: context,
                  trainNo: trainNo,
                  seatStatus: seatStatus,
                  isSeatLoading: isSeatLoading,
                  seatError: seatError,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatRow({
    required BuildContext context,
    required String trainNo,
    required HsrOdSeatStatus? seatStatus,
    required bool isSeatLoading,
    required String? seatError,
  }) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final seat = seatStatus?.forTrain(trainNo);

    // 若座位 API 未回傳此車次 → 顯示未知
    final standard = seat?.hasStandardSeat;
    final business = seat?.hasBusinessSeat;
    final isLoading = isSeatLoading || seatStatus == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.mutedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SeatStatusBadge(
              label: l10n.text_213, // 標準車廂
              hasSeat: standard,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SeatStatusBadge(
              label: l10n.text_216, // 商務車廂
              hasSeat: business,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }

  int _findClosestIndex(List<dynamic> data) {
    int closestIndex = 0;
    Duration minDiff = const Duration(days: 999);
    for (int i = 0; i < data.length; i++) {
      final train = data[i];
      final depTimeStr =
          '${train["TrainDate"]} ${train["OriginStopTime"]["DepartureTime"]}';
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
}

// ─────────────────────────────────────────────────────
// 共用小元件
// ─────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: hsrBrandColor.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? hsrBrandColor.withOpacity(0.05)
                : colors.mutedBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? hsrBrandColor.withOpacity(0.3)
                  : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? hsrBrandColor
                      : hsrBrandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : hsrBrandColor,
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
                        fontSize: 12,
                        color: isSelected
                            ? hsrBrandColor
                            : colors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? hsrBrandColor
                            : colors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              isSelected
                  ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: hsrBrandColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: hsrBrandColor,
                ),
              )
                  : Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHeader(
    BuildContext context, {
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
  final colors = context.appColors;
  return Container(
    margin: const EdgeInsets.only(bottom: 32),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: hsrBrandColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: hsrBrandColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPrimaryButton(
    BuildContext context, {
      required String label,
      VoidCallback? onTap,
    }) {
  final enabled = onTap != null;
  return SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(
        color: enabled ? hsrBrandColor : context.appColors.mutedBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
          BoxShadow(
            color: hsrBrandColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                  color: enabled
                      ? Colors.white
                      : context.appColors.textHint,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? Colors.white
                          : context.appColors.textHint,
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
  );
}

Widget _buildTipCard(
    BuildContext context, {
      required String title,
      required String body,
    }) {
  final colors = context.appColors;
  return Container(
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
            color: hsrBrandColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: hsrBrandColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hsrBrandColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
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

Widget _buildChip(BuildContext context, String label,
    {VoidCallback? onTap}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: hsrBrandColor.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hsrBrandColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hsrBrandColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: hsrBrandColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

void _showSnack(BuildContext context, String message,
    {bool isError = false}) {
  final colors = context.appColors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? colors.danger : colors.info,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}