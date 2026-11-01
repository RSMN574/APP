import 'package:intl/intl.dart';

/// TRA / THSR 共用的日期工具（TDX API 皆使用 yyyy-MM-dd）。
class RailwayDateUtils {
  const RailwayDateUtils._();

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// 轉為 TDX API 使用的日期字串（yyyy-MM-dd）。
  static String formatApiDate(DateTime date) => _apiDate.format(date);

  /// 是否為同一天（忽略時間）。
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 是否落在 [center] 前後 [minutes] 分鐘內。
  static bool isWithinMinutes(
    DateTime target, {
    DateTime? center,
    int minutes = 30,
  }) {
    final now = center ?? DateTime.now();
    return target.isAfter(now.subtract(Duration(minutes: minutes))) &&
        target.isBefore(now.add(Duration(minutes: minutes)));
  }
}
