import '../tdx_api_client.dart';
import 'dart:convert';

import '../../models/mrt_station.dart';
import '../get_data.dart';

Future<List<MRTStation>> getNearMRTStation(String location) async {
  final coordinates = Uri.decodeComponent(location).split(',');
  if (coordinates.length != 2) return [];

  final latitude = double.tryParse(coordinates[0]);
  final longitude = double.tryParse(coordinates[1]);
  if (latitude == null || longitude == null) return [];

  final rows = await mysqlSelect("SELECT * FROM MRT.MRT_Taichung_station;");
  final stations = <MRTStation>[];

  for (final row in rows ?? []) {
    final stationName = _decodeJsonMap(row['StationName']);
    final stationPosition = _decodeJsonMap(row['StationPosition']);
    final positionLat = _toDouble(stationPosition['PositionLat']);
    final positionLon = _toDouble(stationPosition['PositionLon']);
    if (positionLat == null || positionLon == null) continue;

    stations.add(
      MRTStation.fromJson({
        'StationUID': row['StationUID']?.toString() ?? '',
        'StationID': row['StationID']?.toString() ?? '',
        'StationName': {
          'Zh_tw': stationName['Zh_tw']?.toString() ??
              row['StationNameZh_tw']?.toString() ??
              '',
          'En': stationName['En']?.toString() ?? '',
        },
        'StationAddress': row['StationAddress']?.toString() ?? '',
        'BikeAllowOnHoliday':
            row['BikeAllowOnHoliday'] == true || row['BikeAllowOnHoliday'] == 1,
        'SrcUpdateTime': row['SrcUpdateTime']?.toString() ??
            DateTime.now().toIso8601String(),
        'UpdateTime':
            row['UpdateTime']?.toString() ?? DateTime.now().toIso8601String(),
        'VersionID': int.tryParse(row['VersionID']?.toString() ?? '') ?? 0,
        'StationPosition': {
          'PositionLat': positionLat,
          'PositionLon': positionLon,
          'GeoHash': stationPosition['GeoHash']?.toString() ?? '',
        },
        'LocationCity': row['LocationCity']?.toString() ?? '',
        'LocationCityCode': row['LocationCityCode']?.toString() ?? '',
        'LocationTown': row['LocationTown']?.toString() ?? '',
        'LocationTownCode': row['LocationTownCode']?.toString() ?? '',
      }),
    );
  }

  stations.sort((a, b) {
    final distanceA = _distance(
      latitude,
      longitude,
      a.stationPosition.positionLat,
      a.stationPosition.positionLon,
    );
    final distanceB = _distance(
      latitude,
      longitude,
      b.stationPosition.positionLat,
      b.stationPosition.positionLon,
    );
    return distanceA.compareTo(distanceB);
  });

  return stations.take(5).toList();
}

Map<String, dynamic> _decodeJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is String && value.isNotEmpty) {
    final decoded = json.decode(value);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  return {};
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

double _distance(double lat1, double lon1, double lat2, double lon2) {
  final latDiff = lat1 - lat2;
  final lonDiff = lon1 - lon2;
  return latDiff * latDiff + lonDiff * lonDiff;
}

// 捷運對應表
final Map<String, String> metroMap = {
  'TRTC': '臺北捷運',
  'TYMC': '桃園捷運',
  'TMRT': '臺中捷運',
  'NTMC': '新北捷運',
};

// 根據 city 生成捷運代碼列表
List<String> getMetroByCity(String city) {
  switch (city.toLowerCase()) {
    case 'taipei':
      return ['NTMC', 'TRTC']; // 台北市 → 新北捷運 + 台北捷運
    case 'taoyuan':
      return ['TYMC'];
    case 'taichung':
      return ['TMRT'];
    case 'newtaipei':
      return ['NTMC'];
    default:
      return [];
  }
}

// 取得捷運班距資料
Future<List<dynamic>> getNearMRTFrequency(String city) async {
  final metroCodes = getMetroByCity(city);
  final List<dynamic> allData = [];

  // 假設 tokenUri 已經定義好
  // 逐個捷運代碼抓取資料
  for (final code in metroCodes) {
    final url =
        'https://tdx.transportdata.tw/api/basic/v2/Rail/Metro/Frequency/$code?%24format=JSON';

    final response = await TdxApiClient().getRaw(
      Uri.parse(url),
      headers: {
        'accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      print('Warning: HTTP error for $code: ${response.statusCode}');
      continue;
    }

    final List rawData = json.decode(response.body);
    allData.addAll(rawData);
  }

  return allData;
}
