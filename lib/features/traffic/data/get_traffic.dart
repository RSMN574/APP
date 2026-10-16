import 'package:com.rsmn574.app/database/tdx_api_client.dart';
import 'dart:convert';
import 'dart:io';

Future<List<dynamic>> fetchFreewayRoadEvent() async {
  String url =
      "https://tdx.transportdata.tw/api/basic/v1/Traffic/RoadEvent/LiveEvent/Freeway?%24top=30&%24format=JSON";

  try {
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

    // 解析 JSON 数据
    List<dynamic> jsonData = await jsonDecode(response.body)["LiveEvents"];

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
    return [];
  }
}
