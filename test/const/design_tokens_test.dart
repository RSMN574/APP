import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/app_design_tokens.dart';
import 'package:com.rsmn574.app/const/arrival_status_colors.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('textTheme is generated from AppTypography (no conflicting sizes)', () {
    for (final theme in [AppThemes.lightTheme, AppThemes.darkTheme]) {
      final t = theme.textTheme;
      expect(t.bodyLarge!.fontSize, AppTypography.bodyLarge);
      expect(t.bodyMedium!.fontSize, AppTypography.bodyMedium);
      expect(t.bodySmall!.fontSize, AppTypography.bodySmall);
      expect(t.titleLarge!.fontSize, AppTypography.titleLarge);
      expect(t.titleMedium!.fontSize, AppTypography.titleMedium);
      expect(t.labelLarge!.fontSize, AppTypography.labelLarge);
      expect(t.bodyMedium!.color, theme.colorScheme.onSurface);
    }
  });

  test('secondary and tertiary use the design system values', () {
    expect(AppThemes.lightTheme.colorScheme.secondary, const Color(0xFF5B6B85));
    expect(AppThemes.lightTheme.colorScheme.tertiary, const Color(0xFF00796B));
    expect(AppThemes.darkTheme.colorScheme.tertiary, const Color(0xFF4DB6AC));
  });

  test('small-text tokens reach WCAG AA on cards', () {
    for (final c in [AppColors.light, AppColors.dark]) {
      expect(_contrast(c.primaryText, c.cardBackground), greaterThan(4.5));
      expect(_contrast(c.warningText, c.cardBackground), greaterThan(4.5));
      expect(_contrast(c.textHint, c.cardBackground), greaterThan(4.5));
    }
  });

  test('arrival status colors are registered and readable in both modes', () {
    for (final theme in [AppThemes.lightTheme, AppThemes.darkTheme]) {
      final a = theme.extension<ArrivalStatusColors>()!;
      final bg = theme.extension<AppColors>()!.cardBackground;
      expect(_contrast(a.arrivingForeground, a.arrivingBackground),
          greaterThan(4.5));
      expect(_contrast(a.approachingForeground, a.approachingBackground),
          greaterThan(4.5));
      expect(_contrast(a.minutesForeground, a.minutesBackground),
          greaterThan(4.5));
      expect(_contrast(a.abnormalForeground, a.abnormalBackground),
          greaterThan(4.5));
      expect(_contrast(a.idleForeground, a.idleBackground), greaterThan(4.5));
      expect(_contrast(a.highlight, bg), greaterThan(4.5));
    }
  });
}
