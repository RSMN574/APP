import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';

class map extends StatefulWidget {
  const map({Key? key}) : super(key: key);

  @override
  State<map> createState() => _MapScreenState();
}

class _MapScreenState extends State<map> with AutomaticKeepAliveClientMixin {
  final String _mapStyle = '''
  [{"featureType": "administrative.land_parcel", "elementType": "labels", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]}]
  ''';

  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;

  // 台湾的地理边界
  static final LatLngBounds _taiwanBounds = LatLngBounds(
    southwest: const LatLng(20.0, 116.0), // 台湾西南边界
    northeast: const LatLng(26.0, 123.0), // 台湾东北边界
  );

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

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
    super.build(context);

    return Consumer<MarkerProvider>(
      builder: (context, markerProvider, child) {
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 12,
          ),
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            await _mapController!.setMapStyle(_mapStyle); // 设置地图样式
            _getCurrentLocation(); // 获取当前位置
          },
          onCameraMove: (CameraPosition position) {
            // 限制地图的边界范围
            if (!_taiwanBounds.contains(position.target)) {
              LatLng target = position.target;
              double lat = target.latitude;
              double lng = target.longitude;

              if (lat < _taiwanBounds.southwest.latitude) {
                lat = _taiwanBounds.southwest.latitude;
              } else if (lat > _taiwanBounds.northeast.latitude) {
                lat = _taiwanBounds.northeast.latitude;
              }

              if (lng < _taiwanBounds.southwest.longitude) {
                lng = _taiwanBounds.southwest.longitude;
              } else if (lng > _taiwanBounds.northeast.longitude) {
                lng = _taiwanBounds.northeast.longitude;
              }

              _mapController?.moveCamera(
                CameraUpdate.newLatLng(LatLng(lat, lng)),
              );
            }
          },
          markers: Set<Marker>.of(markerProvider.markers), // 从 MarkerProvider 获取标记
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      },
    );
  }
}
