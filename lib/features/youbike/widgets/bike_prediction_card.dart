// lib/youbike/widgets/bike_prediction_card.dart
import 'package:flutter/material.dart';

import '../../../const/app_colors.dart';
import '../../../const/app_design_tokens.dart';
import '../models/bike_prediction.dart';
import '../services/bike_prediction_service.dart';

/// 可查詢的預測時段（HH:mm）
const List<String> kPredictionSchedule = [
  '06:00', '06:15', '06:30', '06:45',
  '07:00', '07:15', '07:30', '07:45',
  '08:00', '09:00', '10:00', '11:00',
  '12:00', '12:30', '13:00',
  '14:00', '15:00',
  '16:00', '16:15', '16:30', '16:45',
  '17:00', '17:15',
];

class BikePredictionCard extends StatefulWidget {
  final String stationUID;

  const BikePredictionCard({super.key, required this.stationUID});

  @override
  State<BikePredictionCard> createState() => _BikePredictionCardState();
}

class _BikePredictionCardState extends State<BikePredictionCard> {
  /// 當前選中的時段（HH:mm），預設為「現在之後最近的時段」
  late String _selectedTime;

  bool _loading = true;
  BikePrediction? _data;
  String? _error;
  int _requestId = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedTime = _defaultTime();
    // 第一次渲染後把選中 chip 滾到可見位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animate: false);
    });
    _fetch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BikePredictionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stationUID != widget.stationUID) {
      _fetch();
    }
  }

  // ──────────── 時間工具 ────────────

  int _toMin(String hhmm) {
    final p = hhmm.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  String _defaultTime() {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    for (final t in kPredictionSchedule) {
      if (_toMin(t) >= m) return t;
    }
    return kPredictionSchedule.first; // 全部已過 → 視為明天第一班
  }

  /// 是否為「今天已過」的時段（選到時要當明天）
  bool _isPast(String hhmm) {
    final now = DateTime.now();
    return _toMin(hhmm) < now.hour * 60 + now.minute;
  }

  /// 組出完整 DateTime；已過則順延一天
  DateTime _targetTime() {
    final now = DateTime.now();
    final p = _selectedTime.split(':');
    final h = int.parse(p[0]);
    final m = int.parse(p[1]);
    var d = DateTime(now.year, now.month, now.day, h, m);
    if (d.isBefore(now)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  // ──────────── 請求 ────────────

  Future<void> _fetch() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await BikePredictionService.instance.predict(
        stationUID: widget.stationUID,
        targetTime: _targetTime(),
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _data = result;
        _loading = false;
        if (result == null) _error = '查無預測資料';
      });
    } catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = '預測暫時無法取得';
        debugPrint('BikePredictionCard error: $e');
      });
    }
  }

  /// 把選中 chip 滾到畫面內
  void _scrollToSelected({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final index = kPredictionSchedule.indexOf(_selectedTime);
    if (index < 0) return;

    // chip 約 66 寬 + 8 gap，抓 -40 讓它靠左一點
    const chipWidth = 66.0;
    const gap = 8.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (index * (chipWidth + gap) - 40)
        .clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  // ──────────── Build ────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: colors.info),
              const SizedBox(width: 8),
              Text(
                '到站預測',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!_loading && _data != null)
                _buildConfidenceChip(colors, _data!.confidence),
            ],
          ),
          const SizedBox(height: 12),

          // 時段 chips（可橫滑）
          _buildTimeChips(colors),
          const SizedBox(height: 14),

          // 內容
          if (_loading)
            _buildLoading(colors)
          else if (_error != null)
            _buildError(colors)
          else if (_data != null)
              _buildBody(colors, _data!),
        ],
      ),
    );
  }

  // ──────────── 時段 chips ────────────

  Widget _buildTimeChips(AppColors colors) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: kPredictionSchedule.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = kPredictionSchedule[i];
          final selected = _selectedTime == t;
          final past = _isPast(t);

          return GestureDetector(
            onTap: () {
              if (selected) return;
              setState(() => _selectedTime = t);
              _scrollToSelected();
              _fetch();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? colors.info.withValues(alpha: 0.15)
                    : colors.mutedBackground,
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: selected
                      ? colors.info.withValues(alpha: 0.5)
                      : (past ? colors.border : Colors.transparent),
                ),
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? colors.info
                      : past
                      ? colors.textHint
                      : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ──────────── 主體 ────────────

  Widget _buildBody(AppColors colors, BikePrediction p) {
    final vals = p.prediction;
    final riskColor = _riskColor(colors, p.risk.level);

    // 標題列的時段說明（含「明天」提示）
    final isTomorrow = _isPast(_selectedTime);
    final timeLabel = isTomorrow
        ? '${_selectedTime}（明天 ${p.target.weekday}）'
        : '${_selectedTime}（${p.target.weekday}）';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 當前選定時間
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: colors.textHint),
            const SizedBox(width: 4),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 12,
                color: colors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 可借 / 可還
        Row(
          children: [
            Expanded(
              child: _buildStat(
                colors,
                icon: Icons.pedal_bike,
                color: colors.success,
                label: '可借（預測）',
                value: vals.availableRentBikes,
                range: vals.rentCIRange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStat(
                colors,
                icon: Icons.local_parking,
                color: colors.info,
                label: '可還（預測）',
                value: vals.availableReturnBikes,
                range: vals.returnCIRange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 車種預測
        Row(
          children: [
            Icon(Icons.pedal_bike, size: 14, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '一般車 ${vals.generalBikes}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(width: 14),
            Icon(Icons.electric_bike, size: 14, color: colors.info),
            const SizedBox(width: 4),
            Text(
              '電動車 ${vals.electricBikes}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 風險
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.08),
            borderRadius: AppRadius.roundedSm,
            border: Border.all(color: riskColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_riskIcon(p.risk.level), size: 16, color: riskColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.risk.alerts.join('・'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: riskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 樣本說明
        if (p.diagnostics.sampleCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '依同${p.target.weekday} ±${p.diagnostics.windowMinutes} 分鐘、共 ${p.diagnostics.sampleCount} 筆歷史樣本',
            style: TextStyle(fontSize: 11, color: colors.textHint),
          ),
        ],
      ],
    );
  }

  // ──────────── 小元件 ────────────

  Widget _buildStat(
      AppColors colors, {
        required IconData icon,
        required Color color,
        required String label,
        required int value,
        required List<int> range,
      }) {
    final rangeText = (range.length == 2) ? '${range[0]}~${range[1]}' : '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (rangeText.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '($rangeText)',
                    style: TextStyle(fontSize: 11.5, color: colors.textHint),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(AppColors colors, PredictionConfidence c) {
    final color = switch (c.level) {
      'high' => colors.success,
      'medium' => colors.info,
      _ => colors.warning ?? colors.textHint,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '信心 ${c.label}・${c.sampleCount} 樣本',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoading(AppColors colors) {
    return const SizedBox(
      height: 100,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _buildError(AppColors colors) {
    return SizedBox(
      height: 90,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? '預測暫時無法取得',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetch,
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(AppColors colors, String level) => switch (level) {
    'high' => colors.danger ?? Colors.red,
    'medium' => colors.warning ?? Colors.orange,
    _ => colors.success,
  };

  IconData _riskIcon(String level) => switch (level) {
    'high' => Icons.error_outline,
    'medium' => Icons.warning_amber_rounded,
    _ => Icons.check_circle_outline,
  };
}