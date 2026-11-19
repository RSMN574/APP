import '../../../database/tdx_api_client.dart';
import '../models/transit_alert.dart';

abstract interface class TransitAlertAdapter {
  String get sourceName;
  Future<List<TransitAlert>> fetchAlerts();
}

abstract class UnconnectedTransitAlertAdapter implements TransitAlertAdapter {
  const UnconnectedTransitAlertAdapter();

  @override
  Future<List<TransitAlert>> fetchAlerts() async => const <TransitAlert>[];
}

abstract class TdxTransitAlertAdapter implements TransitAlertAdapter {
  TdxTransitAlertAdapter({
    TdxApiClient? client,
    required this.path,
    required this.transportType,
    required this.sourceName,
  }) : client = client ?? TdxApiClient();

  final TdxApiClient client;
  final String path;
  final TransportType transportType;
  @override
  final String sourceName;

  @override
  Future<List<TransitAlert>> fetchAlerts() async {
    final response = await client.get(
      path,
      queryParams: const {'\$top': '30', '\$format': 'JSON'},
    );
    // Bus / THSR 回傳陣列；Metro Alert 回傳 { ..., "Alerts": [...] } 物件。
    final items = response is Map ? response['Alerts'] : response;
    if (items is! List) {
      throw const FormatException('TDX alert response must contain a list');
    }
    final alerts = <TransitAlert>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('TDX alert item must be a JSON object');
      }
      alerts.add(mapAlert(item));
    }
    return alerts;
  }

  TransitAlert mapAlert(Map<String, dynamic> json);

  String? text(Object? value) {
    if (value is String) {
      final result = value.trim();
      return result.isEmpty ? null : result;
    }
    if (value is Map) {
      for (final key in const ['Zh_tw', 'zh-tw', 'zh_tw', 'Zh-TW', 'En']) {
        final valueForLocale = value[key];
        if (valueForLocale is String && valueForLocale.trim().isNotEmpty) {
          return valueForLocale.trim();
        }
      }
    }
    return value?.toString();
  }

  List<String> listText(Object? value) {
    if (value is Iterable) {
      return value.map(text).whereType<String>().toList(growable: false);
    }
    final valueText = text(value);
    return valueText == null ? const [] : [valueText];
  }

  DateTime? date(Object? value) {
    final parsed = DateTime.tryParse(text(value) ?? '');
    // TDX 以 0001-01-01 表示「未指定」，不可當成真實時間。
    if (parsed == null || parsed.year < 1900) return null;
    return parsed;
  }

  /// 讀取 TDX `Scope` 內的影響範圍，例如 Scope.Routes[].RouteName。
  List<String> scopeValues(
    Map<String, dynamic> json,
    List<String> scopeKeys,
    List<String> itemKeys,
  ) {
    final scope = json['Scope'];
    if (scope is! Map) return const [];
    final result = <String>[];
    for (final scopeKey in scopeKeys) {
      final entries = scope[scopeKey];
      if (entries is! List) continue;
      for (final entry in entries) {
        if (entry is! Map) continue;
        for (final itemKey in itemKeys) {
          final itemText = text(entry[itemKey]);
          if (itemText != null) {
            if (!result.contains(itemText)) result.add(itemText);
            break;
          }
        }
      }
    }
    return result;
  }

  List<String> affected(
    Map<String, dynamic> json, {
    required List<String> topLevelKeys,
    required List<String> scopeKeys,
    required List<String> itemKeys,
  }) {
    final topLevel = values(json, topLevelKeys);
    if (topLevel.isNotEmpty) return topLevel;
    return scopeValues(json, scopeKeys, itemKeys);
  }

  String value(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final result = text(json[key]);
      if (result != null) return result;
    }
    return '';
  }

  String? optional(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final result = text(json[key]);
      if (result != null) return result;
    }
    return null;
  }

  List<String> values(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final result = listText(json[key]);
      if (result.isNotEmpty) return result;
    }
    return const [];
  }

  TransitAlert buildAlert(
    Map<String, dynamic> json, {
    required String id,
    required String title,
    required String description,
    required AlertType alertType,
    required AlertSeverity severity,
    required List<String> routes,
    required List<String> stops,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    final status = endTime != null && endTime.isBefore(now)
        ? AlertStatus.expired
        : startTime != null && startTime.isAfter(now)
            ? AlertStatus.upcoming
            : AlertStatus.active;
    return TransitAlert(
      id: id,
      title: title,
      description: description,
      transportType: transportType,
      alertType: alertType,
      severity: severity,
      affectedRoutes: routes,
      affectedStops: stops,
      location: location,
      startTime: startTime,
      endTime: endTime,
      publishedAt: publishedAt,
      updatedAt: updatedAt,
      source: sourceName,
      sourceUrl: 'https://tdx.transportdata.tw$path',
      status: status,
      rawData: Map<String, dynamic>.from(json),
    );
  }

  AlertType alertType(Map<String, dynamic> json) {
    final alertValue = '${value(json, ['AlertType', 'Effect', 'Cause'])} '
            '${value(json, ['AlertSubType'])}'
        .toLowerCase();
    if (alertValue.contains('delay') || alertValue.contains('延誤')) {
      return AlertType.delay;
    }
    if (alertValue.contains('suspend') || alertValue.contains('停駛')) {
      return AlertType.suspension;
    }
    if (alertValue.contains('detour') || alertValue.contains('改道')) {
      return AlertType.routeDetour;
    }
    if (alertValue.contains('schedule') || alertValue.contains('班次')) {
      return AlertType.scheduleChange;
    }
    if (alertValue.contains('station') || alertValue.contains('車站')) {
      return AlertType.stationNotice;
    }
    if (alertValue.contains('facility') || alertValue.contains('設備')) {
      return AlertType.facilityNotice;
    }
    if (alertValue.contains('weather') || alertValue.contains('天候')) {
      return AlertType.weatherImpact;
    }
    if (alertValue.contains('disruption') || alertValue.contains('異常')) {
      return AlertType.serviceDisruption;
    }
    return AlertType.generalNotice;
  }

  AlertSeverity severity(Map<String, dynamic> json) {
    final value = valueOf(json, ['Severity', 'Impact', 'Effect']).toLowerCase();
    if (value.contains('critical') || value.contains('緊急')) {
      return AlertSeverity.critical;
    }
    if (value.contains('major') ||
        value.contains('severe') ||
        value.contains('重大')) {
      return AlertSeverity.major;
    }
    if (value.contains('moderate') || value.contains('中度')) {
      return AlertSeverity.moderate;
    }
    if (value.contains('minor') || value.contains('輕微')) {
      return AlertSeverity.minor;
    }
    if (value.contains('info') || value.contains('資訊')) {
      return AlertSeverity.info;
    }
    return AlertSeverity.unknown;
  }

  String valueOf(Map<String, dynamic> json, List<String> keys) =>
      value(json, keys);
}

