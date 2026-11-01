import 'package:flutter/widgets.dart';

import '../data/metro_api_v2.dart';

/// 捷運功能專用字串（繁體中文 / English）。
/// 專案已使用 gen-l10n（text_N 命名）；這裡集中放捷運新增的字串，之後可逐一搬進 ARB，
/// 呼叫端只需把 `MetroStrings.of(context).xxx` 換成 `AppLocalizations.of(context)!.text_N`。
class MetroStrings {
  const MetroStrings(this.locale);
  final Locale locale;

  static MetroStrings of(BuildContext context) => MetroStrings(Localizations.localeOf(context));

  bool get en => locale.languageCode == 'en';
  String _t(String zh, String enText) => en ? enText : zh;

  // 頁面與分頁
  String get title => _t('捷運', 'Metro');
  String get tabMap => _t('路線圖', 'Map');
  String get tabPlan => _t('路線規劃', 'Plan');
  String get tabLines => _t('路線資訊', 'Lines');
  String get tabPlanEmpty => _t('選擇起訖', 'Pick stops');
  String get pickRest => _t('再選一站', 'Pick one more');
  String lineCountLabel(int n) => _t('$n 條路線', '$n lines');
  String get refresh => _t('重新整理', 'Refresh');

  // 搜尋與篩選
  String get searchHint => _t('搜尋站名或站碼', 'Search name or code');
  String get clear => _t('清除', 'Clear');
  String get allLines => _t('全部路線', 'All lines');
  String get retry => _t('重試', 'Retry');
  String get loading => _t('載入中…', 'Loading…');
  String get emptyStations => _t('找不到符合的車站', 'No matching stations');
  String get emptySystem => _t('此系統目前沒有資料', 'No data for this system');

  // 地圖
  String get zoomIn => _t('放大', 'Zoom in');
  String get zoomOut => _t('縮小', 'Zoom out');
  String get resetView => _t('重置視角', 'Reset view');
  String get staleBanner => _t('無法更新，目前顯示本機快取資料', 'Could not refresh. Showing cached data.');
  String get geometryLoading => _t('路線圖幾何載入中…', 'Loading line geometry…');
  String get geometryFallback =>
      _t('路線幾何載入失敗，改以車站連線顯示', 'Line geometry unavailable. Showing station-to-station links.');
  String get stationsNoPosition => _t('此系統沒有車站座標，無法繪製路線圖', 'No station coordinates, cannot draw the map');
  String get openPlanHint => _t('點此查看路線規劃', 'Tap to open the planner');

  String errorMessage(MetroErrorKind? k) {
    switch (k) {
      case MetroErrorKind.timeout:
        return _t('連線逾時，請稍後再試', 'Connection timed out. Please try again.');
      case MetroErrorKind.network:
        return _t('無法連線到伺服器，請檢查網路', 'Cannot reach the server. Check your connection.');
      case MetroErrorKind.server:
        return _t('伺服器發生問題，請稍後再試', 'Server error. Please try again later.');
      case MetroErrorKind.format:
        return _t('資料格式錯誤', 'Unexpected data format.');
      case null:
        return _t('發生未知錯誤', 'Something went wrong.');
    }
  }

  // 系統與資料涵蓋
  String get system => _t('營運系統', 'Operator');
  String stationCountLabel(int n) => _t('$n 站', '$n stations');
  String coverageLine({required int total, required int facility, required int transfer, required bool shape}) {
    final parts = <String>[
      _t('設施資料 $facility/$total 站', 'Facilities $facility/$total'),
      _t('轉乘資料 $transfer 站', 'Transfer info $transfer'),
      shape ? _t('有路線圖', 'Line map') : _t('無路線圖', 'No line map'),
    ];
    return parts.join(' · ');
  }

  String get coverShape => _t('有路線幾何資料（Shape）', 'Line geometry available');
  String get coverNoShape => _t('沒有路線幾何資料', 'No line geometry');
  String coverFacility(int n, int total) => _t('$n / $total 站有設施資料', '$n of $total stations have facility data');
  String get coverNoFacility => _t('此系統沒有車站設施資料', 'No facility data for this operator');
  String coverTransfer(int n) => _t('$n 站有接駁與轉乘說明', '$n stations have connection info');
  String get coverNoTransfer => _t('此系統沒有轉乘或接駁資料', 'No transfer or connection data for this operator');
  String coverCandidates(int n) => _t('另有 $n 處可能的跨系統轉乘，資料未明列', '$n possible cross-operator transfers not listed in the data');
  String dataVersion(String v) => _t('資料版本 $v', 'Data version $v');

