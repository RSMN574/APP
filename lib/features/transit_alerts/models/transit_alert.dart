enum TransportType { bus, metro, tra, thsr, aviation, youbike, other }

enum AlertType {
  serviceDisruption,
  routeDetour,
  suspension,
  delay,
  scheduleChange,
  stationNotice,
  facilityNotice,
  weatherImpact,
  generalNotice,
}

enum AlertSeverity { info, minor, moderate, major, critical, unknown }

enum AlertStatus { upcoming, active, resolved, expired, unknown }

class TransitAlert {
  const TransitAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.transportType,
    required this.alertType,
    required this.severity,
    required this.affectedRoutes,
    required this.affectedStops,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.publishedAt,
    required this.updatedAt,
    required this.source,
    required this.sourceUrl,
    required this.status,
    this.rawData = const {},
  });

  factory TransitAlert.fromJson(Map<String, dynamic> json) {
    return TransitAlert(
      id: _string(json['id']) ?? '',
      title: _string(json['title']) ?? '',
      description: _string(json['description']) ?? '',
      transportType: _enumValue(
        json['transportType'],
        TransportType.values,
        TransportType.other,
      ),
      alertType: _enumValue(
        json['alertType'],
        AlertType.values,
        AlertType.generalNotice,
      ),
      severity: _enumValue(
        json['severity'],
        AlertSeverity.values,
        AlertSeverity.unknown,
      ),
      affectedRoutes: _stringList(json['affectedRoutes']),
      affectedStops: _stringList(json['affectedStops']),
      location: _string(json['location']),
      startTime: _dateTime(json['startTime']),
      endTime: _dateTime(json['endTime']),
      publishedAt: _dateTime(json['publishedAt']),
      updatedAt: _dateTime(json['updatedAt']),
      source: _string(json['source']) ?? '',
      sourceUrl: _string(json['sourceUrl']),
      status: _enumValue(
        json['status'],
        AlertStatus.values,
        AlertStatus.unknown,
      ),
      rawData: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String title;
  final String description;
  final TransportType transportType;
  final AlertType alertType;
  final AlertSeverity severity;
  final List<String> affectedRoutes;
  final List<String> affectedStops;
  final String? location;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final String source;
  final String? sourceUrl;
  final AlertStatus status;
  final Map<String, dynamic> rawData;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'transportType': transportType.name,
        'alertType': alertType.name,
        'severity': severity.name,
        'affectedRoutes': affectedRoutes,
        'affectedStops': affectedStops,
        'location': location,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'source': source,
        'sourceUrl': sourceUrl,
        'status': status.name,
        'rawData': rawData,
      };

  static String? _string(Object? value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map(_string)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _dateTime(Object? value) {
    if (value is DateTime) return value;
    final text = _string(value);
    return text == null ? null : DateTime.tryParse(text);
  }

  static T _enumValue<T extends Enum>(
    Object? value,
    List<T> values,
    T fallback,
  ) {
    final text = _string(value)?.toLowerCase();
    if (text == null) return fallback;
    for (final item in values) {
      if (item.name.toLowerCase() == text) return item;
    }
    return fallback;
  }
}
