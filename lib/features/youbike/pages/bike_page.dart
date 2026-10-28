// import 'dart:convert';
//
// import 'package:com.rsmn574.app/widget/map.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:com.rsmn574.app/database/get_data.dart';
//
// import '../../../firebase/analytics_service.dart';
//
// class Bike extends StatefulWidget {
//   @override
//   _BikeState createState() => _BikeState();
// }
//
// final Set<Marker> _bikeMarkers = {};
// var youBikeStations;
//
// class _BikeState extends State<Bike> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _fetchData();
//     _loadMarkers();
//   }
//
//   Future<void> _fetchData() async {
//     try {
//       youBikeStations = await mysqlSelect(
//         "SELECT * FROM Bike.Bike_taichung_Station;",
//       );
//
//       await AppAnalytics.logQueryResult(
//         feature: 'youbike_stations',
//         success: true,
//       );
//     } catch (error) {
//       await AppAnalytics.logQueryResult(
//         feature: 'youbike_stations',
//         success: false,
//         errorType: error.runtimeType.toString(),
//       );
//
//       rethrow;
//     }
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _indexNotifier.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadMarkers() async {
//     BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
//       ImageConfiguration(size: Size(4, 4)), // 調整大小
//       'assets/img/ubike_icon.png',
//     );
//     for (var station in youBikeStations) {
//       final marker = Marker(
//         markerId: MarkerId(station["StationUID"]),
//         icon: customIcon,
//         position: LatLng(
//           json.decode(station["StationPosition"])["PositionLat"],
//           json.decode(station["StationPosition"])["PositionLon"],
//         ),
//         infoWindow: InfoWindow(
//           title: json.decode(station["StationName"])["Zh_tw"],
//           snippet: "Capacity: ${station["BikesCapacity"]}",
//         ),
//       );
//       _bikeMarkers.add(marker);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final appBarHeight = AppBar().preferredSize.height;
//     final bottomNavBarHeight = kBottomNavigationBarHeight;
//     final mapHeight =
//         screenHeight - (screenHeight * 0.2) - appBarHeight - bottomNavBarHeight;
//
//     return WillPopScope(
//       onWillPop: () async {
//         if (_indexNotifier.value > 0) {
//           _indexNotifier.value--;
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         body: Stack(
//           children: [
//             Positioned.fill(
//               child: SizedBox(
//                 height: mapHeight,
//                 child: map(), // Assuming 'map()' is your custom map widget
//               ),
//             ),
//             ValueListenableBuilder<int>(
//               valueListenable: _indexNotifier,
//               builder: (context, index, child) {
//                 return IndexedStack(
//                   index: index,
//                   children: [
//                     Container(
//                       // Add your child widgets here
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
