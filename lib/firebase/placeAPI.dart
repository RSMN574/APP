import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';

class PlacesService {
  final String apiKey = 'AIzaSyB2rwLvaJa9EC52izD0DXJLiJK2EW-6LjI';

  Future<List<dynamic>> getPlaceAutocomplete(String input,context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    print(locationProvider);
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': apiKey,
        'components': 'country:tw',
        'location': '${locationProvider.latitude},${locationProvider.longitude}', // 中心点坐标，例如台北市
        'radius': '5000', // 半径，单位为米
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
  Future<LatLng?> getLatLngFromPlaceId(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        } else {
          print('Error: ${data['status']}');
        }
      } else {
        print('Failed to fetch place details');
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

}
