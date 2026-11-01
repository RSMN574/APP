import 'package:collection/collection.dart';

import '../data/models/metro_models.dart';

abstract class PlanStep {
  const PlanStep();
}

/// 同一條線上連續搭乘的區段。stationUids 含起訖與中途站（依行進順序）。
class PlanLeg extends PlanStep {
  const PlanLeg({required this.lineUid, required this.stationUids, this.terminalUid});
  final String lineUid;
  final List<String> stationUids;

  /// 行進方向的終點站（來自 StationOfRoute）；找不到對應交路時為 null。
  final String? terminalUid;

  String get fromUid => stationUids.first;
  String get toUid => stationUids.last;
  int get stops => stationUids.length - 1;
}

/// 兩段搭乘之間的轉乘。links 為空代表「同一個站、不同路線」。
class PlanTransfer extends PlanStep {
  const PlanTransfer({required this.fromUid, required this.toUid, required this.links});
  final String fromUid;
  final String toUid;
  final List<StationLink> links;

  bool get isCrossSystem => links.any((l) => l.isCrossSystem);
  bool get isDerived => links.any((l) => l.isDerived);
}

class RoutePlan {
  const RoutePlan({
    required this.stationUids,
    required this.steps,
    required this.rideStops,
    required this.transferCount,
    required this.usesCrossSystem,
    required this.usesDerivedLink,
  });
  final List<String> stationUids;
  final List<PlanStep> steps;
  final int rideStops;

  /// 夾在兩段搭乘之間的轉乘次數。
  final int transferCount;
  final bool usesCrossSystem;
  final bool usesDerivedLink;

  List<PlanLeg> get legs => steps.whereType<PlanLeg>().toList(growable: false);
}

class _Edge {
  const _Edge(this.to, this.cost, {this.lineUid, this.link});
  final String to;
  final int cost;
  final String? lineUid;
  final StationLink? link;
}

class _Node {
  _Node(this.uid, this.cost);
  final String uid;
  final int cost;
}

/// 只使用資料中存在的關係建圖：同線相鄰站（lines[].edges）與轉乘連結（links，含同系統與跨系統）。
/// 候選轉乘（candidateLinks）不參與。不會因站名相同就連起來。不計算票價與時間（資料沒有）。
/// 成本只用來在多條路徑中選擇：搭乘每站 1，轉乘一次 [transferPenalty]。
class MetroRoutePlanner {
  MetroRoutePlanner(this.catalog, {this.transferPenalty = 4}) {
    for (final line in catalog.lines) {
      for (final e in line.edges) {
        _add(e[0], _Edge(e[1], 1, lineUid: line.uid));
        _add(e[1], _Edge(e[0], 1, lineUid: line.uid));
      }
    }
    for (final l in catalog.links) {
      _add(l.a, _Edge(l.b, transferPenalty, link: l));
      _add(l.b, _Edge(l.a, transferPenalty, link: l));
    }
  }

  final MetroCatalog catalog;
  final int transferPenalty;
  final Map<String, List<_Edge>> _adj = {};

  void _add(String from, _Edge e) => _adj.putIfAbsent(from, () => []).add(e);

  RoutePlan? plan(String from, String to) => planBetween([from], [to]);

