import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
import '../metro.dart';
import '../models/MRTStation.dart';
import '../models/Station.dart';
import '../train.dart';
import '../utils/convert.dart';
import '../widget/bubble.dart';
import '../widget/error.dart';
import '../widget/map.dart';
import '../widget/tab.dart';
import 'bus_time.dart';

ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
ValueNotifier<String> _selectStationID = ValueNotifier<String>('');
ValueNotifier<Set<Marker>> _markers = ValueNotifier<Set<Marker>>({});
ValueNotifier<String> _stopName = ValueNotifier<String>('');
ValueNotifier<String> _tabSelect = ValueNotifier<String>('');

class NearbyStationsPage extends StatefulWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  _NearbyStationsPageState createState() => _NearbyStationsPageState();
}

class _NearbyStationsPageState extends State<NearbyStationsPage> {
  final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);
  Future<List<Station>>? _futureNearStations;
  MarkerProvider? _markerProvider;
  Future<void> _updateFutureNearStations() async {

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    setState(() {
      _futureNearStations = getNearStation(Uri.encodeComponent(
          "${locationProvider.latitude},${locationProvider.longitude}"));
    });
  }

  @override
  void initState() {

    super.initState();

    busInit();
    // 添加對 _tabSelect 的監聽
    _tabSelect.addListener(_handleTabSelectChange);
  }
  void busInit() async {
  final locationProvider = Provider.of<LocationProvider>(context, listen: false);
  _futureNearStations = getNearStation(Uri.encodeComponent(
      "${locationProvider.latitude},${locationProvider.longitude}"));
  final stations = await _futureNearStations;
  if (mounted) {
    _loadBusMarkers(context, stations);
  }
}
  List<Map<String, dynamic>> convertStations(type,List<dynamic> stations) {
   if(type=="metro"){
     return stations.map((station) {
       return {
         "stationID": station["StationID"].toString(),
         "stationNameZh": (station["StationName"])["Zh_tw"] ?? "Unknown",
         "positionLat": (station["StationPosition"])["PositionLat"],
         "positionLon": (station["StationPosition"])["PositionLon"],
       };
     }).toList();
   }else if(type=="train"){
     return stations.map((station) {
       return {
         "stationID": station["StationID"].toString(),
         "stationNameZh": json.decode(station["StationName"])["Zh_tw"] ?? "Unknown",
         "positionLat": json.decode(station["StationPosition"])["PositionLat"],
         "positionLon": json.decode(station["StationPosition"])["PositionLon"],
       };
     }).toList();
   }else{
     return[];
   }
  }

  // 處理 _tabSelect 變化的方法
  void _handleTabSelectChange() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    if (_tabSelect.value == "bus") {
      _updateFutureNearStations();
      final stations = await _futureNearStations;
      if (mounted) {
        _loadBusMarkers(context, stations);
      }
    } else if (_tabSelect.value == "metro") {
      final stations = await getNearMRTStation(
        Uri.encodeComponent(
            "${locationProvider.latitude},${locationProvider.longitude}"),
      );
      if (mounted) {
        _loadMarkers(
            context,
            convertStations(
                "metro",stations.map((station) => station.toJson()).toList()));
      }
    } else if (_tabSelect.value == "train") {
      final stations = await getNearTrainStation(

            locationProvider.latitude,locationProvider.longitude
      );

      if (mounted) {

        _loadMarkers(
            context,
            convertStations("train",stations));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在 didChangeDependencies 中获取依赖
    _markerProvider = Provider.of<MarkerProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // 移除監聽器
    _tabSelect.removeListener(_handleTabSelectChange);
    super.dispose(); // 确保调用父类的 dispose 方法
    // 使用之前保存的 _markerProvider
    _markerProvider?.setMarkers({});
  }

  // 加载标记
  Future<void> _loadBusMarkers(BuildContext context, List<Station>? stations) async {
    if (stations == null || stations.isEmpty) {
      debugPrint('Stations data is empty.');
      return;
    }

    Set<Marker> markers = {};

    for (var station in stations) {
      final marker = Marker(
          markerId: MarkerId(station.stationID),
          position: LatLng(
            station.positionLat,
            station.positionLon,
          ),
          infoWindow: InfoWindow(
            title: station.stationNameZh ?? 'Unknown',
            snippet: station.stationID ?? 'Unknown',
          ),
          onTap: () async {
            BusStopCache  cache = BusStopCache();
            List<Map<String, dynamic>> data =await cache.getBusStopInfo(station.stationNameZh);
                // await getBusStopInfo(station.stationNameZh, "Taichung");
             print(data);
            // 使用 map 來提取 StationID 並轉換為字串
            List<String> stationIDs = data
                .map((station) {
                  // 確保 StationID 存在並轉換為字串
                  if (station.containsKey('StationID')) {
                    return station['StationID'].toString();
                  }
                  return '';
                })
                // 過濾掉空字串
                .where((id) => id.isNotEmpty)
                .toList();
            _stationIDs.value = stationIDs;
            _stopName.value = station.stationNameZh;
            _selectStationID.value = station.stationID;

            _indexNotifier.value = 1; // 切换到搜索内容
          });
      markers.add(marker);
    }
    _markers.value = markers; // 添加新标记
    _markers.notifyListeners(); // 通知监听器更新 UI

    // Provider.of<MarkerProvider>(context, listen: false).setMarker(markers);
  }

  Future<void> _loadMarkers(BuildContext context, List<dynamic>? stations) async {
    if (stations == null || stations.isEmpty) {
      debugPrint('Stations data is empty.');
      return;
    }

    Set<Marker> markers = {};

    for (var station in stations) {
      if (station is! Map<String, dynamic>) {
        debugPrint('Invalid station format: $station');
        continue;
      }

      final stationID =
          station["stationID"]?.toString(); // 確保 stationID 是 String
      final stationNameZh = station["stationNameZh"] ?? "Unknown";
      final positionLat = station["positionLat"];
      final positionLon = station["positionLon"];

      if (stationID == null || positionLat == null || positionLon == null) {
        debugPrint('Missing required data in station: $station');
        continue;
      }

      final marker = Marker(
        markerId: MarkerId(stationID),
        position: LatLng(positionLat, positionLon),
        infoWindow: InfoWindow(
          title: stationNameZh,
          snippet: stationID,
        ),
        onTap: () async {},
      );
      markers.add(marker);
    }

    _markers.value = markers;
    _markers.notifyListeners();

    debugPrint('Markers loaded: ${markers.length}');
  }

  static void _updateMarkerStyle([String? selectedIndex]) {
    // String selectedStationID = _stationIDs.value[selectedIndex];

    // 遍歷所有 markers，更新樣式
    _markers.value = _markers.value.map((marker) {
      if (marker.markerId.value == _selectStationID.value) {
        // 更新為選中樣式
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(190.0), // 使用柔和藍色
        );
      } else {
        // 恢復為普通樣式
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarker,
        );
      }
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight =
        screenHeight - (screenHeight * 0.2) - appBarHeight - bottomNavBarHeight;
    final DraggableScrollableController _scrollController =
        DraggableScrollableController();

    return WillPopScope(
        onWillPop: () async {
          if (_indexNotifier.value > 0) {
            setState(() {
              _indexNotifier.value--; // 返回到上一个索引
            });
            return false; // 阻止默认返回导航
          }
          return true; // 在索引为0时允许默认返回导航
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
                          markers: _markers.value,
                          onMapCreated: (controller) {
                            // 自定义逻辑
                          },
                        );
                      },
                    )),
              ),

              DraggableScrollableSheet(
                controller: _scrollController,
                initialChildSize: 0.43,
                minChildSize: 0.25,
                maxChildSize: 0.96,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Stack(
                    clipBehavior: Clip.none, // 确保不会阻挡手势
                    children: [
                      // 提示線
                      Positioned(
                        top: -10, // 往上移動，確保能顯示在頂部
                        left: MediaQuery.of(context).size.width / 2 - 20,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            // 處理拖曳操作，帶動 DraggableScrollableSheet
                            double delta = details.primaryDelta! /
                                MediaQuery.of(context).size.height;
                            double currentSize = _scrollController.size ?? 0.1;
                            double newSize =
                                (currentSize - delta).clamp(0.1, 0.96);
                            _scrollController.animateTo(newSize,
                                duration: const Duration(milliseconds: 50),
                                curve: Curves.easeInOut);
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
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: ValueListenableBuilder<int>(
                              valueListenable: _indexNotifier,
                              builder: (context, index, child) {
                                return IndexedStack(
                                    index: _indexNotifier.value,
                                    children: <Widget>[
                                      TabWidget(
                                        items: const [
                                          "公車站",
                                          "捷運站",
                                          "火車站",
                                          "高鐵站"
                                        ],
                                        icons: [
                                          Icons.directions_bus,
                                          Icons.subway,
                                          Icons.train,
                                          Icons.directions_railway
                                        ],
                                        id: const [
                                          "bus",
                                          "metro",
                                          "train",
                                          "HSR"
                                        ],
                                        buildPageView: (context, controller) {
                                          return PageView.builder(
                                            itemCount: 4,
                                            controller: controller,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              switch (index) {
                                                case 0:
                                                  _tabSelect.value = "bus";
                                                  return // 滚动内容区域

                                                      SingleChildScrollView(
                                                    controller:
                                                        scrollController,
                                                    child: FutureBuilder<List<Station>>(
                                                      future: _futureNearStations,
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot.connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return Center(
                                                            child: LoadingAnimationWidget
                                                                .stretchedDots(
                                                              color:
                                                                  Colors.black,
                                                              size: 40,
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Text(
                                                                  "找不到附近的站牌",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      // 重新觸發 FutureBuilder 的 future
                                                                      getNearMRTStation(
                                                                        Uri.encodeComponent(
                                                                            "${locationProvider.latitude},${locationProvider.longitude}"),
                                                                      );
                                                                    });
                                                                  },
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .refresh,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                  label:
                                                                      const Text(
                                                                    "重試",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            14),
                                                                  ),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .black,
                                                                    elevation:
                                                                        3,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            20,
                                                                        vertical:
                                                                            12),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    shadowColor:
                                                                        Colors.grey[
                                                                            300],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                                .hasData &&
                                                            snapshot.data !=
                                                                null &&
                                                            snapshot.data!
                                                                .isNotEmpty) {
                                                          // 使用 Map 分组
                                                          Map<
                                                                  String,
                                                                  List<
                                                                      Map<String,
                                                                          dynamic>>>
                                                              groupedStations =
                                                              {};
                                                          for (var station
                                                              in snapshot
                                                                  .data!) {
                                                            String stationName =
                                                                station
                                                                    .stationNameZh;
                                                            if (!groupedStations
                                                                .containsKey(
                                                                    stationName)) {
                                                              groupedStations[
                                                                  stationName] = [];
                                                            }
                                                            groupedStations[
                                                                    stationName]!
                                                                .add(station
                                                                    .toJson());
                                                          }

                                                          // 转换为指定格式
                                                          List<
                                                                  Map<String,
                                                                      dynamic>>
                                                              result =
                                                              groupedStations
                                                                  .entries
                                                                  .map((entry) {
                                                            return {
                                                              "StationGroup": {
                                                                "StationGroupName":
                                                                    {
                                                                  "Zh_tw":
                                                                      entry.key
                                                                },
                                                                "Stations":
                                                                    entry.value
                                                              }
                                                            };
                                                          }).toList();

                                                          // 加载标记
                                                          // WidgetsBinding
                                                          //     .instance
                                                          //     .addPostFrameCallback(
                                                          //         (_) {
                                                          //   _loadBusMarkers(
                                                          //       context,
                                                          //       snapshot.data!);
                                                          // });

                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            child: Column(
                                                              children:
                                                                  List.generate(
                                                                result.length,
                                                                (index) {
                                                                  final station =
                                                                      result[
                                                                          index];
                                                                  return _stationCard(
                                                                      station:
                                                                          station);
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          return const Center(
                                                            child: Text(
                                                              "找不到附近的站牌",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 16),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  );

                                                case 1:
                                                  _tabSelect.value = "metro";
///////////////////////////////////////////////////////

                                                  return SingleChildScrollView(
                                                    controller:
                                                        scrollController,
                                                    child: FutureBuilder<
                                                        List<MRTStation>>(
                                                      future: getNearMRTStation(
                                                        Uri.encodeComponent(
                                                            "${locationProvider.latitude},${locationProvider.longitude}"),
                                                      ),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot.connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return Center(
                                                            child: LoadingAnimationWidget
                                                                .stretchedDots(
                                                              color:
                                                                  Colors.black,
                                                              size: 40,
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Text(
                                                                  "找不到附近的站牌",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      // 重新觸發 FutureBuilder 的 future
                                                                      getNearMRTStation(
                                                                        Uri.encodeComponent(
                                                                            "${locationProvider.latitude},${locationProvider.longitude}"),
                                                                      );
                                                                    });
                                                                  },
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .refresh,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                  label:
                                                                      const Text(
                                                                    "重試",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            14),
                                                                  ),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .black,
                                                                    elevation:
                                                                        3,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            20,
                                                                        vertical:
                                                                            12),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    shadowColor:
                                                                        Colors.grey[
                                                                            300],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                                .hasData &&
                                                            snapshot.data !=
                                                                null &&
                                                            snapshot.data!
                                                                .isNotEmpty) {
                                                          // 使用 Map 分组
                                                          Map<
                                                                  String,
                                                                  List<
                                                                      Map<String,
                                                                          dynamic>>>
                                                              groupedStations =
                                                              {};
                                                          for (var station
                                                              in snapshot
                                                                  .data!) {
                                                            String stationName =
                                                                station
                                                                    .stationNameZh;
                                                            if (!groupedStations
                                                                .containsKey(
                                                                    stationName)) {
                                                              groupedStations[
                                                                  stationName] = [];
                                                            }
                                                            groupedStations[
                                                                    stationName]!
                                                                .add(station
                                                                    .toJson());
                                                          }

                                                          // 转换为指定格式
                                                          List<
                                                                  Map<String,
                                                                      dynamic>>
                                                              result =
                                                              groupedStations
                                                                  .entries
                                                                  .map((entry) {
                                                            return {
                                                              "StationGroup": {
                                                                "StationGroupName":
                                                                    {
                                                                  "Zh_tw":
                                                                      entry.key
                                                                },
                                                                "Stations":
                                                                    entry.value
                                                              }
                                                            };
                                                          }).toList();

                                                          // 加载标记
                                                          // WidgetsBinding.instance.addPostFrameCallback((_) {
                                                          //   _loadMarkers(context, snapshot.data!);
                                                          // });

                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            child: Column(
                                                              children:
                                                                  List.generate(
                                                                result.length,
                                                                (index) {
                                                                  final station =
                                                                      result[
                                                                          index];
                                                                  return _stationCard(
                                                                      station:
                                                                          station);
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          return const Center(
                                                            child: Text(
                                                              "找不到附近的站牌",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 16),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  );

                                                case 2:
                                                  _tabSelect.value = "train";
                                                  return SingleChildScrollView(
                                                    controller:
                                                        scrollController,
                                                    child: FutureBuilder<List<dynamic>>(
                                                      future:
                                                          getNearTrainStation(  locationProvider.latitude,locationProvider.longitude),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return Center(
                                                            child: LoadingAnimationWidget
                                                                .stretchedDots(
                                                              color:
                                                                  Colors.black,
                                                              size: 40,
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Text(
                                                                  "找不到附近的站牌",
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black54,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 16),
                                                                ElevatedButton
                                                                    .icon(
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      getNearTrainStation(  locationProvider.latitude,locationProvider.longitude);
                                                                    });
                                                                  },
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .refresh,
                                                                      color: Colors
                                                                          .black),
                                                                  label:
                                                                      const Text(
                                                                    "重試",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontSize:
                                                                            14),
                                                                  ),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .black,
                                                                    elevation:
                                                                        3,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            20,
                                                                        vertical:
                                                                            12),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    shadowColor:
                                                                        Colors.grey[
                                                                            300],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                            .hasData) {


                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            child: Column(
                                                              children:
                                                                  List.generate(
                                                                    snapshot.data
                                                                    !.length,
                                                                (index) {
                                                                  final station =
                                                                  snapshot.data
                                                                  ![
                                                                          index];
                                                                  print(
                                                                      station);
                                                                  return GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        // 跳转到 StationPage 并传递选中的车站名称
                                                                        DateTime
                                                                            today =
                                                                            DateTime.now();
                                                                        // 输出当前的日期和时间

// 如果你只需要日期部分（没有时间）
                                                                        DateTime todayDate = DateTime(
                                                                            today.year,
                                                                            today.month,
                                                                            today.day);
                                                                        // 输出当前的日期，不包含时间部分
                                                                        Navigator
                                                                            .push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                StationPage(
                                                                              stationName: json.decode(station["StationName"])["Zh_tw"],
                                                                              stationID: (station["StationID"]),
                                                                              datetime: todayDate, // 将选中的车站名称传递给 StationPage
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        margin: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                8,
                                                                            horizontal:
                                                                                12),
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            vertical:
                                                                                12,
                                                                            horizontal:
                                                                                16),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.white,
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                              color: Colors.black.withOpacity(0.05),
                                                                              blurRadius: 8,
                                                                              offset: const Offset(0, 4),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              json.decode(station["StationName"])["Zh_tw"],
                                                                              style: const TextStyle(
                                                                                fontSize: 16,
                                                                                fontWeight: FontWeight.w400,
                                                                                color: Colors.black,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 8),
                                                                            Divider(
                                                                                color: Colors.grey[300],
                                                                                thickness: 0.5),
                                                                          ],
                                                                        ),
                                                                      ));
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        return Container();
                                                      },
                                                    ),
                                                  );

                                                case 3:
                                                  _tabSelect.value = "HSR";
                                                  return const Center(
                                                      child: Text("這是高鐵站的內容"));
                                                default:
                                                  return const Center(
                                                      child: Text("開發中"));
                                              }
                                            },
                                          );
                                        },
                                      ),
                                      DraggableScrollableSheetPageTwo(
                                          scrollController),
                                    ]);
                              })),
                    ],
                  );
                },
              ),

              // 重載按鈕
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () async {

                    // 直接調用監聽器方法來重新加載
                    _handleTabSelectChange();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _stationCard({required Map<String, dynamic> station}) {
    return GestureDetector(
      onTap: () {
        List<String> stationIDs =
            (station["StationGroup"]["Stations"] as List<dynamic>?)
                    ?.map((station) => station["stationID"].toString())
                    .toList() ??
                [];

        _stopName.value = station["StationGroup"]["StationGroupName"]["Zh_tw"];
        _stationIDs.value = stationIDs;

        _indexNotifier.value = 1; // 切换到搜索内容
      },
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          // 向左滑动
          setState(() {
            if (_indexNotifier.value > 0) {
              _indexNotifier.value = 1; // 切换到搜索内容
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              station["StationGroup"]["StationGroupName"]["Zh_tw"],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300], thickness: 0.5),
          ],
        ),
      ),
    );
  }

  Widget DraggableScrollableSheetPageTwo(ScrollController scrollController) {
    if (_tabSelect.value == "bus") {
      print(_stopName.value);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: PrimaryScrollController(
          controller: scrollController, // 绑定 PrimaryScrollController
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
          controller: scrollController, // 绑定 PrimaryScrollController
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
          controller: scrollController, // 绑定 PrimaryScrollController
          child: const Text("開發中"),
        ),
      );
    }
  }
}

