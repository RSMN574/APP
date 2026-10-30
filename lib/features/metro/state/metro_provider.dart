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

/// 清單頁用：一條路線與其（已套用搜尋條件的）車站，順序依路線站序。
class MetroLineSection {
  const MetroLineSection(this.line, this.stations);
  final MetroLine line;
  final List<MetroStation> stations;
}

/// 取代舊的 MetroProvider（類別名稱與檔名不變，既有的 Provider 註冊可沿用）。
/// 所有 HTTP、快取與路徑計算都在 Repository / Planner，這裡只維護 UI 狀態。
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

  /// 網路失敗、目前顯示本機快取。
  bool get isStale => _isStale;

  // ---- 篩選 ----
  String? _systemCode;
  String? _lineUid;
  String _query = '';
  List<MetroStation> _visibleStations = const [];
  List<MetroLineSection> _sections = const [];

  String? get selectedSystemCode => _systemCode;
  String? get selectedLineUid => _lineUid;
  String get query => _query;
  List<MetroStation> get visibleStations => _visibleStations;
  List<MetroLineSection> get sections => _sections;

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

  // ---- 路徑 ----
  String? _startUid;
  String? _endUid;
  RoutePlan? _plan;
  bool _noRoute = false;

  MetroStation? get startStation => _startUid == null ? null : _catalog?.stationByUid[_startUid];
  MetroStation? get endStation => _endUid == null ? null : _catalog?.stationByUid[_endUid];
  RoutePlan? get plan => _plan;

  /// 已選好起訖點，但資料中找不到相連路徑。
  bool get noRoute => _noRoute;

  // ---- Shape / 詳情 ----
  final Map<String, MetroShapesState> _shapes = {};
  final Map<String, MetroDetailState> _details = {};

  MetroShapesState shapesOf(String operatorCode) =>
      _shapes[operatorCode] ?? const MetroShapesState(MetroAsyncState.idle);
  MetroDetailState detailOf(String uid) => _details[uid] ?? const MetroDetailState(MetroAsyncState.idle);

  // =========================================================
  // 載入
  // =========================================================

  /// 載入（或重試）目錄。同時間只會有一個進行中的請求。
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

  /// 舊程式碼相容：原本 App 啟動時會呼叫 loadCities()。
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
  // 篩選
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

  bool _matches(MetroStation s, String q) {
    if (q.isEmpty) return true;
    return _norm(s.name.zh ?? '').contains(q) ||
        (s.name.en ?? '').toLowerCase().contains(q) ||
        s.code.toLowerCase().contains(q);
  }

  void _recompute() {
    final c = _catalog;
    final code = _systemCode;
    if (c == null || code == null) {
      _visibleStations = const [];
      _sections = const [];
      return;
    }
    final q = _norm(_query);
    _visibleStations = c.stations
        .where((s) => s.operator == code && (_lineUid == null || s.lineUids.contains(_lineUid)) && _matches(s, q))
        .toList(growable: false);

    final out = <MetroLineSection>[];
    for (final line in systemLines) {
      if (_lineUid != null && line.uid != _lineUid) continue;
      final list = <MetroStation>[];
      for (final u in line.stationUids) {
        final s = c.stationByUid[u];
        if (s != null && _matches(s, q)) list.add(s);
      }
      if (list.isNotEmpty) out.add(MetroLineSection(line, list));
    }
    _sections = out;
  }

  // =========================================================
  // 起訖點與路徑
  // =========================================================

  void setStart(String uid) {
    _startUid = uid;
    if (_endUid == uid) _endUid = null;
    _replan();
    _notify();
  }

  void setEnd(String uid) {
    _endUid = uid;
    if (_startUid == uid) _startUid = null;
    _replan();
    _notify();
  }

  void swapEndpoints() {
    final s = _startUid;
    _startUid = _endUid;
    _endUid = s;
    _replan();
    _notify();
  }

  void clearRoute() {
    _startUid = null;
    _endUid = null;
    _replan();
    _notify();
  }

  void _replan() {
    final s = _startUid;
    final e = _endUid;
    if (s == null || e == null || _planner == null) {
      _plan = null;
      _noRoute = false;
      return;
    }
    _plan = _planner!.plan(s, e);
    _noRoute = _plan == null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.dispose();
    super.dispose();
  }
}
