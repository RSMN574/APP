import 'package:flutter/material.dart';

import '../data/models/metro_models.dart';

// 後端沒有提供色碼的路線使用的後備色（只做辨識用，不代表官方線色）。
const List<Color> _fallbackPalette = [
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
];

Color metroLineColor(MetroLine? line) {
  if (line == null) return _fallbackPalette.first;
  final argb = line.colorArgb;
  if (argb != null) return Color(argb);
  final h = line.uid.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
  return _fallbackPalette[h % _fallbackPalette.length];
}

Locale metroLocale(BuildContext context) => Localizations.localeOf(context);

/// 標籤樣式：沿用既有頁面的規格（圓角 20、背景 10%、邊框 30%）。
class MetroTag extends StatelessWidget {
  const MetroTag({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