class BusStopList extends StatefulWidget {
  final String stop;

  const BusStopList(this.stop, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _BusStopListState();
  }
}

class _BusStopListState extends State<BusStopList> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<BusStopList> {
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController();

  late ValueNotifier<TabController> _tabControllerNotifier;

  // 构建 TabBar
  @override
  void initState() {
    super.initState();
// 初始化 _tabControllerNotifier
    _tabControllerNotifier = ValueNotifier(
      TabController(
        length: _stationIDs.value.length, // 初始长度为 _stationIDs 的长度
        vsync: this,
      ),
    );
    // 初始化 TabController
    // _tabController = TabController(
    //     length: _stationIDs.value.length, // 使用 stationIDs 的長度
    //     vsync: this
    // );
    _selectStationID.addListener(() {
      if (_tabControllerNotifier.value.length != _stationIDs.value.length) {
        _initTabController();
      }

      String currentStop = _selectStationID.value;
      _stationIDs.value.sort(); // 對站點列表進行排序
      int index =
          _stationIDs.value.indexOf(currentStop); // 獲取 currentStop 在排序後列表中的索引

      if (index != -1) {
        _NearbyStationsPageState._updateMarkerStyle(
            _selectStationID.value); // 切換 marker 樣式
        _tabControllerNotifier.value.animateTo(index); // 切換 Tab
      }
    });
    // 初始化时确保 _stationIDs 不为空
    if (_stationIDs.value.isEmpty) {
      _initTabController();
    }

    // 监听 _stationIDs 的变化
    _stationIDs.addListener(() {
      if (!mounted) return;

      // 当 stationIDs 发生变化时，重新创建 TabController
      setState(() {
        _initTabController();
      });
    });

    // 监听 _selectStationID 的变化
    _selectStationID.addListener(() {
      if (!mounted) return;

      String currentStop = _selectStationID.value;
      if (_stationIDs.value.isNotEmpty) {
        int index = _stationIDs.value.indexOf(currentStop);
        if (index != -1) {
          _NearbyStationsPageState._updateMarkerStyle(_selectStationID.value);
          _tabControllerNotifier.value.animateTo(index);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant BusStopList oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget called");
  }

  void _initTabController() {
    _tabControllerNotifier.value = TabController(
      length: _stationIDs.value.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _streamController.close(); // 关闭 StreamController
    // 釋放 TabController
    _tabControllerNotifier.value.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadData() async {
    final List<Map<String, dynamic>> data = await fetchBusStopInfo();

    // _streamController.add(data); // 向数据流中添加新数据
    return data;
  }

  Future<Widget> _buildTabContent(String direction, List<Map<String, dynamic>> stopEstimatedTime) async {
    List<Map<String, dynamic>> directionList = stopEstimatedTime
        .where((item) => item["Direction"] == direction)
        .toList();
    // 使用 Map 來確保每個路線只出現一次
    List<Map<String, dynamic>> uniqueList;
    final Map<String, Map<String, dynamic>> uniqueRoutes = {};
    for (var item in stopEstimatedTime) {
      final routeKey = "${item["RouteName"]["Zh_tw"]}_${item["Direction"]}";
      if (!uniqueRoutes.containsKey(routeKey) ||
          _parseTimeToMinutes(item["time"]) <
              _parseTimeToMinutes(uniqueRoutes[routeKey]!["time"])) {
        uniqueRoutes[routeKey] = item;
      }
    }

    uniqueList = uniqueRoutes.values.toList();

    List<Map<String, dynamic>> finalList = [];

    // 按 StationID 分类
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in uniqueList) {
      String stationID = item["StationID"];
      groupedData.putIfAbsent(stationID, () => []).add(item);
    }

    // 打印分组后的结果
    groupedData.forEach((stationID, items) {
      if (stationID == direction) {
        finalList = items;
      }
    });

    for (int index = 0; index < finalList.length; index++) {
      var i = finalList[index];

      // 根据方向查找去程或回程的目的地信息
      if (i['Direction'] == 1) {
        List<dynamic> result = await mysqlSelect(
            "SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");

        finalList[index]["RouteID"] =
            result.isNotEmpty ? result[0]["RouteID"] : "未知";
        finalList[index]["from"] =
            result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
        finalList[index]["to"] = result.isNotEmpty
            ? result[0]["DepartureStopNameZh"]
            : "未知目的地"; // 赋值到 'to' 字段
        finalList[index]["DepartureStopName"] =
            result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        finalList[index]["DestinationStopName"] =
            result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
      } else if (i['Direction'] == 0) {
        List<dynamic> result = await mysqlSelect(
            "SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '${i["RouteName"]["Zh_tw"]}'");
        finalList[index]["to"] = result.isNotEmpty
            ? result[0]["DestinationStopNameZh"]
            : "未知目的地"; // 赋值到 'to' 字段
        finalList[index]["from"] =
            result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        finalList[index]["RouteID"] =
            result.isNotEmpty ? result[0]["RouteID"] : "未知";
        finalList[index]["DepartureStopName"] =
            result.isNotEmpty ? result[0]["DepartureStopNameZh"] : "未知目的地";
        finalList[index]["DestinationStopName"] =
            result.isNotEmpty ? result[0]["DestinationStopNameZh"] : "未知目的地";
      }
    }

    // 对 stop["time"] 按照时间升序排序
    finalList.sort((a, b) {
      if (a["time"] == "即將到站") return -1;
      if (b["time"] == "即將到站") return 1;
      if (a["time"] == "班次結束") return 1;
      if (b["time"] == "班次結束") return -1;

      int aTimeInMinutes = _parseTimeToMinutes(a["time"]);
      int bTimeInMinutes = _parseTimeToMinutes(b["time"]);

      return aTimeInMinutes.compareTo(bTimeInMinutes);
    });

    return RefreshIndicator(
        onRefresh: () async {},
        child: Container(
          margin: const EdgeInsets.only(bottom: 25), // 设置底部间距
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadData(); // 刷新时重新加载数据
            },
            child: ListView.separated(
              itemCount: finalList.length,
              itemBuilder: (context, index) {
                final stop = finalList[index];
                final PlateNumb = stop["PlateNumb"];

                final color = stop["color"] == '0'
                    ? const Color.fromRGBO(235, 15, 41, 0.85)
                    : (stop["color"] == '2'
                        ? const Color.fromRGBO(225, 85, 104, 0.1)
                        : (stop["color"] == "班次結束"
                            ? const Color.fromRGBO(69, 69, 69, 0.1)
                            : (stop["color"] == "min"
                                ? const Color.fromRGBO(13, 168, 255, 0.1)
                                : const Color.fromRGBO(68, 68, 68, 0.1))));

                return Container(
                  height: 53.0, // 每个列表项的固定高度
                  child: ListTile(
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusTime(
                            routeName: stop["RouteName"]["Zh_tw"],
                            departureStopName: stop["DepartureStopName"],
                            destinationStopName: stop["DestinationStopName"],
                            operators: "",
                            routeMapImageUrl: "",
                            city: "Taichung",
                            routeID: int.parse(stop["RouteID"]),
                            mark: Mark.fromMap({
                              "highlight": [
                                _stopName.value,
                              ],
                              "direction": stop["Direction"],
                            }),
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        stop["time"] ?? "未知",
                        style: TextStyle(
                          fontFamily: 'MiSans-normal',
                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? Colors.white
                              : (stop["color"] == '2'
                                  ? const Color.fromRGBO(255, 85, 104, 1)
                                  : (stop["color"] == "班次結束"
                                      ? const Color.fromRGBO(149, 149, 149, 1.0)
                                      : (stop["color"] == "min"
                                          ? const Color.fromRGBO(
                                              13, 168, 255, 1)
                                          : const Color.fromRGBO(
                                              68, 68, 68, 1)))),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          stop["RouteName"]["Zh_tw"] ?? "未知班次",
                          style: TextStyle(
                            fontFamily: stop["color"] == "0"
                                ? 'MiSans-Semibold'
                                : 'MiSans-normal',
                            fontSize: 17,
                            color: stop["color"] == "班次結束"
                                ? const Color.fromRGBO(136, 136, 136, 1)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8), // 增加站名和方向之間的間距
                        Text(
                          "往 ${stop["to"] ?? "未知方向"}",
                          style: TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: const Color.fromRGBO(136, 136, 136, 1),
                          ),
                        ),
                        if (stop["RouteName"]["Zh_tw"]!.contains("車站"))
                          Padding(
                            padding: const EdgeInsets.only(left: 6), // 左侧间距
                            child: SvgPicture.asset(
                              'assets/icons/Taiwan_Railways_Logo.svg',
                              // 自定义SVG路径
                              width: 18, // SVG图标宽度
                              height: 18, // SVG图标高度
                            ),
                          )
                        else if (stop["RouteName"]["Zh_tw"]!.contains("捷運"))
                          Padding(
                            padding: const EdgeInsets.only(left: 6), // 左侧间距
                            child: SvgPicture.asset(
                              'assets/icons/tc_MRT.svg', // 自定义SVG路径
                              width: 18, // SVG图标宽度
                              height: 18, // SVG图标高度
                            ),
                          ),
                      ],
                    ),
                    trailing: bubble(plateNum: PlateNumb),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: Color.fromRGBO(231, 231, 231, 1),
                  // 分隔线颜色
                  height: 9,
                  // 分隔线与上下元素间距
                  thickness: 1,
                  // 分隔线粗细
                  indent: 20,
                  // 分隔线左间距
                  endIndent: 20, // 分隔线右间距
                );
              },
            ),
          ),
        ));
  }

  // 解析时间格式，转换成相对于当前时间的分钟数
  int _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return -1;

    // 处理 "X 分鐘" 格式
    if (time.contains("分鐘")) {
      return int.tryParse(time.split(" ").first) ?? -1;
    }

    // 处理 "XX:XX" 格式
    if (time.contains(":")) {
      final parts = time.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;

        // 获取当前时间
        DateTime now = DateTime.now();
        DateTime parsedTime =
            DateTime(now.year, now.month, now.day, hour, minute);

        // 如果时间已经过去了，则认为是第二天的时间
        if (parsedTime.isBefore(now)) {
          parsedTime = parsedTime.add(const Duration(days: 1));
        }

        return parsedTime.difference(now).inMinutes;
      }
    }

    return -1;
  }

  // 获取公交站信息的异步方法
  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {
     List<dynamic> info = await StopInfoCache().getStopInfo(widget.stop, "Taichung");
    // List<dynamic> info = await GetBusStopInfo(widget.stop, "Taichung");
    List<Map<String, dynamic>> tempData = [];

    for (var i in info) {
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

// 返回每个隐藏的菜单项
  SelectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: busBlue),
            Text(text),
          ],
        ));
  }

