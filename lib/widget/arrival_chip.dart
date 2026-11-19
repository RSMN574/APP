import 'package:flutter/material.dart';

import '../const/app_design_tokens.dart';
import '../const/arrival_status_colors.dart';
import '../core/transit/arrival_status.dart';

/// 到站時間膠囊（docs/design_system.md §2.4）。
///
/// - 即時資料：填滿底色
/// - 固定班表（[ArrivalStatus.scheduled]）：只有外框 + 時鐘圖示
/// - 異常：加上警示圖示，不只靠顏色傳達狀態
class ArrivalChip extends StatelessWidget {
  const ArrivalChip({
    super.key,
    required this.status,
    required this.label,
    this.semanticsLabel,
  });

  final ArrivalStatus status;
  final String label;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.arrivalColors;
    final (Color bg, Color fg) = switch (status) {
      ArrivalStatus.arriving => (c.arrivingBackground, c.arrivingForeground),
      ArrivalStatus.approaching => (
          c.approachingBackground,
          c.approachingForeground
        ),
      ArrivalStatus.minutes => (c.minutesBackground, c.minutesForeground),
      ArrivalStatus.notDeparted => (c.idleBackground, c.idleForeground),
      ArrivalStatus.ended => (c.idleBackground, c.endedForeground),
      ArrivalStatus.abnormal => (c.abnormalBackground, c.abnormalForeground),
      ArrivalStatus.scheduled => (Colors.transparent, c.idleForeground),
    };
    final IconData? icon = switch (status) {
      ArrivalStatus.scheduled => Icons.schedule_rounded,
      ArrivalStatus.abnormal => Icons.warning_amber_rounded,
      _ => null,
    };

    return Semantics(
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: ShapeDecoration(
          color: bg,
          shape: StadiumBorder(
            side: status == ArrivalStatus.scheduled
                ? BorderSide(color: c.scheduledBorder)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconSm, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              maxLines: 1,
              style: AppTypography.arrivalTimeStyle.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
