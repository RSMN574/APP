import 'package:flutter/material.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';

/// 座位狀態徽章。
///
/// [hasSeat]：
/// - `true`  → 有座位（成功綠）
/// - `false` → 無座位（錯誤紅）
/// - `null`  → 未知（灰）
class SeatStatusBadge extends StatelessWidget {
  const SeatStatusBadge({
    super.key,
    required this.label,
    required this.hasSeat,
    this.isLoading = false,
  });

  final String label;
  final bool? hasSeat;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String text;

    if (isLoading) {
      bg = colors.mutedBackground;
      fg = colors.textSecondary;
      icon = Icons.hourglass_empty_rounded;
      text = '$label ...';
    } else if (hasSeat == true) {
      bg = colors.successContainer;
      fg = colors.success;
      icon = Icons.check_circle_rounded;
      text = label;
    } else if (hasSeat == false) {
      bg = colors.dangerContainer;
      fg = colors.danger;
      icon = Icons.cancel_rounded;
      text = label;
    } else {
      bg = colors.mutedBackground;
      fg = colors.textHint;
      icon = Icons.help_outline_rounded;
      text = label;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}