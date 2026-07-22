class MRTStation {
  String stationUID;
  String stationID;
  MRTStationName stationName;
  String stationNameZh;
  String stationAddress;
  bool bikeAllowOnHoliday;
  DateTime srcUpdateTime;
  DateTime updateTime;
  int versionID;
  StationPosition stationPosition;
  String locationCity;
  String locationCityCode;
  String locationTown;
  String locationTownCode;

  MRTStation({
    required this.stationUID,
    required this.stationID,
    required this.stationName,
    required this.stationNameZh,
    required this.stationAddress,
    required this.bikeAllowOnHoliday,
    required this.srcUpdateTime,
    required this.updateTime,
    required this.versionID,
    required this.stationPosition,
    required this.locationCity,
    required this.locationCityCode,
    required this.locationTown,
    required this.locationTownCode,
  });

  factory MRTStation.fromJson(Map<String, dynamic> json) {
    return MRTStation(
      stationUID: json['StationUID'],
      stationID: json['StationID'],
      stationName: MRTStationName.fromJson(json['StationName']),
      stationAddress: json['StationAddress'],
      bikeAllowOnHoliday: json['BikeAllowOnHoliday'],
      srcUpdateTime: DateTime.parse(json['SrcUpdateTime']),
      updateTime: DateTime.parse(json['UpdateTime']),
      versionID: json['VersionID'],
      stationPosition: StationPosition.fromJson(json['StationPosition']),
      locationCity: json['LocationCity'],
      locationCityCode: json['LocationCityCode'],
      locationTown: json['LocationTown'],
      locationTownCode: json['LocationTownCode'], stationNameZh:  json['StationName']?['Zh_tw'] ?? '',
    );
  }
  String get stationZh => stationNameZh;


  Map<String, dynamic> toJson() {
    return {
      'StationUID': stationUID,
      'StationID': stationID,
      'StationName': stationName.toJson(),
      'StationAddress': stationAddress,
      'BikeAllowOnHoliday': bikeAllowOnHoliday,
      'SrcUpdateTime': srcUpdateTime.toIso8601String(),
      'UpdateTime': updateTime.toIso8601String(),
      'VersionID': versionID,
      'StationPosition': stationPosition.toJson(),
      'LocationCity': locationCity,
      'LocationCityCode': locationCityCode,
      'LocationTown': locationTown,
      'LocationTownCode': locationTownCode,
    };
  }
}

class MRTStationName {
  String zhTw;
  String en;

  MRTStationName({required this.zhTw, required this.en});

  factory MRTStationName.fromJson(Map<String, dynamic> json) {
    return MRTStationName(
      zhTw: json['Zh_tw'],
      en: json['En'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Zh_tw': zhTw,
      'En': en,
    };
  }
}

class StationPosition {
  double positionLon;
  double positionLat;
  String geoHash;

  StationPosition({
    required this.positionLon,
    required this.positionLat,
    required this.geoHash,
  });

  factory StationPosition.fromJson(Map<String, dynamic> json) {
    return StationPosition(
      positionLon: json['PositionLon'],
      positionLat: json['PositionLat'],
      geoHash: json['GeoHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PositionLon': positionLon,
      'PositionLat': positionLat,
      'GeoHash': geoHash,
    };
  }
}
