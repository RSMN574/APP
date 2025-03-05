import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';

class PlacesService {
  final String apiKey = 'AIzaSyB2rwLvaJa9EC52izD0DXJLiJK2EW-6LjI';

  Future<List> getPlaceAutocomplete(String input, context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    if (input.trim().isEmpty) {
      // 如果輸入是空的，直接返回空列表
      return [];
    }

    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': apiKey,
        'components': 'country:tw',
        // 'location': '${locationProvider.latitude},${locationProvider.longitude}', // 先拿掉
        // 'radius': '5000', // 先拿掉
      },
    );


    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('無法獲取地點建議 (HTTP ${response.statusCode})');
    }

    final Map<String, dynamic> data = json.decode(response.body);

    if (data['status'] != 'OK') {
      throw Exception('地點自動完成 API 錯誤: ${data['status']}');
    }

    List<dynamic> predictions = data['predictions'];

    // 計算每個地點與當前位置的距離，並排序
    List<Map<String, dynamic>> placesWithDistance = [];
    for (var prediction in predictions) {
      final placeId = prediction['place_id'];
      final detail = await _fetchPlaceDetail(placeId);

      if (detail != null) {
        final double distance = _calculateDistance(
          locationProvider.latitude,
          locationProvider.longitude,
          detail['lat'],
          detail['lng'],
        );
        placesWithDistance.add({
          'prediction': prediction,
          'distance': distance,
        });
      }
    }

    // 按距離排序，最近的排最前
    placesWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

    // 只返回經過處理的 prediction 陣列
    return placesWithDistance.map((e) => e['prediction']).toList();
  }

// 簡單距離計算 (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    double latDiff = (lat1 - lat2).abs();
    double lonDiff = (lon1 - lon2).abs();
    return latDiff + lonDiff; // 這只是簡單估算，數字越小代表越近
  }


// 取得地點的詳細資訊（主要是為了拿經緯度）
  Future<Map<String, dynamic>?> _fetchPlaceDetail(String placeId) async {
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'key': apiKey,
        'place_id': placeId,
        'fields': 'geometry',
        'language': 'zh-TW',
      },
    );

    final http.Response response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final Map<String, dynamic> data = json.decode(response.body);
    if (data['status'] != 'OK') return null;

    final location = data['result']['geometry']['location'];
    return {
      'lat': location['lat'],
      'lng': location['lng'],
    };
  }

// 生成Session Token
  String _getSessionToken() {
    return DateTime.now().millisecondsSinceEpoch.toString();
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
