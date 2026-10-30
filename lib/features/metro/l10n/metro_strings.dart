import 'package:flutter/widgets.dart';

import '../data/metro_api_v2.dart';

/// 捷運功能專用字串（繁體中文 / English）。
/// 專案若已使用 gen-l10n，可把這些 getter 搬進 ARB；呼叫端只需改 `MetroStrings.of(context)`。
class MetroStrings {
  const MetroStrings(this.locale);
  final Locale locale;

  static MetroStrings of(BuildContext context) => MetroStrings(Localizations.localeOf(context));

  bool get en => locale.languageCode == 'en';
  String _t(String zh, String enText) => en ? enText : zh;

  String get title => _t('捷運路線與車站', 'Metro Lines & Stations');
  String get tabMap => _t('路線圖', 'Map');
  String get tabList => _t('車站清單', 'Stations');
  String get searchHint => _t('搜尋站名或站碼', 'Search name or code');
  String get clear => _t('清除', 'Clear');
  String get allLines => _t('全部路線', 'All lines');
  String get retry => _t('重試', 'Retry');
  String get loading => _t('載入中…', 'Loading…');
  String get resetView => _t('重置視角', 'Reset view');

  String get staleBanner => _t('無法更新，目前顯示本機快取資料', 'Could not refresh. Showing cached data.');
  String get emptyStations => _t('找不到符合的車站', 'No matching stations');
  String get emptySystem => _t('此系統目前沒有資料', 'No data for this system');
  String get geometryLoading => _t('路線圖幾何載入中…', 'Loading line geometry…');
  String get geometryFallback =>
      _t('路線幾何載入失敗，改以車站連線顯示', 'Line geometry unavailable. Showing station-to-station links.');
  String get stationsNoPosition => _t('此系統沒有車站座標，無法繪製路線圖', 'No station coordinates, cannot draw the map');

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

  // 車站
  String get stationCode => _t('站碼', 'Code');
  String get address => _t('地址', 'Address');
  String get setStart => _t('設為起點', 'Set as start');
  String get setEnd => _t('設為終點', 'Set as end');
  String get pickStart => _t('選擇起點', 'Select start');
  String get pickEnd => _t('選擇終點', 'Select end');
  String get swap => _t('對調起訖點', 'Swap start and end');
  String get transferStation => _t('轉乘站', 'Interchange');

  // 路徑
  String get routeTitle => _t('規劃路線', 'Planned route');
  String get noRoute => _t('資料中找不到相連的路徑', 'No connecting path found in the data');
  String routeSummary(int stops, int transfers) =>
      _t('搭乘 $stops 站 · 轉乘 $transfers 次', '$stops stops · $transfers transfers');
  String get crossSystemNote => _t('含跨系統轉乘（依資料提供的轉乘連結）', 'Includes a cross-operator transfer (from provided transfer data)');
  String get derivedNote => _t('部分轉乘為依座標推導', 'Some transfers are derived from coordinates');
  String get noFareNote => _t('資料中沒有票價與時間，故不顯示', 'Fare and time are not in the data, so they are not shown');
  String legLabel(int stops) => _t('$stops 站', '$stops stops');

  // 轉乘
  String get transferSection => _t('轉乘', 'Transfers');
  String get sameSystemTransfer => _t('系統內轉乘', 'Same-operator transfer');
  String get crossSystemTransfer => _t('跨系統轉乘', 'Cross-operator transfer');
  String get derivedLink => _t('依座標推導（同名且距離 250 公尺內）', 'Derived from name and distance (within 250 m)');
  String get sqlLink => _t('資料明列', 'Listed in data');
  String get onSite => _t('站內轉乘', 'On-site');
  String get noTransferLinks => _t('資料中沒有此站的捷運轉乘', 'No metro transfers listed for this station');

  // 設施
  String get facilities => _t('車站設施', 'Facilities');
  String get noFacilityData => _t('此站沒有設施資料', 'No facility data for this station');
  String get noneListed => _t('資料中未列出', 'None listed');
  String get elevators => _t('電梯', 'Elevators');
  String get infoSpots => _t('詢問處', 'Information');
  String get drinkingFountains => _t('飲水機', 'Drinking fountains');
  String get toilets => _t('廁所', 'Restrooms');
  String get stationMaps => _t('車站圖', 'Station maps');
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
  String more(int n) => _t('另有 $n 筆', '$n more');
}
