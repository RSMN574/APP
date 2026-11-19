import 'package:com.rsmn574.app/core/utils/convert.dart';
import 'package:com.rsmn574.app/database/get_data.dart';

import 'get_park.dart';

/// 停車場資料入口：整合 MySQL 靜態停車場資料與 TDX 即時剩餘車位。
class ParkingRepository {
  const ParkingRepository();

  Future<List<dynamic>> liveStatus(String city) => fetchParkLiveStatus(city);

  /// 指定縣市的路外停車場靜態資料（一般、國道、台鐵、高鐵四個來源合併）。
  ///
  /// 原本這 4 段 SQL 直接寫在 ParkingPage 裡；移到 Repository 後，
  /// 頁面不再知道資料表名稱與 SQL。查詢內容與合併順序維持不變。
  Future<List<Map<String, dynamic>>> offStreetCarParks(String cityCode) async {
    final regionCode = convertCityCode(cityCode);
    final results = await Future.wait([
      mysqlSelect('SELECT * FROM CarPark.OffStreetCarPark_$cityCode;'),
      mysqlSelect(
        'SELECT * FROM CarPark.OffStreetCarPark_Freeway WHERE CityCode="$regionCode";',
      ),
      mysqlSelect(
        'SELECT * FROM CarPark.OffStreetCarPark_TRA WHERE CityCode="$regionCode";',
      ),
      mysqlSelect(
        'SELECT * FROM CarPark.OffStreetCarPark_THSR WHERE CityCode="$regionCode";',
      ),
    ]);
    return [
      for (final rows in results)
        for (final row in rows) Map<String, dynamic>.from(row),
    ];
  }
}
