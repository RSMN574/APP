import 'package:flutter/material.dart';

/// 交通到站狀態的語意色（docs/design_system.md §2.4）。
///
/// 取代先前散落在公車頁面中的 `Color.fromRGBO(235, 15, 41, …)` 等寫死值。
/// 即時資料使用填滿底色；固定班表只用外框（[scheduledBorder]）。
@immutable
class ArrivalStatusColors extends ThemeExtension<ArrivalStatusColors> {
  const ArrivalStatusColors({
    required this.arrivingBackground,
    required this.arrivingForeground,
    required this.approachingBackground,
    required this.approachingForeground,
    required this.minutesBackground,
    required this.minutesForeground,
    required this.idleBackground,
    required this.idleForeground,
    required this.endedForeground,
    required this.abnormalBackground,
    required this.abnormalForeground,
    required this.scheduledBorder,
    required this.highlight,
  });

  /// 即將進站（實心）。
  final Color arrivingBackground;
  final Color arrivingForeground;

  /// 2–3 分鐘內。
  final Color approachingBackground;
  final Color approachingForeground;

  /// N 分鐘。
  final Color minutesBackground;
  final Color minutesForeground;

  /// 尚未發車 / 預定時間 / 班次結束共用的淡底。
  final Color idleBackground;
  final Color idleForeground;
  final Color endedForeground;

  /// 交管不停靠、異常。
  final Color abnormalBackground;
  final Color abnormalForeground;

  /// 固定班表外框。
  final Color scheduledBorder;

  /// 目前所在 / 高亮站名。
  final Color highlight;

  static const light = ArrivalStatusColors(
    arrivingBackground: Color(0xFFD32F2F),
    arrivingForeground: Color(0xFFFFFFFF),
    approachingBackground: Color(0xFFFDECEA),
    approachingForeground: Color(0xFFC62828),
    minutesBackground: Color(0xFFE8F0FE),
    minutesForeground: Color(0xFF1765CC),
    idleBackground: Color(0xFFEEF3FB),
    idleForeground: Color(0xFF5F6368),
    endedForeground: Color(0xFF6B7075),
    abnormalBackground: Color(0xFFFFF4E5),
    abnormalForeground: Color(0xFFA84A00),
    scheduledBorder: Color(0xFFDADCE0),
    highlight: Color(0xFF1765CC),
  );

  static const dark = ArrivalStatusColors(
    arrivingBackground: Color(0xFFEF9A9A),
    arrivingForeground: Color(0xFF3F1D1D),
    approachingBackground: Color(0xFF3F1D1D),
    approachingForeground: Color(0xFFEF9A9A),
    minutesBackground: Color(0xFF14283F),
    minutesForeground: Color(0xFF90CAF9),
    idleBackground: Color(0xFF2C2C2E),
    idleForeground: Color(0xFFAEAEB2),
    endedForeground: Color(0xFF8E8E93),
    abnormalBackground: Color(0xFF3D2E14),
    abnormalForeground: Color(0xFFFFB74D),
    scheduledBorder: Color(0xFF3A3A3C),
    highlight: Color(0xFF90CAF9),
  );

  @override
  ArrivalStatusColors copyWith({
    Color? arrivingBackground,
    Color? arrivingForeground,
    Color? approachingBackground,
    Color? approachingForeground,
    Color? minutesBackground,
    Color? minutesForeground,
    Color? idleBackground,
    Color? idleForeground,
    Color? endedForeground,
    Color? abnormalBackground,
    Color? abnormalForeground,
    Color? scheduledBorder,
    Color? highlight,
  }) {
    return ArrivalStatusColors(
      arrivingBackground: arrivingBackground ?? this.arrivingBackground,
      arrivingForeground: arrivingForeground ?? this.arrivingForeground,
      approachingBackground:
          approachingBackground ?? this.approachingBackground,
      approachingForeground:
          approachingForeground ?? this.approachingForeground,
      minutesBackground: minutesBackground ?? this.minutesBackground,
      minutesForeground: minutesForeground ?? this.minutesForeground,
      idleBackground: idleBackground ?? this.idleBackground,
      idleForeground: idleForeground ?? this.idleForeground,
      endedForeground: endedForeground ?? this.endedForeground,
      abnormalBackground: abnormalBackground ?? this.abnormalBackground,
      abnormalForeground: abnormalForeground ?? this.abnormalForeground,
      scheduledBorder: scheduledBorder ?? this.scheduledBorder,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  ArrivalStatusColors lerp(
      ThemeExtension<ArrivalStatusColors>? other, double t) {
    if (other is! ArrivalStatusColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ArrivalStatusColors(
      arrivingBackground: l(arrivingBackground, other.arrivingBackground),
      arrivingForeground: l(arrivingForeground, other.arrivingForeground),
      approachingBackground:
          l(approachingBackground, other.approachingBackground),
      approachingForeground:
          l(approachingForeground, other.approachingForeground),
      minutesBackground: l(minutesBackground, other.minutesBackground),
      minutesForeground: l(minutesForeground, other.minutesForeground),
      idleBackground: l(idleBackground, other.idleBackground),
      idleForeground: l(idleForeground, other.idleForeground),
      endedForeground: l(endedForeground, other.endedForeground),
      abnormalBackground: l(abnormalBackground, other.abnormalBackground),
      abnormalForeground: l(abnormalForeground, other.abnormalForeground),
      scheduledBorder: l(scheduledBorder, other.scheduledBorder),
      highlight: l(highlight, other.highlight),
    );
  }
}

extension ArrivalStatusColorsContext on BuildContext {
  ArrivalStatusColors get arrivalColors =>
      Theme.of(this).extension<ArrivalStatusColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? ArrivalStatusColors.dark
          : ArrivalStatusColors.light);
}