class BusTransitAlertAdapter extends TdxTransitAlertAdapter {
  BusTransitAlertAdapter({super.client})
      : super(
          path: '/api/basic/v2/Bus/Alert/City/Taichung',
          transportType: TransportType.bus,
          sourceName: '台中市公車',
        );

  @override
  TransitAlert mapAlert(Map<String, dynamic> json) {
    final routes = affected(
      json,
      topLevelKeys: ['RouteID', 'RouteName'],
      scopeKeys: ['Routes', 'SubRoutes'],
      itemKeys: ['RouteName', 'SubRouteName', 'RouteID', 'SubRouteID'],
    );
    return buildAlert(
      json,
      id: value(json, ['AlertID', 'ID']),
      title: value(json, ['Title', 'AlertType', 'Effect']),
      description: value(json, ['Description', 'Cause', 'Effect']),
      alertType: alertType(json),
      severity: severity(json),
      routes: routes,
      stops: affected(
        json,
        topLevelKeys: ['StopID', 'StopName'],
        scopeKeys: ['Stops', 'Stations'],
        itemKeys: ['StopName', 'StationName', 'StopID', 'StationID'],
      ),
      location: optional(json, ['Road', 'Location']),
      startTime: date(json['StartTime']),
      endTime: date(json['EndTime']),
      publishedAt: date(json['PublishTime'] ?? json['SrcUpdateTime']),
      updatedAt: date(json['UpdateTime']),
    );
  }
}

