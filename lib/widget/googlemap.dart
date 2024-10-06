import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../Const/regularClass.dart';
 // 確保導入正確的 Provider

class MapWidget extends StatelessWidget {
  void _onMapCreated(GoogleMapController controller) {
    // Handle map creation
  }

  Future<LatLng> _getInitialLocation(BuildContext context) async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: true);
    return LatLng(locationProvider.latitude, locationProvider.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: _getInitialLocation(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading map'));
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No location data'));
        }

        return GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: snapshot.data!,
            zoom: 17.0,
          ),
        );
      },
    );
  }
}