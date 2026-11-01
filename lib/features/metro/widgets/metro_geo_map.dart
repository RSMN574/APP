import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_station_sheet.dart';
import 'metro_ui_utils.dart';

/// 縮放範圍。原本最大 8 倍；現在 30 倍，並以「螢幕尺寸隨縮放緩慢成長」的方式繪製點與線，
/// 放大後仍清晰、不會變成巨大的圓點。
const double kMetroMaxZoom = 30;
const double kMetroMinZoom = 0.6;

/// 以真實經緯度繪製路線圖（以「實體站」為單位，轉乘站只畫一個點）。
///  - Shape 座標順序為 [經度, 緯度]，模型已轉成 (lat, lon)；投影為等距圓柱（x = 經度 × cos(緯度中心)）。
///  - Shape 的 MULTILINESTRING 各段不一定相連，逐段繪製。
///  - Shape 載入中或失敗時，改用資料中的相鄰站關係連接車站座標，並明確提示，不偽造軌道幾何。
///  - 世界座標固定（不隨鍵盤或視窗大小改變），只有切換系統才會重置視角。
class MetroGeoMap extends StatefulWidget {
  const MetroGeoMap({super.key, required this.onOpenPlan});

  /// 點擊左上角路徑摘要時切到「路線規劃」分頁。
  final VoidCallback onOpenPlan;

  @override
  State<MetroGeoMap> createState() => _MetroGeoMapState();
}

