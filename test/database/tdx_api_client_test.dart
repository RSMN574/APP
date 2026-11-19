import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:com.rsmn574.app/database/tdx_api_client.dart';

void main() {
  test('sends the loaded token as a bearer authorization header', () async {
    late http.BaseRequest request;
    final client = MockClient((incoming) async {
      request = incoming;
      return http.Response(jsonEncode({'ok': true}), 200);
    });

    final api = TdxApiClient(
      loadToken: () async => 'test-token',
      clientFactory: () => client,
    );

    final result = await api.get('/api/basic/v2/Bus/Route');

    expect(result, isA<Map<String, dynamic>>());
    expect(request.headers['authorization'], 'Bearer test-token');
    expect(request.headers['accept'], 'application/json');
  });
}
