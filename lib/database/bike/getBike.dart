import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../Const/regularConst.dart';
//取得動態指定[縣市]的公共自行車即時車位資料
Future <Map<String, dynamic>> getBikeAvailability(
    String city ,String stationID ) async {
  String encodedFilter = Uri.encodeComponent("StationID eq '$stationID'");
  final String url =
      'https://tdx.transportdata.tw/api/basic/v2/Bike/Availability/City/Taichung?%24filter=$encodedFilter&format=JSON';

  print(url);
        final tokenResponse = await http.get(tokenUri);
  final token=tokenResponse.body;
  // 发起 GET 请求
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }
  final List jsonData = json.decode(response.body) ;


  return jsonData[0];
}
