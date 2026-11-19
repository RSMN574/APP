/// 交通到站狀態（公車、未來可延伸至台鐵/高鐵）。
///
/// 取代先前以字串 `'0' / '2' / 'min' / l10n.text_317` 表示的 `colorKey`，
/// 讓狀態判斷不再依賴本地化文案（QA 架構審查 B2）。
enum ArrivalStatus {
  /// 即將進站（< 1 分鐘）。
  arriving,

  /// 1–2 分鐘內。
  approaching,

  /// N 分鐘（即時預估）。
  minutes,

  /// 尚未發車：顯示下一班預計發車時間（HH:mm）。
  notDeparted,

  /// 末班已過 / 班次結束 / 無資料。
  ended,

  /// 交管不停靠、異常。
  abnormal,

  /// 固定班表時間（非即時）。
  scheduled;

  /// 是否為即時預估（會隨自動更新變動）。
  bool get isLive =>
      this == ArrivalStatus.arriving ||
      this == ArrivalStatus.approaching ||
      this == ArrivalStatus.minutes;

  /// 是否應以較淡的文字呈現站名（沒有可用的到站資訊）。
  bool get isInactive => this == ArrivalStatus.ended;
}
