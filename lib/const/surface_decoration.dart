import 'package:flutter/material.dart';


import 'app_colors.dart';

/// 全 App 統一的「外框」樣式。
///
/// 所有卡片、Dialog、按鈕、Tab 容器、AppBar leading 容器
/// 都應使用這裡的 helper，避免各頁寫死顏色。
class SurfaceDecoration {
  SurfaceDecoration._();
// 在 surface_decoration.dart 新增
  /// 卡片：Surface 底 + 陰影（無邊框）。
  static BoxDecoration cardShadow(BuildContext context, {double radius = 12}) {
    final c = context.appColors;
    return BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: c.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  /// 一般卡片：Surface 底 + Border 邊框 + 輕陰影。
  static BoxDecoration card(BuildContext context, {double radius = 12}) {
    final c = context.appColors;
    return BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: c.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 頁面 / Dialog 主容器：Surface 底 + 較大圓角 + 較強陰影（無邊框）。
  static BoxDecoration dialog(BuildContext context, {double radius = 20}) {
    final c = context.appColors;
    return BoxDecoration(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: c.shadow,
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// 圖示底 / 內嵌區塊 / hover 底：Muted 底 + 小圓角（無邊框）。
  static BoxDecoration muted(BuildContext context, {double radius = 10}) {
    final c = context.appColors;
    return BoxDecoration(
      color: c.mutedBackground,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// 外框按鈕（未選中 / 次要按鈕）：透明底 + Border 邊框。
  static BoxDecoration outlined(
      BuildContext context, {
        double radius = 12,
        Color? borderColor,
        double width = 1,
      }) {
    final c = context.appColors;
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? c.border, width: width),
    );
  }

  /// 外框按鈕（選中 / 主要）：Muted 底 + Primary 邊框。
  static BoxDecoration selected(
      BuildContext context, {
        double radius = 12,
      }) {
    final c = context.appColors;
    return BoxDecoration(
      color: c.mutedBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.info.withOpacity(0.3), width: 1.5),
    );
  }

  /// AppBar leading / actions 圓角容器底。
  static BoxDecoration appBarSlot(BuildContext context, {double radius = 12}) {
    final c = context.appColors;
    return BoxDecoration(
      color: c.mutedBackground,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// 分隔線。
  static Divider divider(BuildContext context, {double height = 9}) {
    return Divider(
      color: context.appColors.divider,
      height: height,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}