class _MetroGeoMapState extends State<MetroGeoMap> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TransformationController _tc = TransformationController();
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _cam = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  Matrix4Tween? _camTween;
  final _LabelCache _labels = _LabelCache();

  _MapLayout? _layout;
  Object? _layoutKey;
  String? _layoutCode;
  Size _viewport = Size.zero;
  MetroProvider? _provider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cam.addListener(() {
      final t = _camTween;
      if (t != null) _tc.value = t.transform(Curves.easeOutCubic.transform(_cam.value));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.read<MetroProvider>();
    if (!identical(p, _provider)) {
      _provider?.mapFocus.removeListener(_onFocus);
      _provider = p;
      p.mapFocus.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _provider?.mapFocus.removeListener(_onFocus);
    _tc.dispose();
    _glow.dispose();
    _cam.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // 相機
  // ------------------------------------------------------------------

  double get _zoom => _tc.value.getMaxScaleOnAxis();

  Matrix4 _matrixFor(Offset world, double scale) {
    final s = scale.clamp(kMetroMinZoom, kMetroMaxZoom).toDouble();
    final tx = _viewport.width / 2 - s * world.dx;
    final ty = _viewport.height / 2 - s * world.dy;
    return Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  Matrix4 _fitRect(Rect r, {double pad = 56, double maxScale = 14}) {
    final w = math.max(r.width, 1.0);
    final h = math.max(r.height, 1.0);
    final s = math.min((_viewport.width - 2 * pad) / w, (_viewport.height - 2 * pad) / h);
    return _matrixFor(r.center, math.min(s, maxScale));
  }

  void _animateTo(Matrix4 target) {
    _cam.stop();
    _camTween = Matrix4Tween(begin: _tc.value.clone(), end: target);
    _cam.forward(from: 0);
  }

  Offset _viewportCenterInWorld() {
    final inv = Matrix4.tryInvert(_tc.value);
    final c = Offset(_viewport.width / 2, _viewport.height / 2);
    return inv == null ? c : MatrixUtils.transformPoint(inv, c);
  }

  void _zoomBy(double factor) {
    if (_viewport.isEmpty) return;
    _animateTo(_matrixFor(_viewportCenterInWorld(), _zoom * factor));
  }

  void _fitAll() => _animateTo(Matrix4.identity());

  void _onFocus() {
    final f = _provider?.mapFocus.value;
    final layout = _layout;
    if (f == null || layout == null || _viewport.isEmpty) return;
    final p = _provider!;
    switch (f.kind) {
      case MetroFocusKind.group:
        final o = layout.groupPos[f.id];
        if (o != null) _animateTo(_matrixFor(o, 9));
        break;
      case MetroFocusKind.line:
        final pts = <Offset>[
          for (final g in layout.groups)
            if (g.lineUids.contains(f.id)) layout.groupPos[g.id]!,
        ];
        if (pts.isNotEmpty) _animateTo(_fitRect(_bounds(pts)));
        break;
      case MetroFocusKind.route:
        final pts = <Offset>[
          for (final id in p.planGroupIds)
            if (layout.groupPos[id] != null) layout.groupPos[id]!,
        ];
        if (pts.isNotEmpty) _animateTo(_fitRect(_bounds(pts)));
        break;
    }
  }

  Rect _bounds(List<Offset> pts) {
    var minX = pts.first.dx, maxX = pts.first.dx, minY = pts.first.dy, maxY = pts.first.dy;
    for (final o in pts) {
      minX = math.min(minX, o.dx);
      maxX = math.max(maxX, o.dx);
      minY = math.min(minY, o.dy);
      maxY = math.max(maxY, o.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _syncGlow(bool active) {
    if (active && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!active && _glow.isAnimating) {
      _glow.stop();
    }
  }

  // ------------------------------------------------------------------
  // 點擊：密集區先放大，單一站才開啟詳情
  // ------------------------------------------------------------------

  void _handleTap(Offset local, _MapLayout layout, Set<String>? highlight) {
    final zoom = _zoom;
    final radius = 22 / zoom;
    final hits = <_Cand>[];
    for (final g in layout.groups) {
      if (highlight != null && !highlight.contains(g.id)) continue;
      final d = (layout.groupPos[g.id]! - local).distance;
      if (d <= radius) hits.add(_Cand(g, d));
    }
    if (hits.isEmpty) return;
    hits.sort((a, b) => a.dist.compareTo(b.dist));
    if (hits.length > 1 && zoom < kMetroMaxZoom * 0.5) {
      _animateTo(_matrixFor(local, math.min(zoom * 2.8, kMetroMaxZoom)));
      return;
    }
    showMetroGroupSheet(context, hits.first.group.id);
  }

  // ------------------------------------------------------------------

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

    final hasGroups = catalog.groups.any((g) => g.operator == code && g.hasPosition);
    if (!hasGroups) return MetroEmptyView(message: s.stationsNoPosition, icon: Icons.map_outlined);

    final shapesState = p.shapesOf(code);
    final plan = p.plan;
    _syncGlow(plan != null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _viewport = viewport;

        // 世界座標只在資料或系統改變時重算，不受鍵盤或視窗大小影響
        final key = Object.hash(identityHashCode(catalog), code, identityHashCode(shapesState.shapes), shapesState.state);
        if (_layoutKey != key || _layout == null) {
          final systemChanged = _layoutCode != code;
          _layoutKey = key;
          _layoutCode = code;
          _layout = _MapLayout.build(
            catalog: catalog,
            operatorCode: code,
            shapes: shapesState.state == MetroAsyncState.ready ? shapesState.shapes : const [],
            // 同系統內只因 Shape 載入而重算時沿用原世界大小，避免畫面跳動
            world: (!systemChanged && _layout != null) ? _layout!.world : viewport,
          );
          _labels.clear();
          if (systemChanged) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _tc.value = Matrix4.identity();
            });
          }
        }
        final layout = _layout!;
        _labels.configure(locale: locale, textColor: cs.onSurface, haloColor: cs.surface);

        final highlight = p.highlightGroupIds;
        final planIds = p.planGroupIds;
        final routePath = _routePath(plan == null ? null : plan.stationUids, catalog, layout);
        final geometryNotice = shapesState.state == MetroAsyncState.loading || shapesState.state == MetroAsyncState.error;

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _tc,
              constrained: false,
              minScale: kMetroMinZoom,
              maxScale: kMetroMaxZoom,
              boundaryMargin: EdgeInsets.all(layout.world.longestSide),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _handleTap(d.localPosition, layout, highlight),
                child: SizedBox(
                  width: layout.world.width,
                  height: layout.world.height,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _MetroMapPainter(
                        layout: layout,
                        highlight: highlight,
                        selectedLineUid: p.selectedLineUid,
                        startId: p.startGroup?.id,
                        endId: p.endGroup?.id,
                        planIds: planIds,
                        routePath: routePath,
                        viewport: viewport,
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
            ),
            // 縮放控制
            Positioned(
              right: 12,
              top: 8,
              child: Column(
                children: [
                  IconButton.filledTonal(tooltip: s.zoomIn, icon: const Icon(Icons.add), onPressed: () => _zoomBy(2)),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(tooltip: s.zoomOut, icon: const Icon(Icons.remove), onPressed: () => _zoomBy(0.5)),
                  const SizedBox(height: 6),
                  IconButton.filledTonal(tooltip: s.resetView, icon: const Icon(Icons.center_focus_strong), onPressed: _fitAll),
                ],
              ),
            ),
            // 路徑摘要
            if (p.startGroup != null || p.endGroup != null)
              Positioned(
                left: 12,
                top: 8,
                right: 72,
                child: _PlanChip(onTap: widget.onOpenPlan),
              ),
            if (geometryNotice)
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
          ],
        );
      },
    );
  }

  Path? _routePath(List<String>? stationUids, MetroCatalog catalog, _MapLayout layout) {
    if (stationUids == null) return null;
    final path = Path();
    var started = false;
    String? lastId;
    for (final u in stationUids) {
      final g = catalog.groupOfStation(u);
      final o = g == null ? null : layout.groupPos[g.id];
      if (o == null) {
        started = false; // 其他系統的站不在這張圖上，路徑在此中斷
        lastId = null;
        continue;
      }
      if (g!.id == lastId) continue; // 同一實體站內換線不重複畫
      if (!started) {
        path.moveTo(o.dx, o.dy);
        started = true;
      } else {
        path.lineTo(o.dx, o.dy);
      }
      lastId = g.id;
    }
    return path;
  }
}

