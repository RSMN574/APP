import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getDirections(
    String origin, String destination) async {
  final String apiKey = 'AIzaSyB2rwLvaJa9EC52izD0DXJLiJK2EW-6LjI';
  final String url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';
print(url);
  var response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load directions');
  }
}