  // 車站
  String get address => _t('地址', 'Address');
  String get setStart => _t('設為起點', 'Set as start');
  String get setEnd => _t('設為終點', 'Set as end');
  String get transferStation => _t('轉乘站', 'Interchange');
  String mergedNote(List<String> codes) => _t(
        '同一個實體站，站碼 ${codes.join('、')} 已合併顯示',
        'One physical station. Codes ${codes.join(', ')} are merged.',
      );
  String get directions => _t('行經路線與方向', 'Lines and directions');
  String towards(String terminal) => _t('往 $terminal', 'To $terminal');

  // 規劃
  String get startPoint => _t('起點', 'From');
  String get endPoint => _t('終點', 'To');
  String get pickStart => _t('選擇起點', 'Select start');
  String get pickEnd => _t('選擇終點', 'Select end');
  String get swap => _t('對調起訖點', 'Swap start and end');
  String get planHint => _t('選擇起點與終點，即可查看搭乘路線', 'Pick a start and an end to see the route');
  String get noRoute => _t('資料中找不到相連的路徑', 'No connecting path found in the data');
  String get quickPickInterchange => _t('目前系統的轉乘站', 'Interchange stations in this operator');
  String routeSummary(int stops, int transfers) => _t('搭乘 $stops 站 · 轉乘 $transfers 次', '$stops stops · $transfers transfers');
  String routeSummaryShort(int stops, int transfers) => _t('$stops 站 · 轉 $transfers', '$stops stops · $transfers xfer');
  String get crossSystemNote => _t('含跨系統轉乘', 'Includes a cross-operator transfer');
  String get derivedNote => _t('部分轉乘為依座標推導', 'Some transfers are derived from coordinates');
  String get noFareNote => _t('資料庫沒有票價與行駛時間，故不顯示', 'Fare and travel time are not in the database, so they are not shown');
  String legLabel(int stops) => _t('$stops 站', '$stops stops');
  String intermediateStops(int n) => _t('途經 $n 站', '$n stops in between');
  String get showOnMap => _t('在地圖上查看', 'Show on map');
  String transferAt(String name) => _t('在 $name 站內轉乘', 'Change at $name');

  // 轉乘
  String get transferSection => _t('轉乘', 'Transfers');
  String get sameSystemTransfer => _t('系統內轉乘', 'Same-operator transfer');
  String get crossSystemTransfer => _t('跨系統轉乘', 'Cross-operator transfer');
  String get candidateLink => _t('可能可轉乘（資料未明列）', 'Possible transfer (not listed in data)');
  String get derivedLink => _t('依座標推導', 'Derived from coordinates');
  String get sqlLink => _t('資料明列', 'Listed in data');
  String get onSite => _t('站內轉乘', 'On-site');
  String get noTransferLinks => _t('資料中沒有此站的捷運轉乘', 'No metro transfers listed for this station');
  String distanceM(int m) => _t('相距約 $m 公尺', 'about $m m apart');
  String interchangeLines(List<String> lines) =>
      _t('可在本站轉乘：${lines.join('、')}', 'Change here between: ${lines.join(', ')}');

  // 設施
  String get facilities => _t('車站設施', 'Facilities');
  String get noFacilityData => _t('此站沒有設施資料', 'No facility data for this station');
  String get noneListed => _t('資料中未列出', 'None listed');
  String get elevators => _t('電梯', 'Elevators');
  String get infoSpots => _t('詢問處', 'Information');
  String get drinkingFountains => _t('飲水機', 'Drinking fountains');
  String get toilets => _t('廁所', 'Restrooms');
  String get stationMaps => _t('車站圖', 'Station maps');
  String get interiorMaps => _t('站內圖', 'Interior maps');
  String get otherAccess => _t('其他接駁', 'Other connections');
  String modeLabel(String mode) {
    switch (mode) {
      case 'rail':
        return _t('鐵路', 'Rail');
      case 'bus':
        return _t('公車', 'Bus');
      case 'bike':
        return _t('單車', 'Bike');
      case 'parking':
        return _t('停車', 'Parking');
      case 'airport':
        return _t('機場', 'Airport');
      default:
        return mode;
    }
  }

  String floor(String f) => _t('樓層 $f', 'Floor $f');
}
