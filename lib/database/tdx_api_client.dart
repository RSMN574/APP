import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/database/token_manager.dart';
import 'package:http/http.dart' as http;

class TdxApiClient {
  static const String _baseUrl = 'tdx.transportdata.tw';
  final TokenManager _tokenManager = TokenManager();

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.https(_baseUrl, path, queryParams);
    var token = await _tokenManager.getToken();

    for (var attempt = 0; attempt < 2; attempt++) {
      if (token == null || token.isEmpty) {
        throw const HttpException('TDX token is unavailable');
      }

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (response.statusCode == 401 && attempt == 0) {
        token = await _tokenManager.refreshToken();
        continue;
      }

      throw HttpException(
        'TDX API error: ${response.statusCode} - ${response.body}',
      );
    }

    throw const HttpException('TDX API request failed after retry');
  }
}
