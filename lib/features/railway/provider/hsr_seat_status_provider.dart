import 'package:flutter/foundation.dart';



import '../data/railway_repository.dart';
import '../model/hsr_seat_status_model.dart';
import '../services/hsr_seat_status_service.dart';

/// 高鐵座位狀態的狀態管理。
///
/// 用途：
/// - 讓多個 widget 共用同一份座位資料
/// - 提供 loading / error 狀態給 UI
class HsrSeatStatusProvider extends ChangeNotifier {
  /// 資料一律經由 [RailwayRepository] 取得。
  ///
  /// [service] 為測試注入點，會交給預設 Repository 使用。
  HsrSeatStatusProvider({
    RailwayRepository? repository,
    HsrSeatStatusService? service,
  }) : _repository =
            repository ?? RailwayRepository(hsrSeatStatusService: service);

  final RailwayRepository _repository;

  final Map<String, HsrOdSeatStatus> _byKey = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  String _key(String origin, String dest, DateTime date) {
    final d = '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '$origin|$dest|$d';
  }

  HsrOdSeatStatus? statusFor(
      String origin, String dest, DateTime date) {
    return _byKey[_key(origin, dest, date)];
  }

  bool isLoadingFor(String origin, String dest, DateTime date) {
    return _loading[_key(origin, dest, date)] ?? false;
  }

  String? errorFor(String origin, String dest, DateTime date) {
    return _errors[_key(origin, dest, date)];
  }

  Future<void> load({
    required String originStationId,
    required String destinationStationId,
    required DateTime date,
    bool forceRefresh = false,
  }) async {
    final key =
    _key(originStationId, destinationStationId, date);
    if (_loading[key] == true) return;

    _loading[key] = true;
    _errors[key] = null;
    notifyListeners();

    try {
      final data = await _repository.hsrSeatStatus(
        originStationId: originStationId,
        destinationStationId: destinationStationId,
        date: date,
        forceRefresh: forceRefresh,
      );
      _byKey[key] = data;
    } catch (e) {
      _errors[key] = e.toString();
      debugPrint('HsrSeatStatusProvider.load failed: $e');
    } finally {
      _loading[key] = false;
      notifyListeners();
    }
  }

  void clear() {
    _byKey.clear();
    _loading.clear();
    _errors.clear();
    notifyListeners();
  }
}