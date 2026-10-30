import 'package:collection/collection.dart';

import '../data/models/metro_models.dart';

/// 路徑中的一步。link 不為 null 代表這一步是「轉乘」（換站或換系統），否則是同一條線上的搭乘。
class PlanHop {
  const PlanHop({required this.from, required this.to, this.lineUid, this.link});
  final String from;
  final String to;
  final String? lineUid;
  final StationLink? link;
  bool get isTransfer => link != null;
}

/// 同一條線上連續搭乘的區段。
class PlanLeg {
  const PlanLeg({required this.lineUid, required this.fromUid, required this.toUid, required this.stops});
  final String lineUid;
  final String fromUid;
  final String toUid;
  final int stops;
}

class RoutePlan {
  const RoutePlan({
    required this.stationUids,
    required this.hops,
    required this.legs,
    required this.rideStops,
    required this.transferCount,
    required this.usesCrossSystem,
    required this.usesDerivedLink,
  });
  final List<String> stationUids;
  final List<PlanHop> hops;
  final List<PlanLeg> legs;
  final int rideStops;
  final int transferCount;
  final bool usesCrossSystem;

  /// 是否用到「由座標與站名推導」的轉乘連結（非 SQL 明列）。
  final bool usesDerivedLink;
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

/// 只使用資料中存在的相鄰關係與轉乘連結建圖：
///   - 同線相鄰站（catalog.lines[].edges）
///   - 轉乘連結（catalog.links，含同系統與跨系統）
/// 不會因為站名相同就連起來。不計算票價與時間，因為資料中沒有這些欄位。
/// 成本只用來在多條路徑中選擇：搭乘每站 1，轉乘一次 [transferPenalty]（約等於少搭幾站）。
class MetroRoutePlanner {
  MetroRoutePlanner(MetroCatalog catalog, {this.transferPenalty = 4}) {
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

  final int transferPenalty;
  final Map<String, List<_Edge>> _adj = {};

  void _add(String from, _Edge e) => _adj.putIfAbsent(from, () => []).add(e);

  RoutePlan? plan(String from, String to) {
    if (from == to) return null;
    if (!_adj.containsKey(from) || !_adj.containsKey(to)) return null;

    final dist = <String, int>{from: 0};
    final prev = <String, _Edge>{};
    final prevNode = <String, String>{};
    final pq = PriorityQueue<_Node>((a, b) => a.cost.compareTo(b.cost))..add(_Node(from, 0));

    while (pq.isNotEmpty) {
      final cur = pq.removeFirst();
      if (cur.cost > (dist[cur.uid] ?? 1 << 30)) continue;
      if (cur.uid == to) break;
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
    if (!dist.containsKey(to)) return null;

    final hops = <PlanHop>[];
    var node = to;
    while (node != from) {
      final e = prev[node]!;
      final p = prevNode[node]!;
      hops.add(PlanHop(from: p, to: node, lineUid: e.lineUid, link: e.link));
      node = p;
    }
    final ordered = hops.reversed.toList(growable: false);

    final legs = <PlanLeg>[];
    var rideStops = 0;
    var transfers = 0;
    var cross = false;
    var derived = false;
    String? legLine;
    String? legFrom;
    var legStops = 0;
    String? lastTo;

    void flush() {
      if (legLine != null && legFrom != null && lastTo != null) {
        legs.add(PlanLeg(lineUid: legLine!, fromUid: legFrom!, toUid: lastTo!, stops: legStops));
      }
      legLine = null;
      legFrom = null;
      legStops = 0;
    }

    for (final h in ordered) {
      if (h.isTransfer) {
        flush();
        transfers++;
        if (h.link!.isCrossSystem) cross = true;
        if (h.link!.isDerived) derived = true;
      } else {
        rideStops++;
        if (legLine != h.lineUid) {
          flush();
          legLine = h.lineUid;
          legFrom = h.from;
        }
        legStops++;
      }
      lastTo = h.to;
    }
    flush();

    return RoutePlan(
      stationUids: [from, ...ordered.map((h) => h.to)],
      hops: ordered,
      legs: legs,
      rideStops: rideStops,
      transferCount: transfers,
      usesCrossSystem: cross,
      usesDerivedLink: derived,
    );
  }
}
