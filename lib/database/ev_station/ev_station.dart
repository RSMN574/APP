import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;

import '../../const/regular_const.dart';
import '../token_manager.dart';
Future<List<dynamic>> fetchConnectorLiveStatus(StationID) async {
  String filter = Uri.encodeComponent("StationID eq '$StationID'");
  var url = "https://tdx.transportdata.tw/api/basic/v1/EV/ConnectorLiveStatus/City/Taichung?\$filter=$filter&\$format=JSON";


  try {

    final token = await TokenManager().getToken();
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

    // 解析 JSON 数据
    List<dynamic> jsonData = await jsonDecode(response.body)["LiveStatuses"];
    print(jsonData);
    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');

    return [];
  }
}