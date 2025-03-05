import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../Const/regularConst.dart';
//取得指定[國內機場]氣象資訊觀測資料
Future <List<dynamic>> getAirportMETAR(
    String location) async {

    const String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/METAR/Airport/rmq?%24format=JSON';
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


  return jsonData;
}
//取得指定[機場的即時航班]資料
Future <List<dynamic>> getAirportFIDS(
    String location) async {

  const String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/tpe?%24top=30&%24format=JSON';
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


  return jsonData;
}
Future <List<dynamic>> getAirportFIDSDeparture(
    String location) async {

  const String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/Departure/TPE?%24format=JSON';
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


  return jsonData;
}
Future <List<dynamic>> getAirportFIDSArrival(
    ) async {

  const String url =
      'https://tdx.transportdata.tw/api/basic/v2/Air/FIDS/Airport/Arrival/TPE?%24top=70&%24format=JSON';
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


  return jsonData;
}

