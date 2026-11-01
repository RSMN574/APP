/// 附近站點的交通類型。
enum NearbyStationType { bus, metro, train }

/// 整理完成、可直接用於地圖 Marker 的附近站點資料。
///
/// 與地圖 SDK 無關（不含 LatLng），座標一定是有效值。
class NearbyStationResult {
  const NearbyStationResult({
    required this.id,
    required this.type,
    required this.nameZh,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
    this.groupId,
  });

  /// 穩定的站點識別碼（同一交通類型內唯一）。
  final String id;
  final NearbyStationType type;
  final String nameZh;
  final String nameEn;
  final double latitude;
  final double longitude;

  /// 公車站牌群組 ID（其他交通類型為 null）。
  final String? groupId;

  /// 供 `_localizedName` 使用的多語系名稱。
  Map<String, String> get names => {'Zh_tw': nameZh, 'En': nameEn};
}
