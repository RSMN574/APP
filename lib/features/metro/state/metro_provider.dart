import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/metro_api_v2.dart';
import '../data/metro_data_repository.dart';
import '../data/models/metro_models.dart';
import '../domain/metro_route_planner.dart';

enum MetroLoadStatus { loading, ready, error }

enum MetroAsyncState { idle, loading, ready, error }

class MetroShapesState {
  const MetroShapesState(this.state, {this.shapes = const [], this.error});
  final MetroAsyncState state;
  final List<LineShape> shapes;
  final MetroErrorKind? error;
}

class MetroDetailState {
  const MetroDetailState(this.state, {this.detail, this.error});
  final MetroAsyncState state;
  final StationDetail? detail;
  final MetroErrorKind? error;
}

enum MetroFocusKind { group, line, route }

/// 給地圖的一次性指令（聚焦某站、某線或目前路徑）。每個指令是新物件，地圖用 ValueListenable 接收，
/// 不經過 notifyListeners，因此不會造成整頁重建。
class MetroMapFocus {
  MetroMapFocus(this.kind, {this.id}) : seq = _next++;
  static int _next = 0;
  final MetroFocusKind kind;
  final String? id;
  final int seq;
}

/// 狀態管理。HTTP、快取、路徑計算都在 Repository / Planner，這裡只維護 UI 狀態。
/// 類別名稱與檔名沿用舊版，既有的 Provider 註冊可直接使用。
/// 所有「站」的選取、搜尋、顯示都以「實體站」(MetroStationGroup) 為單位，
/// 因此同一個轉乘站（如台北車站 R10/BL12）只會出現一次。
class MetroProvider extends ChangeNotifier {
  MetroProvider({MetroDataRepository? repository}) : _repo = repository ?? MetroDataRepository();

  final MetroDataRepository _repo;
  bool _disposed = false;
  bool _loading = false;

  // ---- 目錄 ----
  MetroLoadStatus _status = MetroLoadStatus.loading;
  MetroCatalog? _catalog;
  MetroErrorKind? _error;
  bool _isStale = false;
  MetroRoutePlanner? _planner;

  MetroLoadStatus get status => _status;
  MetroCatalog? get catalog => _catalog;
  MetroErrorKind? get error => _error;
  bool get isStale => _isStale;

  // ---- 篩選與搜尋 ----
  String? _systemCode;
  String? _lineUid;
  String _query = '';
  List<MetroStationGroup> _searchResults = const [];
  Set<String>? _highlightGroupIds;

  String? get selectedSystemCode => _systemCode;
  String? get selectedLineUid => _lineUid;
  String get query => _query;

  /// 目前系統（與路線篩選）內符合搜尋的實體站，最多 40 筆，供建議清單使用。
  List<MetroStationGroup> get searchResults => _searchResults;

  /// 地圖要強調的實體站；null 表示不篩選。有搜尋字串時是符合者，否則若選了路線則是該路線上的站。
  Set<String>? get highlightGroupIds => _highlightGroupIds;

  MetroSystem? get selectedSystem {
    final c = _catalog;
    final code = _systemCode;
    if (c == null || code == null) return null;
    return c.systemByCode[code];
  }

  List<MetroLine> get systemLines {
    final c = _catalog;
    final s = selectedSystem;
    if (c == null || s == null) return const [];
    return s.lineUids.map((u) => c.lineByUid[u]).whereType<MetroLine>().toList(growable: false);
  }

  // ---- 路徑（起訖點為實體站）----
  String? _startGroupId;
  String? _endGroupId;
  RoutePlan? _plan;
  bool _noRoute = false;

  MetroStationGroup? get startGroup => _startGroupId == null ? null : _catalog?.groupById[_startGroupId];
  MetroStationGroup? get endGroup => _endGroupId == null ? null : _catalog?.groupById[_endGroupId];
  RoutePlan? get plan => _plan;
  bool get noRoute => _noRoute;

