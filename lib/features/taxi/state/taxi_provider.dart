import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/uber_ride_link_service.dart';

enum TaxiError {
  locationServicesDisabled,
  locationPermissionDenied,
  locationPermissionDeniedForever,
  locationUnavailable,
  destinationRequired,
  destinationNotFound,
  uberClientNotConfigured,
}

class TaxiProvider extends ChangeNotifier {
  TaxiProvider({UberRideLinkService? rideLinkService})
      : _rideLinkService = rideLinkService ?? UberRideLinkService();

  final UberRideLinkService _rideLinkService;

  double? _pickupLatitude;
  double? _pickupLongitude;
  bool _isLocating = false;
  bool _isPreparingRide = false;
  TaxiError? _error;
  bool _disposed = false;

  double? get pickupLatitude => _pickupLatitude;
  double? get pickupLongitude => _pickupLongitude;
  bool get hasPickupLocation =>
      _pickupLatitude != null && _pickupLongitude != null;
  bool get isLocating => _isLocating;
  bool get isPreparingRide => _isPreparingRide;
  TaxiError? get error => _error;
  bool get isUberConfigured => _rideLinkService.isConfigured;

  Future<void> useCurrentLocation() async {
    _error = null;
    _isLocating = true;
    _notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _error = TaxiError.locationServicesDisabled;
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _error = TaxiError.locationPermissionDenied;
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _error = TaxiError.locationPermissionDeniedForever;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _pickupLatitude = position.latitude;
      _pickupLongitude = position.longitude;
    } catch (_) {
      _error = TaxiError.locationUnavailable;
    } finally {
      _isLocating = false;
      _notifyListeners();
    }
  }

  Future<Uri?> buildRideLink(String destinationAddress) async {
    _error = null;
    if (!_rideLinkService.isConfigured) {
      _error = TaxiError.uberClientNotConfigured;
      _notifyListeners();
      return null;
    }
    if (!hasPickupLocation) {
      _error = TaxiError.locationUnavailable;
      _notifyListeners();
      return null;
    }
    final address = destinationAddress.trim();
    if (address.isEmpty) {
      _error = TaxiError.destinationRequired;
      _notifyListeners();
      return null;
    }

    _isPreparingRide = true;
    _notifyListeners();
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        _error = TaxiError.destinationNotFound;
        return null;
      }

      final destination = locations.first;
      return _rideLinkService.build(
        pickupLatitude: _pickupLatitude!,
        pickupLongitude: _pickupLongitude!,
        pickupLabel: 'Current location',
        dropoffLatitude: destination.latitude,
        dropoffLongitude: destination.longitude,
        dropoffAddress: address,
      );
    } catch (_) {
      _error = TaxiError.destinationNotFound;
      return null;
    } finally {
      _isPreparingRide = false;
      _notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
