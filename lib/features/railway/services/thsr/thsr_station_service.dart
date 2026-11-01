import 'dart:convert';

import 'package:com.rsmn574.app/database/get_data.dart';

/// 高鐵（THSR）車站服務：車站清單。
class ThsrStationService {
  const ThsrStationService();

  /// 取得全部高鐵車站（供車站選擇）。
  Future<List<Map<String, dynamic>>> fetchStations() async {
    final List stationData = await mysqlSelect(
        "SELECT StationID, StationName, StationPosition, URL FROM HSR.HSR_Station ORDER BY StationID;");

    return stationData.map<Map<String, dynamic>>((item) {
      final stationName = json.decode(item["StationName"]);
      return {
        'StationName': {
          'Zh_tw': stationName['Zh_tw'],
          'En': stationName['En'],
        },
        'StationID': item['StationID'],
        'StationPosition': item['StationPosition'],
        'URL': item['URL']
      };
    }).toList();
  }
}
