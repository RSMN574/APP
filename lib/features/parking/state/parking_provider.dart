import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/parking/data/parking_repository.dart';
import 'package:flutter/foundation.dart';

class ParkingProvider extends ChangeNotifier {
  ParkingProvider({
    ParkingRepository? repository,
    Duration cacheTtl = const Duration(seconds: 30),
  })  : _repository = repository ?? const ParkingRepository(),
        _cache = RequestCache(ttl: cacheTtl);

  final ParkingRepository _repository;
  final RequestCache _cache;

  Future<List<dynamic>> liveStatus(String city, {bool force = false}) =>
      _cache.get('live:$city', () => _repository.liveStatus(city),
          force: force);

  /// 靜態停車場資料；同縣市在快取期間內重複進入頁面不再重查 4 次 MySQL。
  Future<List<dynamic>> offStreetCarParks(String cityCode,
          {bool force = false}) =>
      _cache.get('static:$cityCode',
          () => _repository.offStreetCarParks(cityCode),
          force: force);

  void refresh() {
    _cache.invalidate();
    notifyListeners();
  }
}
