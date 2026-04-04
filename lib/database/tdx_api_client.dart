import 'dart:convert';
import 'dart:io';
import 'package:com.rsmn574.app/database/token_manager.dart';
import 'package:http/http.dart' as http;


class TdxApiClient {
  static const String _baseUrl = 'tdx.transportdata.tw';
  final TokenManager _tokenManager = TokenManager();

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    String? token = await _tokenManager.getToken();

    final uri = Uri.https(_baseUrl, path, queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token 過期，嘗試刷新
      await _tokenManager.refreshToken();
      return get(path, queryParams: queryParams); // 重試一次
    } else {
      throw HttpException('TDX API error: ${response.statusCode} - ${response.body}');
    }
  }
}