// 获取到站时间列表的异步方法
  Future<Map<String, dynamic>> getTimeList(stopData) async {
    if (stopData["EstimateTime"] != null) {
      if (stopData["EstimateTime"] == 0) {
        List PlateNumb = [];
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }
        return {
          "color": '0',
          "time": "即將到站",
          "isRed": '0',
          "PlateNumb": PlateNumb.toString()
        };
      } else {
        int result = (stopData["EstimateTime"] / 60).floor();
        List PlateNumb = [];
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }

        return {
          "color": result < 3 ? "2" : "min",
          "time": result < 1 ? "即將到站" : "$result 分鐘",
          "isRed": result < 3 ? "2" : "",
          "PlateNumb": result < 20 ? PlateNumb.toString() : ""
        };
      }
    } else if (stopData["NextBusTime"] != null) {
      Duration difference =
          DateTime.parse(stopData["NextBusTime"]).difference(DateTime.now());
      if (difference.inHours == 0) {
        return {
          "time": difference.inMinutes.remainder(60) <= 0
              ? "班次結束"
              : "${difference.inMinutes.remainder(60)} 分鐘",
          "isRed": '',
          "PlateNumb": "",
          "color": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "min",
        };
      } else {
        DateTime NextBusTime = DateTime.now().add(Duration(
            hours: difference.inHours,
            minutes: difference.inMinutes.remainder(60)));
        return {
          'time':
              "${NextBusTime.hour.toString().padLeft(2, '0')}:${NextBusTime.minute.toString().padLeft(2, '0')}",
          "isRed": '',
          "PlateNumb": "",
          "color": "班次結束"
        };
      }
    } else {
      return {"time": "班次結束", "isRed": '', "PlateNumb": "", "color": "班次結束"};
    }
  }

  PreferredSize _buildTabBar(List<Map<String, dynamic>> station) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // 使用白色背景
        ),
        child: ValueListenableBuilder<TabController>(
            valueListenable: _tabControllerNotifier,
            builder: (context, tabController, child) {
              return TabBar(
                controller: _tabControllerNotifier.value,
                // 添加 controller
                indicatorColor: Colors.black,
                // 使用黑色作为指示器颜色
                labelColor: Colors.black,
                // 黑色文字
                unselectedLabelColor: Colors.grey,
                // 灰色未选中文字
                indicatorWeight: 2.0,
                // 更细的指示器
                indicatorSize: TabBarIndicatorSize.label,
                // 窄指示器
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // 略轻的加粗，显得现代
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15, // 未选中标签稍小字体
                ),

                tabs: List.generate(_stationIDs.value.length, (index) {
                  String label =
                      String.fromCharCode(65 + index); // 將索引轉為字母 A, B, C...
                  return Tab(
                    icon: Icon(Icons.directions_bus, size: 24),
                    text: _stationIDs.value[index],
                  );
                }),
              );
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadData(), // 调用异步方法
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Colors.black,
                size: 40,
              ),
            ); // 加载中的占位组件
          } else if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}')); // 错误提示
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('沒有資料')); // 无数据占位
          }

          return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // 自定义 AppBar
                  SingleChildScrollView(
                    child: PreferredSize(
                      preferredSize: const Size.fromHeight(120), // 自定义高度
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2), // 微弱阴影
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            AppBar(
                              backgroundColor: Colors.transparent,
                              // 设置透明背景
                              elevation: 0,
                              // 移除默认阴影
                              title: Text(
                                _stopName.value,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              actions: [
                                IconButton(
                                  icon:
                                      Icon(Icons.refresh, color: Colors.black),
                                  onPressed: _loadData, // 刷新数据
                                ),
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color: Colors.black),
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuItem<String>>[
                                    SelectView(Icons.info, '站牌資訊', 'A'),
                                    SelectView(Icons.add, '加入收藏', 'B'),
                                  ],
                                  onSelected: (String action) async {
                                    if (action == 'B') {
                                      favorite_feature dbHelper =
                                          favorite_feature();
                                      final output = await dbHelper.addFavorite(
                                        StopName: widget.stop,
                                        table: "FavoritesStop",
                                        city: 'Taichung',
                                      );
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
                                          text: '儲存項目時發生錯誤',
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                              bottom: _buildTabBar(snapshot.data!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 内容部分
                  Expanded(
                    child: TabBarView(
                      controller:
                          _tabControllerNotifier.value, // 加入 controller 綁定
                      children:
                          List.generate(_stationIDs.value.length, (index) {
                        String label =
                            String.fromCharCode(65 + index); // A, B, C...
                        return FutureBuilder(
                          future: _buildTabContent(_stationIDs.value[index],
                              snapshot.data!), // 傳入 A, B, C...
                          builder: (context, contentSnapshot) {
                            if (contentSnapshot.connectionState ==
                                ConnectionState.waiting) {
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

                            if (contentSnapshot.data == null) {
                              return Center(
                                child: Text("No content available"),
                              );
                            }
                            return contentSnapshot.data is Widget
                                ? contentSnapshot.data as Widget
                                : Center(child: Text("Invalid content"));
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ));
        });
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
        child: SingleChildScrollView(
          child: buildStationInfo(widget.station),
        ));
  }
}
class BusStopCache {
  // 單例實例
  static final BusStopCache _instance = BusStopCache._internal();
  factory BusStopCache() => _instance;

  // 快取存儲結構：鍵為 "城市_站點名"，值為 CachedData<List<Map<String, dynamic>>>
  final Map<String, CachedData<List<Map<String, dynamic>>>> _cache = {};
  // 線程安全鎖
  final Lock _lock = Lock();
  // 緩存配置
  int _maxSize = 10;
  String _currentCity = 'Taichung';
  // LRU 用的快取訪問記錄
  final List<String> _accessRecords = [];
  // 預設快取有效期
  static const Duration _defaultExpiry = Duration(minutes: 5);

  // 私有構造函數
  BusStopCache._internal();

  /// 配置緩存參數
  void config({int? maxSize, String? city}) {
    _lock.synchronized(() {
      if (maxSize != null && maxSize > 0) {
        _maxSize = maxSize;
        _cleanup(); // 調整大小後立即清理
      }
      if (city != null) {
        _currentCity = city;
      }
    });
  }

  /// 获取站点信息（带缓存）
  Future<List<Map<String, dynamic>>> getBusStopInfo(String stationName) async {
    final cacheKey = _generateKey(stationName);

    return await _lock.synchronized(() async {
      // 嘗試從快取中取得，並檢查是否過期
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (cached.expiry.isAfter(DateTime.now())) {
          _recordAccess(cacheKey);
          print('[Cache] 命中快取 $cacheKey');
          return cached.data;
        } else {
          // 過期則清除
          _cache.remove(cacheKey);
          _accessRecords.removeWhere((k) => k == cacheKey);
        }
      }

      // 快取未命中時，取得遠端資料
      print('[Cache] 請求遠程數據 $cacheKey');
      final data = await _fetchData(stationName);
      _updateCache(cacheKey, data);
      return data;
    });
  }

  // 生成快取鍵（格式：城市_站點名）
  String _generateKey(String stationName) => '${_currentCity}_$stationName';

  // 實際數據獲取方法（此處應調用實際 API，示例中用 GetBusStopInfo）
  Future<List<Map<String, dynamic>>> _fetchData(String stationName) async {
    return await GetBusStopInfo(stationName, _currentCity);
  }

  // 更新快取（並透過 LRU 機制管理）
  void _updateCache(String key, List<Map<String, dynamic>> data) {
    _lock.synchronized(() {
      // 移除舊記錄
      if (_cache.containsKey(key)) {
        _accessRecords.removeWhere((k) => k == key);
      }
      // 添加新資料，並設定快取過期時間
      _cache[key] = CachedData<List<Map<String, dynamic>>>(
        data: data,
        expiry: DateTime.now().add(_defaultExpiry),
      );
      _accessRecords.add(key);
      // 清理超出上限的快取
      _cleanup();
    });
  }

  // 快取清理邏輯（基於 LRU，移除最久未訪問的記錄）
  void _cleanup() {
    while (_cache.length > _maxSize) {
      final oldestKey = _accessRecords.first;
      _cache.remove(oldestKey);
      _accessRecords.removeAt(0);
      print('[Cache] 移除最舊快取 $oldestKey');
    }
  }

  // 記錄快取訪問（用於 LRU 管理）
  void _recordAccess(String key) {
    _lock.synchronized(() {
      _accessRecords.removeWhere((k) => k == key);
      _accessRecords.add(key);
    });
  }

  /// 清空全部快取
  void clear() {
    _lock.synchronized(() {
      _cache.clear();
      _accessRecords.clear();
      print('[Cache] 已清空全部快取');
    });
  }

  /// 移除特定快取
  void remove(String stationName) {
    final key = _generateKey(stationName);
    _lock.synchronized(() {
      _cache.remove(key);
      _accessRecords.removeWhere((k) => k == key);
      print('[Cache] 已移除快取 $key');
    });
  }
}


// 在全局或缓存类中添加以下内容
// 定義泛型快取類別
class CachedData<T> {
  final T data;
  final DateTime expiry;
  CachedData({required this.data, required this.expiry});
}
class StopInfoCache {
  // 單例實例
  static final StopInfoCache _instance = StopInfoCache._internal();
  factory StopInfoCache() => _instance;

  // 快取存儲結構：鍵為 "city-stop"，值為 CachedData<List<dynamic>>
  final Map<String, CachedData<List<dynamic>>> _cache = {};
  // LRU 訪問記錄（儲存鍵）
  final List<String> _recentKeys = [];
  // 最大快取筆數
  final int _maxCacheSize = 10;
  // 預設快取有效期
  final Duration _cacheExpiry = Duration(minutes: 5);

  StopInfoCache._internal();

  /// 取得站點資料（若相同 city 與 stop 在最近 10 筆中且快取未過期則使用快取）
  Future<List<dynamic>> getStopInfo(String stop, String city) async {
    final key = '$city-$stop';

    // 檢查快取是否存在且資料未過期
    if (_cache.containsKey(key)) {
      final cachedData = _cache[key]!;
      if (cachedData.expiry.isAfter(DateTime.now())) {
        _recordAccess(key);
        print('[Cache] 命中快取 $key');
        return cachedData.data;
      } else {
        // 資料過期則移除快取
        _cache.remove(key);
        _recentKeys.remove(key);
      }
    }

    // 快取未命中或資料過期，呼叫 API 取得新資料
    print('[Cache] 快取未命中或過期，請求遠端資料 $key');
    List<dynamic> info = await GetBusStopInfo(stop, city);
    _updateCache(key, info);
    return info;
  }

  // 更新快取，並根據 LRU 機制管理大小
  void _updateCache(String key, List<dynamic> data) {
    if (_cache.containsKey(key)) {
      _recentKeys.remove(key);
    }
    _cache[key] = CachedData<List<dynamic>>(
      data: data,
      expiry: DateTime.now().add(_cacheExpiry),
    );
    _recentKeys.add(key);
    // 超出最大筆數則移除最舊快取
    if (_recentKeys.length > _maxCacheSize) {
      final oldestKey = _recentKeys.removeAt(0);
      _cache.remove(oldestKey);
      print('[Cache] 移除最舊快取 $oldestKey');
    }
  }

  // 更新快取訪問記錄
  void _recordAccess(String key) {
    _recentKeys.remove(key);
    _recentKeys.add(key);
  }

  /// 清空所有快取（如有需要）
  void clear() {
    _cache.clear();
    _recentKeys.clear();
  }
}