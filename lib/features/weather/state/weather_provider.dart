import 'package:com.rsmn574.app/features/common/state/request_cache.dart';
import 'package:com.rsmn574.app/features/weather/data/weather_repository.dart';
import 'package:flutter/foundation.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider({
    WeatherRepository? repository,
    Duration cacheTtl = const Duration(minutes: 5),
  })  : _repository = repository ?? const WeatherRepository(),
        _cache = RequestCache(ttl: cacheTtl);

  final WeatherRepository _repository;
  final RequestCache _cache;

  Future<WeatherRawData> rawFor(String cityName, {bool force = false}) {
    final key = 'raw:$cityName';
    final future =
        _cache.get(key, () => _repository.fetchRaw(cityName), force: force);
    future.then<void>((data) {
      if (data.forecast == null &&
          data.warnings == null &&
          data.earthquakes == null) {
        _cache.invalidate(key);
      }
    }, onError: (Object _) {});
    return future;
  }
}

