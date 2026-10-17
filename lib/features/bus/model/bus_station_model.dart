import 'dart:convert';

/// TDX Bus.bus_station 資料表模型
class BusStationInfo {
  final String uid;
  final String stationUID;
  final String stationID;
  final String stationNameZh;
  final String stationNameEn;

  final double positionLon;
  final double positionLat;
  final String stationGroupID;
  final List<BusStationStop> stops;
  final String locationCityCode;
  final dynamic bearing;
  final String updateTime;
  final String versionID;
  final String stationAddress;

  BusStationInfo({
    required this.uid,
    required this.stationUID,
    required this.stationID,

    required this.stationNameZh,
    this.stationNameEn = '',
    required this.positionLon,
    required this.positionLat,
    required this.stationGroupID,
    required this.stops,
    required this.locationCityCode,
    this.bearing,
    required this.updateTime,
    required this.versionID,
    required this.stationAddress,
  });
  @override
  String toString() {
    return 'Station(stationNameZh: $stationNameZh, stationID: $stationID,stationUID: $stationUID)';
  }
  Map<String, dynamic> toJson() {
    return {
      "stationUID": stationUID,
      "stationID": stationID,
      "stationNameZh": stationNameZh,
      "stationNameEn": stationNameEn,

      "positionLon": positionLon,
      "positionLat": positionLat,
      "stops": stops
    };
  }
  factory BusStationInfo.fromMap(Map<String, dynamic> map) {
    List<BusStationStop> parsedStops = [];
    final rawStops = map['Stops'];
    if (rawStops != null) {
      try {
        final List<dynamic> decodedList = (rawStops is String)
            ? (json.decode(rawStops) as List<dynamic>)
            : (rawStops as List<dynamic>);
        parsedStops = decodedList
            .whereType<Map<String, dynamic>>()
            .map((e) => BusStationStop.fromMap(e))
            .toList();
      } catch (_) {}
    }

    return BusStationInfo(
      uid: map['UID']?.toString() ?? '',
      stationUID: map['StationUID']?.toString() ?? '',
      stationID: map['StationID']?.toString() ?? '',
      stationNameEn: map['StationName']?['En'] ?? '',
      stationNameZh: map['StationName']?['Zh_tw'] ?? '', // 如果为空，使用默认空字符串
      positionLon:
      map['StationPosition']?['PositionLon']?.toDouble() ?? 0.0, // 处理 null
      positionLat:
      map['StationPosition']?['PositionLat']?.toDouble() ?? 0.0, // 处理 null
      stationGroupID: map['StationGroupID']?.toString() ?? '',
      stops: parsedStops,
      locationCityCode: map['LocationCityCode']?.toString() ?? '',
      bearing: map['Bearing'],
      updateTime: map['UpdateTime']?.toString() ?? '',
      versionID: map['VersionID']?.toString() ?? '',
      stationAddress: map['StationAddress']?.toString() ?? '',
    );
  }
}

/// bus_station.Stops JSON 陣列內單一站點路線項目
class BusStationStop {
  final String stopUID;
  final String stopID;
  final dynamic stopName;
  final String routeUID;
  final String routeID;
  final dynamic routeName;

  BusStationStop({
    required this.stopUID,
    required this.stopID,
    this.stopName,
    required this.routeUID,
    required this.routeID,
    this.routeName,
  });

  factory BusStationStop.fromMap(Map<String, dynamic> map) {
    return BusStationStop(
      stopUID: map['StopUID']?.toString() ?? '',
      stopID: map['StopID']?.toString() ?? '',
      stopName: map['StopName'],
      routeUID: map['RouteUID']?.toString() ?? '',
      routeID: map['RouteID']?.toString() ?? '',
      routeName: map['RouteName'],
    );
  }
}