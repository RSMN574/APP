import 'dart:async';
import 'dart:convert';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:synchronized/synchronized.dart';

import '../Const/regularClass.dart';
import '../Const/regularConst.dart';
import '../database/MRT/getMRTInfo.dart';
import '../database/SQL/favorite_feature.dart';
import '../database/bus/getBusTime.dart';
import '../database/getData.dart';
import '../database/bus/getStationInfo.dart';
import '../l10n/app_localizations.dart';

import '../metro.dart';
import '../models/MRTStation.dart';
import '../models/Station.dart';
import '../models/bus.dart';
import 'train/train.dart';
import '../utils/convert.dart';
import '../widget/bus/bubble.dart';
import '../widget/error.dart';
import '../widget/map.dart';
import '../widget/tab.dart';
import 'bus/busStopInfo.dart';
import 'bus/bus_time.dart';

// Top-level / State shared Notifiers
final ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
final ValueNotifier<String> _selectStationID = ValueNotifier<String>('');
final ValueNotifier<String> _selectStationGroupID = ValueNotifier<String>('');
final ValueNotifier<Set<Marker>> _markers = ValueNotifier<Set<Marker>>({});
final ValueNotifier<String> _stopName = ValueNotifier<String>('');
final ValueNotifier<String> _tabSelect = ValueNotifier<String>('bus');
final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);
final ValueNotifier<SortType> _sortNotifier = ValueNotifier<SortType>(SortType.timeAsc);

final GlobalKey<_NearbyStationsPageState> mapKey = GlobalKey();

class NearbyStationsPage extends StatefulWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  _NearbyStationsPageState createState() => _NearbyStationsPageState();
}

class _NearbyStationsPageState extends State<NearbyStationsPage> {
  GoogleMapController? _mapController;
  Future<List<Station>>? _futureNearStations;
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  MarkerProvider? _markerProvider;

