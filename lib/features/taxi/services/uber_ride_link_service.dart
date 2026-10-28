import 'dart:convert';

class UberRideLinkService {
  UberRideLinkService({
    String? clientId,
  }) : _clientId =
      clientId ?? const String.fromEnvironment('UBER_CLIENT_ID');

  final String _clientId;

  bool get isConfigured => _clientId.trim().isNotEmpty;

  Uri build({
    required double pickupLatitude,
    required double pickupLongitude,
    required String pickupLabel,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String dropoffAddress,
  }) {
    if (!isConfigured) {
      throw StateError('Uber client ID is not configured.');
    }

    if (pickupLabel.trim().isEmpty ||
        dropoffAddress.trim().isEmpty) {
      throw ArgumentError('上車地點與目的地不能為空。');
    }

    _validateCoordinates(pickupLatitude, pickupLongitude);
    _validateCoordinates(dropoffLatitude, dropoffLongitude);

    return Uri.https('m.uber.com', '/looking', {
      'client_id': _clientId,
      'pickup': jsonEncode({
        'latitude': pickupLatitude,
        'longitude': pickupLongitude,
        'addressLine1': pickupLabel,
      }),
      'drop[0]': jsonEncode({
        'latitude': dropoffLatitude,
        'longitude': dropoffLongitude,
        'addressLine1': dropoffAddress,
      }),
    });
  }

  void _validateCoordinates(
      double latitude,
      double longitude,
      ) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid coordinates.');
    }
  }
}