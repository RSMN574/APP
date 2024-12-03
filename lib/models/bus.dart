import 'dart:convert';

class BusRoute {
  final int uid;
  final String routeUID;
  final String routeID;
  final bool hasSubRoutes;
  final List<Operator> operators;
  final String authorityID;
  final String providerID;
  final List<SubRoute> subRoutes;
  final int busRouteType;
  final RouteName routeName;
  final String departureStopNameZh;
  final String departureStopNameEn;
  final String destinationStopNameZh;
  final String destinationStopNameEn;
  final String? routeMapImageUrl;
  final String city;
  final String cityCode;
  final DateTime updateTime;
  final int versionID;

  BusRoute({
    required this.uid,
    required this.routeUID,
    required this.routeID,
    required this.hasSubRoutes,
    required this.operators,
    required this.authorityID,
    required this.providerID,
    required this.subRoutes,
    required this.busRouteType,
    required this.routeName,
    required this.departureStopNameZh,
    required this.departureStopNameEn,
    required this.destinationStopNameZh,
    required this.destinationStopNameEn,
    this.routeMapImageUrl,
    required this.city,
    required this.cityCode,
    required this.updateTime,
    required this.versionID,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      uid: json['UID'] as int,
      routeUID: json['RouteUID'] as String,
      routeID: json['RouteID'] as String,
      hasSubRoutes: json['HasSubRoutes'] == 1,
      operators: (jsonDecode(json['Operators']) as List)
          .map((op) => Operator.fromJson(op))
          .toList(),
      authorityID: json['AuthorityID'] as String,
      providerID: json['ProviderID'] as String,
      subRoutes: (jsonDecode(json['SubRoutes']) as List)
          .map((sr) => SubRoute.fromJson(sr))
          .toList(),
      busRouteType: json['BusRouteType'] as int,
      routeName: RouteName.fromJson(jsonDecode(json['RouteName'])),
      departureStopNameZh: json['DepartureStopNameZh'] as String,
      departureStopNameEn: json['DepartureStopNameEn'] as String,
      destinationStopNameZh: json['DestinationStopNameZh'] as String,
      destinationStopNameEn: json['DestinationStopNameEn'] as String,
      routeMapImageUrl: json['RouteMapImageUrl'] as String?,
      city: json['City'] as String,
      cityCode: json['CityCode'] as String,
      updateTime: DateTime.parse(json['UpdateTime'] as String),
      versionID: json['VersionID'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'UID': uid,
    'RouteUID': routeUID,
    'RouteID': routeID,
    'HasSubRoutes': hasSubRoutes ? 1 : 0,
    'Operators': jsonEncode(operators.map((op) => op.toJson()).toList()),
    'AuthorityID': authorityID,
    'ProviderID': providerID,
    'SubRoutes': jsonEncode(subRoutes.map((sr) => sr.toJson()).toList()),
    'BusRouteType': busRouteType,
    'RouteName': jsonEncode(routeName.toJson()),
    'DepartureStopNameZh': departureStopNameZh,
    'DepartureStopNameEn': departureStopNameEn,
    'DestinationStopNameZh': destinationStopNameZh,
    'DestinationStopNameEn': destinationStopNameEn,
    'RouteMapImageUrl': routeMapImageUrl,
    'City': city,
    'CityCode': cityCode,
    'UpdateTime': updateTime.toIso8601String(),
    'VersionID': versionID,
  };
}

class Operator {
  final String operatorID;
  final OperatorName operatorName;
  final String operatorCode;
  final String operatorNo;

  Operator({
    required this.operatorID,
    required this.operatorName,
    required this.operatorCode,
    required this.operatorNo,
  });

  factory Operator.fromJson(Map<String, dynamic> json) {
    return Operator(
      operatorID: json['OperatorID'] as String,
      operatorName: OperatorName.fromJson(json['OperatorName']),
      operatorCode: json['OperatorCode'] as String,
      operatorNo: json['OperatorNo'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'OperatorID': operatorID,
    'OperatorName': operatorName.toJson(),
    'OperatorCode': operatorCode,
    'OperatorNo': operatorNo,
  };
}

class OperatorName {
  final String zhTw;
  final String en;

  OperatorName({required this.zhTw, required this.en});

  factory OperatorName.fromJson(Map<String, dynamic> json) {
    return OperatorName(
      zhTw: json['Zh_tw'] as String,
      en: json['En'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'Zh_tw': zhTw,
    'En': en,
  };
}

class SubRoute {
  final String headsign;
  final int direction;
  final String subRouteID;
  final List<String> operatorIDs;
  final String subRouteUID;
  final RouteName subRouteName;

  SubRoute({
    required this.headsign,
    required this.direction,
    required this.subRouteID,
    required this.operatorIDs,
    required this.subRouteUID,
    required this.subRouteName,
  });

  factory SubRoute.fromJson(Map<String, dynamic> json) {
    return SubRoute(
      headsign: json['Headsign'] as String,
      direction: json['Direction'] as int,
      subRouteID: json['SubRouteID'] as String,
      operatorIDs: List<String>.from(json['OperatorIDs']),
      subRouteUID: json['SubRouteUID'] as String,
      subRouteName: RouteName.fromJson(json['SubRouteName']),
    );
  }

  Map<String, dynamic> toJson() => {
    'Headsign': headsign,
    'Direction': direction,
    'SubRouteID': subRouteID,
    'OperatorIDs': operatorIDs,
    'SubRouteUID': subRouteUID,
    'SubRouteName': subRouteName.toJson(),
  };
}

class RouteName {
  final String zhTw;
  final String en;

  RouteName({required this.zhTw, required this.en});

  factory RouteName.fromJson(Map<String, dynamic> json) {
    return RouteName(
      zhTw: json['Zh_tw'] as String,
      en: json['En'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'Zh_tw': zhTw,
    'En': en,
  };
}