  GoogleMapController? get mapController => _mapController;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _updateFutureNearStations() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    setState(() {
      _futureNearStations = getNearStation(
        Uri.encodeComponent("${locationProvider.latitude},${locationProvider.longitude}"),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _busInit();
    _tabSelect.addListener(_handleTabSelectChange);
  }

  void _busInit() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    _futureNearStations = getNearStation(
      Uri.encodeComponent("${locationProvider.latitude},${locationProvider.longitude}"),
    );
    final stations = await _futureNearStations;
    if (mounted) {
      _loadBusMarkers(stations);
    }
  }

  List<Map<String, dynamic>> _convertStations(String type, List<dynamic> stations) {
    if (type == "metro") {
      return stations.map((station) {
        return {
          "stationID": station["StationID"].toString(),
          "stationNameZh": (station["StationName"])["Zh_tw"] ?? "Unknown",
          "positionLat": (station["StationPosition"])["PositionLat"],
          "positionLon": (station["StationPosition"])["PositionLon"],
        };
      }).toList();
    } else if (type == "train") {
      return stations.map((station) {
        final nameMap = json.decode(station["StationName"]);
        final posMap = json.decode(station["StationPosition"]);
        return {
          "stationID": station["StationID"].toString(),
          "stationNameZh": nameMap["Zh_tw"] ?? "Unknown",
          "positionLat": posMap["PositionLat"],
          "positionLon": posMap["PositionLon"],
        };
      }).toList();
    } else {
      return [];
    }
  }

  void _handleTabSelectChange() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (_tabSelect.value == "bus") {
      await _updateFutureNearStations();
      final stations = await _futureNearStations;
      if (mounted) {
        _loadBusMarkers(stations);
      }
    } else if (_tabSelect.value == "metro") {
      final stations = await getNearMRTStation(
        Uri.encodeComponent("${locationProvider.latitude},${locationProvider.longitude}"),
      );
      if (mounted) {
        _loadMarkers(
          _convertStations("metro", stations.map((s) => s.toJson()).toList()),
        );
      }
    } else if (_tabSelect.value == "train") {
      final stations = await getNearTrainStation(
        locationProvider.latitude,
        locationProvider.longitude,
      );
      if (mounted) {
        _loadMarkers(_convertStations("train", stations));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _markerProvider = Provider.of<MarkerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _tabSelect.removeListener(_handleTabSelectChange);
    _scrollController.dispose();
    _markerProvider?.setMarkers({});
    super.dispose();
  }

  Future<void> _loadBusMarkers(List<Station>? stations) async {
    if (stations == null || stations.isEmpty) {
      debugPrint('Stations data is empty.');
      return;
    }

    final Set<Marker> markers = {};

    for (var station in stations) {
      final marker = Marker(
        markerId: MarkerId(station.stationID),
        position: LatLng(station.positionLat, station.positionLon),
        infoWindow: InfoWindow(
          title: station.stationNameZh,
          snippet: station.stationID,
        ),
        onTap: () async {
          final stopName = station.stationNameZh;
          final stopID = station.stationID;
          final stationGroupID = station.stationGroupID;

          try {
            final data = await BusStopCache().getBusStopInfo(stopName);
            final stationIDs = data
                .map((item) => item['StationID']?.toString())
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .toList();

            if (stationIDs.isEmpty) return;

            if (!mounted) return;

            if (_isSameStationGroup(_stationIDs.value, stationIDs)) {
              _selectStationID.value = stopID;
            } else {
              _stopName.value = stopName;
              _selectStationID.value = stopID;
              _selectStationGroupID.value = stationGroupID;
              _stationIDs.value = stationIDs;
            }

            _updateMarkerStyle();
            _indexNotifier.value = 1;

            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(station.positionLat, station.positionLon),
                  zoom: 19.0,
                ),
              ),
            );
          } catch (e) {
            debugPrint('Error loading bus station info: $e');
          }
        },
      );
      markers.add(marker);
    }
    _markers.value = markers;
  }

  bool _isSameStationGroup(List<String>? oldList, List<String>? newList) {
    if ((oldList == null || oldList.isEmpty) && (newList == null || newList.isEmpty)) {
      return false;
    }
    if (oldList == null || oldList.isEmpty || newList == null || newList.isEmpty) {
      return false;
    }
    if (oldList.length != newList.length) return false;

    final sortedOld = List.of(oldList)..sort();
    final sortedNew = List.of(newList)..sort();

    for (int i = 0; i < sortedOld.length; i++) {
      if (sortedOld[i] != sortedNew[i]) return false;
    }
    return true;
  }

  Future<void> _loadMarkers(List<dynamic>? stations) async {
    if (stations == null || stations.isEmpty) {
      debugPrint('Stations data is empty.');
      return;
    }

    final Set<Marker> markers = {};

    for (var station in stations) {
      if (station is! Map<String, dynamic>) continue;

      final stationID = station["stationID"]?.toString();
      final stationNameZh = station["stationNameZh"] ?? "Unknown";
      final positionLat = station["positionLat"];
      final positionLon = station["positionLon"];

      if (stationID == null || positionLat == null || positionLon == null) continue;

      final marker = Marker(
        markerId: MarkerId(stationID),
        position: LatLng(positionLat, positionLon),
        infoWindow: InfoWindow(
          title: stationNameZh,
          snippet: stationID,
        ),
      );
      markers.add(marker);
    }

    _markers.value = markers;
  }

  static void _updateMarkerStyle() {
    _markers.value = _markers.value.map((marker) {
      if (marker.markerId.value == _selectStationID.value) {
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(190.0),
        );
      } else {
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarker,
        );
      }
    }).toSet();
  }

  static void _clearMarkerStyle() {
    _markers.value = _markers.value.map((marker) {
      return marker.copyWith(
        iconParam: BitmapDescriptor.defaultMarker,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight = screenHeight - (screenHeight * 0.2) - appBarHeight - bottomNavBarHeight;

    return PopScope(
      canPop: _indexNotifier.value == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _indexNotifier.value > 0) {
          _indexNotifier.value--;
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SizedBox(
                height: mapHeight,
                child: ValueListenableBuilder<Set<Marker>>(
                  valueListenable: _markers,
                  builder: (context, markers, child) {
                    return map(
                      markers: markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                    );
                  },
                ),
              ),
            ),

            DraggableScrollableSheet(
              controller: _scrollController,
              initialChildSize: 0.43,
              minChildSize: 0.3,
              maxChildSize: 0.96,
              builder: (BuildContext context, ScrollController scrollController) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -10,
                      left: MediaQuery.of(context).size.width / 2 - 20,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          double delta = details.primaryDelta! / MediaQuery.of(context).size.height;
                          final currentSize =
                          _scrollController.isAttached ? _scrollController.size : 0.43;
                          double newSize = (currentSize - delta).clamp(0.1, 0.96);
                          _scrollController.animateTo(
                            newSize,
                            duration: const Duration(milliseconds: 50),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 800,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: ValueListenableBuilder<int>(
                        valueListenable: _indexNotifier,
                        builder: (context, index, child) {
                          return IndexedStack(
                            index: index,
                            children: <Widget>[
                              TabWidget(
                                items: [
                                  AppLocalizations.of(context)!.text_415,
                                  AppLocalizations.of(context)!.text_416,
                                  AppLocalizations.of(context)!.text_417,
                                  AppLocalizations.of(context)!.text_418
                                ],
                                icons: const [
                                  Icons.directions_bus,
                                  Icons.subway,
                                  Icons.train,
                                  Icons.directions_railway
                                ],
                                id: const ["bus", "metro", "train", "HSR"],
                                buildPageView: (context, controller) {
                                  return PageView.builder(
                                    itemCount: 4,
                                    controller: controller,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, pageIndex) {
                                      switch (pageIndex) {
                                        case 0:
                                          _tabSelect.value = "bus";
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            child: FutureBuilder<List<Station>>(
                                              future: _futureNearStations,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Center(
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 40),
                                                      child: LoadingAnimationWidget.stretchedDots(
                                                        color: Colors.black,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  );
                                                }

                                                if (snapshot.hasError) {
                                                  return Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const SizedBox(height: 40),
                                                        Text(
                                                          AppLocalizations.of(context)!.text_419,
                                                          style: const TextStyle(
                                                            color: Colors.black54,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            _updateFutureNearStations();
                                                          },
                                                          icon: const Icon(Icons.refresh, color: Colors.black),
                                                          label: Text(
                                                            AppLocalizations.of(context)!.text_420,
                                                            style: const TextStyle(color: Colors.black, fontSize: 14),
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.white,
                                                            foregroundColor: Colors.black,
                                                            elevation: 3,
                                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            shadowColor: Colors.grey[300],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }

                                                if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                                                  final Map<String, List<Map<String, dynamic>>> groupedStations = {};
                                                  for (var station in snapshot.data!) {
                                                    String stationName = station.stationNameZh;
                                                    if (!groupedStations.containsKey(stationName)) {
                                                      groupedStations[stationName] = [];
                                                    }
                                                    groupedStations[stationName]!.add(station.toJson());
                                                  }

                                                  final List<Map<String, dynamic>> result = groupedStations.entries.map((entry) {
                                                    return {
                                                      "StationGroup": {
                                                        "StationGroupName": {"Zh_tw": entry.key},
                                                        "Stations": entry.value
                                                      }
                                                    };
                                                  }).toList();

                                                  return Padding(
                                                    padding: const EdgeInsets.all(16.0),
                                                    child: Column(
                                                      children: result.map((station) => _stationCard(station: station)).toList(),
                                                    ),
                                                  );
                                                }

                                                return Container(
                                                  margin: const EdgeInsets.only(top: 20),
                                                  child: Center(
                                                    child: Text(
                                                      AppLocalizations.of(context)!.text_419,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        case 1:
                                          _tabSelect.value = "metro";
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            child: FutureBuilder<List<MRTStation>>(
                                              future: getNearMRTStation(
                                                Uri.encodeComponent(
                                                  "${locationProvider.latitude},${locationProvider.longitude}",
                                                ),
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Center(
                                                    child: LoadingAnimationWidget.stretchedDots(
                                                      color: Colors.black,
                                                      size: 40,
                                                    ),
                                                  );
                                                }

                                                if (snapshot.hasError) {
                                                  return Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          AppLocalizations.of(context)!.text_419,
                                                          style: const TextStyle(
                                                            color: Colors.black54,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            setState(() {});
                                                          },
                                                          icon: const Icon(Icons.refresh, color: Colors.black),
                                                          label: Text(
                                                            AppLocalizations.of(context)!.text_420,
                                                            style: const TextStyle(color: Colors.black, fontSize: 14),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }

                                                final stations = snapshot.data ?? [];
                                                if (stations.isEmpty) {
                                                  return Container(
                                                    margin: const EdgeInsets.only(top: 20),
                                                    child: Center(
                                                      child: Text(
                                                        AppLocalizations.of(context)!.text_419,
                                                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return Padding(
                                                  padding: const EdgeInsets.all(16),
                                                  child: Column(
                                                    children: stations.map((s) => _mrtStationCard(station: s)).toList(),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        case 2:
                                          _tabSelect.value = "train";
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            child: FutureBuilder<List<dynamic>>(
                                              future: getNearTrainStation(
                                                locationProvider.latitude,
                                                locationProvider.longitude,
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return Center(
                                                    child: LoadingAnimationWidget.stretchedDots(
                                                      color: Colors.black,
                                                      size: 40,
                                                    ),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          AppLocalizations.of(context)!.text_419,
                                                          style: const TextStyle(
                                                            color: Colors.black54,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        ElevatedButton.icon(
                                                          onPressed: () {
                                                            setState(() {});
                                                          },
                                                          icon: const Icon(Icons.refresh, color: Colors.black),
                                                          label: Text(
                                                            AppLocalizations.of(context)!.text_420,
                                                            style: const TextStyle(color: Colors.black, fontSize: 14),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } else if (snapshot.hasData) {
                                                  return Padding(
                                                    padding: const EdgeInsets.all(16.0),
                                                    child: Column(
                                                      children: List.generate(
                                                        snapshot.data!.length,
                                                            (idx) {
                                                          final station = snapshot.data![idx];
                                                          final nameMap = json.decode(station["StationName"]);
                                                          return GestureDetector(
                                                            onTap: () {
                                                              DateTime today = DateTime.now();
                                                              DateTime todayDate = DateTime(
                                                                today.year,
                                                                today.month,
                                                                today.day,
                                                              );

                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => StationPage(
                                                                    stationName: nameMap["Zh_tw"],
                                                                    stationID: station["StationID"],
                                                                    datetime: todayDate,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Container(
                                                              margin: const EdgeInsets.symmetric(
                                                                vertical: 8,
                                                                horizontal: 12,
                                                              ),
                                                              padding: const EdgeInsets.symmetric(
                                                                vertical: 12,
                                                                horizontal: 16,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                borderRadius: BorderRadius.circular(12),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors.black.withOpacity(0.05),
                                                                    blurRadius: 8,
                                                                    offset: const Offset(0, 4),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    nameMap["Zh_tw"],
                                                                    style: const TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w400,
                                                                      color: Colors.black,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 8),
                                                                  Divider(
                                                                    color: Colors.grey[300],
                                                                    thickness: 0.5,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return Container(
                                                    margin: const EdgeInsets.only(top: 20),
                                                    child: Center(
                                                      child: Text(
                                                        AppLocalizations.of(context)!.text_419,
                                                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        case 3:
                                          _tabSelect.value = "HSR";
                                          return Center(
                                            child: Text(AppLocalizations.of(context)!.text_421),
                                          );
                                        default:
                                          return Center(
                                            child: Text(AppLocalizations.of(context)!.text_422),
                                          );
                                      }
                                    },
                                  );
                                },
                              ),
                              _buildDraggableScrollableSheetPageTwo(scrollController),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            // 重載按鈕
            Positioned(
              bottom: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _handleTabSelectChange();
                  },
                  borderRadius: BorderRadius.circular(50),
                  splashColor: const Color(0xFF1A73E8).withOpacity(0.2),
                  highlightColor: const Color(0xFFEEF3FB),
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFEEF3FB),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF1A73E8),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stationCard({required Map<String, dynamic> station}) {
    final List<String> stationIDs = (station["StationGroup"]["Stations"] as List<dynamic>?)
        ?.map((s) => s["stationID"].toString())
        .toList() ??
        [];

    final firstStation = station["StationGroup"]["Stations"][0];

    void onCardTap() {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstStation["positionLat"], firstStation["positionLon"]),
            zoom: 19.0,
          ),
        ),
      );

      _stopName.value = station["StationGroup"]["StationGroupName"]["Zh_tw"];
      _stationIDs.value = stationIDs;
      _indexNotifier.value = 1;
    }

    return GestureDetector(
      onTap: onCardTap,
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          if (_indexNotifier.value > 0) {
            _indexNotifier.value = 1;
          }
        }
      },
      child: Transform.translate(
        offset: const Offset(0, 0.5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCardTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
            highlightColor: const Color(0xFFEEF3FB).withOpacity(0.5),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.train_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station["StationGroup"]["StationGroupName"]["Zh_tw"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mrtStationCard({required MRTStation station}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  station.stationPosition.positionLat,
                  station.stationPosition.positionLon,
                ),
                zoom: 17.0,
              ),
            ),
          );
          _stopName.value = station.stationName.zhTw;
          _stationIDs.value = [station.stationID];
          _indexNotifier.value = 1;
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF34C759).withOpacity(0.1),
        highlightColor: const Color(0xFFEAF7EF),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.subway_rounded,
                  size: 20,
                  color: Color(0xFF34C759),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.stationName.zhTw,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (station.stationName.en.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        station.stationName.en,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableScrollableSheetPageTwo(ScrollController scrollController) {
    if (_tabSelect.value == "bus") {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrimaryScrollController(
          controller: scrollController,
          child: BusStopList(
            _stopName.value,
            key: ValueKey(_stopName.value),
          ),
        ),
      );
    } else if (_tabSelect.value == "metro") {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrimaryScrollController(
          controller: scrollController,
          child: MRTStationList(
            station: _stopName.value,
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrimaryScrollController(
          controller: scrollController,
          child: Center(child: Text(AppLocalizations.of(context)!.text_422)),
        ),
      );
    }
  }
}

class BusStopList extends StatefulWidget {
  final String stop;

  const BusStopList(this.stop, {super.key});

  @override
  State<StatefulWidget> createState() => _BusStopListState();
}

class _BusStopListState extends State<BusStopList>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<BusStopList> {
  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController.broadcast();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    final sortedIDs = List<String>.from(_stationIDs.value)..sort();
    int initialIndex = sortedIDs.indexOf(_selectStationID.value);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: _stationIDs.value.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    _selectStationID.addListener(_onSelectStationChanged);
  }

  void _onSelectStationChanged() {
    if (!mounted || _stationIDs.value.isEmpty) return;

    final currentStop = _selectStationID.value;
    final sortedIDs = List<String>.from(_stationIDs.value)..sort();
    final index = sortedIDs.indexOf(currentStop);
    if (index != -1 && index < _tabController.length) {
      _NearbyStationsPageState._updateMarkerStyle();
      _tabController.animateTo(index);
    }
  }

  @override
  void dispose() {
    _selectStationID.removeListener(_onSelectStationChanged);
    _streamController.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadData() async {
    return await fetchBusStopInfo();
  }

  Future<List<Map<String, dynamic>>> _processData(
      String stationID,
      List<Map<String, dynamic>> stopEstimatedTime,
      ) async {
    try {
      final routeMap = <String, Map<String, dynamic>>{};

      for (final item in stopEstimatedTime) {
        if (item["StationID"] != stationID) continue;

        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        final direction = item["Direction"];
        if (routeName == null || routeName.isEmpty) continue;

        final routeKey = "${routeName}_$direction";
        final currentTime = _parseTimeToMinutes(item["time"]);

        final existing = routeMap[routeKey];
        if (existing == null ||
            (currentTime != -1 && currentTime < _parseTimeToMinutes(existing["time"]))) {
          routeMap[routeKey] = item;
        }
      }

      final stationData = routeMap.values.toList();
      if (stationData.isEmpty) return [];

      final routeNames = <String>{};
      for (final item in stationData) {
        final routeNameObj = item["RouteName"];
        String? routeName;
        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        if (routeName != null && routeName.isNotEmpty) {
          routeNames.add(routeName);
        }
      }

      final Map<String, Map<String, dynamic>> routeInfoCache = {};

      if (routeNames.isNotEmpty) {
        try {
          final nameList = routeNames.map((name) => "'$name'").join(',');
          final query = """
            SELECT *
            FROM Bus.bus_route
            WHERE City = 'Taichung'
              AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) IN ($nameList)
          """;

          final results = await mysqlSelect(query);

          for (final result in results) {
            final routeNameField = result["RouteName"];
            String? routeName;

            if (routeNameField is Map) {
              routeName = routeNameField["Zh_tw"] as String?;
            } else if (routeNameField is String) {
              try {
                final parsed = json.decode(routeNameField) as Map<String, dynamic>;
                routeName = parsed["Zh_tw"] as String?;
              } catch (_) {
                routeName = routeNameField;
              }
            }

            if (routeName != null && routeName.isNotEmpty) {
              routeInfoCache[routeName] = result;
            }
          }
        } catch (_) {
          for (final routeName in routeNames) {
            try {
              final query = """
                SELECT * FROM Bus.Bus_Taichung_Route 
                WHERE RouteName LIKE '%"Zh_tw": "$routeName"%'
                OR JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName'
              """;
              final results = await mysqlSelect(query);
              if (results.isNotEmpty) {
                routeInfoCache[routeName] = results.first;
              }
            } catch (_) {}
          }
        }
      }

      final List<Map<String, dynamic>> processedData = [];

      for (final item in stationData) {
        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        final direction = item["Direction"];
        if (routeName == null) continue;

        final resultItem = Map<String, dynamic>.from(item);
        final routeInfo = routeInfoCache[routeName];
        final hasValidInfo = routeInfo != null && routeInfo.isNotEmpty;

        if (!mounted) return [];
        final localizations = AppLocalizations.of(context)!;

        resultItem["RouteID"] = hasValidInfo
            ? (routeInfo["RouteID"]?.toString() ?? localizations.text_321)
            : localizations.text_321;

        String? departureName;
        String? destinationName;

        if (hasValidInfo) {
          departureName = routeInfo["DepartureStopNameZh"]?.toString() ??
              routeInfo["DepartureStopName"]?.toString();
          destinationName = routeInfo["DestinationStopNameZh"]?.toString() ??
              routeInfo["DestinationStopName"]?.toString();
        }

        resultItem["DepartureStopName"] = departureName ?? localizations.text_325;
        resultItem["DestinationStopName"] = destinationName ?? localizations.text_326;

        final isDirection1 = direction == 1;
        resultItem["from"] = isDirection1
            ? (destinationName ?? localizations.text_428)
            : (departureName ?? localizations.text_429);
        resultItem["to"] = isDirection1
            ? (departureName ?? localizations.text_429)
            : (destinationName ?? localizations.text_428);

        processedData.add(resultItem);
      }

      return processedData;
    } catch (e) {
      debugPrint('Error processing data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ValueListenableBuilder<String>(
      valueListenable: _selectStationGroupID,
      builder: (context, groupID, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.stretchedDots(
                  color: Colors.black,
                  size: 40,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('錯誤: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text(AppLocalizations.of(context)!.text_430));
            }

            if (_stationIDs.value.isEmpty) {
              return const SizedBox();
            }

            return Column(
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(120),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AppBar(
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      title: Text(
                        _stopName.value,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          if (_indexNotifier.value > 0) {
                            _indexNotifier.value--;
                            _NearbyStationsPageState._clearMarkerStyle();
                            _stationIDs.value = [];
                            _stopName.value = "";
                            _selectStationID.value = "";
                            _selectStationGroupID.value = "";
                          }
                        },
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF3FB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.refresh_rounded, size: 20),
                            ),
                            onPressed: () {
                              setState(() {});
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF3FB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.more_vert_rounded, size: 20),
                            ),
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              _buildPopupMenuItem(
                                icon: Icons.info_outline_rounded,
                                title: AppLocalizations.of(context)!.text_333,
                                value: 'info',
                                color: const Color(0xFF1A73E8),
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.favorite_border_rounded,
                                title: AppLocalizations.of(context)!.text_334,
                                value: 'favorite',
                                color: const Color(0xFFFF3B30),
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.sort_rounded,
                                title: AppLocalizations.of(context)!.text_335,
                                value: 'sort',
                                color: const Color(0xFF34C759),
                              ),
                            ],
                            onSelected: (String action) async {
                              if (action == 'favorite') {
                                favorite_feature dbHelper = favorite_feature();
                                final output = await dbHelper.addFavoriteStop(
                                  stopName: widget.stop,
                                  city: "Taichung",
                                );

                                if (!mounted) return;

                                if (output == 100) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.success,
                                    text: '${widget.stop}已儲存項目',
                                  );
                                } else if (output == -1) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.warning,
                                    text: '${widget.stop}已存在於列表中，不會重複添加',
                                  );
                                } else if (output == 200) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.error,
                                    title: 'Oops...',
                                    text: AppLocalizations.of(context)!.text_336,
                                  );
                                }
                              } else if (action == 'sort') {
                                _showSortDialog(context);
                              }
                            },
                          ),
                        ),
                      ],
                      bottom: _buildTabBar(snapshot.data!, _tabController),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      _stationIDs.value.length,
                          (index) {
                        return FutureBuilder<Widget>(
                          future: _buildTabContent(
                            _stationIDs.value[index],
                            snapshot.data!,
                          ),
                          builder: (context, contentSnapshot) {
                            if (contentSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: LoadingAnimationWidget.stretchedDots(
                                  color: Colors.black,
                                  size: 40,
                                ),
                              );
                            }

                            if (contentSnapshot.hasError) {
                              return Center(
                                child: Text('Error: ${contentSnapshot.error}'),
                              );
                            }

                            return contentSnapshot.data ??
                                const Center(child: Text("No content available"));
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  PreferredSize _buildTabBar(List<Map<String, dynamic>> station, TabController tabController) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(color: Colors.white),
        child: AnimatedBuilder(
          animation: tabController,
          builder: (context, child) {
            final currentIndex = tabController.index;
            return Row(
              children: List.generate(_stationIDs.value.length, (index) {
                final label = String.fromCharCode(65 + index);
                final isSelected = currentIndex == index;

                return Expanded(
                  child: Padding(
                    padding: index < _stationIDs.value.length - 1
                        ? const EdgeInsets.only(right: 8)
                        : EdgeInsets.zero,
                    child: GestureDetector(
                      onTap: () => tabController.animateTo(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A73E8).withOpacity(0.08)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[200]!,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_bus,
                                  size: 14,
                                  color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "站牌 $label",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _stationIDs.value[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF1A73E8).withOpacity(0.8)
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Future<Widget> _buildTabContent(
      String stationID,
      List<Map<String, dynamic>> stopEstimatedTime,
      ) async {
    List<Map<String, dynamic>> finalList = await _processData(stationID, stopEstimatedTime);

    return ValueListenableBuilder<SortType>(
      valueListenable: _sortNotifier,
      builder: (context, sortType, _) {
        final sortedList = [...finalList];

        switch (sortType) {
          case SortType.nameAsc:
            sortedList.sort(
                  (a, b) => getChineseName(a['RouteName']["Zh_tw"])
                  .compareTo(getChineseName(b['RouteName']["Zh_tw"])),
            );
            break;
          case SortType.nameDesc:
            sortedList.sort(
                  (a, b) => getChineseName(b['RouteName']["Zh_tw"])
                  .compareTo(getChineseName(a['RouteName']["Zh_tw"])),
            );
            break;
          case SortType.timeAsc:
            sortedList.sort(_timeAscComparator);
            break;
          case SortType.timeDesc:
            sortedList.sort(_timeDescComparator);
            break;
        }

        return _buildTabContentUI(sortedList);
      },
    );
  }

  int _timeAscComparator(Map<String, dynamic> a, Map<String, dynamic> b) {
    final localizations = AppLocalizations.of(context)!;
    if (a["time"] == localizations.text_316) return -1;
    if (b["time"] == localizations.text_316) return 1;
    if (a["time"] == localizations.text_317) return 1;
    if (b["time"] == localizations.text_317) return -1;
    return _parseTimeToMinutes(a['time']).compareTo(_parseTimeToMinutes(b['time']));
  }

  int _timeDescComparator(Map<String, dynamic> a, Map<String, dynamic> b) {
    final localizations = AppLocalizations.of(context)!;
    if (a["time"] == localizations.text_316) return 1;
    if (b["time"] == localizations.text_316) return -1;
    if (a["time"] == localizations.text_317) return -1;
    if (b["time"] == localizations.text_317) return 1;
    return _parseTimeToMinutes(b['time']).compareTo(_parseTimeToMinutes(a['time']));
  }

  Widget _buildTabContentUI(List<Map<String, dynamic>> finalList) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: ValueKey(_sortNotifier.value),
        items: finalList,
        areItemsTheSame: (a, b) => a["RouteID"] == b["RouteID"],
        itemBuilder: (context, animation, stop, index) {
          final plateNumb = stop["PlateNumb"];
          final localizations = AppLocalizations.of(context)!;

          final color = stop["color"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["color"] == '2'
              ? const Color.fromRGBO(225, 85, 104, 0.1)
              : (stop["color"] == localizations.text_317
              ? const Color.fromRGBO(69, 69, 69, 0.1)
              : (stop["color"] == "min"
              ? const Color.fromRGBO(13, 168, 255, 0.1)
              : const Color.fromRGBO(68, 68, 68, 0.1))));

          return SizeFadeTransition(
            animation: animation,
            curve: Curves.easeInOut,
            sizeFraction: 0.9,
            child: Column(
              children: [
                SizedBox(
                  height: 53.0,
                  child: ListTile(
                    onTap: () async {
                      final rawData = await getBusRouteWithId(
                        city: "Taichung",
                        routeId: stop["RouteID"],
                      );
                      if (!context.mounted) return;
                      BusRoute route = BusRoute.fromJson(rawData);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusTime(
                            routeName: route.routeZh,
                            departureStopName: route.departureStopNameZh,
                            destinationStopName: route.destinationStopNameZh,
                            operators: route.operatorName,
                            routeMapImageUrl: route.routeMapUrl,
                            city: route.routeCity ?? 'InterCity',
                            routeID: route.routeId,
                            hasSubRoutes: route.hasSubRoute,
                            data: route,
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        stop["time"] ?? localizations.text_321,
                        style: TextStyle(
                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? Colors.white
                              : (stop["color"] == '2'
                              ? const Color.fromRGBO(255, 85, 104, 1)
                              : (stop["color"] == localizations.text_317
                              ? const Color.fromRGBO(149, 149, 149, 1.0)
                              : (stop["color"] == "min"
                              ? const Color.fromRGBO(13, 168, 255, 1)
                              : const Color.fromRGBO(68, 68, 68, 1)))),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          stop["RouteName"]?["Zh_tw"] ?? localizations.text_322,
                          style: TextStyle(
                            fontFamily:
                            stop["color"] == "0" ? 'MiSans-Semibold' : 'MiSans-normal',
                            fontSize: 17,
                            color: stop["color"] == localizations.text_317
                                ? const Color.fromRGBO(136, 136, 136, 1)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "往 ${stop["to"] ?? localizations.text_323}",
                          style: const TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: Color.fromRGBO(136, 136, 136, 1),
                          ),
                        ),
                      ],
                    ),
                    trailing: plateNumb != null ? bubble(plateNum: plateNumb) : null,
                  ),
                ),
                const Divider(
                  color: Color.fromRGBO(231, 231, 231, 1),
                  height: 9,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return -1;
    final localizations = AppLocalizations.of(context)!;

    if (time.contains(localizations.text_332)) {
      return int.tryParse(time.split(" ").first) ?? -1;
    }

    if (time.contains(":")) {
      final parts = time.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;

        DateTime now = DateTime.now();
        DateTime parsedTime = DateTime(now.year, now.month, now.day, hour, minute);

        if (parsedTime.isBefore(now)) {
          parsedTime = parsedTime.add(const Duration(days: 1));
        }

        return parsedTime.difference(now).inMinutes;
      }
    }

    return -1;
  }

  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {
    List<dynamic> info = await StopInfoCache().getStopInfo(widget.stop, "Taichung");
    List<Map<String, dynamic>> tempData = [];

    for (var _ in info) {
      var stationInfo = await fetchStationInfo(_stationIDs.value, "Taichung");
      for (var stop in stationInfo) {
        var timeData = await getTimeList(stop);
        stop["time"] = timeData["time"];
        stop["isRed"] = timeData["isRed"];
        stop["color"] = timeData["color"];
      }
      tempData.addAll(stationInfo);
    }

    return tempData;
  }

  Future<Map<String, dynamic>> getTimeList(Map<String, dynamic> stopData) async {
    final localizations = AppLocalizations.of(context)!;

    if (stopData["EstimateTime"] != null) {
      if (stopData["EstimateTime"] == 0) {
        List plateNumb = [];
        if (stopData['Estimates'] != null) {
          for (var estimate in stopData['Estimates']) {
            plateNumb.add(estimate["PlateNumb"]);
          }
        }
        return {
          "color": '0',
          "time": localizations.text_316,
          "isRed": '0',
          "PlateNumb": plateNumb.toString()
        };
      } else {
        int result = (stopData["EstimateTime"] / 60).floor();
        List plateNumb = [];
        if (stopData['Estimates'] != null) {
          for (var estimate in stopData['Estimates']) {
            plateNumb.add(estimate["PlateNumb"]);
          }
        }

        return {
          "color": result < 3 ? "2" : "min",
          "time": result < 1 ? localizations.text_316 : "$result 分鐘",
          "isRed": result < 3 ? "2" : "",
          "PlateNumb": result < 20 ? plateNumb.toString() : ""
        };
      }
    } else if (stopData["NextBusTime"] != null) {
      Duration difference =
      DateTime.parse(stopData["NextBusTime"]).difference(DateTime.now());
      if (difference.inHours == 0) {
        return {
          "time": difference.inMinutes.remainder(60) <= 0
              ? localizations.text_317
              : "${difference.inMinutes.remainder(60)} 分鐘",
          "isRed": '',
          "PlateNumb": "",
          "color": difference.inMinutes.remainder(60) <= 0 ? localizations.text_317 : "min",
        };
      } else {
        DateTime nextBusTime = DateTime.now().add(
          Duration(hours: difference.inHours, minutes: difference.inMinutes.remainder(60)),
        );
        return {
          'time':
          "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}",
          "isRed": '',
          "PlateNumb": "",
          "color": localizations.text_317
        };
      }
    } else {
      return {
        "time": localizations.text_317,
        "isRed": '',
        "PlateNumb": "",
        "color": localizations.text_317
      };
    }
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sort_rounded,
                        size: 24,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.text_318,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSortOption(
                  '站序 1→10',
                  SortType.nameAsc,
                  Icons.numbers_rounded,
                  const Color(0xFF1A73E8),
                ),
                _buildSortOption(
                  '站序 10→1',
                  SortType.nameDesc,
                  Icons.numbers_rounded,
                  const Color(0xFF1A73E8),
                ),
                _buildSortOption(
                  AppLocalizations.of(context)!.text_319,
                  SortType.timeAsc,
                  Icons.access_time_rounded,
                  const Color(0xFF34C759),
                ),
                _buildSortOption(
                  AppLocalizations.of(context)!.text_320,
                  SortType.timeDesc,
                  Icons.access_time_rounded,
                  const Color(0xFFFF9500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, SortType type, IconData icon, Color color) {
    final isSelected = _sortNotifier.value == type;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _sortNotifier.value = type;
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                  : Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MRTStationList extends StatefulWidget {
  final String station;

  const MRTStationList({
    super.key,
    required this.station,
  });

  @override
  State<MRTStationList> createState() => _MRTStationListState();
}

class _MRTStationListState extends State<MRTStationList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      // child: SingleChildScrollView(
      //   child: buildStationInfo(widget.station),
      // ),
    );
  }
}

class BusStopCache {
  static final BusStopCache _instance = BusStopCache._internal();
  factory BusStopCache() => _instance;

  final Map<String, CachedData<List<Map<String, dynamic>>>> _cache = {};
  final Lock _lock = Lock();
  int _maxSize = 10;
  String _currentCity = 'Taichung';
  final List<String> _accessRecords = [];
  static const Duration _defaultExpiry = Duration(minutes: 5);

  BusStopCache._internal();

  void config({int? maxSize, String? city}) {
    _lock.synchronized(() {
      if (maxSize != null && maxSize > 0) {
        _maxSize = maxSize;
        _cleanup();
      }
      if (city != null) {
        _currentCity = city;
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBusStopInfo(String stationName) async {
    final cacheKey = _generateKey(stationName);

    return await _lock.synchronized(() async {
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (cached.expiry.isAfter(DateTime.now())) {
          _recordAccess(cacheKey);
          return cached.data;
        } else {
          _cache.remove(cacheKey);
          _accessRecords.removeWhere((k) => k == cacheKey);
        }
      }

      final data = await _fetchData(stationName);
      _updateCache(cacheKey, data);
      return data;
    });
  }

  String _generateKey(String stationName) => '${_currentCity}_$stationName';

  Future<List<Map<String, dynamic>>> _fetchData(String stationName) async {
    return await GetBusStopInfo(stopName: stationName, city: _currentCity);
  }

  void _updateCache(String key, List<Map<String, dynamic>> data) {
    _lock.synchronized(() {
      if (_cache.containsKey(key)) {
        _accessRecords.removeWhere((k) => k == key);
      }
      _cache[key] = CachedData<List<Map<String, dynamic>>>(
        data: data,
        expiry: DateTime.now().add(_defaultExpiry),
      );
      _accessRecords.add(key);
      _cleanup();
    });
  }

  void _cleanup() {
    while (_cache.length > _maxSize) {
      final oldestKey = _accessRecords.first;
      _cache.remove(oldestKey);
      _accessRecords.removeAt(0);
    }
  }

  void _recordAccess(String key) {
    _lock.synchronized(() {
      _accessRecords.removeWhere((k) => k == key);
      _accessRecords.add(key);
    });
  }

  void clear() {
    _lock.synchronized(() {
      _cache.clear();
      _accessRecords.clear();
    });
  }

  void remove(String stationName) {
    final key = _generateKey(stationName);
    _lock.synchronized(() {
      _cache.remove(key);
      _accessRecords.removeWhere((k) => k == key);
    });
  }
}

class CachedData<T> {
  final T data;
  final DateTime expiry;
  CachedData({required this.data, required this.expiry});
}

class StopInfoCache {
  static final StopInfoCache _instance = StopInfoCache._internal();
  factory StopInfoCache() => _instance;

  final Map<String, CachedData<List<dynamic>>> _cache = {};
  final List<String> _recentKeys = [];
  final int _maxCacheSize = 10;
  final Duration _cacheExpiry = const Duration(minutes: 5);

  StopInfoCache._internal();

  Future<List<dynamic>> getStopInfo(String stop, String city) async {
    final key = '$city-$stop';

    if (_cache.containsKey(key)) {
      final cachedData = _cache[key]!;
      if (cachedData.expiry.isAfter(DateTime.now())) {
        _recordAccess(key);
        return cachedData.data;
      } else {
        _cache.remove(key);
        _recentKeys.remove(key);
      }
    }

    List<dynamic> info = await GetBusStopInfo(stopName: stop, city: city);
    _updateCache(key, info);
    return info;
  }

  void _updateCache(String key, List<dynamic> data) {
    if (_cache.containsKey(key)) {
      _recentKeys.remove(key);
    }
    _cache[key] = CachedData<List<dynamic>>(
      data: data,
      expiry: DateTime.now().add(_cacheExpiry),
    );
    _recentKeys.add(key);

    if (_recentKeys.length > _maxCacheSize) {
      final oldestKey = _recentKeys.removeAt(0);
      _cache.remove(oldestKey);
    }
  }

  void _recordAccess(String key) {
    _recentKeys.remove(key);
    _recentKeys.add(key);
  }

  void clear() {
    _cache.clear();
    _recentKeys.clear();
  }
}