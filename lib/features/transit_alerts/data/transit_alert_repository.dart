import '../models/transit_alert.dart';
import 'transit_alert_adapters.dart';
import 'transit_alert_service.dart';

class TransitAlertFetchResult {
  const TransitAlertFetchResult({
    required this.alerts,
    required this.sourceErrors,
    required this.updatedAt,
  });

  final List<TransitAlert> alerts;
  final Map<String, Object> sourceErrors;
  final DateTime updatedAt;
}

class TransitAlertRepository {
  TransitAlertRepository({
    List<TransitAlertAdapter>? adapters,
    TransitAlertService? service,
  }) : adapters = adapters ?? _adaptersFrom(service);

  final List<TransitAlertAdapter> adapters;

  static List<TransitAlertAdapter> _adaptersFrom(
    TransitAlertService? service,
  ) {
    final resolvedService = service ?? TransitAlertService();
    return resolvedService.adapters;
  }

  Future<TransitAlertFetchResult> fetchAlerts() async {
    final results = await Future.wait(
      adapters.map((adapter) async {
        try {
          return (
            alerts: await adapter.fetchAlerts(),
            error: null as Object?,
            source: adapter.sourceName,
          );
        } catch (error) {
          return (
            alerts: const <TransitAlert>[],
            error: error,
            source: adapter.sourceName,
          );
        }
      }),
    );

    final byId = <String, TransitAlert>{};
    final errors = <String, Object>{};
    for (final result in results) {
      if (result.error != null) errors[result.source] = result.error!;
      for (final alert in result.alerts) {
        if (alert.id.isNotEmpty) byId[alert.id] = alert;
      }
    }

    return TransitAlertFetchResult(
      alerts: byId.values.toList(growable: false),
      sourceErrors: errors,
      updatedAt: DateTime.now(),
    );
  }
}
