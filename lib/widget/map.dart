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
  final Set<Polyline>? polylines; // 新增線條
  final CameraPosition? initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final Function()? onCameraIdle;
  final bool myLocationEnabled;

  const map({
    Key? key,
    this.markers,
    this.polylines, // 新增線條
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
  LatLng _currentPosition = _defaultPosition;
  bool _hasAnimatedToCurrent = false;

  final String _mapStyle = ''' [{"featureType": "administrative.land_parcel", "elementType": "labels", "stylers": [{"visibility": "off"}]}, {"featureType": "poi", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}, {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]}] ''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _currentPosition = LatLng(position.latitude, position.longitude);

      // 只在第一次定位時 animate camera
      if (_mapController != null && !_hasAnimatedToCurrent) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition, zoom: 15),
          ),
        );
        _hasAnimatedToCurrent = true;
      }
      setState(() {});
    } catch (e) {
      print('無法獲取位置: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    return Consumer<MarkerProvider>(
      builder: (context, markerProvider, child) {
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 15,
          ),
          onMapCreated: (controller) {
            if (_mapController == null) {
              _mapController = controller;
              _mapController!.setMapStyle(_mapStyle);
              widget.onMapCreated?.call(controller);
            }
          },
          onCameraMove: widget.onCameraMove,
          onCameraIdle: widget.onCameraIdle,
          markers: widget.markers ?? markerProvider.markers,
          myLocationEnabled: widget.myLocationEnabled,
          polylines: widget.polylines ?? {}, // <-- 加上線條
          myLocationButtonEnabled: true,
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer())
          },
        );
      },
    );
  }
}
