class Station {
  final String stationUID;
  final String stationID;
  final String stationNameZh;
  final String stationNameEn;
  final double positionLon;
  final double positionLat;
  final String geoHash;
  final String stationGroupID;
  final List<Stop> stops;
  final String locationCityCode;
  final String bearing;
  final DateTime updateTime;
  final int versionID;

  Station({
    required this.stationUID,
    required this.stationID,
    required this.stationNameZh,
    this.stationNameEn = '',
    required this.positionLon,
    required this.positionLat,
    required this.geoHash,
    required this.stationGroupID,
    required this.stops,
    required this.locationCityCode,
    required this.bearing,
    required this.updateTime,
    required this.versionID,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationUID: json['StationUID'] ?? '', // 如果为空，使用默认空字符串
      stationID: json['StationID'] ?? '', // 如果为空，使用默认空字符串
      stationNameEn: json['StationName']?['En'] ?? '',
      stationNameZh: json['StationName']?['Zh_tw'] ?? '', // 如果为空，使用默认空字符串
      positionLon:
          json['StationPosition']?['PositionLon']?.toDouble() ?? 0.0, // 处理 null
      positionLat:
          json['StationPosition']?['PositionLat']?.toDouble() ?? 0.0, // 处理 null
      geoHash: json['StationPosition']?['GeoHash'] ?? '', // 处理 null
      stationGroupID: json['StationGroupID'] ?? '', // 如果为空，使用默认空字符串
      stops: (json['Stops'] as List<dynamic>?)
              ?.map((stop) => Stop.fromJson(stop))
              .toList() ??
          [], // 处理 null，默认空列表
      locationCityCode: json['LocationCityCode'] ?? '', // 如果为空，使用默认空字符串
      bearing: json['Bearing'] ?? '', // 如果为空，使用默认空字符串
      updateTime: json['UpdateTime'] != null
          ? DateTime.parse(json['UpdateTime'])
          : DateTime.now(), // 如果为空，使用当前时间
      versionID: json['VersionID'] ?? 0, // 如果为空，使用默认值 0
    );
  }
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
}

class Stop {
  final String stopUID;
  final String stopID;
  final String stopNameZh;
  final String routeUID;
  final String routeID;
  final String routeNameZh;

  Stop({
    required this.stopUID,
    required this.stopID,
    required this.stopNameZh,
    required this.routeUID,
    required this.routeID,
    required this.routeNameZh,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      stopUID: json['StopUID'],
      stopID: json['StopID'],
      stopNameZh: json['StopName']['Zh_tw'],
      routeUID: json['RouteUID'],
      routeID: json['RouteID'],
      routeNameZh: json['RouteName']['Zh_tw'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "StopUID": stopUID,
      "StopID": stopID,
      "StopName": stopNameZh,
      "RouteUID": routeUID,
      "RouteID": routeID,
    };
  }

  @override
  String toString() {
    return '路線名稱: $routeNameZh, 路線 ID: $routeID, 站名: $stopNameZh, 站點 ID: $stopID';
  }
}