class _Cand {
  const _Cand(this.group, this.dist);
  final MetroStationGroup group;
  final double dist;
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MetroProvider>();
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = metroLocale(context);
    final start = p.startGroup?.name.resolve(locale);
    final end = p.endGroup?.name.resolve(locale);
    final plan = p.plan;
    final text = '${start ?? s.pickStart} → ${end ?? s.pickEnd}';
    final sub = plan != null ? s.routeSummary(plan.rideStops, plan.transferCount) : (p.noRoute ? s.noRoute : s.openPlanHint);

    return Material(
      color: cs.surface,
      elevation: 3,
      shadowColor: cs.shadow.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.noRoute ? cs.error : cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 版面：固定的世界座標
// ---------------------------------------------------------------------------

class _MapLayout {
  _MapLayout(this.world, this.groups, this.groupPos, this.linePaths, this.lineColors);
  final Size world;
  final List<MetroStationGroup> groups;
  final Map<String, Offset> groupPos;
  final Map<String, Path> linePaths;
  final Map<String, Color> lineColors;

  static _MapLayout build({
    required MetroCatalog catalog,
    required String operatorCode,
    required List<LineShape> shapes,
    required Size world,
  }) {
    final groups = catalog.groups.where((g) => g.operator == operatorCode && g.hasPosition).toList(growable: false);
    final lines = catalog.lines.where((l) => l.operator == operatorCode).toList(growable: false);
    final shapeByLine = {for (final s in shapes) s.lineUid: s};

    // 範圍只看車站座標，Shape 載入前後位置不變
    var minLat = double.infinity, maxLat = -double.infinity, minLon = double.infinity, maxLon = -double.infinity;
    for (final g in groups) {
      minLat = math.min(minLat, g.lat!);
      maxLat = math.max(maxLat, g.lat!);
      minLon = math.min(minLon, g.lon!);
      maxLon = math.max(maxLon, g.lon!);
    }
    const pad = 36.0;
    final kx = math.cos(((minLat + maxLat) / 2) * math.pi / 180);
    final wDeg = math.max((maxLon - minLon) * kx, 1e-6);
    final hDeg = math.max(maxLat - minLat, 1e-6);
    final scale = math.max(1.0, math.min((world.width - 2 * pad) / wDeg, (world.height - 2 * pad) / hDeg));
    final ox = (world.width - wDeg * scale) / 2;
    final oy = (world.height - hDeg * scale) / 2;
    Offset project(double lat, double lon) => Offset(ox + (lon - minLon) * kx * scale, oy + (maxLat - lat) * scale);

    final pos = {for (final g in groups) g.id: project(g.lat!, g.lon!)};
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
          final ga = catalog.groupOfStation(e[0]);
          final gb = catalog.groupOfStation(e[1]);
          final a = ga == null ? null : pos[ga.id];
          final b = gb == null ? null : pos[gb.id];
          if (a == null || b == null || ga!.id == gb!.id) continue;
          path.moveTo(a.dx, a.dy);
          path.lineTo(b.dx, b.dy);
        }
      }
      paths[l.uid] = path;
    }
    return _MapLayout(world, groups, pos, paths, colors);
  }
}

class _LabelPair {
  const _LabelPair(this.halo, this.fill);
  final TextPainter halo;
  final TextPainter fill;
}

class _LabelCache {
  final Map<String, _LabelPair> _m = {};
  Locale? _locale;
  Color? _text;
  Color? _halo;

  void configure({required Locale locale, required Color textColor, required Color haloColor}) {
    if (_locale != locale || _text != textColor || _halo != haloColor) {
      _locale = locale;
      _text = textColor;
      _halo = haloColor;
      _m.clear();
    }
  }

  void clear() => _m.clear();

