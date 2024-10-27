import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';

class map extends StatefulWidget {


  const map({Key? key, }) : super(key: key);

  @override
  State<map> createState() => _mapState();
}

class _mapState extends State<map> with AutomaticKeepAliveClientMixin {
  final String _mapStyle = '''[{"featureType": "administrative.land_parcel", "elementType": "labels", "stylers": [{"visibility": "off"}]}, {"featureType": "poi", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}, {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]}]''';

  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  late Set<Marker> _markers = {};
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;

  void _getCurrentLocation() async {
    try {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // 确保 _mapController 已创建
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition,
            zoom: 15.0,
          ),
        ));
      }
    } catch (e) {
      print('无法获取当前位置: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 在初始化时获取当前位置
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
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // 在地图创建时获取当前定位
            _getCurrentLocation();
            // 设置标记
            setState(() {
              _markers = markerProvider.markers;
            });
          },
          markers: Set<Marker>.of(markerProvider.markers), // 监听变化的 markers
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          style: _mapStyle, // 自定义样式
        );
      },
    );
  }
}
