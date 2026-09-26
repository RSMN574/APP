import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:com.rsmn574.app/database/token_manager.dart';
import 'package:http/http.dart' as http;

typedef TdxTokenLoader = Future<String?> Function();
typedef TdxTokenRefresher = Future<String?> Function();
typedef TdxClientFactory = http.Client Function();

class TdxRequestCancelledException implements Exception {
  const TdxRequestCancelledException();

  @override
  String toString() => 'TDX request was cancelled';
}

class TdxApiClient {
  static const String _baseUrl = 'tdx.transportdata.tw';

  TdxApiClient({
    TokenManager? tokenManager,
    TdxTokenLoader? loadToken,
    TdxTokenRefresher? refreshToken,
    TdxClientFactory? clientFactory,
    Duration timeout = const Duration(seconds: 20),
  })  : _tokenManager = tokenManager ?? TokenManager(),
        _loadToken = loadToken,
        _refreshToken = refreshToken,
        _clientFactory = clientFactory ?? http.Client.new,
        _timeout = timeout;

  final TokenManager _tokenManager;
  final TdxTokenLoader? _loadToken;
  final TdxTokenRefresher? _refreshToken;
  final TdxClientFactory _clientFactory;
  final Duration _timeout;

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    Future<void>? abortTrigger,
  }) async {
    final uri = Uri.https(_baseUrl, path, queryParams);
    final response = await getResponse(uri, abortTrigger: abortTrigger);
    return jsonDecode(response.body);
  }

  Future<http.Response> getResponse(
    Uri uri, {
    Future<void>? abortTrigger,
  }) {
    return getRaw(uri, abortTrigger: abortTrigger);
  }

  Future<http.Response> getRaw(
    Uri uri, {
    Map<String, String>? headers,
    Future<void>? abortTrigger,
  }) async {
    if (uri.scheme != 'https' || uri.host != _baseUrl) {
      throw ArgumentError.value(uri, 'uri', 'A secure TDX API URI is required');
    }

    var token = await (_loadToken?.call() ?? _tokenManager.getToken());
    final client = _clientFactory();

    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        if (token == null || token.isEmpty) {
          throw const HttpException('TDX token is unavailable');
        }

        final request = http.Request('GET', uri)
          ..headers.addAll({
            if (headers != null)
              for (final entry in headers.entries)
                if (entry.key.toLowerCase() != 'authorization' &&
                    entry.key.toLowerCase() != 'accept')
                  entry.key: entry.value,
            'Authorization': 'Bearer $token',
            'accept': 'application/json',
          });
        final response = await _send(
          client,
          request,
          abortTrigger: abortTrigger,
        );

        if (response.statusCode == 200) {
          return response;
        }

        if (response.statusCode == 401 && attempt == 0) {
          token = await (_refreshToken?.call() ?? _tokenManager.refreshToken());
          continue;
        }

        throw HttpException(
          'TDX API error: ${response.statusCode} - ${response.body}',
        );
      }
    } finally {
      client.close();
    }

    throw const HttpException('TDX API request failed after retry');
  }

  Future<http.Response> _send(
    http.Client client,
    http.Request request, {
    Future<void>? abortTrigger,
  }) async {
    final responseFuture =
        client.send(request).then<http.Response>(http.Response.fromStream);
    final futures = <Future<http.Response>>[responseFuture];
    if (abortTrigger != null) {
      futures.add(
        abortTrigger.then<http.Response>((_) {
          client.close();
          throw const TdxRequestCancelledException();
        }),
      );
    }

    try {
      return await Future.any(futures).timeout(_timeout);
    } on TimeoutException {
      client.close();
      throw TimeoutException('TDX request timed out after $_timeout');
    }
  }
}
