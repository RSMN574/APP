import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/app_error_handler.dart';
import '../../../firebase/analytics_service.dart';
import '../../../firebase/performance_service.dart';
import '../data/bus_schedule_remote_data_source.dart';
import '../data/bus_schedule_repository.dart';
import '../model/bus_daily_timetable.dart';

enum BusScheduleStatus { idle, loading, loaded, empty, unsupported, error }

/// 公車每日班表頁面狀態。
class BusScheduleProvider extends ChangeNotifier {
  BusScheduleProvider({
    required this.city,
    required this.routeName,
    this.routeId,
    BusScheduleRepository? repository,
    DateTime Function()? clock,
  })  : _repository = repository ?? sharedRepository,
        _now = clock ?? DateTime.now;

  /// App 內共用一個 Repository，讓快取與請求去重跨頁面生效。
  static final BusScheduleRepository sharedRepository = BusScheduleRepository();

  final String city;
  final String routeName;
  final String? routeId;
  final BusScheduleRepository _repository;
  final DateTime Function() _now;

  BusScheduleStatus _status = BusScheduleStatus.idle;
  BusScheduleResult? _result;
  Object? _error;
  int _directionIndex = 0;
  int _stopIndex = 0;
  bool _disposed = false;
  int _requestId = 0;

  BusScheduleStatus get status => _status;
  Object? get error => _error;
  AppErrorCategory? get errorCategory =>
      _error == null ? null : AppErrorHandler.classify(_error!);
  BusScheduleResult? get result => _result;
  bool get isStale => _result?.isStale ?? false;

  List<BusDailyTimetable> get directions =>
      _result?.timetables.where((t) => t.hasAnyTime).toList() ?? const [];

  int get directionIndex =>
      directions.isEmpty ? 0 : _directionIndex.clamp(0, directions.length - 1);

  BusDailyTimetable? get selectedDirection =>
      directions.isEmpty ? null : directions[directionIndex];

  List<BusTimetableStop> get stops =>
      selectedDirection?.stops.where((s) => s.entries.isNotEmpty).toList() ??
      const [];

  int get stopIndex =>
      stops.isEmpty ? 0 : _stopIndex.clamp(0, stops.length - 1);

  BusTimetableStop? get selectedStop => stops.isEmpty ? null : stops[stopIndex];

  bool get isCitySupported => BusScheduleRemoteDataSource.isSupported(city);

  /// 資料的營運日不是今天（台灣時間）。
  bool get isOutdated {
    final busDate = selectedDirection?.busDate;
    if (busDate == null) return false;
    final tw = busDate.toUtc().add(const Duration(hours: 8));
    final today = _now().toUtc().add(const Duration(hours: 8));
    return tw.year != today.year ||
        tw.month != today.month ||
        tw.day != today.day;
  }

  /// 下一班（以目前台灣時間計算，含跨日班次）。
  BusTimetableEntry? get nextDeparture {
    final stop = selectedStop;
    if (stop == null || isOutdated) return null;
    final now = _now().toUtc().add(const Duration(hours: 8));
    final minutes = now.hour * 60 + now.minute;
    for (final entry in stop.entries) {
      if (entry.departure.minutesFromServiceDayStart >= minutes) return entry;
    }
    return null;
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (!isCitySupported) {
      _status = BusScheduleStatus.unsupported;
      _notify();
      return;
    }
    final requestId = ++_requestId;
    _status = BusScheduleStatus.loading;
    _error = null;
    _notify();

    AppErrorHandler.breadcrumb('bus_schedule load city=$city');
    try {
      final result = await AppPerformance.measure(
        traceName: AppTraces.busScheduleApi,
        attributes: {
          'city': BusScheduleRemoteDataSource.resolveCity(city) ?? 'unknown'
        },
        action: () => _repository.load(
          city: city,
          routeName: routeName,
          routeId: routeId,
          forceRefresh: forceRefresh,
        ),
      );
      if (_disposed || requestId != _requestId) return;
      _result = result;
      _status =
          result.isEmpty ? BusScheduleStatus.empty : BusScheduleStatus.loaded;
      if (result.isStale && result.staleReason is! String) {
        unawaited(AppErrorHandler.recordNonFatal(
          result.staleReason!,
          null,
          feature: 'bus_schedule',
          reason: 'served_stale_cache',
        ));
      }
    } catch (error, stack) {
      if (_disposed || requestId != _requestId) return;
      if (error is BusScheduleUnsupportedCityException) {
        _status = BusScheduleStatus.unsupported;
      } else {
        _error = error;
        _status = BusScheduleStatus.error;
        final category = AppErrorHandler.classify(error);
        unawaited(AppErrorHandler.recordNonFatal(error, stack,
            feature: 'bus_schedule'));
        unawaited(AppAnalytics.logApiError(
          api: 'bus_daily_timetable',
          category: category.name,
        ));
      }
    }
    _notify();
  }

  void selectDirection(int index) {
    if (index == _directionIndex) return;
    _directionIndex = index;
    _stopIndex = 0;
    _notify();
  }

  void selectStop(int index) {
    if (index == _stopIndex) return;
    _stopIndex = index;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
