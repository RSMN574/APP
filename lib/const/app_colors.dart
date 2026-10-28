import 'package:flutter/material.dart';

/// 隨淺色／深色主題變化的語意色彩，由 [AppThemes] 註冊為 ThemeExtension。
/// 交通路線色、品牌識別色、地圖標記色等具固定語意的顏色不放在此處。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.cardBackground,
    required this.mutedBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.scrim,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
  });

  final Color cardBackground;
  final Color mutedBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color shadow;
  final Color scrim;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;

  static const AppColors light = AppColors(
    cardBackground: Color(0xFFFFFFFF),
    mutedBackground: Color(0xFFEEF3FB),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF5F6368),
    textHint: Color(0xFF80868B),
    border: Color(0xFFDADCE0),
    divider: Color(0xFFE8EAED),
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    success: Color(0xFF2E7D32),
    successContainer: Color(0xFFE8F5E9),
    warning: Color(0xFFED6C02),
    warningContainer: Color(0xFFFFF4E5),
    danger: Color(0xFFD32F2F),
    dangerContainer: Color(0xFFFDECEA),
    info: Color(0xFF1A73E8),
    infoContainer: Color(0xFFE8F0FE),
  );

  static const AppColors dark = AppColors(
    cardBackground: Color(0xFF1C1C1E),
    mutedBackground: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFAEAEB2),
    textHint: Color(0xFF8E8E93),
    border: Color(0xFF3A3A3C),
    divider: Color(0xFF38383A),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1B3A24),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF3D2E14),
    danger: Color(0xFFEF9A9A),
    dangerContainer: Color(0xFF3F1D1D),
    info: Color(0xFF64B5F6),
    infoContainer: Color(0xFF14283F),
  );

  @override
  AppColors copyWith({
    Color? cardBackground,
    Color? mutedBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? shadow,
    Color? scrim,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return AppColors(
      cardBackground: cardBackground ?? this.cardBackground,
      mutedBackground: mutedBackground ?? this.mutedBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      mutedBackground: Color.lerp(mutedBackground, other.mutedBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light);
}
