import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;

import 'getData.dart'; // 用于网络请求
Future<dynamic> fetchBusTime(routeName,city) async {
print(routeName);
  final tokenUri = Uri.parse('http://hidden.rsmn574.com:3920/token');

int id=await getInfo('routeID');
  int? top=  await getInfo('sum');
  //List BusInfo=await getInfo('routeInfo');
  var url="https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city/$routeName?%24filter=RouteID%20eq%20%27$id%27&%24top=$top&%24format=JSON";
print(url);
  try {

    await  connMysql();
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

    // 解析 JSON 数据
    final jsonData = await jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    print('JSON fetched successfully: $jsonData');
    return jsonData;
  } catch (e) {
    print('Error occurred: $e');
  }
}