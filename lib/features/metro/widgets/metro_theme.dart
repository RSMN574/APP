import 'package:flutter/material.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';

/// 捷運頁面的樣式入口。全部沿用 Bus 頁使用的 Token（AppThemes、context.appColors），
/// 之後若 Token 位置或名稱調整，只需要改這一個檔案。
class MetroTheme {
  const MetroTheme._();

  static Color surface(BuildContext c) => AppThemes.getSurface(c);
  static Color? card(BuildContext c) => AppThemes.getCardColor(c);
  static Color onSurface(BuildContext c) => AppThemes.getOnSurface(c);
  static Color muted(BuildContext c) => c.appColors.mutedBackground;

  /// Bus 頁的卡片樣式：surface 底色、圓角、淡陰影。
  static BoxDecoration cardDecoration(BuildContext c, {double radius = 16, double shadow = 0.06}) {
    return BoxDecoration(
      color: surface(c),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Theme.of(c).colorScheme.shadow.withValues(alpha: shadow),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
