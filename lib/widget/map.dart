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
  final String _mapStyle = '''[{"featureType": "administrative.land_parcel", "elementType": "labels", "stylers": [{"visibility": "off"}]}, {"featureType": "poi", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}, {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]}]''';

  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;

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
        print("更新");
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: 12,
          ),
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            await _mapController!.setMapStyle(_mapStyle); // 设置地图样式
            _getCurrentLocation(); // 获取当前位置
            setState(() {}); // 触发重绘以显示标记
          },
          markers: Set<Marker>.of(markerProvider.markers), // 从 MarkerProvider 获取标记
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      },
    );
  }
}
