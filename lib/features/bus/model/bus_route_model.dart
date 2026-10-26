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

  const BusRoute({
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
    final hasSubRoutes = json['HasSubRoutes'];
    return BusRoute(
      // API 小駝峰 routeUid/routeId；DB 還原用 RouteUID/RouteID
      routeUID: _asString(json['routeUid'] ?? json['RouteUID']),
      routeID: _asString(json['routeId'] ?? json['RouteID']),
      hasSubRoutes: hasSubRoutes == true || hasSubRoutes == 'true',
      operators: _decodeList(json['Operators']),
      subRoutes: _decodeList(json['SubRoutes']),
      routeName: _decodeMap(json['RouteName']),
      departureStopNameZh: _asString(json['DepartureStopNameZh']),
      departureStopNameEn: _asString(json['DepartureStopNameEn']),
      destinationStopNameZh: _asString(json['DestinationStopNameZh']),
      destinationStopNameEn: _asString(json['DestinationStopNameEn']),
      ticketPriceDescriptionZh: _nullableString(
        json['TicketPriceDescriptionZh'],
      ),
      ticketPriceDescriptionEn: _nullableString(
        json['TicketPriceDescriptionEn'],
      ),
      routeMapImageUrl: _nullableString(json['RouteMapImageUrl']),
      city: _asString(json['City']),
      cityCode: _asString(json['CityCode']),
      updateTime: DateTime.tryParse(_asString(json['UpdateTime'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      versionID: _asInt(json['VersionID']),
    );
  }
  static Map<String, dynamic> _decodeMap(dynamic value) {
    final decoded = _decode(value);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
  }

  static List<Map<String, dynamic>> _decodeList(dynamic value) {
    final decoded = _decode(value);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static dynamic _decode(dynamic value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }

  static String _asString(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) => value?.toString();

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get routeCity => city.isEmpty || city == 'all' ? 'InterCity' : city;
  String get routeZh => _asString(routeName['Zh_tw']);
  String get departureStopZh => departureStopNameZh;
  String get destinationStopZh => destinationStopNameZh;
  String get routeId => routeID;
  bool get hasSubRoute => hasSubRoutes;
  String get routeEn => _asString(routeName['En']);
  String? get routeMapUrl => routeMapImageUrl;

  String get operatorName {
    if (operators.isEmpty) return '';
    final name = _decodeMap(operators.first['OperatorName']);
    return _asString(name['Zh_tw']);
  }

  String get firstBusTime =>
      subRoutes.isNotEmpty ? _asString(subRoutes.first['FirstBusTime']) : '';

  String get lastBusTime =>
      subRoutes.isNotEmpty ? _asString(subRoutes.first['LastBusTime']) : '';
}

class RouteName {
  final String zhTw;
  final String en;

  const RouteName({required this.zhTw, required this.en});

  factory RouteName.fromJson(Map<String, dynamic> json) {
    return RouteName(
      zhTw: BusRoute._asString(json['Zh_tw']),
      en: BusRoute._asString(json['En']),
    );
  }

  Map<String, dynamic> toJson() => {
        'Zh_tw': zhTw,
        'En': en,
      };
}
