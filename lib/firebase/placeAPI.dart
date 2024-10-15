import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  final String apiKey = 'AIzaSyB2rwLvaJa9EC52izD0DXJLiJK2EW-6LjI';

  Future<List<dynamic>> getPlaceAutocomplete(String input) async {
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': apiKey,
        'components': 'country:tw'
      },
    );

    final http.Response response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'OK') {
        for(var i in data['predictions']){
          print(i);
        }
        return data['predictions'];

      } else {
        throw Exception('Error fetching place autocomplete: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch place autocomplete');
    }
  }
}
