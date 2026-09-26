import '../tdx_api_client.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

//取得指定[國內機場]氣象資訊觀測資料
Future<List<dynamic>> getAirportMETAR(String location) async {
  const String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/METAR/Airport/rmq?%24format=JSON';
  // 发起 GET 请求
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }
  final List jsonData = json.decode(response.body);

  return jsonData;
}

//取得指定[機場的即時航班]資料
Future<List<dynamic>> getAirportFIDS(String location) async {
  const String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/tpe?%24top=30&%24format=JSON';
  // 发起 GET 请求
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }
  final List jsonData = json.decode(response.body);

  return jsonData;
}

Future<List<dynamic>> getAirportFIDSDeparture(String airport) async {
  final String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/Departure/$airport?%24top=70&%24format=JSON';
  // 发起 GET 请求
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }
  final List jsonData = json.decode(response.body);

  return jsonData;
}

Future<List<dynamic>> getAirportFIDSArrival(String airport) async {
  final String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/Arrival/$airport?%24top=70&%24format=JSON';
  // 发起 GET 请求
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }
  final List jsonData = json.decode(response.body);

  return jsonData;
}

//取得指定[即時航班]資料
Future<List<dynamic>> getFlight(String airlineId, String flightNumber) async {
// 先處理 filter 字串（未編碼）
  final String filterRaw = "AirlineID eq '$airlineId'";

// 用 Dart 內建的方法編碼
  final String encodedFilter = Uri.encodeQueryComponent(filterRaw);
// 結果會是：AirlineID%20eq%20%27BR%27

// 組成完整 URL
  final String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Flight/$flightNumber?\$filter=$encodedFilter&\$format=JSON';
  // 发起 GET 请求
  final response = await TdxApiClient().getRaw(
    Uri.parse(url),
    headers: {
      'accept': 'application/json',
    },
  );

  // 检查响应状态
  if (response.statusCode != 200) {
    throw HttpException('HTTP error! status: ${response.statusCode}');
  }
  final List jsonData = json.decode(response.body);

  return jsonData;
}

class AirportService {
  static const String apiUrl =
      "https://hidden.rsmn574.com:3920/token/data/airports.json";

  static Future<Map<String, dynamic>> loadAirportData(String code) async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data[code] ?? {};
    } else {
      throw Exception("Failed to load airport data");
    }
  }
}
