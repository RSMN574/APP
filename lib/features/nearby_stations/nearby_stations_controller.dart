import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


/// 站牌列表排序方式。
enum SortType { nameAsc, nameDesc, timeAsc, timeDesc }


/// 鄰近站點頁面的狀態控制器。
///
/// 集中管理原本散落在 top-level 的 `ValueNotifier`：
/// `_stationIDs`、`_selectStationID`、`_selectStationGroupID`、`_markers`、
/// `_stopName`、`_stopNameEn`、`_tabSelect`、`_indexNotifier`、`_sortNotifier`。
class NearbyStationsController extends ChangeNotifier {
  // ── 站牌選擇 ─────────────────────────────────────────
  final List<String> _stationIDs = <String>[];
  String _selectStationID = '';
  String _selectStationGroupID = '';

  // ── 站名 ─────────────────────────────────────────────
  String _stopName = '';
  String _stopNameEn = '';

  // ── Tab / 頁面索引 ───────────────────────────────────
  String _tabSelect = 'bus';
  int _index = 0;

  // ── 排序 ─────────────────────────────────────────────
  SortType _sortType = SortType.timeAsc;

  // ── 地圖 marker ──────────────────────────────────────
  Set<Marker> _markers = <Marker>{};

  // ── Getter ───────────────────────────────────────────
  List<String> get stationIDs => List.unmodifiable(_stationIDs);
  String get selectStationID => _selectStationID;
  String get selectStationGroupID => _selectStationGroupID;
  String get stopName => _stopName;
  String get stopNameEn => _stopNameEn;
  String get tabSelect => _tabSelect;
  int get index => _index;
  SortType get sortType => _sortType;
  Set<Marker> get markers => _markers;

  // ── 站牌選擇 ─────────────────────────────────────────
  void setStationIDs(List<String> ids) {
    _stationIDs
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void setSelectStationID(String id) {
    if (_selectStationID == id) return;
    _selectStationID = id;
    _applyMarkerStyle();
    notifyListeners();
  }

  void setSelectStationGroupID(String id) {
    if (_selectStationGroupID == id) return;
    _selectStationGroupID = id;
    notifyListeners();
  }

  // ── 站名 ─────────────────────────────────────────────
  void setStopName(String zh, {String en = ''}) {
    _stopName = zh;
    _stopNameEn = en;
    notifyListeners();
  }

  // ── Tab / 頁面索引 ───────────────────────────────────
  void setTabSelect(String tab) {
    if (_tabSelect == tab) return;
    _tabSelect = tab;
    notifyListeners();
  }

  void setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }

  // ── 排序 ─────────────────────────────────────────────
  void setSortType(SortType type) {
    if (_sortType == type) return;
    _sortType = type;
    notifyListeners();
  }

  // ── marker ──────────────────────────────────────────
  void setMarkers(Set<Marker> markers) {
    _markers = markers;
    notifyListeners();
  }

  /// 依目前 `selectStationID` 更新 marker icon 樣式。
  void updateMarkerStyle() {
    _applyMarkerStyle();
    notifyListeners();
  }

  /// 全部 marker 恢復預設樣式。
  void clearMarkerStyle() {
    if (_markers.isEmpty) return;
    _markers = _markers
        .map((m) => m.copyWith(iconParam: BitmapDescriptor.defaultMarker))
        .toSet();
    notifyListeners();
  }

  /// 清空站牌選擇狀態（含 marker 樣式）。
  void clearStationSelection() {
    _stationIDs.clear();
    _stopName = '';
    _stopNameEn = '';
    _selectStationID = '';
    _selectStationGroupID = '';
    _applyMarkerStyle();
    notifyListeners();
  }

  void _applyMarkerStyle() {
    if (_markers.isEmpty) return;
    final selected = _selectStationID;
    _markers = _markers.map((marker) {
      if (marker.markerId.value == selected) {
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(190.0),
        );
      }
      return marker.copyWith(iconParam: BitmapDescriptor.defaultMarker);
    }).toSet();
  }
}