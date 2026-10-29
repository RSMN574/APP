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

import '../../../const/app_colors.dart';
import '../../../const/regular_class.dart';
import '../../../const/regular_const.dart';
import '../../../const/surface_decoration.dart';
import '../../../database/get_data.dart';
import '../../../database/mrt/get_mrt_info.dart';
import '../../../database/sql/favorite_feature.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/mrt_station.dart';
import '../../../utils/convert.dart';
import '../../../widget/map.dart';
import '../../../widget/tab.dart';
import '../../bus/data/get_bus_time.dart';
import '../../bus/data/get_station_info.dart';
import '../../bus/model/bus_route_model.dart';
import '../../bus/model/bus_station_model.dart';

import '../../bus/pages/bus_time_page.dart';
import '../../bus/widgets/bubble.dart';
import '../../railway/pages/train_page.dart';
import '../nearby_stations_controller.dart';

String _localizedName(BuildContext context, dynamic names,
    {String fallback = ''}) {
  if (names is! Map) return fallback;
  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final preferred = names[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
  if (preferred.trim().isNotEmpty) return preferred;
  final other = names[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
  return other.trim().isNotEmpty ? other : fallback;
}

class NearbyStationsPage extends StatefulWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  State<NearbyStationsPage> createState() => NearbyStationsPageState();
}

class NearbyStationsPageState extends State<NearbyStationsPage> {
  GoogleMapController? _mapController;
  Future<List<BusStationInfo>>? _futureNearStations;
  final DraggableScrollableController _scrollController =
  DraggableScrollableController();
  MarkerProvider? _markerProvider;

  final NearbyStationsController _controller = NearbyStationsController();

  GoogleMapController? get mapController => _mapController;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _busInit();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _updateFutureNearStations() async {
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);
    setState(() {
      _futureNearStations = getNearStation(
        Uri.encodeComponent(
            "${locationProvider.latitude},${locationProvider.longitude}"),
      );
    });
  }

  void _busInit() async {
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);
    _futureNearStations = getNearStation(
      Uri.encodeComponent(
          "${locationProvider.latitude},${locationProvider.longitude}"),
    );
    final stations = await _futureNearStations;
    if (mounted) {
      _loadBusMarkers(stations);
    }
  }

  List<Map<String, dynamic>> _convertStations(
      String type, List<dynamic> stations) {
    if (type == "metro") {
      return stations.map((station) {
        return {
          "stationID": station["StationID"].toString(),
          "stationNameZh": (station["StationName"])["Zh_tw"] ?? "Unknown",
          "stationNameEn": (station["StationName"])["En"] ?? "",
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
          "stationNameEn": nameMap["En"] ?? "",
          "positionLat": posMap["PositionLat"],
          "positionLon": posMap["PositionLon"],
        };
      }).toList();
    }
    return [];
  }

  void _handleTabSelectChange() async {
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);
    if (_controller.tabSelect == "bus") {
      await _updateFutureNearStations();
      final stations = await _futureNearStations;
      if (mounted) {
        _loadBusMarkers(stations);
      }
    } else if (_controller.tabSelect == "metro") {
      final stations = await getNearMRTStation(
        Uri.encodeComponent(
            "${locationProvider.latitude},${locationProvider.longitude}"),
      );
      if (mounted) {
        _loadMarkers(
          _convertStations("metro", stations.map((s) => s.toJson()).toList()),
        );
      }
    } else if (_controller.tabSelect == "train") {
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
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _markerProvider?.setMarkers({});
    super.dispose();
  }

  int _markerTapSeq = 0;

  Future<void> _loadBusMarkers(List<BusStationInfo>? stations) async {
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
          title: _localizedName(context, {
            "Zh_tw": station.stationNameZh,
            "En": station.stationNameEn,
          }),
          snippet: station.stationID,
        ),
        onTap: () async {
          final stopName = station.stationNameZh;
          final stopID = station.stationID;
          final stationGroupID = station.stationGroupID;
          final tapSeq = ++_markerTapSeq;

          try {
            final data = await BusStopCache().getBusStopInfo(stopName);
            if (tapSeq != _markerTapSeq) return;
            final stationIDs = data
                .map((item) => item['StationID']?.toString())
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .toList();

            if (stationIDs.isEmpty) return;
            if (!mounted) return;

            if (_isSameStationGroup(_controller.stationIDs, stationIDs)) {
              _controller.setSelectStationID(stopID);
            } else {
              _controller.setStopName(stopName, en: station.stationNameZh);
              _controller.setSelectStationGroupID(stationGroupID);
              _controller.setStationIDs(stationIDs);
              _controller.setSelectStationID(stopID);
            }

            _controller.setIndex(1);

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
    _controller.setMarkers(markers);
    _controller.updateMarkerStyle();
  }

  bool _isSameStationGroup(List<String>? oldList, List<String>? newList) {
    if ((oldList == null || oldList.isEmpty) &&
        (newList == null || newList.isEmpty)) {
      return false;
    }
    if (oldList == null ||
        oldList.isEmpty ||
        newList == null ||
        newList.isEmpty) {
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
      final stationName = _localizedName(context, {
        "Zh_tw": station["stationNameZh"] ?? "Unknown",
        "En": station["stationNameEn"],
      });
      final positionLat = station["positionLat"];
      final positionLon = station["positionLon"];

      if (stationID == null || positionLat == null || positionLon == null) {
        continue;
      }

      final marker = Marker(
        markerId: MarkerId(stationID),
        position: LatLng(positionLat, positionLon),
        infoWindow: InfoWindow(title: stationName, snippet: stationID),
      );
      markers.add(marker);
    }

    _controller.setMarkers(markers);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locationProvider = Provider.of<LocationProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight =
        screenHeight - (screenHeight * 0.2) - appBarHeight - bottomNavBarHeight;

    return PopScope(
      canPop: _controller.index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _controller.index > 0) {
          _controller.setIndex(_controller.index - 1);
        }
      },
      child: Scaffold(
        backgroundColor: colors.cardBackground,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: colors.cardBackground,
                child: SizedBox(
                  height: mapHeight,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return map(
                        markers: _controller.markers,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              controller: _scrollController,
              initialChildSize: 0.43,
              minChildSize: 0.3,
              maxChildSize: 0.96,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -10,
                      left: MediaQuery.of(context).size.width / 2 - 20,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          double delta = details.primaryDelta! /
                              MediaQuery.of(context).size.height;
                          final currentSize = _scrollController.isAttached
                              ? _scrollController.size
                              : 0.43;
                          double newSize =
                          (currentSize - delta).clamp(0.1, 0.96);
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
                            color: colors.textHint.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 800,
                      decoration: BoxDecoration(
                        color: AppThemes.getSurface(context),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return IndexedStack(
                            index: _controller.index,
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
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, pageIndex) {
                                      switch (pageIndex) {
                                        case 0:
                                          _controller.setTabSelect("bus");
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            child: FutureBuilder<
                                                List<BusStationInfo>>(
                                              future: _futureNearStations,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Center(
                                                    child: Padding(
                                                      padding:
                                                      const EdgeInsets.only(
                                                          top: 40),
                                                      child:
                                                      LoadingAnimationWidget
                                                          .stretchedDots(
                                                        color:
                                                        colors.textPrimary,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                if (snapshot.hasError) {
                                                  return _buildErrorColumn(
                                                    colors,
                                                    onRetry: () =>
                                                        _updateFutureNearStations(),
                                                  );
                                                }
                                                if (snapshot.hasData &&
                                                    snapshot.data != null &&
                                                    snapshot
                                                        .data!.isNotEmpty) {
                                                  final groupedStations =
                                                  <String,
                                                      List<Map<String,
                                                          dynamic>>>{};
                                                  final stationNamesEn =
                                                  <String, String>{};
                                                  for (var station
                                                  in snapshot.data!) {
                                                    final stationName =
                                                        station.stationNameZh;
                                                    groupedStations
                                                        .putIfAbsent(
                                                        stationName,
                                                            () => [])
                                                        .add(station.toJson());
                                                  }

                                                  final result =
                                                  groupedStations.entries
                                                      .map((entry) {
                                                    return {
                                                      "StationGroup": {
                                                        "StationGroupName": {
                                                          "Zh_tw": entry.key,
                                                          "En": stationNamesEn[
                                                          entry.key]
                                                        },
                                                        "Stations": entry.value
                                                      }
                                                    };
                                                  }).toList();

                                                  return Padding(
                                                    padding:
                                                    const EdgeInsets.all(
                                                        16.0),
                                                    child: Column(
                                                      children: result
                                                          .map((station) =>
                                                          _stationCard(
                                                              station:
                                                              station))
                                                          .toList(),
                                                    ),
                                                  );
                                                }
                                                return _buildEmptyColumn(
                                                    colors);
                                              },
                                            ),
                                          );
                                        case 1:
                                          _controller.setTabSelect("metro");
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            child: FutureBuilder<
                                                List<MRTStation>>(
                                              future: getNearMRTStation(
                                                Uri.encodeComponent(
                                                  "${locationProvider.latitude},${locationProvider.longitude}",
                                                ),
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Center(
                                                    child:
                                                    LoadingAnimationWidget
                                                        .stretchedDots(
                                                      color: colors.textPrimary,
                                                      size: 40,
                                                    ),
                                                  );
                                                }
                                                if (snapshot.hasError) {
                                                  return _buildErrorColumn(
                                                    colors,
                                                    onRetry: () =>
                                                        setState(() {}),
                                                  );
                                                }
                                                final stations =
                                                    snapshot.data ?? [];
                                                if (stations.isEmpty) {
                                                  return _buildEmptyColumn(
                                                      colors);
                                                }
                                                return Padding(
                                                  padding:
                                                  const EdgeInsets.all(16),
                                                  child: Column(
                                                    children: stations
                                                        .map((s) =>
                                                        _mrtStationCard(
                                                            station: s))
                                                        .toList(),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        case 2:
                                          _controller.setTabSelect("train");
                                          return SingleChildScrollView(
                                            controller: scrollController,
                                            child:
                                            FutureBuilder<List<dynamic>>(
                                              future: getNearTrainStation(
                                                locationProvider.latitude,
                                                locationProvider.longitude,
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Center(
                                                    child:
                                                    LoadingAnimationWidget
                                                        .stretchedDots(
                                                      color: colors.textPrimary,
                                                      size: 40,
                                                    ),
                                                  );
                                                } else if (snapshot
                                                    .hasError) {
                                                  return _buildErrorColumn(
                                                    colors,
                                                    onRetry: () =>
                                                        setState(() {}),
                                                  );
                                                } else if (snapshot
                                                    .hasData) {
                                                  return Padding(
                                                    padding:
                                                    const EdgeInsets.all(
                                                        16.0),
                                                    child: Column(
                                                      children: List.generate(
                                                        snapshot.data!.length,
                                                            (idx) {
                                                          final station =
                                                          snapshot
                                                              .data![idx];
                                                          final nameMap = json
                                                              .decode(station[
                                                          "StationName"]);
                                                          return GestureDetector(
                                                            onTap: () {
                                                              final today =
                                                              DateTime
                                                                  .now();
                                                              final todayDate =
                                                              DateTime(
                                                                today.year,
                                                                today.month,
                                                                today.day,
                                                              );
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      StationPage(
                                                                        stationName:
                                                                        nameMap[
                                                                        "Zh_tw"],
                                                                        stationNameEn:
                                                                        nameMap["En"]?.toString() ??
                                                                            '',
                                                                        stationID:
                                                                        station[
                                                                        "StationID"],
                                                                        datetime:
                                                                        todayDate,
                                                                      ),
                                                                ),
                                                              );
                                                            },
                                                            child: Container(
                                                              margin: const EdgeInsets
                                                                  .symmetric(
                                                                vertical: 8,
                                                                horizontal: 12,
                                                              ),
                                                              padding: const EdgeInsets
                                                                  .symmetric(
                                                                vertical: 12,
                                                                horizontal: 16,
                                                              ),
                                                              decoration:
                                                              SurfaceDecoration
                                                                  .cardShadow(
                                                                context,
                                                                radius: 12,
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                                children: [
                                                                  Text(
                                                                    _localizedName(
                                                                        context,
                                                                        nameMap),
                                                                    style:
                                                                    TextStyle(
                                                                      fontSize:
                                                                      16,
                                                                      fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                      color: colors
                                                                          .textPrimary,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                      8),
                                                                  Divider(
                                                                    color: colors
                                                                        .divider,
                                                                    thickness:
                                                                    0.5,
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
                                                  return _buildEmptyColumn(
                                                      colors);
                                                }
                                              },
                                            ),
                                          );
                                        case 3:
                                          _controller.setTabSelect("HSR");
                                          return Center(
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .text_421,
                                              style: TextStyle(
                                                  color: colors.textPrimary),
                                            ),
                                          );
                                        default:
                                          return Center(
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .text_422,
                                              style: TextStyle(
                                                  color: colors.textPrimary),
                                            ),
                                          );
                                      }
                                    },
                                  );
                                },
                              ),
                              _buildDraggableScrollableSheetPageTwo(
                                  scrollController),
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
                  splashColor: colors.info.withOpacity(0.2),
                  highlightColor: colors.mutedBackground,
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: colors.info,
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

  Widget _buildErrorColumn(AppColors colors,
      {required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.text_419,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: colors.info),
            label: Text(
              AppLocalizations.of(context)!.text_420,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.cardBackground,
              foregroundColor: colors.textPrimary,
              elevation: 3,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: colors.shadow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.text_419,
          style: TextStyle(color: colors.textSecondary, fontSize: 16),
        ),
      ),
    );
  }

  Widget _stationCard({required Map<String, dynamic> station}) {
    final colors = context.appColors;
    final List<String> stationIDs =
        (station["StationGroup"]["Stations"] as List<dynamic>?)
            ?.map((s) => s["stationID"].toString())
            .toList() ??
            [];
    final firstStation = station["StationGroup"]["Stations"][0];

    void onCardTap() {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              firstStation["positionLat"],
              firstStation["positionLon"],
            ),
            zoom: 19.0,
          ),
        ),
      );

      _controller.setStopName(
        station["StationGroup"]["StationGroupName"]["Zh_tw"],
        en: station["StationGroup"]["StationGroupName"]["En"]?.toString() ?? '',
      );
      _controller.setStationIDs(stationIDs);
      _controller
          .setSelectStationID(stationIDs.isEmpty ? '' : stationIDs.first);
      _controller.setIndex(1);
    }

    return GestureDetector(
      onTap: onCardTap,
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          if (_controller.index > 0) {
            _controller.setIndex(1);
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
            splashColor: colors.info.withOpacity(0.1),
            highlightColor: colors.mutedBackground,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: SurfaceDecoration.cardShadow(context, radius: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.infoContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.train_rounded,
                      size: 20,
                      color: colors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _localizedName(context,
                          station["StationGroup"]["StationGroupName"]),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: SurfaceDecoration.muted(context, radius: 8),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textSecondary,
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
    final colors = context.appColors;
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
          _controller.setStopName(station.stationName.zhTw,
              en: station.stationName.en ?? '');
          _controller.setStationIDs([station.stationID]);
          _controller.setIndex(1);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: colors.success.withOpacity(0.1),
        highlightColor: colors.mutedBackground,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: SurfaceDecoration.cardShadow(context, radius: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.subway_rounded,
                  size: 20,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedName(context, {
                        "Zh_tw": station.stationName.zhTw,
                        "En": station.stationName.en,
                      }),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
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
                          color: colors.textSecondary,
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
                decoration: SurfaceDecoration.muted(context, radius: 8),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 選中站點後顯示的「到站資訊」面板。
  ///
  /// - bus / train / HSR 都走同一套 `BusStopList`
  /// - metro 走 `MRTStationList`
  Widget _buildDraggableScrollableSheetPageTwo(
      ScrollController scrollController) {
    final colors = context.appColors;
    final tab = _controller.tabSelect;

    if (tab == "metro") {
      return Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrimaryScrollController(
          controller: scrollController,
          child: MRTStationList(
            station: _controller.stopName,
          ),
        ),
      );
    }

    // bus / train / HSR 統一使用 BusStopList
    if (tab == "bus" || tab == "train" || tab == "HSR") {
      return Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrimaryScrollController(
          controller: scrollController,
          child: BusStopList(
            _controller.stopName,
            controller: _controller,
            key: ValueKey(_controller.stopName),
          ),
        ),
      );
    }

    // fallback
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PrimaryScrollController(
        controller: scrollController,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.text_422,
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class BusStopList extends StatefulWidget {
  final String stop;
  final NearbyStationsController controller;

  const BusStopList(this.stop, {super.key, required this.controller});

  @override
  State<StatefulWidget> createState() => _BusStopListState();
}

class _BusStopListState extends State<BusStopList>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<BusStopList> {
  final StreamController<List<Map<String, dynamic>>> _streamController =
  StreamController.broadcast();
  late TabController _tabController;

  NearbyStationsController get _ctrl => widget.controller;

  String? _minuteUnit;

  @override
  void initState() {
    super.initState();

    final ids = _ctrl.stationIDs;
    int initialIndex = ids.indexOf(_ctrl.selectStationID);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: ids.isEmpty ? 1 : ids.length,
      vsync: this,
      initialIndex:
      initialIndex.clamp(0, ids.isEmpty ? 0 : ids.length - 1),
    );

    _ctrl.addListener(_onControllerChanged);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ctrl.stationIDs.isEmpty) return;
      final currentIds = _ctrl.stationIDs;
      if (!currentIds.contains(_ctrl.selectStationID)) {
        _ctrl.setSelectStationID(currentIds[_tabController.index]);
      }
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final ids = _ctrl.stationIDs;
    if (ids.isNotEmpty && ids.length != _tabController.length) {
      final old = _tabController;
      final oldIndex = old.index;
      old.removeListener(_onTabChanged);
      old.dispose();
      _tabController = TabController(
        length: ids.length,
        vsync: this,
        initialIndex: oldIndex.clamp(0, ids.length - 1),
      );
      _tabController.addListener(_onTabChanged);
    }
    setState(() {});
  }

  void _onTabChanged() {
    final ids = _ctrl.stationIDs;
    final index = _tabController.index;
    if (!mounted ||
        ids.length != _tabController.length ||
        index >= ids.length) {
      return;
    }
    if (_ctrl.selectStationID != ids[index]) {
      _ctrl.setSelectStationID(ids[index]);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    _tabController.removeListener(_onTabChanged);
    _streamController.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _minuteUnit = AppLocalizations.of(context)!.text_332;
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
            (currentTime != -1 &&
                currentTime < _parseTimeToMinutes(existing["time"]))) {
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
                final parsed =
                json.decode(routeNameField) as Map<String, dynamic>;
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
      final l10n = AppLocalizations.of(context)!;

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

        resultItem["RouteID"] = hasValidInfo
            ? (routeInfo["RouteID"]?.toString() ?? l10n.text_321)
            : l10n.text_321;

        String? departureName;
        String? destinationName;
        String? departureNameEn;
        String? destinationNameEn;

        if (hasValidInfo) {
          departureName = routeInfo["DepartureStopNameZh"]?.toString() ??
              routeInfo["DepartureStopName"]?.toString();
          destinationName = routeInfo["DestinationStopNameZh"]?.toString() ??
              routeInfo["DestinationStopName"]?.toString();
          departureNameEn = routeInfo["DepartureStopNameEn"]?.toString();
          destinationNameEn = routeInfo["DestinationStopNameEn"]?.toString();
        }

        resultItem["DepartureStopName"] = departureName ?? l10n.text_325;
        resultItem["DestinationStopName"] = destinationName ?? l10n.text_326;

        final isDirection1 = direction == 1;
        resultItem["from"] = isDirection1
            ? (destinationName ?? l10n.text_428)
            : (departureName ?? l10n.text_429);
        resultItem["to"] = isDirection1
            ? (departureName ?? l10n.text_429)
            : (destinationName ?? l10n.text_428);
        final toEn = isDirection1 ? departureNameEn : destinationNameEn;
        resultItem["toEn"] =
        (toEn != null && toEn.trim().isNotEmpty) ? toEn : null;

        processedData.add(resultItem);
      }

      return processedData;
    } catch (e) {
      debugPrint('Error processing data: $e');
      return [];
    }
  }

  String _tabLabel(int index) {
    if (index < 26) return String.fromCharCode(65 + index);
    return '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.stretchedDots(
                  color: colors.textPrimary,
                  size: 40,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!
                      .nearStopLoadError('${snapshot.error}'),
                  style: TextStyle(color: colors.textSecondary),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.text_430,
                  style: TextStyle(color: colors.textSecondary),
                ),
              );
            }

            if (_ctrl.stationIDs.isEmpty) {
              return const SizedBox();
            }

            return Column(
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(120),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      color: colors.cardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow,
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
                        _localizedName(context, {
                          'Zh_tw': _ctrl.stopName,
                          'En': _ctrl.stopNameEn,
                        }),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      leading: IconButton(
                        icon: Icon(Icons.close, color: colors.textPrimary),
                        onPressed: () {
                          if (_ctrl.index > 0) {
                            _ctrl.setIndex(_ctrl.index - 1);
                            _ctrl.clearStationSelection();
                          }
                        },
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: SurfaceDecoration.muted(
                                context,
                                radius: 10,
                              ),
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: colors.info,
                              ),
                            ),
                            onPressed: () => setState(() {}),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: SurfaceDecoration.muted(
                                context,
                                radius: 10,
                              ),
                              child: Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: colors.info,
                              ),
                            ),
                            color: colors.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colors.border,
                                width: 1,
                              ),
                            ),
                            itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              _buildPopupMenuItem(
                                icon: Icons.info_outline_rounded,
                                title: AppLocalizations.of(context)!.text_333,
                                value: 'info',
                                color: colors.info,
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.favorite_border_rounded,
                                title: AppLocalizations.of(context)!.text_334,
                                value: 'favorite',
                                color: colors.danger,
                              ),
                              _buildPopupMenuItem(
                                icon: Icons.sort_rounded,
                                title: AppLocalizations.of(context)!.text_335,
                                value: 'sort',
                                color: colors.success,
                              ),
                            ],
                            onSelected: (String action) async {
                              if (action == 'favorite') {
                                final dbHelper = favorite_feature();
                                final output =
                                await dbHelper.addFavoriteStop(
                                  stopName: widget.stop,
                                  city: "Taichung",
                                );
                                if (!mounted) return;

                                if (output == 100) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.success,
                                    text: AppLocalizations.of(context)!
                                        .nearStopSaved(widget.stop),
                                  );
                                } else if (output == -1) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.warning,
                                    text: AppLocalizations.of(context)!
                                        .nearStopAlreadySaved(widget.stop),
                                  );
                                } else if (output == 200) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.error,
                                    title: 'Oops...',
                                    text:
                                    AppLocalizations.of(context)!.text_336,
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
                      _ctrl.stationIDs.length,
                          (index) {
                        return FutureBuilder<Widget>(
                          future: _buildTabContent(
                            _ctrl.stationIDs[index],
                            snapshot.data!,
                          ),
                          builder: (context, contentSnapshot) {
                            if (contentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: LoadingAnimationWidget.stretchedDots(
                                  color: colors.textPrimary,
                                  size: 40,
                                ),
                              );
                            }
                            if (contentSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${contentSnapshot.error}',
                                  style:
                                  TextStyle(color: colors.textSecondary),
                                ),
                              );
                            }
                            return contentSnapshot.data ??
                                Center(
                                  child: Text(
                                    "No content available",
                                    style: TextStyle(
                                        color: colors.textSecondary),
                                  ),
                                );
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

  PreferredSize _buildTabBar(
      List<Map<String, dynamic>> station, TabController tabController) {
    final colors = context.appColors;
    final ids = _ctrl.stationIDs;
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: colors.cardBackground),
        child: AnimatedBuilder(
          animation: tabController,
          builder: (context, child) {
            final currentIndex = tabController.index;
            return Row(
              children: List.generate(ids.length, (index) {
                final label = _tabLabel(index);
                final isSelected = currentIndex == index;

                return Expanded(
                  child: Padding(
                    padding: index < ids.length - 1
                        ? const EdgeInsets.only(right: 8)
                        : EdgeInsets.zero,
                    child: GestureDetector(
                      onTap: () => tabController.animateTo(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.info.withOpacity(0.08)
                              : colors.mutedBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? colors.info : colors.border,
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
                                  color: isSelected
                                      ? colors.info
                                      : colors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .nearStopLabel(label),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? colors.info
                                          : colors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              ids[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colors.info.withOpacity(0.8)
                                    : colors.textSecondary,
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
    final finalList = await _processData(stationID, stopEstimatedTime);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final sortedList = [...finalList];

        switch (_ctrl.sortType) {
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
    final l10n = AppLocalizations.of(context)!;
    final comingSoon = l10n.text_316;
    final unknown = l10n.text_317;
    if (a["time"] == comingSoon) return -1;
    if (b["time"] == comingSoon) return 1;
    if (a["time"] == unknown) return 1;
    if (b["time"] == unknown) return -1;
    return _parseTimeToMinutes(a['time'])
        .compareTo(_parseTimeToMinutes(b['time']));
  }

  int _timeDescComparator(Map<String, dynamic> a, Map<String, dynamic> b) {
    final l10n = AppLocalizations.of(context)!;
    final comingSoon = l10n.text_316;
    final unknown = l10n.text_317;
    if (a["time"] == comingSoon) return 1;
    if (b["time"] == comingSoon) return -1;
    if (a["time"] == unknown) return -1;
    if (b["time"] == unknown) return 1;
    return _parseTimeToMinutes(b['time'])
        .compareTo(_parseTimeToMinutes(a['time']));
  }

  Widget _buildTabContentUI(List<Map<String, dynamic>> finalList) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: const ValueKey('bus_stop_list'),
        items: finalList,
        areItemsTheSame: (a, b) =>
        a["RouteID"] == b["RouteID"] &&
            a["Direction"] == b["Direction"],
        itemBuilder: (context, animation, stop, index) {
          final plateNumb = stop["PlateNumb"];
          final colorKey = stop["color"]?.toString();

          final Color pillBg = colorKey == '0'
              ? colors.danger
              : colorKey == '2'
              ? colors.dangerContainer
              : colorKey == l10n.text_317
              ? colors.mutedBackground
              : colorKey == 'min'
              ? colors.infoContainer
              : colors.mutedBackground;

          final Color pillFg = colorKey == '0'
              ? colors.cardBackground
              : colorKey == '2'
              ? colors.danger
              : colorKey == l10n.text_317
              ? colors.textHint
              : colorKey == 'min'
              ? colors.info
              : colors.textPrimary;

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
                      final tappedDirection = stop["Direction"] is int
                          ? stop["Direction"] as int
                          : int.tryParse("${stop["Direction"]}");
                      final rawData = await getBusRouteWithId(
                        city: "Taichung",
                        routeId: stop["RouteID"],
                      );
                      if (!context.mounted) return;
                      final route = BusRoute.fromJson(rawData);
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
                            mark: tappedDirection == null
                                ? null
                                : Mark(direction: tappedDirection),
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        stop["time"] ?? l10n.text_321,
                        style: TextStyle(
                          fontSize: 17,
                          color: pillFg,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          _localizedName(context, stop["RouteName"],
                              fallback: l10n.text_322),
                          style: TextStyle(
                            fontFamily: colorKey == "0"
                                ? 'MiSans-Semibold'
                                : 'MiSans-normal',
                            fontSize: 17,
                            color: colorKey == l10n.text_317
                                ? colors.textSecondary
                                : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.nearStopTo(
                            Localizations.localeOf(context).languageCode ==
                                'en' &&
                                stop["toEn"] != null
                                ? stop["toEn"]
                                : (stop["to"] ?? l10n.text_323),
                          ),
                          style: TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                    plateNumb != null ? bubble(plateNum: plateNumb) : null,
                  ),
                ),
                Divider(
                  color: colors.divider,
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

    final minuteUnit =
        _minuteUnit ?? AppLocalizations.of(context)!.text_332;
    if (time.contains(minuteUnit)) {
      return int.tryParse(time.split(" ").first) ?? -1;
    }

    if (time.contains(":")) {
      final parts = time.split(":");
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final now = DateTime.now();
        var parsed = DateTime(now.year, now.month, now.day, hour, minute);
        if (parsed.isBefore(now)) {
          parsed = parsed.add(const Duration(days: 1));
        }
        return parsed.difference(now).inMinutes;
      }
    }

    return -1;
  }

  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {
    final info = await StopInfoCache().getStopInfo(widget.stop, "Taichung");
    if (info.isEmpty) return [];

    final stationInfo =
    await fetchStationInfo(_ctrl.stationIDs, "Taichung");
    if (stationInfo.isEmpty) return [];

    for (final stop in stationInfo) {
      final timeData = await getTimeList(stop);
      stop["time"] = timeData["time"];
      stop["isRed"] = timeData["isRed"];
      stop["color"] = timeData["color"];
    }
    return stationInfo;
  }

  Future<Map<String, dynamic>> getTimeList(
      Map<String, dynamic> stopData) async {
    final l10n = AppLocalizations.of(context)!;

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
          "time": l10n.text_316,
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
          "time": result < 1
              ? l10n.text_316
              : l10n.nearStopMinutes(result.toString()),
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
              ? l10n.text_317
              : l10n.nearStopMinutes(
              difference.inMinutes.remainder(60).toString()),
          "isRed": '',
          "PlateNumb": "",
          "color": difference.inMinutes.remainder(60) <= 0
              ? l10n.text_317
              : "min",
        };
      } else {
        final nextBusTime = DateTime.now().add(Duration(
          hours: difference.inHours,
          minutes: difference.inMinutes.remainder(60),
        ));
        return {
          'time':
          "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}",
          "isRed": '',
          "PlateNumb": "",
          "color": l10n.text_317
        };
      }
    } else {
      return {
        "time": l10n.text_317,
        "isRed": '',
        "PlateNumb": "",
        "color": l10n.text_317
      };
    }
  }

  void _showSortDialog(BuildContext context) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colors.cardBackground,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.cardBackground,
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
                        color: colors.infoContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sort_rounded,
                        size: 24,
                        color: colors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.text_318,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.info,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSortOption(
                  AppLocalizations.of(context)!.nearStopSortAsc,
                  SortType.nameAsc,
                  Icons.numbers_rounded,
                  colors.info,
                ),
                _buildSortOption(
                  AppLocalizations.of(context)!.nearStopSortDesc,
                  SortType.nameDesc,
                  Icons.numbers_rounded,
                  colors.info,
                ),
                _buildSortOption(
                  AppLocalizations.of(context)!.text_319,
                  SortType.timeAsc,
                  Icons.access_time_rounded,
                  colors.success,
                ),
                _buildSortOption(
                  AppLocalizations.of(context)!.text_320,
                  SortType.timeDesc,
                  Icons.access_time_rounded,
                  colors.warning,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
      String title, SortType type, IconData icon, Color color) {
    final colors = context.appColors;
    final isSelected = _ctrl.sortType == type;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _ctrl.setSortType(type);
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
                  : Border.all(color: colors.border, width: 1),
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
                    color: isSelected ? colors.cardBackground : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : colors.textPrimary,
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
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: colors.cardBackground,
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
    final colors = context.appColors;
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
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  const MRTStationList({super.key, required this.station});

  @override
  State<MRTStationList> createState() => _MRTStationListState();
}

class _MRTStationListState extends State<MRTStationList> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      // child: SingleChildScrollView(
      //   child: buildStationInfo(widget.station),
      // ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Caches
// ─────────────────────────────────────────────────────

class BusStopCache {
  static final BusStopCache _instance = BusStopCache._internal();
  factory BusStopCache() => _instance;

  final Map<String, CachedData<List<Map<String, dynamic>>>> _cache = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _inFlight = {};
  int _maxSize = 10;
  String _currentCity = 'Taichung';
  final List<String> _accessRecords = [];
  static const Duration _defaultExpiry = Duration(minutes: 5);

  BusStopCache._internal();

  void config({int? maxSize, String? city}) {
    if (maxSize != null && maxSize > 0) {
      _maxSize = maxSize;
      _cleanup();
    }
    if (city != null) _currentCity = city;
  }

  Future<List<Map<String, dynamic>>> getBusStopInfo(String stationName) {
    final key = '${_currentCity}_$stationName';

    final cached = _cache[key];
    if (cached != null && cached.expiry.isAfter(DateTime.now())) {
      _recordAccess(key);
      return Future.value(cached.data);
    }
    if (cached != null) {
      _cache.remove(key);
      _accessRecords.remove(key);
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _fetchAndCache(key, stationName);
    _inFlight[key] = future;
    future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
    return future;
  }

  Future<List<Map<String, dynamic>>> _fetchAndCache(
      String key, String stationName) async {
    final data = await _fetchData(stationName);
    _updateCache(key, data);
    return data;
  }

  Future<List<Map<String, dynamic>>> _fetchData(String stationName) {
    return GetBusStopInfo(stopName: stationName, city: _currentCity);
  }

  void _updateCache(String key, List<Map<String, dynamic>> data) {
    if (_cache.containsKey(key)) {
      _accessRecords.remove(key);
    }
    _cache[key] = CachedData<List<Map<String, dynamic>>>(
      data: data,
      expiry: DateTime.now().add(_defaultExpiry),
    );
    _accessRecords.add(key);
    _cleanup();
  }

  void _cleanup() {
    while (_cache.length > _maxSize && _accessRecords.isNotEmpty) {
      final oldestKey = _accessRecords.removeAt(0);
      _cache.remove(oldestKey);
    }
  }

  void _recordAccess(String key) {
    _accessRecords.remove(key);
    _accessRecords.add(key);
  }

  void clear() {
    _cache.clear();
    _accessRecords.clear();
    _inFlight.clear();
  }

  void remove(String stationName) {
    final key = '${_currentCity}_$stationName';
    _cache.remove(key);
    _accessRecords.remove(key);
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
  final Map<String, Future<List<dynamic>>> _inFlight = {};
  final List<String> _recentKeys = [];
  final int _maxCacheSize = 10;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  StopInfoCache._internal();

  Future<List<dynamic>> getStopInfo(String stop, String city) {
    final key = '$city-$stop';

    final cached = _cache[key];
    if (cached != null && cached.expiry.isAfter(DateTime.now())) {
      _recordAccess(key);
      return Future.value(cached.data);
    }
    if (cached != null) {
      _cache.remove(key);
      _recentKeys.remove(key);
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _fetchAndCache(key, stop, city);
    _inFlight[key] = future;
    future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
    return future;
  }

  Future<List<dynamic>> _fetchAndCache(
      String key, String stop, String city) async {
    final info = await GetBusStopInfo(stopName: stop, city: city);
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
    _inFlight.clear();
  }
}