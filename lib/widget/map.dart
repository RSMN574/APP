import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../Const/regularClass.dart';

class map extends StatefulWidget {
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final CameraPosition? initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final Function()? onCameraIdle;
  final bool myLocationEnabled;

  const map({
    Key? key,
    this.markers,
    this.polylines,
    this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = true,
    this.onCameraMove,
    this.onCameraIdle,
  }) : super(key: key);

  @override
  State<map> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<map>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;

  static const LatLng _defaultPosition = LatLng(25.0330, 121.5654);

  /// ⚠️ initialCameraPosition 一定要固定
  static const CameraPosition _initialCameraPosition =
  CameraPosition(target: _defaultPosition, zoom: 15);

  LatLng _currentPosition = _defaultPosition;
  bool _hasAnimatedToCurrent = false;

  final String _mapStyle = '''
[
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// 只負責移動 camera，不 rebuild UI
  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _currentPosition = LatLng(position.latitude, position.longitude);

      if (_mapController != null && !_hasAnimatedToCurrent) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 15),
        );
        _hasAnimatedToCurrent = true;
      }
    } catch (e) {
      debugPrint('無法獲取位置: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GoogleMap(
      initialCameraPosition:
      widget.initialCameraPosition ?? _initialCameraPosition,

      /// 只在第一次建立 Map 時呼叫
      onMapCreated: (controller) {
        if (_mapController == null) {
          _mapController = controller;
          _mapController!.setMapStyle(_mapStyle);
          widget.onMapCreated?.call(controller);
        }
      },

      onCameraMove: widget.onCameraMove,
      onCameraIdle: widget.onCameraIdle,

      /// ⚠️ 用 select，避免整張 Map rebuild
      markers: widget.markers ??
          context.select<MarkerProvider, Set<Marker>>(
                (p) => p.markers,
          ),

      polylines: widget.polylines ??
          context.select<PolylineProvider, Set<Polyline>>(
                (p) => p.polylines,
          ),

      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: true,

      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
        )
      },
    );
  }
}
