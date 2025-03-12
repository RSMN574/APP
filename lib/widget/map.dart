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
  final CameraPosition? initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final Function()? onCameraIdle;
  final bool myLocationEnabled;
  final LatLng? initialPosition;

  const map({
    Key? key,
    this.markers,
    this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = true,
    this.initialPosition,
    this.onCameraMove,
    this.onCameraIdle,
  }) : super(key: key);

  @override
  State<map> createState() => _MapScreenState();
}

class _MapScreenState extends State<map> {
  final String _mapStyle = '''
  [{"featureType": "administrative.land_parcel", "elementType": "labels", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]}]
  ''';

  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;


  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      print(position);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 15.0),
        ));
      }
    } catch (e) {
      print('无法获取当前位置: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarkerProvider>(
      builder: (context, markerProvider, child) {
        return GoogleMap(
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 15,
          ),
          onMapCreated: (controller) {
            widget.onMapCreated?.call(controller);
            _mapController = controller;
            _mapController?.setMapStyle(_mapStyle);
            _getCurrentLocation(); // 地圖創建完成後再次定位並更新視角
          },
          onCameraMove: (CameraPosition position) {
            widget.onCameraMove?.call(position);
          },
          onCameraIdle: () {
            widget.onCameraIdle?.call(); // 呼叫 onCameraIdle 回调
          },
          markers: widget.markers ?? Set<Marker>.of(markerProvider.markers),
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: true,
        );
      },
    );
  }
}
