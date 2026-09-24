class YouBikeStation {
  final String stationUID;
  final String stationID;
  final String authorityID;
  final YouBikeStationName stationName;
  final YouBikeStationPosition stationPosition;
  final YouBikeStationAddress stationAddress;
  final int bikesCapacity;
  final int serviceType;
  final DateTime srcUpdateTime;
  final DateTime updateTime;

  YouBikeStation({
    required this.stationUID,
    required this.stationID,
    required this.authorityID,
    required this.stationName,
    required this.stationPosition,
    required this.stationAddress,
    required this.bikesCapacity,
    required this.serviceType,
    required this.srcUpdateTime,
    required this.updateTime,
  });

  factory YouBikeStation.fromJson(Map<String, dynamic> json) {
    return YouBikeStation(
      stationUID: json['StationUID']?.toString() ?? '',
      stationID: json['StationID']?.toString() ?? '',
      authorityID: json['AuthorityID']?.toString() ?? '',
      stationName: YouBikeStationName.fromJson(
        json['StationName'] ?? {},
      ),
      stationPosition: YouBikeStationPosition.fromJson(
        json['StationPosition'] ?? {},
      ),
      stationAddress: YouBikeStationAddress.fromJson(
        json['StationAddress'] ?? {},
      ),
      // MySQL drivers often return numeric columns as Strings.  Parse both
      // native numbers and numeric strings so loading the YouBike page does
      // not fail for an otherwise valid station row.
      bikesCapacity: _asInt(json['BikesCapacity']),
      serviceType: _asInt(json['ServiceType']),
      srcUpdateTime: DateTime.tryParse(
        json['SrcUpdateTime']?.toString() ?? '',
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updateTime: DateTime.tryParse(
        json['UpdateTime']?.toString() ?? '',
      ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'StationUID': stationUID,
      'StationID': stationID,
      'AuthorityID': authorityID,
      'StationName': stationName.toJson(),
      'StationPosition': stationPosition.toJson(),
      'StationAddress': stationAddress.toJson(),
      'BikesCapacity': bikesCapacity,
      'ServiceType': serviceType,
      'SrcUpdateTime': srcUpdateTime.toIso8601String(),
      'UpdateTime': updateTime.toIso8601String(),
    };
  }
}

class YouBikeStationName {
  final String en;
  final String zhTw;

  YouBikeStationName({
    required this.en,
    required this.zhTw,
  });

  factory YouBikeStationName.fromJson(Map<String, dynamic> json) {
    return YouBikeStationName(
      en: json['En']?.toString() ?? '',
      zhTw: json['Zh_tw']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'En': en,
      'Zh_tw': zhTw,
    };
  }
}

class YouBikeStationPosition {
  final String geoHash;
  final double positionLat;
  final double positionLon;

  YouBikeStationPosition({
    required this.geoHash,
    required this.positionLat,
    required this.positionLon,
  });

  factory YouBikeStationPosition.fromJson(Map<String, dynamic> json) {
    return YouBikeStationPosition(
      geoHash: json['GeoHash']?.toString() ?? '',
      positionLat: _asDouble(json['PositionLat']),
      positionLon: _asDouble(json['PositionLon']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'GeoHash': geoHash,
      'PositionLat': positionLat,
      'PositionLon': positionLon,
    };
  }
}

class YouBikeStationAddress {
  final String en;
  final String zhTw;

  YouBikeStationAddress({
    required this.en,
    required this.zhTw,
  });

  factory YouBikeStationAddress.fromJson(Map<String, dynamic> json) {
    return YouBikeStationAddress(
      en: json['En']?.toString() ?? '',
      zhTw: json['Zh_tw']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'En': en,
      'Zh_tw': zhTw,
    };
  }
}