  _LabelPair get(MetroStationGroup g) {
    return _m.putIfAbsent(g.id, () {
      final label = g.name.resolve(_locale ?? const Locale('zh'));
      TextPainter make(TextStyle style) =>
          TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr, maxLines: 1)..layout();
      const base = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
      return _LabelPair(
        make(base.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round
            ..color = _halo ?? const Color(0xFFFFFFFF),
        )),
        make(base.copyWith(color: _text)),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// 繪製
// ---------------------------------------------------------------------------

class _MetroMapPainter extends CustomPainter {
  _MetroMapPainter({
    required this.layout,
    required this.highlight,
    required this.selectedLineUid,
    required this.startId,
    required this.endId,
    required this.planIds,
    required this.routePath,
    required this.viewport,
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
  final Set<String>? highlight;
  final String? selectedLineUid;
  final String? startId;
  final String? endId;
  final Set<String> planIds;
  final Path? routePath;
  final Size viewport;
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
    final m = transformation.value;
    final zoom = m.getMaxScaleOnAxis();
    // 螢幕上的線寬與點徑只隨 zoom^0.3 成長：放大時仍精細，縮小時仍看得見
    final k = math.pow(zoom, 0.7).toDouble();
    final hasRoute = routePath != null;
    final filtering = highlight != null;

    // 路線
    layout.linePaths.forEach((uid, path) {
      final dim = hasRoute || (selectedLineUid != null && selectedLineUid != uid);
      canvas.drawPath(
        path,
        Paint()
          ..color = (layout.lineColors[uid] ?? primary).withValues(alpha: dim ? 0.25 : 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 / k
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    });

    // 規劃路徑（發光）
    final rp = routePath;
    if (rp != null) {
      canvas.drawPath(
        rp,
        Paint()
          ..color = primary.withValues(alpha: 0.25 + 0.25 * glow.value)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12 / k
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 / zoom),
      );
      canvas.drawPath(
        rp,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 / k
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 只處理畫面內的站（座標轉換後裁切）
    final inv = Matrix4.tryInvert(m);
    final view = inv == null
        ? Offset.zero & size
        : MatrixUtils.transformRect(inv, Offset.zero & viewport).inflate(48 / zoom);

    final items = <_Drawn>[];
    for (final g in layout.groups) {
      final o = layout.groupPos[g.id]!;
      if (!view.contains(o)) continue;
      final isStart = g.id == startId, isEnd = g.id == endId;
      final inRoute = planIds.contains(g.id);
      final matched = !filtering || highlight!.contains(g.id);
      final alpha = matched ? 1.0 : 0.2;
      final base = g.isInterchange ? 5.5 : 3.8;
      final r = ((isStart || isEnd) ? base * 1.7 : base) / k;
      final fill = isStart ? startColor : (isEnd ? endColor : (inRoute ? primary : surface));
      canvas.drawCircle(o, r, Paint()..color = fill.withValues(alpha: alpha));
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (g.isInterchange ? 2.2 : 1.5) / k
          ..color = (isStart || isEnd || inRoute ? primary : outline).withValues(alpha: alpha),
      );
      final emphasized = isStart || isEnd || inRoute || (filtering && matched);
      if (matched) items.add(_Drawn(g, o, r, emphasized));
    }

    // 標籤：依優先順序放置，與已放置的標籤重疊就略過（避免擠成一團）
    items.sort((a, b) {
      int pri(_Drawn d) => d.emphasized ? 0 : (d.group.isInterchange ? 1 : 2);
      return pri(a).compareTo(pri(b));
    });
    final placed = <Rect>[];
    final screenBounds = Offset.zero & viewport;
    for (final it in items) {
      final eligible = it.emphasized || (it.group.isInterchange && zoom >= 1.0) || zoom >= 1.8;
      if (!eligible) continue;
      final pair = labels.get(it.group);
      final w = pair.fill.width, h = pair.fill.height;
      final sp = MatrixUtils.transformPoint(m, it.pos);
      final rScreen = it.radius * zoom;
      final rect = Rect.fromLTWH(sp.dx - w / 2, sp.dy + rScreen + 3, w, h);
      if (!screenBounds.contains(rect.topLeft) || !screenBounds.contains(rect.bottomRight)) continue;
      final box = rect.inflate(2);
      if (placed.any(box.overlaps)) continue;
      placed.add(box);
      canvas.save();
      canvas.translate(it.pos.dx, it.pos.dy);
      canvas.scale(1 / zoom);
      final off = Offset(-w / 2, rScreen + 3);
      pair.halo.paint(canvas, off);
      pair.fill.paint(canvas, off);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MetroMapPainter old) =>
      old.layout != layout ||
      old.selectedLineUid != selectedLineUid ||
      old.startId != startId ||
      old.endId != endId ||
      old.routePath != routePath ||
      old.viewport != viewport ||
      old.surface != surface ||
      old.outline != outline ||
      old.primary != primary ||
      !_sameSet(old.highlight, highlight) ||
      !_sameSet(old.planIds, planIds);

  static bool _sameSet(Set<String>? a, Set<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    return a.containsAll(b);
  }
}

class _Drawn {
  const _Drawn(this.group, this.pos, this.radius, this.emphasized);
  final MetroStationGroup group;
  final Offset pos;
  final double radius;
  final bool emphasized;
}
