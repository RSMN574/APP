import 'dart:convert';

class BusRoute {
  final String routeUID;
  final String routeID;
  final bool hasSubRoutes;

  final List<Map<String, dynamic>> operators;
  final List<Map<String, dynamic>> subRoutes;
  final Map<String, dynamic> routeName;

  final String departureStopNameZh;
  final String departureStopNameEn;
  final String destinationStopNameZh;
  final String destinationStopNameEn;

  final String? ticketPriceDescriptionZh;
  final String? ticketPriceDescriptionEn;
  final String? routeMapImageUrl;

  final String city;
  final String cityCode;

  final DateTime updateTime;
  final int versionID;

  BusRoute({
    required this.routeUID,
    required this.routeID,
    required this.hasSubRoutes,
    required this.operators,
    required this.subRoutes,
    required this.routeName,
    required this.departureStopNameZh,
    required this.departureStopNameEn,
    required this.destinationStopNameZh,
    required this.destinationStopNameEn,
    this.ticketPriceDescriptionZh,
    this.ticketPriceDescriptionEn,
    this.routeMapImageUrl,
    required this.city,
    required this.cityCode,
    required this.updateTime,
    required this.versionID,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      routeUID: json['RouteUID'] ?? '',
      routeID: json['RouteID'] ?? '',
      hasSubRoutes:
      json['HasSubRoutes'] == true ||
          json['HasSubRoutes'] == 'true',

      operators: List<Map<String, dynamic>>.from(
        jsonDecode(json['Operators']),
      ),
      subRoutes: List<Map<String, dynamic>>.from(
        jsonDecode( json['SubRoutes'] )?? [],
      ),

      routeName: Map<String, dynamic>.from(
        jsonDecode( json['RouteName'] )?? {},
      ),

      departureStopNameZh: json['DepartureStopNameZh'] ?? '',
      departureStopNameEn: json['DepartureStopNameEn'] ?? '',
      destinationStopNameZh: json['DestinationStopNameZh'] ?? '',
      destinationStopNameEn: json['DestinationStopNameEn'] ?? '',
      ticketPriceDescriptionZh: json['TicketPriceDescriptionZh'],
      ticketPriceDescriptionEn: json['TicketPriceDescriptionEn'],
      routeMapImageUrl: json['RouteMapImageUrl'],
      city: json['City'] ?? '',
      cityCode: json['CityCode'] ?? '',
      updateTime: DateTime.parse(json['UpdateTime']),
      versionID: int.tryParse(json['VersionID'].toString()) ?? 0,
    );
  }
  String get routeCity => city;
  String get routeZh => routeName['Zh_tw'] ?? '';
  String get departureStopZh => departureStopNameZh;
  String get destinationStopZh => destinationStopNameZh;
  String get routeId => routeID;
  bool get hasSubRoute => hasSubRoutes;
  String get routeEn => routeName['En'] ?? '';
  String? get routeMapUrl => routeMapImageUrl;
  String get operatorName {
    if (operators.isEmpty) return '';

    final operatorName = operators.first['OperatorName'];

    if (operatorName is Map<String, dynamic>) {
      return operatorName['Zh_tw'] ?? '';
    }

    return '';
  }
  String get firstBusTime =>
      subRoutes.isNotEmpty
          ? subRoutes.first['FirstBusTime'] ?? ''
          : '';

  String get lastBusTime =>
      subRoutes.isNotEmpty
          ? subRoutes.first['LastBusTime'] ?? ''
          : '';
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
