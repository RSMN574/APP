import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../Const/regularClass.dart';

class map extends StatefulWidget {
  final Set<Marker>? markers;
  final CameraPosition? initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final bool myLocationEnabled;
final LatLng? initialPosition;
  const map({
    Key? key,
     this.markers,
     this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = true,
    this.initialPosition
  }) : super(key: key);
  @override
  State<map> createState() => _MapScreenState();
}
//with AutomaticKeepAliveClientMixin
class _MapScreenState extends State<map>  {
  final String _mapStyle = '''
  [{"featureType": "administrative.land_parcel", "elementType": "labels", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "poi.park", "elementType": "labels.text", "stylers": [{"visibility": "off"}]}, 
  {"featureType": "road.local", "elementType": "labels", "stylers": [{"visibility": "off"}]}]
  ''';

  // @override
  // bool get wantKeepAlive => true;

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

    // super.build(context);
    return Consumer<MarkerProvider>(
      builder: (context, markerProvider, child) {
        return GoogleMap(
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
            // 限制地圖的邊界範圍
            // if (!_taiwanBounds.contains(position.target)) {
            //   LatLng target = position.target;
            //   double lat = target.latitude;
            //   double lng = target.longitude;
            //
            //   if (lat < _taiwanBounds.southwest.latitude) {
            //     lat = _taiwanBounds.southwest.latitude;
            //   } else if (lat > _taiwanBounds.northeast.latitude) {
            //     lat = _taiwanBounds.northeast.latitude;
            //   }
            //
            //   if (lng < _taiwanBounds.southwest.longitude) {
            //     lng = _taiwanBounds.southwest.longitude;
            //   } else if (lng > _taiwanBounds.northeast.longitude) {
            //     lng = _taiwanBounds.northeast.longitude;
            //   }
            //
            //   _mapController?.moveCamera(
            //     CameraUpdate.newLatLng(LatLng(lat, lng)),
            //   );
            // }
          },
          markers: widget.markers ?? Set<Marker>.of(markerProvider.markers),
          myLocationEnabled: widget.myLocationEnabled,
          myLocationButtonEnabled: true,
        );
      },
    );
  }

}
