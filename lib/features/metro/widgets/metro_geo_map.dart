import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../domain/metro_route_planner.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_station_sheet.dart';
import 'metro_ui_utils.dart';

/// 以真實經緯度繪製路線圖。
///  - 座標順序：後端 Shape 為 [經度, 緯度]，LineShape 已轉成 (lat, lon)；投影為等距圓柱（x = 經度×cos(緯度中心)）。
///  - 有 Shape 的路線逐段繪製（各段不一定相連，所以不串成同一條線）。
///  - Shape 載入中或失敗時，改以「資料中的相鄰站關係」連接車站座標，並明確提示，不偽造幾何。
///  - 車站不用 Widget 逐一建立，單一 CustomPainter 繪製，點擊以最近點命中。
class MetroGeoMap extends StatefulWidget {
  const MetroGeoMap({super.key});
  @override
  State<MetroGeoMap> createState() => _MetroGeoMapState();
}

class _MetroGeoMapState extends State<MetroGeoMap> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TransformationController _tc = TransformationController();
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  final _LabelCache _labels = _LabelCache();

  _MapLayout? _layout;
  Object? _layoutKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tc.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _syncGlow(bool active) {
    if (active && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!active && _glow.isAnimating) {
      _glow.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<MetroProvider>();
    final catalog = p.catalog;
    final code = p.selectedSystemCode;
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = metroLocale(context);
    if (catalog == null || code == null) return const SizedBox.shrink();

    final sysStations = catalog.stations.where((st) => st.operator == code && st.hasPosition).toList(growable: false);
    if (sysStations.isEmpty) return MetroEmptyView(message: s.stationsNoPosition, icon: Icons.map_outlined);

    final shapesState = p.shapesOf(code);
    final plan = p.plan;
    _syncGlow(plan != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final key = Object.hash(identityHashCode(catalog), code, identityHashCode(shapesState.shapes), shapesState.state, size);
        if (_layoutKey != key) {
          _layoutKey = key;
          _layout = _MapLayout.build(
            catalog: catalog,
            operatorCode: code,
            stations: sysStations,
            shapes: shapesState.state == MetroAsyncState.ready ? shapesState.shapes : const [],
            size: size,
          );
          _labels.clear();
        }
        final layout = _layout!;
        _labels.configure(locale: locale, color: cs.onSurface);

        final routePath = _routePath(plan, layout);
        final showGeometryNotice = shapesState.state == MetroAsyncState.loading || shapesState.state == MetroAsyncState.error;

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _tc,
              minScale: 0.8,
              maxScale: 8,
              boundaryMargin: const EdgeInsets.all(80),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _handleTap(d.localPosition, layout, p, catalog),
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: size,
                    painter: _MetroMapPainter(
                      layout: layout,
                      catalog: catalog,
                      visibleUids: p.visibleStations.map((e) => e.uid).toSet(),
                      filtering: p.query.isNotEmpty || p.selectedLineUid != null,
                      selectedLineUid: p.selectedLineUid,
                      startUid: p.startStation?.uid,
                      endUid: p.endStation?.uid,
                      routeUids: plan?.stationUids.toSet(),
                      routePath: routePath,
                      transformation: _tc,
                      glow: _glow,
                      labels: _labels,
                      surface: cs.surface,
                      outline: cs.onSurfaceVariant,
                      primary: cs.primary,
                      startColor: cs.tertiary,
                      endColor: cs.error,
                    ),
                  ),
                ),
              ),
            ),
            if (showGeometryNotice)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MetroNoticeBar(
                  icon: shapesState.state == MetroAsyncState.loading ? Icons.hourglass_empty_rounded : Icons.warning_amber_rounded,
                  message: shapesState.state == MetroAsyncState.loading ? s.geometryLoading : s.geometryFallback,
                  actionLabel: shapesState.state == MetroAsyncState.error ? s.retry : null,
                  onAction: shapesState.state == MetroAsyncState.error ? () => p.ensureShapes(code, retry: true) : null,
                ),
              ),
            Positioned(
              right: 12,
              top: 8,
              child: IconButton.filledTonal(
                tooltip: s.resetView,
                icon: const Icon(Icons.center_focus_strong),
                onPressed: () => _tc.value = Matrix4.identity(),
              ),
            ),
          ],
        );
      },
    );
  }

  Path? _routePath(RoutePlan? plan, _MapLayout layout) {
    if (plan == null) return null;
    final path = Path();
    var started = false;
    for (final uid in plan.stationUids) {
      final o = layout.stationPos[uid];
      if (o == null) {
        started = false; // 其他系統的站不在這張圖上，路徑在此中斷
        continue;
      }
      if (!started) {
        path.moveTo(o.dx, o.dy);
        started = true;
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    return path;
  }

  void _handleTap(Offset local, _MapLayout layout, MetroProvider p, MetroCatalog catalog) {
    final scale = _tc.value.getMaxScaleOnAxis();
    final radius = 24 / scale; // 以螢幕像素計的點擊容許距離
    final visible = p.visibleStations.map((e) => e.uid).toSet();
    String? best;
    var bestD = radius;
    layout.stationPos.forEach((uid, o) {
      if (!visible.contains(uid)) return;
      final d = (o - local).distance;
      if (d < bestD) {
        bestD = d;
        best = uid;
      }
    });
    if (best != null) showMetroStationSheet(context, best!);
  }
}

// ---------------------------------------------------------------------------
// 版面：投影與路徑，僅在資料或尺寸改變時重算
// ---------------------------------------------------------------------------

class _MapLayout {
  _MapLayout(this.stationPos, this.linePaths, this.lineColors);
  final Map<String, Offset> stationPos;
  final Map<String, Path> linePaths;
  final Map<String, Color> lineColors;

  static _MapLayout build({
    required MetroCatalog catalog,
    required String operatorCode,
    required List<MetroStation> stations,
    required List<LineShape> shapes,
    required Size size,
  }) {
    final lines = catalog.lines.where((l) => l.operator == operatorCode).toList(growable: false);
    final shapeByLine = {for (final s in shapes) s.lineUid: s};

    // 範圍：車站 + Shape 頂點
    var minLat = double.infinity, maxLat = -double.infinity, minLon = double.infinity, maxLon = -double.infinity;
    void include(double lat, double lon) {
      minLat = math.min(minLat, lat);
      maxLat = math.max(maxLat, lat);
      minLon = math.min(minLon, lon);
      maxLon = math.max(maxLon, lon);
    }

    for (final s in stations) {
      include(s.lat!, s.lon!);
    }
    for (final l in lines) {
      final sh = shapeByLine[l.uid];
      if (sh == null) continue;
      for (final seg in sh.segments) {
        for (final pt in seg) {
          include(pt.lat, pt.lon);
        }
      }
    }

    const pad = 36.0;
    final kx = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final wDeg = math.max((maxLon - minLon) * kx, 1e-6);
    final hDeg = math.max(maxLat - minLat, 1e-6);
    final scale = math.max(1.0, math.min((size.width - 2 * pad) / wDeg, (size.height - 2 * pad) / hDeg));
    final ox = (size.width - wDeg * scale) / 2;
    final oy = (size.height - hDeg * scale) / 2;
    Offset project(double lat, double lon) => Offset(ox + (lon - minLon) * kx * scale, oy + (maxLat - lat) * scale);

    final pos = {for (final s in stations) s.uid: project(s.lat!, s.lon!)};
    final paths = <String, Path>{};
    final colors = <String, Color>{};
    for (final l in lines) {
      colors[l.uid] = metroLineColor(l);
      final sh = shapeByLine[l.uid];
      final path = Path();
      if (sh != null && sh.segments.isNotEmpty) {
        for (final seg in sh.segments) {
          final first = project(seg.first.lat, seg.first.lon);
          path.moveTo(first.dx, first.dy);
          for (var i = 1; i < seg.length; i++) {
            final o = project(seg[i].lat, seg[i].lon);
            path.lineTo(o.dx, o.dy);
          }
        }
      } else {
        // 後備：用資料中的相鄰站關係連線（真實座標，但不是真實軌道幾何）
        for (final e in l.edges) {
          final a = pos[e[0]], b = pos[e[1]];
          if (a == null || b == null) continue;
          path.moveTo(a.dx, a.dy);
          path.lineTo(b.dx, b.dy);
        }
      }
      paths[l.uid] = path;
    }
    return _MapLayout(pos, paths, colors);
  }
}

class _LabelCache {
  final Map<String, TextPainter> _m = {};
  Locale? _locale;
  Color? _color;

  void configure({required Locale locale, required Color color}) {
    if (_locale != locale || _color != color) {
      _locale = locale;
      _color = color;
      _m.clear();
    }
  }

  void clear() => _m.clear();

  TextPainter get(MetroStation s) {
    return _m.putIfAbsent(s.uid, () {
      final tp = TextPainter(
        text: TextSpan(text: s.name.resolve(_locale ?? const Locale('zh')), style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      return tp;
    });
  }
}

// ---------------------------------------------------------------------------
// 繪製
// ---------------------------------------------------------------------------

class _MetroMapPainter extends CustomPainter {
  _MetroMapPainter({
    required this.layout,
    required this.catalog,
    required this.visibleUids,
    required this.filtering,
    required this.selectedLineUid,
    required this.startUid,
    required this.endUid,
    required this.routeUids,
    required this.routePath,
    required this.transformation,
    required this.glow,
    required this.labels,
    required this.surface,
    required this.outline,
    required this.primary,
    required this.startColor,
    required this.endColor,
  }) : super(repaint: Listenable.merge([transformation, glow]));

  final _MapLayout layout;
  final MetroCatalog catalog;
  final Set<String> visibleUids;
  final bool filtering;
  final String? selectedLineUid;
  final String? startUid;
  final String? endUid;
  final Set<String>? routeUids;
  final Path? routePath;
  final TransformationController transformation;
  final Animation<double> glow;
  final _LabelCache labels;
  final Color surface;
  final Color outline;
  final Color primary;
  final Color startColor;
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    final zoom = transformation.value.getMaxScaleOnAxis();
    final hasRoute = routePath != null;

    // 路線
    layout.linePaths.forEach((uid, path) {
      final dim = hasRoute || (selectedLineUid != null && selectedLineUid != uid);
      final paint = Paint()
        ..color = (layout.lineColors[uid] ?? primary).withValues(alpha: dim ? 0.25 : 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 / math.sqrt(zoom)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    });

    // 規劃路徑（發光）
    if (routePath != null) {
      canvas.drawPath(
        routePath!,
        Paint()
          ..color = primary.withValues(alpha: 0.25 + 0.25 * glow.value)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12 / math.sqrt(zoom)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        routePath!,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 / math.sqrt(zoom)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 車站
    final labelAt = zoom >= 2.2;
    layout.stationPos.forEach((uid, o) {
      final isStart = uid == startUid, isEnd = uid == endUid;
      final inRoute = routeUids?.contains(uid) ?? false;
      final matched = !filtering || visibleUids.contains(uid);
      final station = catalog.stationByUid[uid];
      final interchange = (station?.lineUids.length ?? 0) > 1 || catalog.linksOf(uid).isNotEmpty;

      final base = (interchange ? 5.0 : 3.5) / math.sqrt(zoom);
      final r = (isStart || isEnd) ? base * 1.8 : base;
      final fill = isStart ? startColor : (isEnd ? endColor : (inRoute ? primary : surface));
      final alpha = matched ? 1.0 : 0.25;
      canvas.drawCircle(o, r, Paint()..color = fill.withValues(alpha: alpha));
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (interchange ? 2.0 : 1.4) / math.sqrt(zoom)
          ..color = (isStart || isEnd || inRoute ? primary : outline).withValues(alpha: alpha),
      );

      final emphasized = isStart || isEnd || inRoute || (filtering && matched);
      if (station != null && (labelAt || emphasized) && matched) {
        final tp = labels.get(station);
        canvas.save();
        canvas.translate(o.dx - tp.width / (2 * zoom), o.dy + r + 2 / zoom);
        canvas.scale(1 / zoom);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      }
    });
  }

  @override
  bool shouldRepaint(covariant _MetroMapPainter old) =>
      old.layout != layout ||
      old.catalog != catalog ||
      old.filtering != filtering ||
      old.selectedLineUid != selectedLineUid ||
      old.startUid != startUid ||
      old.endUid != endUid ||
      old.routePath != routePath ||
      old.surface != surface ||
      old.outline != outline ||
      old.primary != primary ||
      !_sameSet(old.visibleUids, visibleUids) ||
      !_sameSet(old.routeUids, routeUids);

  static bool _sameSet(Set<String>? a, Set<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    return a.containsAll(b);
  }
}
