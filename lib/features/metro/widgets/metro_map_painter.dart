import 'dart:math';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';  // 用于 shouldRepaint 里的 SetEquality

import '../../../const/regular_const.dart';
import '../data/metro_repository.dart';

class MetroMapPainter extends CustomPainter {
  final CityMetroData cityData;
  final Station? startStation;
  final Station? endStation;
  final RouteResult? routeResult;
  final double animationValue;
  final Offset mapOrigin;
  final Set<String> visibleStationIds;
  final Color backgroundColor;
  final Color gridColor;
  final Color stationLabelColor;

  // ── 预建索引，避免 paint 里线性查找 ──
  final Map<String, Station> _stationById;
  final Map<String, MetroLine> _lineById;

  MetroMapPainter({
    required this.cityData,
    this.startStation,
    this.endStation,
    this.routeResult,
    required this.animationValue,
    required this.mapOrigin,
    required this.visibleStationIds,
    required this.backgroundColor,
    required this.gridColor,
    required this.stationLabelColor,
  })  : _stationById = {for (final s in cityData.stations) s.id: s},
        _lineById = {for (final l in cityData.lines) l.id: l};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(backgroundColor, BlendMode.src);

    // 微弱背景網格
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 1. 繪製預設捷運路線軌跡
    for (final edge in cityData.edges) {
      // ── 用 Map 查，查不到返回 null，不抛异常 ──
      final stationA = _stationById[edge.stationA];
      final stationB = _stationById[edge.stationB];
      final line = _lineById[edge.lineId];

      if (stationA == null || stationB == null || line == null) {
        // 数据不完整，跳过这条边（开发期可加 debugPrint 定位）
        assert(() {
          debugPrint('⚠️ edge 数据不匹配: '
              'A=${edge.stationA}(${stationA != null}), '
              'B=${edge.stationB}(${stationB != null}), '
              'line=${edge.lineId}(${line != null})');
          return true;
        }());
        continue;
      }

      final linePaint = Paint()
        ..color =
        line.color.withValues(alpha: routeResult != null ? 0.25 : 0.85)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        stationA.position - mapOrigin,
        stationB.position - mapOrigin,
        linePaint,
      );
    }

    // 2. 繪製計算後的高亮動態發光路線
    if (routeResult != null && routeResult!.path.length > 1) {
      final path = routeResult!.path;
      final routePath = Path();
      final firstPosition = path.first.position - mapOrigin;
      routePath.moveTo(firstPosition.dx, firstPosition.dy);

      for (int i = 1; i < path.length; i++) {
        final position = path[i].position - mapOrigin;
        routePath.lineTo(position.dx, position.dy);
      }

      final glowPaint = Paint()
        ..color = primary.withValues(
          alpha: 0.3 + 0.2 * sin(animationValue * pi * 2),
        )
        ..strokeWidth = 12.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final corePathPaint = Paint()
        ..color = primary
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(routePath, glowPaint);
      canvas.drawPath(routePath, corePathPaint);
    }

    // 3. 繪製站名文字標籤
    for (final station in cityData.stations) {
      if (!visibleStationIds.contains(station.id)) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: station.name,
          style: TextStyle(
            color: stationLabelColor,
            fontSize: 12,
            fontWeight:
            station.isTransfer ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          station.position.dx - mapOrigin.dx - textPainter.width / 2,
          station.position.dy - mapOrigin.dy + 14,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MetroMapPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.routeResult != routeResult ||
        oldDelegate.startStation != startStation ||
        oldDelegate.endStation != endStation ||
        oldDelegate.cityData != cityData ||
        oldDelegate.mapOrigin != mapOrigin ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.stationLabelColor != stationLabelColor ||
        // Set 用常量时间比较，避免每次都重绘
        !const SetEquality<String>().equals(
          oldDelegate.visibleStationIds,
          visibleStationIds,
        );
  }
}