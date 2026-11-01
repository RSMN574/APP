/// 一次載入的完整結果。
class BusStopInfoResult {
  final List<String> stationIds;
  final Map<String, List<Map<String, dynamic>>> stopsByStation;
  final DateTime fetchedAt;

  const BusStopInfoResult({
    required this.stationIds,
    required this.stopsByStation,
    required this.fetchedAt,
  });

  bool get isEmpty => stationIds.isEmpty || stopsByStation.isEmpty;

  bool get hasLiveData {
    for (final list in stopsByStation.values) {
      for (final s in list) {
        if (s['hasLiveData'] == true) return true;
      }
    }
    return false;
  }
}