  /// 實體站對實體站：起點與終點各是「一組站碼」（如台北車站 R10 與 BL12），
  /// 以多起點最短路徑計算，因此不會把站內換線算成多餘的轉乘。
  RoutePlan? planBetween(Iterable<String> fromUids, Iterable<String> toUids) {
    final sources = fromUids.where(_adj.containsKey).toSet();
    final targets = toUids.where(_adj.containsKey).toSet();
    if (sources.isEmpty || targets.isEmpty) return null;
    if (sources.intersection(targets).isNotEmpty) return null;

    final dist = <String, int>{for (final s in sources) s: 0};
    final prev = <String, _Edge>{};
    final prevNode = <String, String>{};
    final pq = PriorityQueue<_Node>((a, b) => a.cost.compareTo(b.cost))
      ..addAll(sources.map((s) => _Node(s, 0)));

    String? end;
    while (pq.isNotEmpty) {
      final cur = pq.removeFirst();
      if (cur.cost > (dist[cur.uid] ?? 1 << 30)) continue;
      if (targets.contains(cur.uid)) {
        end = cur.uid;
        break;
      }
      for (final e in _adj[cur.uid] ?? const <_Edge>[]) {
        final nc = cur.cost + e.cost;
        if (nc < (dist[e.to] ?? 1 << 30)) {
          dist[e.to] = nc;
          prev[e.to] = e;
          prevNode[e.to] = cur.uid;
          pq.add(_Node(e.to, nc));
        }
      }
    }
    if (end == null) return null;

    final reversed = <_Hop>[];
    var node = end;
    while (prev.containsKey(node)) {
      final e = prev[node]!;
      final p = prevNode[node]!;
      reversed.add(_Hop(p, node, e.lineUid, e.link));
      node = p;
    }
    final hops = reversed.reversed.toList(growable: false);
    return _build(node, hops);
  }

  RoutePlan _build(String start, List<_Hop> hops) {
    final steps = <PlanStep>[];
    var rideStops = 0;
    var cross = false;
    var derived = false;

    String? legLine;
    List<String>? legStations;

    void flushLeg() {
      if (legLine != null && legStations != null) {
        steps.add(PlanLeg(
          lineUid: legLine!,
          stationUids: legStations!,
          terminalUid: _terminal(legLine!, legStations!.first, legStations!.last),
        ));
      }
      legLine = null;
      legStations = null;
    }

    void addTransfer(String from, String to, StationLink? link) {
      final last = steps.isEmpty ? null : steps.last;
      if (last is PlanTransfer) {
        steps[steps.length - 1] = PlanTransfer(
          fromUid: last.fromUid,
          toUid: to,
          links: [...last.links, if (link != null) link],
        );
      } else {
        steps.add(PlanTransfer(fromUid: from, toUid: to, links: [if (link != null) link]));
      }
    }

    for (final h in hops) {
      if (h.link != null) {
        flushLeg();
        addTransfer(h.from, h.to, h.link);
        if (h.link!.isCrossSystem) cross = true;
        if (h.link!.isDerived) derived = true;
      } else {
        rideStops++;
        if (legLine != h.lineUid) {
          final hadLeg = legLine != null;
          flushLeg();
          // 同一站但換了路線（沒有轉乘連結）：補上一個空的轉乘
          if (hadLeg) addTransfer(h.from, h.from, null);
          legLine = h.lineUid;
          legStations = [h.from];
        }
        legStations!.add(h.to);
      }
    }
    flushLeg();

    var transfers = 0;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i] is PlanTransfer && i > 0 && i < steps.length - 1) transfers++;
    }

    return RoutePlan(
      stationUids: [start, ...hops.map((h) => h.to)],
      steps: steps,
      rideStops: rideStops,
      transferCount: transfers,
      usesCrossSystem: cross,
      usesDerivedLink: derived,
    );
  }

  /// 在該路線的交路中，找出同時包含起訖站且順序相同、站數最少的交路，其終點即為行進方向。
  String? _terminal(String lineUid, String from, String to) {
    MetroRoute? best;
    for (final r in catalog.routesOfLine(lineUid)) {
      final a = r.stationUids.indexOf(from);
      final b = r.stationUids.indexOf(to);
      if (a < 0 || b < 0 || a >= b) continue;
      if (best == null || r.stationUids.length < best.stationUids.length) best = r;
    }
    return best?.terminalUid;
  }
}

class _Hop {
  const _Hop(this.from, this.to, this.lineUid, this.link);
  final String from;
  final String to;
  final String? lineUid;
  final StationLink? link;
}
