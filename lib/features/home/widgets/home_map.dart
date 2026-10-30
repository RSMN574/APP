import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// 請根據你的實際路徑引入 MarkerProvider
// 這裡假設它與 BikeProvider 放在一起
import '../../../const/regular_class.dart';
import '../../youbike/state/bike_provider.dart';

class HomeMap extends StatelessWidget {
  final ValueNotifier<double> sheetExtent;
  final Function(GoogleMapController) onMapCreated;
  final LatLng initialPosition;
  final Set<ClusterManager> clusterManagers; // 新增 ClusterManager

  const HomeMap({
    super.key,
    required this.sheetExtent,
    required this.onMapCreated,
    required this.initialPosition,
    required this.clusterManagers,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavBarHeight = kBottomNavigationBarHeight;

    // 監聽 Marker 的變化
    final markerProvider = context.watch<MarkerProvider>();

    return ValueListenableBuilder<double>(
      valueListenable: sheetExtent,
      builder: (context, extent, child) {
        // 計算 Bottom Sheet 佔用的高度，作為地圖的 Padding
        final bottomPadding = (screenHeight * extent) - bottomNavBarHeight;

        return GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 15.0,
          ),
          // 傳入 markers 與 clusterManagers
          markers: markerProvider.markers,
          clusterManagers: clusterManagers,

          // 動態調整地圖內距
          padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 0),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        );
      },
    );
  }
}