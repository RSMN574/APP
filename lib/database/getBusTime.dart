import 'dart:convert'; // 用于 JSON 解码
import 'dart:io'; // 用于文件读写
import 'package:http/http.dart' as http;

import 'getData.dart'; // 用于网络请求
Future<void> fetchBusTime(routeId) async {
  int routeID=routeId;
  int top=0;
  var url="https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Taichung/$routeID?%24filter=RouteID%20eq%20%27$routeID%27&%24top=$top&%24format=JSON";

  try {
    // 读取本地 token.txt 文件
    await  connMysql();
    final accessToken = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJER2lKNFE5bFg4WldFajlNNEE2amFVNm9JOGJVQ3RYWGV6OFdZVzh3ZkhrIn0.eyJleHAiOjE3MjY2NzMxNjIsImlhdCI6MTcyNjU4Njc2MiwianRpIjoiY2RiNGFmMDgtNzQ2Zi00YTJiLTg3OTUtNDA0YWU5N2JmMjk3IiwiaXNzIjoiaHR0cHM6Ly90ZHgudHJhbnNwb3J0ZGF0YS50dy9hdXRoL3JlYWxtcy9URFhDb25uZWN0Iiwic3ViIjoiNTMxNGUwMjEtOGE5YS00MzVhLTg4OWEtM2EzNDg2ZjM1ODQ3IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoibmlja2tvb2wwMzE5LTE1MDIyMjM4LTY0YzgtNGFkNiIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsic3RhdGlzdGljIiwicHJlbWl1bSIsInBhcmtpbmdGZWUiLCJtYWFzIiwiYWR2YW5jZWQiLCJnZW9pbmZvIiwidmFsaWRhdG9yIiwidG91cmlzbSIsImhpc3RvcmljYWwiLCJiYXNpYyIsIm1hYXMteW94aSJdfSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwidXNlciI6ImNhNjNiNzc2In0.qPC4cqxQqQBaDpFY0nJCc9LgEIp7JHPZqqbrjsPUspOqCjCGUqS9tG547kf5OEiqkfseQoCmmTkezXJsl199tLMnz5nWTivAOR7T2NlJ0M_JhB05xob7XRDSZRpnzzMqo4BF4obsYlmYGqDhutCXoG_ZBsYUtUksEuh8QV3tK45WhnCpe4e0bXoieHANC4Z_ZCKZgq0yD9JuBlEYUv7sTsLe2Xq9EOb0Sr6PxsBXzSQQZKa4XCEQE_o6AVF-m3UyIEXtcqWkFrkW9Vzm1iwzTuE3u4-y1vgjST9GyMDpTrPQkUdzKisjjoQyfVEvec5YVq6PTY02IkZxEIT7Vs4NWQ";
    // 发起 GET 请求
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    );

    // 检查响应状态
    if (response.statusCode != 200) {
      throw HttpException('HTTP error! status: ${response.statusCode}');
    }

    // 解析 JSON 数据
    final jsonData = jsonDecode(response.body);

    // TODO: 将解析后的 JSON 数据转换为 SQL 插入语句
    // 这里你可以根据你的需求来构建 SQL 语句，例如：
    // String sql = 'INSERT INTO $tableName (...) VALUES (...)';

    print('JSON fetched successfully: $jsonData');
  } catch (e) {
    print('Error occurred: $e');
  }
}