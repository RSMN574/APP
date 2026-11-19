import 'package:flutter/foundation.dart';

import '../data/transit_alert_repository.dart';
import '../models/transit_alert.dart';

class TransitAlertProvider extends ChangeNotifier {
  TransitAlertProvider({TransitAlertRepository? repository})
      : _repository = repository ?? TransitAlertRepository();

  final TransitAlertRepository _repository;
  List<TransitAlert> _alerts = const [];
  Map<String, Object> _sourceErrors = const {};
  DateTime? _lastUpdated;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _disposed = false;
  Future<void>? _request;

  List<TransitAlert> get alerts => _alerts;
  Map<String, Object> get sourceErrors => _sourceErrors;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get hasSourceErrors => _sourceErrors.isNotEmpty;

  Future<void> load({bool force = false}) {
    if (_request != null) return _request!;
    if (_hasLoaded && !force) return Future.value();

    final request = _load();
    final trackedRequest = request.whenComplete(() => _request = null);
    _request = trackedRequest;
    return trackedRequest;
  }

  Future<void> _load() async {
    _setLoading(true);
    try {
      final result = await _repository.fetchAlerts();
      if (result.alerts.isNotEmpty || result.sourceErrors.isEmpty) {
        _alerts = _sort(result.alerts);
      }
      _sourceErrors = result.sourceErrors;
      _lastUpdated = result.updatedAt;
      _hasLoaded = true;
    } finally {
      _setLoading(false);
    }
  }

  List<TransitAlert> _sort(List<TransitAlert> alerts) {
    final sorted = [...alerts];
    sorted.sort((a, b) {
      final severity =
          _severityRank(b.severity).compareTo(_severityRank(a.severity));
      if (severity != 0) return severity;
      // rank 越高越優先（active > upcoming > resolved > expired）。
      final status = _statusRank(b.status).compareTo(_statusRank(a.status));
      if (status != 0) return status;
      final aTime = a.updatedAt ??
          a.publishedAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ??
          b.publishedAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  int _severityRank(AlertSeverity severity) => switch (severity) {
        AlertSeverity.critical => 5,
        AlertSeverity.major => 4,
        AlertSeverity.moderate => 3,
        AlertSeverity.minor => 2,
        AlertSeverity.info => 1,
        AlertSeverity.unknown => 0,
      };

  int _statusRank(AlertStatus status) => switch (status) {
        AlertStatus.active => 3,
        AlertStatus.upcoming => 2,
        AlertStatus.resolved => 1,
        AlertStatus.expired => 0,
        AlertStatus.unknown => 0,
      };

  void _setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
