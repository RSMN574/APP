import 'package:flutter/material.dart';

// ==========================================
// AirportData
// ==========================================
class AirportData {
  final String name;
  final String iataCode;
  final double area;
  final int terminals;
  final int annualPassengers;
  final String phone;
  final Color primaryColor;

  final List<TransportInfo> transport;
  final List<TransportRoute>? transportRoute;
  final List<ServiceInfo> services;
  final Map<String, String> emergencyContacts;

  AirportData({
    required this.name,
    required this.iataCode,
    required this.area,
    required this.terminals,
    required this.annualPassengers,
    required this.phone,
    required this.primaryColor,
    required this.transport,
    required this.services,
    required this.emergencyContacts,
    this.transportRoute,
  });

  factory AirportData.fromJson(Map<String, dynamic> json) {
    return AirportData(
      name: json['name'] as String? ?? '',
      iataCode: json['iataCode'] as String? ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0,
      terminals: (json['terminals'] as num?)?.toInt() ?? 0,
      annualPassengers:
      (json['annualPassengers'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      primaryColor: _colorFromHex(json['primaryColor'] as String?),
      transport: (json['transport'] as List<dynamic>? ?? [])
          .map((e) => TransportInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      transportRoute: json['transportRoute'] == null
          ? null
          : (json['transportRoute'] as List<dynamic>)
          .map((e) =>
          TransportRoute.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => ServiceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      emergencyContacts:
      (json['emergencyContacts'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'iataCode': iataCode,
    'area': area,
    'terminals': terminals,
    'annualPassengers': annualPassengers,
    'phone': phone,
    'primaryColor': _colorToHex(primaryColor),
    'transport': transport.map((e) => e.toJson()).toList(),
    'transportRoute': transportRoute?.map((e) => e.toJson()).toList(),
    'services': services.map((e) => e.toJson()).toList(),
    'emergencyContacts': emergencyContacts,
  };
}

// ==========================================
// TransportType
// ==========================================
enum TransportType { bus, train, hsr, mrt }

extension TransportTypeX on TransportType {
  static TransportType fromString(String? s) {
    return TransportType.values.firstWhere(
          (e) => e.name == s,
      orElse: () => TransportType.bus,
    );
  }
}

// ==========================================
// TransportRoute
// ==========================================
class TransportRoute {
  final TransportType type;
  final String routeId;
  final String name;
  final String? operator;
  final String? destination;
  final Color? color;
  final String? remark;

  TransportRoute({
    required this.type,
    required this.routeId,
    required this.name,
    this.operator,
    this.destination,
    this.color,
    this.remark,
  });

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    return TransportRoute(
      type: TransportTypeX.fromString(json['type'] as String?),
      routeId: json['routeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      operator: json['operator'] as String?,
      destination: json['destination'] as String?,
      color: json['color'] == null
          ? null
          : _colorFromHex(json['color'] as String?),
      remark: json['remark'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'routeId': routeId,
    'name': name,
    'operator': operator,
    'destination': destination,
    'color': color == null ? null : _colorToHex(color!),
    'remark': remark,
  };
}

// ==========================================
// TransportInfo
// ==========================================
class TransportInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  TransportInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  factory TransportInfo.fromJson(Map<String, dynamic> json) {
    return TransportInfo(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: _iconFromName(json['icon'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'icon': _iconToName(icon),
  };
}

// ==========================================
// ServiceInfo
// ==========================================
class ServiceInfo {
  final String label;
  final IconData icon;

  ServiceInfo({
    required this.label,
    required this.icon,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      label: json['label'] as String? ?? '',
      icon: _iconFromName(json['icon'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'icon': _iconToName(icon),
  };
}

// ==========================================
// 輔助函式：Color ↔ Hex
// ==========================================
Color _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.blue;
  final cleaned = hex.replaceAll('#', '').replaceAll('0x', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0xFF1A73E8;
  return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0')}';
}

// ==========================================
// 輔助函式：IconData ↔ 名稱
// ==========================================
const Map<String, IconData> _iconRegistry = {
  // 交通
  'train_rounded': Icons.train_rounded,
  'directions_bus_rounded': Icons.directions_bus_rounded,
  'local_taxi_rounded': Icons.local_taxi_rounded,
  'directions_car_rounded': Icons.directions_car_rounded,
  'pedal_bike_rounded': Icons.pedal_bike_rounded,
  'flight_rounded': Icons.flight_rounded,
  'subway_rounded': Icons.subway_rounded,

  // 服務設施
  'shopping_bag_rounded': Icons.shopping_bag_rounded,
  'star_rounded': Icons.star_rounded,
  'restaurant_rounded': Icons.restaurant_rounded,
  'wifi_rounded': Icons.wifi_rounded,
  'currency_exchange_rounded': Icons.currency_exchange_rounded,
  'luggage_rounded': Icons.luggage_rounded,
  'people_rounded': Icons.people_rounded,
  'child_care_rounded': Icons.child_care_rounded,
  'store_rounded': Icons.store_rounded,
  'visibility_rounded': Icons.visibility_rounded,

  // 備用
  'info': Icons.info,
  'phone': Icons.phone,
  'local_hospital': Icons.local_hospital,
};

IconData _iconFromName(String? name) {
  if (name == null) return Icons.info;
  return _iconRegistry[name] ?? Icons.info;
}

String _iconToName(IconData icon) {
  for (final entry in _iconRegistry.entries) {
    if (entry.value.codePoint == icon.codePoint &&
        entry.value.fontFamily == icon.fontFamily) {
      return entry.key;
    }
  }
  return 'info';
}