import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _lum(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('dark theme uses an OLED-friendly background with layered surfaces', () {
    final theme = AppThemes.darkTheme;
    final scheme = theme.colorScheme;
    final colors = theme.extension<AppColors>()!;
    expect(scheme.primary, const Color(0xFF64B5F6));
    expect(_lum(theme.scaffoldBackgroundColor), lessThan(0.005));
    // 背景 < 卡片 < Dialog/BottomSheet < 最高層
    expect(_lum(theme.scaffoldBackgroundColor),
        lessThan(_lum(colors.cardBackground)));
    expect(_lum(colors.cardBackground),
        lessThanOrEqualTo(_lum(scheme.surfaceContainer)));
    expect(_lum(scheme.surfaceContainer),
        lessThan(_lum(scheme.surfaceContainerHighest)));
    expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainer);
    expect(theme.bottomSheetTheme.backgroundColor, scheme.surfaceContainer);
  });

  test('text and primary keep WCAG AA contrast in both modes', () {
    for (final theme in [AppThemes.lightTheme, AppThemes.darkTheme]) {
      final s = theme.colorScheme;
      expect(_contrast(s.onSurface, theme.scaffoldBackgroundColor),
          greaterThan(7));
      expect(_contrast(s.onPrimary, s.primary), greaterThan(4.5));
      expect(
          _contrast(s.primary, theme.scaffoldBackgroundColor), greaterThan(3));
    }
  });
}
