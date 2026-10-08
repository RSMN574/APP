import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../const/regular_class.dart';
import '../utils/convert.dart';

class PlaceRequestCancelledException implements Exception {
  const PlaceRequestCancelledException();

  @override
  String toString() => 'Place request was cancelled';
}

class PlacesService {
  static const _requestTimeout = Duration(seconds: 12);

  String get apiKey => AppConfig.placesApiKey;

  Future<List<dynamic>> getPlaceAutocomplete(
    String input,
    BuildContext context, {
    Future<void>? abortTrigger,
  }) async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (input.trim().isEmpty) return [];

    final sessionToken = _getSessionToken();
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input.trim(),
        'key': apiKey,
        'components': 'country:tw',
        'sessiontoken': sessionToken,
      },
    );
    final client = http.Client();

    try {
      final response = await _send(
        client,
        http.Request('GET', uri),
        abortTrigger: abortTrigger,
      );
      if (response.statusCode != 200) {
        throw Exception('無法獲取地點建議 (HTTP ${response.statusCode})');
      }

      final data = _decodeObject(response.body);
      final status = data['status'];
      if (status == 'ZERO_RESULTS') return [];
      if (status != 'OK') {
        throw Exception('地點自動完成 API 錯誤: $status');
      }

      final rawPredictions = data['predictions'];
      if (rawPredictions is! List) {
        throw const FormatException('Autocomplete predictions must be a list');
      }
      final predictions = rawPredictions
          .whereType<Map>()
          .map((prediction) => Map<String, dynamic>.from(prediction))
          .toList(growable: false);

      final placesWithDistance = await Future.wait(
        predictions.map((prediction) async {
          final placeId = prediction['place_id']?.toString();
          if (placeId == null || placeId.isEmpty) return null;
          final location = await _fetchPlaceDetail(
            client,
            placeId,
            sessionToken,
            abortTrigger,
          );
          if (location == null) return null;
          return _PlaceWithDistance(
            prediction,
            calculateApproxDistance(
              locationProvider.latitude,
              locationProvider.longitude,
              location.latitude,
              location.longitude,
            ),
          );
        }),
      );

      final validPlaces = placesWithDistance
          .whereType<_PlaceWithDistance>()
          .toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));
      return validPlaces.map((place) => place.prediction).toList();
    } finally {
      client.close();
    }
  }

  Future<_PlaceLocation?> _fetchPlaceDetail(
    http.Client client,
    String placeId,
    String sessionToken,
    Future<void>? abortTrigger,
  ) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'key': apiKey,
        'place_id': placeId,
        'fields': 'geometry',
        'language': 'zh-TW',
        'sessiontoken': sessionToken,
      },
    );
    final response = await _send(
      client,
      http.Request('GET', uri),
      abortTrigger: abortTrigger,
    );
    if (response.statusCode != 200) {
      throw Exception('無法獲取地點詳細資訊 (HTTP ${response.statusCode})');
    }

    final data = _decodeObject(response.body);
    if (data['status'] != 'OK') {
      if (data['status'] == 'NOT_FOUND') return null;
      throw Exception('地點詳細資訊 API 錯誤: ${data['status']}');
    }

    final result = data['result'];
    final geometry = result is Map ? result['geometry'] : null;
    final location = geometry is Map ? geometry['location'] : null;
    if (location is! Map ||
        location['lat'] is! num ||
        location['lng'] is! num) {
      throw const FormatException('Place details response has no coordinates');
    }
    return _PlaceLocation(
      (location['lat'] as num).toDouble(),
      (location['lng'] as num).toDouble(),
    );
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
          throw const PlaceRequestCancelledException();
        }),
      );
    }

    try {
      return await Future.any(futures).timeout(_requestTimeout);
    } on TimeoutException {
      client.close();
      throw TimeoutException(
        'Place request timed out after $_requestTimeout',
      );
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = json.decode(body);
    if (decoded is! Map) {
      throw const FormatException('Places API response must be an object');
    }
    return Map<String, dynamic>.from(decoded);
  }

  String _getSessionToken() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<LatLng?> getLatLngFromPlaceId(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': apiKey,
        'fields': 'geometry',
        'language': 'zh-TW',
      },
    );

    final client = http.Client();
    try {
      final response = await _send(client, http.Request('GET', uri));
      if (response.statusCode != 200) {
        throw Exception('無法獲取地點詳細資訊 (HTTP ${response.statusCode})');
      }
      final data = _decodeObject(response.body);
      if (data['status'] != 'OK') {
        throw Exception('地點詳細資訊 API 錯誤: ${data['status']}');
      }
      final result = data['result'];
      final geometry = result is Map ? result['geometry'] : null;
      final location = geometry is Map ? geometry['location'] : null;
      if (location is! Map ||
          location['lat'] is! num ||
          location['lng'] is! num) {
        throw const FormatException(
            'Place details response has no coordinates');
      }
      return LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );
    } finally {
      client.close();
    }
  }
}

class _PlaceLocation {
  const _PlaceLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class _PlaceWithDistance {
  const _PlaceWithDistance(this.prediction, this.distance);

  final Map<String, dynamic> prediction;
  final double distance;
}
