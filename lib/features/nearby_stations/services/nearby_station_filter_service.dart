import 'dart:convert';

import '../../bus/model/bus_station_model.dart';
import '../models/nearby_station_result.dart';

/// 附近站點資料整理：座標驗證、去重、正規化。
///
/// 純邏輯，不存取網路或資料庫。
class NearbyStationFilterService {
  const NearbyStationFilterService();

  /// 座標是否有效（排除 NaN、超出範圍與 (0,0) 預設值）。
  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    if (latitude == 0 && longitude == 0) return false;
    return true;
  }

  /// 公車站牌：排除無效座標與空 ID，並以 stationID 去重（保留第一筆）。
  List<BusStationInfo> cleanBusStations(List<BusStationInfo> stations) {
    final seen = <String>{};
    final out = <BusStationInfo>[];
    for (final s in stations) {
      if (s.stationID.isEmpty) continue;
      if (!isValidCoordinate(s.positionLat, s.positionLon)) continue;
      if (seen.add(s.stationID)) out.add(s);
    }
    return out;
  }

  /// 公車站牌 → 地圖用結果。
  List<NearbyStationResult> busResults(List<BusStationInfo> stations) {
    return cleanBusStations(stations)
        .map((s) => NearbyStationResult(
              id: s.stationID,
              type: NearbyStationType.bus,
              nameZh: (s.stationNameZh as String?) ?? '',
              nameEn: (s.stationNameEn as String?) ?? '',
              latitude: s.positionLat,
              longitude: s.positionLon,
              groupId: s.stationGroupID as String?,
            ))
        .toList();
  }

  /// 捷運站（`MRTStation.toJson()` 的結果）→ 地圖用結果。
  List<NearbyStationResult> metroResults(List<dynamic> jsonList) {
    return _build(NearbyStationType.metro, jsonList, (raw) {
      if (raw is! Map) return null;
      final name = _asMap(raw['StationName']);
      final pos = _asMap(raw['StationPosition']);
      return _Parsed(
        id: raw['StationID']?.toString(),
        nameZh: name?['Zh_tw']?.toString(),
        nameEn: name?['En']?.toString(),
        lat: _toDouble(pos?['PositionLat']),
        lon: _toDouble(pos?['PositionLon']),
      );
    });
  }

  /// 臺鐵站（資料庫列，名稱與座標為 JSON 字串）→ 地圖用結果。
  List<NearbyStationResult> trainResults(List<dynamic> rows) {
    return _build(NearbyStationType.train, rows, (raw) {
      if (raw is! Map) return null;
      final name = _asMap(raw['StationName']);
      final pos = _asMap(raw['StationPosition']);
      return _Parsed(
        id: raw['StationID']?.toString(),
        nameZh: name?['Zh_tw']?.toString(),
        nameEn: name?['En']?.toString(),
        lat: _toDouble(pos?['PositionLat']),
        lon: _toDouble(pos?['PositionLon']),
      );
    });
  }

  List<NearbyStationResult> _build(
    NearbyStationType type,
    List<dynamic> raws,
    _Parsed? Function(dynamic raw) parse,
  ) {
    final seen = <String>{};
    final out = <NearbyStationResult>[];
    for (final raw in raws) {
      _Parsed? p;
      try {
        p = parse(raw);
      } catch (_) {
        p = null; // 格式錯誤的單筆資料直接略過。
      }
      if (p == null) continue;
      final id = p.id;
      if (id == null || id.isEmpty) continue;
      if (!isValidCoordinate(p.lat, p.lon)) continue;
      if (!seen.add(id)) continue;
      out.add(NearbyStationResult(
        id: id,
        type: type,
        nameZh: (p.nameZh == null || p.nameZh!.isEmpty) ? 'Unknown' : p.nameZh!,
        nameEn: p.nameEn ?? '',
        latitude: p.lat!,
        longitude: p.lon!,
      ));
    }
    return out;
  }

  static Map<dynamic, dynamic>? _asMap(dynamic value) {
    if (value is Map) return value;
    if (value is String && value.isNotEmpty) {
      final decoded = json.decode(value);
      if (decoded is Map) return decoded;
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _Parsed {
  const _Parsed({
    this.id,
    this.nameZh,
    this.nameEn,
    this.lat,
    this.lon,
  });
  final String? id;
  final String? nameZh;
  final String? nameEn;
  final double? lat;
  final double? lon;
}