  /// 路徑經過的實體站 id（供地圖強調）。
  Set<String> get planGroupIds {
    final p = _plan;
    final c = _catalog;
    if (p == null || c == null) return const {};
    return {
      for (final u in p.stationUids)
        if (c.groupOfStation(u) != null) c.groupOfStation(u)!.id,
    };
  }

  // ---- 地圖指令 ----
  final ValueNotifier<MetroMapFocus?> mapFocus = ValueNotifier<MetroMapFocus?>(null);
  void requestFocusGroup(String groupId) => mapFocus.value = MetroMapFocus(MetroFocusKind.group, id: groupId);
  void requestFocusLine(String lineUid) => mapFocus.value = MetroMapFocus(MetroFocusKind.line, id: lineUid);
  void requestFitRoute() => mapFocus.value = MetroMapFocus(MetroFocusKind.route);

  // ---- Shape / 詳情 ----
  final Map<String, MetroShapesState> _shapes = {};
  final Map<String, MetroDetailState> _details = {};

  MetroShapesState shapesOf(String operatorCode) =>
      _shapes[operatorCode] ?? const MetroShapesState(MetroAsyncState.idle);
  MetroDetailState detailOf(String uid) => _details[uid] ?? const MetroDetailState(MetroAsyncState.idle);

  // =========================================================
  // 載入
  // =========================================================

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    final hadData = _catalog != null;
    if (!hadData) {
      _status = MetroLoadStatus.loading;
      _error = null;
      _notify();
    }
    try {
      final r = await _repo.loadCatalog();
      _catalog = r.catalog;
      _isStale = r.isStale;
      _planner = MetroRoutePlanner(r.catalog);
      _status = MetroLoadStatus.ready;
      _error = null;
      final codes = r.catalog.systems.map((s) => s.code).toList();
      if (_systemCode == null || !codes.contains(_systemCode)) {
        _systemCode = codes.contains('TRTC') ? 'TRTC' : (codes.isEmpty ? null : codes.first);
      }
      _recompute();
      _replan();
      _notify();
      final op = _systemCode;
      if (op != null) unawaited(ensureShapes(op));
    } on MetroApiException catch (e) {
      _error = e.kind;
      if (!hadData) _status = MetroLoadStatus.error;
      _notify();
    } finally {
      _loading = false;
    }
  }

  /// 舊程式碼相容。
  Future<void> loadCities() => load();

  Future<void> ensureShapes(String operatorCode, {bool retry = false}) async {
    final cur = _shapes[operatorCode];
    if (cur != null && !retry && (cur.state == MetroAsyncState.loading || cur.state == MetroAsyncState.ready)) {
      return;
    }
    _shapes[operatorCode] = const MetroShapesState(MetroAsyncState.loading);
    _notify();
    try {
      final shapes = await _repo.loadShapes(operatorCode);
      _shapes[operatorCode] = MetroShapesState(MetroAsyncState.ready, shapes: shapes);
    } on MetroApiException catch (e) {
      _shapes[operatorCode] = MetroShapesState(MetroAsyncState.error, error: e.kind);
    }
    _notify();
  }

  Future<void> loadDetail(String uid, {bool retry = false}) async {
    final cur = _details[uid];
    if (cur != null && !retry && (cur.state == MetroAsyncState.loading || cur.state == MetroAsyncState.ready)) {
      return;
    }
    _details[uid] = const MetroDetailState(MetroAsyncState.loading);
    _notify();
    try {
      final d = await _repo.loadDetail(uid);
      _details[uid] = MetroDetailState(MetroAsyncState.ready, detail: d);
    } on MetroApiException catch (e) {
      _details[uid] = MetroDetailState(MetroAsyncState.error, error: e.kind);
    }
    _notify();
  }

  // =========================================================
  // 篩選與搜尋
  // =========================================================

  void selectSystem(String code) {
    if (code == _systemCode) return;
    _systemCode = code;
    _lineUid = null;
    _query = '';
    _recompute();
    _notify();
    unawaited(ensureShapes(code));
  }

  void selectLine(String? lineUid) {
    if (lineUid == _lineUid) return;
    _lineUid = lineUid;
    _recompute();
    _notify();
  }

  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    _recompute();
    _notify();
  }

  static String _norm(String s) => s.trim().toLowerCase().replaceAll('臺', '台');

  /// 搜尋實體站：站名（臺/台視為相同）、英文名、任一站碼。結果依相符程度排序，每個實體站只出現一次。
  /// systemCode 為 null 時搜尋所有系統（起訖點選擇器使用）。
  List<MetroStationGroup> searchGroups(String raw, {String? systemCode, String? lineUid, int limit = 40}) {
    final c = _catalog;
    final q = _norm(raw);
    if (c == null || q.isEmpty) return const [];
    final hits = <_Hit>[];
    for (final g in c.groups) {
      if (systemCode != null && g.operator != systemCode) continue;
      if (lineUid != null && !g.lineUids.contains(lineUid)) continue;
      final zh = _norm(g.name.zh ?? '');
      final en = (g.name.en ?? '').toLowerCase();
      var score = 99;
      for (final code in g.codes) {
        final cl = code.toLowerCase();
        if (cl == q) {
          score = 0;
        } else if (cl.startsWith(q) && score > 1) {
          score = 1;
        }
      }
      if (zh == q || en == q) {
        score = 0;
      } else if ((zh.startsWith(q) || en.startsWith(q)) && score > 1) {
        score = 1;
      } else if ((zh.contains(q) || en.contains(q)) && score > 2) {
        score = 2;
      }
      if (score < 99) hits.add(_Hit(score, g));
    }
    hits.sort((a, b) {
      final d = a.score - b.score;
      return d != 0 ? d : (a.group.name.zh ?? '').compareTo(b.group.name.zh ?? '');
    });
    return hits.take(limit).map((h) => h.group).toList(growable: false);
  }

  /// 某系統的轉乘站（起訖點選擇器的快速選項）。
  List<MetroStationGroup> interchangeGroups(String? systemCode) {
    final c = _catalog;
    if (c == null) return const [];
    return c.groups
        .where((g) => g.isInterchange && (systemCode == null || g.operator == systemCode))
        .toList(growable: false);
  }

  void _recompute() {
    final c = _catalog;
    final code = _systemCode;
    if (c == null || code == null) {
      _searchResults = const [];
      _highlightGroupIds = null;
      return;
    }
    if (_query.trim().isNotEmpty) {
      final all = searchGroups(_query, systemCode: code, lineUid: _lineUid, limit: 100000);
      _searchResults = all.take(40).toList(growable: false);
      _highlightGroupIds = {for (final g in all) g.id};
    } else {
      _searchResults = const [];
      _highlightGroupIds = _lineUid == null
          ? null
          : {
              for (final g in c.groups)
                if (g.operator == code && g.lineUids.contains(_lineUid)) g.id,
            };
    }
  }

  // =========================================================
  // 起訖點與路徑
  // =========================================================

  void setStartGroup(String groupId) {
    _startGroupId = groupId;
    if (_endGroupId == groupId) _endGroupId = null;
    _replan();
    _notify();
  }

  void setEndGroup(String groupId) {
    _endGroupId = groupId;
    if (_startGroupId == groupId) _startGroupId = null;
    _replan();
    _notify();
  }

  void swapEndpoints() {
    final s = _startGroupId;
    _startGroupId = _endGroupId;
    _endGroupId = s;
    _replan();
    _notify();
  }

  void clearRoute() {
    _startGroupId = null;
    _endGroupId = null;
    _replan();
    _notify();
  }

  void _replan() {
    final s = startGroup;
    final e = endGroup;
    if (s == null || e == null || _planner == null) {
      _plan = null;
      _noRoute = false;
      return;
    }
    _plan = _planner!.planBetween(s.stationUids, e.stationUids);
    _noRoute = _plan == null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    mapFocus.dispose();
    _repo.dispose();
    super.dispose();
  }
}

class _Hit {
  const _Hit(this.score, this.group);
  final int score;
  final MetroStationGroup group;
}