class MetroTransitAlertAdapter extends TdxTransitAlertAdapter {
  MetroTransitAlertAdapter({super.client})
      : super(
          path: '/api/basic/v2/Rail/Metro/Alert/TYMC',
          transportType: TransportType.metro,
          sourceName: '桃園捷運',
        );

  @override
  TransitAlert mapAlert(Map<String, dynamic> json) {
    return buildAlert(
      json,
      id: value(json, ['AlertID', 'ID']),
      title: value(json, ['Title', 'Effect', 'AlertType']),
      description: value(json, ['Description', 'Reason', 'Effect']),
      alertType: alertType(json),
      severity: severity(json),
      routes: affected(
        json,
        topLevelKeys: ['LineID', 'LineName'],
        scopeKeys: ['Lines', 'Routes'],
        itemKeys: ['LineName', 'RouteName', 'LineID', 'RouteID'],
      ),
      stops: affected(
        json,
        topLevelKeys: ['StationID', 'StationName'],
        scopeKeys: ['Stations'],
        itemKeys: ['StationName', 'StationID'],
      ),
      location: optional(json, ['Location']),
      startTime: date(json['StartTime']),
      endTime: date(json['EndTime']),
      publishedAt: date(json['PublishTime'] ?? json['SrcUpdateTime']),
      updatedAt: date(json['UpdateTime']),
    );
  }
}

class ThsrTransitAlertAdapter extends TdxTransitAlertAdapter {
  ThsrTransitAlertAdapter({super.client})
      : super(
          path: '/api/basic/v2/Rail/THSR/AlertInfo',
          transportType: TransportType.thsr,
          sourceName: '高鐵',
        );

  @override
  TransitAlert mapAlert(Map<String, dynamic> json) {
    final start = date(json['StartTime'] ?? json['StartDate']);
    final end = date(json['EndTime'] ?? json['EndDate']);
    return buildAlert(
      json,
      id: value(json, ['AlertID', 'ID', 'UpdateTime', 'StartDate']),
      title: value(json, ['Title', 'Status', 'Description']),
      description: value(json, ['Description', 'Title', 'Status']),
      alertType: alertType(json),
      severity: severity(json),
      routes: values(json, ['TrainDates']),
      stops: values(json, ['StationID', 'StationName']),
      location: optional(json, ['Location']),
      startTime: start,
      endTime: end,
      publishedAt: date(json['PublishTime'] ?? json['UpdateTime']),
      updatedAt: date(json['UpdateTime']),
    );
  }
}

class TraTransitAlertAdapter extends UnconnectedTransitAlertAdapter {
  const TraTransitAlertAdapter();

  @override
  String get sourceName => '台鐵公告（尚未串接）';
}

class AviationTransitAlertAdapter extends UnconnectedTransitAlertAdapter {
  AviationTransitAlertAdapter();

  @override
  String get sourceName => '航空公告（尚未串接）';
}

class YoubikeTransitAlertAdapter extends UnconnectedTransitAlertAdapter {
  YoubikeTransitAlertAdapter();

  @override
  String get sourceName => 'YouBike 公告（尚未串接）';
}

class OtherTransitAlertAdapter extends UnconnectedTransitAlertAdapter {
  OtherTransitAlertAdapter();

  @override
  String get sourceName => '其他交通公告（尚未串接）';
}
