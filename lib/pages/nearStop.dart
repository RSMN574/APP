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
import '../metro.dart';

import '../models/Station.dart';
import '../train.dart';
import '../utils/convert.dart';
import '../widget/bubble.dart';
import '../widget/error.dart';
import '../widget/map.dart';
import '../widget/tab.dart';
import 'busStopInfo.dart';
import 'bus_time.dart';

ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
ValueNotifier<String> _selectStationID = ValueNotifier<String>('');
ValueNotifier<String> _selectStationGroupID = ValueNotifier<String>('');
ValueNotifier<Set<Marker>> _markers = ValueNotifier<Set<Marker>>({});
ValueNotifier<String> _stopName = ValueNotifier<String>('');
ValueNotifier<String> _tabSelect = ValueNotifier<String>('');
final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);
class NearbyStationsPage extends StatefulWidget {
  const NearbyStationsPage({Key? key}) : super(key: key);

  @override
  _NearbyStationsPageState createState() => _NearbyStationsPageState();
}
final GlobalKey<_NearbyStationsPageState> mapKey = GlobalKey();
List<Map<String, dynamic>> processedUp = [];
List<Map<String, dynamic>> processedDown = [];


final _sortNotifier = ValueNotifier<SortType>(SortType.timeAsc);
class _NearbyStationsPageState extends State<NearbyStationsPage> {
   GoogleMapController? _mapController;

   List<Map<String, dynamic>> data = [];
  Future<List<Station>>? _futureNearStations;
  MarkerProvider? _markerProvider;
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

   GoogleMapController? get mapController => _mapController;
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

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
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
   void _updateMarkerSelection() {
     final currentSelected = _selectStationID.value;

     // ⚠️ 關鍵：必須 map 出一個全新的 Set，GoogleMap 才會偵測到對象改變
     _markers.value = _markers.value.map((marker) {
       final isSelected = marker.markerId.value == currentSelected;

       return marker.copyWith(
         iconParam: BitmapDescriptor.defaultMarkerWithHue(
           isSelected ? 210.0 : BitmapDescriptor.hueRed, // 選中變藍色
         ),
         zIndexParam: isSelected ? 1.0 : 0.0, // 確保選中的在最上面
       );
     }).toSet();
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
            final stopName = station.stationNameZh;
            final stopID = station.stationID;
            final stationGroupID = station.stationGroupID;

            try {
              // 1. 先獲取數據，不要急著更新 UI 變數
              final data = await BusStopCache().getBusStopInfo(stopName);

              final stationIDs = data
                  .map((item) => item['StationID']?.toString())
                  .whereType<String>()
                  .where((id) => id.isNotEmpty)
                  .toList();

              if (stationIDs.isEmpty) return;

              // 2. 檢查 Context 是否還存在 (避免非同步回傳後頁面已銷毀)
              if (!context.mounted) return;

              // 3. 邏輯判定
              if (_isSameStationGroup(_stationIDs.value, stationIDs)) {
                _selectStationID.value = stopID;
                _indexNotifier.value = 1;
              } else {
                // 建議：如果是複雜狀態，考慮將這些封裝成一個實體類，一次性通知更新
                _stopName.value = stopName;
                _selectStationID.value = stopID;
                _selectStationGroupID.value = stationGroupID;
                _stationIDs.value = stationIDs; // 最後更新數據主體

                // 4. 先切換頁面索引，確保數據已經到位
                _indexNotifier.value = 1;
              }
              if (_isSameStationGroup(_stationIDs.value, stationIDs)) {
                _selectStationID.value = stopID;
              } else {
                _stopName.value = stopName;
                _selectStationID.value = stopID;
                _selectStationGroupID.value = stationGroupID;
                _stationIDs.value = stationIDs;
              }

              // 關鍵修復 1：手動觸發地圖 Marker 變色
              _NearbyStationsPageState._updateMarkerStyle();

              // 關鍵修復 2：先切換頁面索引
              _indexNotifier.value = 1;
              // 5. 地圖動畫（放在最後，不阻塞 UI 邏輯）
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(station.positionLat, station.positionLon),
                    zoom: 19.0,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('取得站點資料失敗: $e');
            }
          }
      );
      markers.add(marker);
    }
    _markers.value = markers; // 添加新标记
    _markers.notifyListeners(); // 通知监听器更新 UI

    // Provider.of<MarkerProvider>(context, listen: false).setMarker(markers);
  }
// ✅ 正確的輔助函數
  bool _isSameStationGroup(List<String>? oldList, List<String>? newList) {
    // 兩個都是 null 或兩個都是空列表 → 視為相同
    if ((oldList == null || oldList.isEmpty) &&
        (newList == null || newList.isEmpty)) {
      return false;
    }

    // 其中一個是 null 或空，另一個不是 → 不同
    if (oldList == null || oldList.isEmpty) return false;
    if (newList == null || newList.isEmpty) return false;

    // 長度不同 → 不同
    if (oldList.length != newList.length) return false;

    // 排序後比較內容
    final sortedOld = List.of(oldList)..sort();
    final sortedNew = List.of(newList)..sort();

    for (int i = 0; i < sortedOld.length; i++) {
      if (sortedOld[i] != sortedNew[i]) return false;
    }
    return true;
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
    // 遍歷所有 markers，根據 _selectStationID 更新樣式
    _markers.value = _markers.value.map((marker) {
      if (marker.markerId.value == _selectStationID.value) {
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(190.0), // 選中顏色
        );
      } else {
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarker, // 恢復預設
        );
      }
    }).toSet();
  }
  static void _clearMarkerStyle(context) {
    _markers.value = _markers.value.map((marker) {
      return marker.copyWith(
        iconParam: BitmapDescriptor.defaultMarker, // 全部恢復成預設樣式
      );
    }).toSet();
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    final LatLng currentPosition = LatLng(
      locationProvider.latitude,
      locationProvider.longitude,
    );

    // mapKey.currentState?.mapController?.animateCamera(
    //   CameraUpdate.newCameraPosition(
    //     CameraPosition(
    //       target: currentPosition,
    //       zoom: 15.0, // 你要的縮放
    //     ),
    //   ),
    // );

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
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        );
                      },
                    )),
              ),

              DraggableScrollableSheet(
                controller: _scrollController,
                initialChildSize: 0.43,
                minChildSize: 0.3,
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
                                        icons: const [
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

                                                      controller: scrollController,
                                                      child: FutureBuilder<List<Station>>(
                                                        future: _futureNearStations,
                                                        builder: (context, snapshot) {
                                                          // 1. 等待狀態
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

                                                          // 2. 錯誤處理狀態
                                                          if (snapshot.hasError) {
                                                            return Center(
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  const SizedBox(height: 40),
                                                                  const Text(
                                                                    "找不到附近的站牌",
                                                                    style: TextStyle(
                                                                      color: Colors.black54,
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                  ElevatedButton.icon(
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        // 重新觸發與原本邏輯一致
                                                                        getNearMRTStation(
                                                                          Uri.encodeComponent("${locationProvider.latitude},${locationProvider.longitude}"),
                                                                        );
                                                                      });
                                                                    },
                                                                    icon: const Icon(Icons.refresh, color: Colors.black),
                                                                    label: const Text("重試", style: TextStyle(color: Colors.black, fontSize: 14)),
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor: Colors.white,
                                                                      foregroundColor: Colors.black,
                                                                      elevation: 3,
                                                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                      shadowColor: Colors.grey[300],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }

                                                          // 3. 有資料且不為空的狀態
                                                          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                                                            // --- 資料分組邏輯 (保持不變) ---
                                                            final Map<String, List<Map<String, dynamic>>> groupedStations = {};
                                                            for (var station in snapshot.data!) {
                                                              String stationName = station.stationNameZh;
                                                              if (!groupedStations.containsKey(stationName)) {
                                                                groupedStations[stationName] = [];
                                                              }
                                                              groupedStations[stationName]!.add(station.toJson());
                                                            }

                                                            // 轉換為原本指定的 List<Map> 格式
                                                            final List<Map<String, dynamic>> result = groupedStations.entries.map((entry) {
                                                              return {
                                                                "StationGroup": {
                                                                  "StationGroupName": {"Zh_tw": entry.key},
                                                                  "Stations": entry.value
                                                                }
                                                              };
                                                            }).toList();

                                                            // --- UI 渲染 ---
                                                            return Padding(
                                                              padding: const EdgeInsets.all(16.0),
                                                              child: Column(
                                                                children: [
                                                                  for (var station in result)
                                                                    _stationCard(station: station),
                                                                ],
                                                              ),
                                                            );
                                                          }

                                                          // 4. 空資料或其他狀態
                                                          return Container(
                                                            margin: const EdgeInsets.only(top: 20),
                                                            child: const Center(
                                                              child: Text(
                                                                "找不到附近的站牌",
                                                                style: TextStyle(color: Colors.grey, fontSize: 16),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
//
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
                                                        // 1. 載入中狀態
                                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                                          return Center(
                                                            child: LoadingAnimationWidget.stretchedDots(
                                                              color: Colors.black,
                                                              size: 40,
                                                            ),
                                                          );
                                                        }

                                                        // 2. 發生錯誤狀態
                                                        else if (snapshot.hasError) {
                                                          return Center(
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                const Text(
                                                                  "找不到附近的站牌",
                                                                  style: TextStyle(
                                                                    color: Colors.black54,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 16),
                                                                ElevatedButton.icon(
                                                                  onPressed: () {
                                                                    setState(() {
                                                                      getNearTrainStation(
                                                                        locationProvider.latitude,
                                                                        locationProvider.longitude,
                                                                      );
                                                                    });
                                                                  },
                                                                  icon: const Icon(Icons.refresh, color: Colors.black),
                                                                  label: const Text(
                                                                    "重試",
                                                                    style: TextStyle(color: Colors.black, fontSize: 14),
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

                                                        // 3. 有資料狀態
                                                        else if (snapshot.hasData) {
                                                          return Padding(
                                                            padding: const EdgeInsets.all(16.0),
                                                            child: Column(
                                                              children: List.generate(
                                                                snapshot.data!.length,
                                                                    (index) {
                                                                  final station = snapshot.data![index];
                                                                  return GestureDetector(
                                                                    onTap: () {
                                                                      DateTime today = DateTime.now();
                                                                      DateTime todayDate = DateTime(today.year, today.month, today.day);

                                                                      Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) => StationPage(
                                                                            stationName: json.decode(station["StationName"])["Zh_tw"],
                                                                            stationID: (station["StationID"]),
                                                                            datetime: todayDate,
                                                                          ),
                                                                        ),
                                                                      );
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
                                                                            json.decode(station["StationName"])["Zh_tw"],
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
                                                                },
                                                              ),
                                                            ),
                                                          );
                                                        }

                                                        // 4. 其他預設狀態 (如無資料)
                                                        else {
                                                          return Container(
                                                            margin: const EdgeInsets.only(top: 20),
                                                            child: Center(
                                                              child: Text(
                                                                "找不到附近的站牌",
                                                                style: TextStyle(color: Colors.grey, fontSize: 16),
                                                              ),
                                                            ),
                                                          );
                                                        }
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
              // 重載按鈕（白色版本）
              Positioned(
                bottom: 20,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
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

         // 聚焦到該站點位置
         _mapController?.animateCamera(
           CameraUpdate.newCameraPosition(
             CameraPosition(
               target: LatLng(
                   station["StationGroup"]["Stations"][0]["positionLat"],
                   station["StationGroup"]["Stations"][0]["positionLon"]
               ),
               zoom: 19.0,
             ),
           ),
         );

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
       child: Transform.translate(
         offset: const Offset(0, 0.5),
         child: Material(
           color: Colors.transparent,
           child: InkWell(
             onTap: () {
               List<String> stationIDs =
                   (station["StationGroup"]["Stations"] as List<dynamic>?)
                       ?.map((station) => station["stationID"].toString())
                       .toList() ??
                       [];

               _mapController?.animateCamera(
                 CameraUpdate.newCameraPosition(
                   CameraPosition(
                     target: LatLng(
                         station["StationGroup"]["Stations"][0]["positionLat"],
                         station["StationGroup"]["Stations"][0]["positionLon"]
                     ),
                     zoom: 19.0,
                   ),
                 ),
               );

               _stopName.value = station["StationGroup"]["StationGroupName"]["Zh_tw"];
               _stationIDs.value = stationIDs;
               _indexNotifier.value = 1;
             },
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
                   // 站點圖標
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

                   // 站點資訊
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
                         const SizedBox(height: 4),
                         // 站點數量資訊
                         // if (stationIDs != null && stationIDs.isNotEmpty)
                         //   Text(
                         //     '${stationIDs.length} 個站點',
                         //     style: TextStyle(
                         //       fontSize: 13,
                         //       color: Colors.grey[600],
                         //       fontWeight: FontWeight.w500,
                         //     ),
                         //   ),
                       ],
                     ),
                   ),

                   // 導航箭頭
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

  Widget DraggableScrollableSheetPageTwo(ScrollController scrollController) {
    print("_selectStationGroupID.value");print(_stopName.value);
    if (_tabSelect.value == "bus") {

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
  late final  TabController _tabController;
  final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
  @override
  void initState() {
    super.initState();

    // 關鍵修復 3：計算初始 Index (確保與排序後的列表一致)
    final sortedIDs = List<String>.from(_stationIDs.value)..sort();
    int initialIndex = sortedIDs.indexOf(_selectStationID.value);
    if (initialIndex == -1) initialIndex = 0;

    // 初始化 TabController 時帶入 initialIndex
    _tabController = TabController(
      length: _stationIDs.value.length,
      vsync: this,
      initialIndex: initialIndex, // 這裡設定初始位置
    );

    // 監聽器邏輯保持，但要注意內部也要使用排序後的列表來找 index
    _selectStationID.addListener(_onSelectStationChanged);
  }

  void _onSelectStationChanged() {
    print("_onSelectStationChanged");
    if (!mounted || _stationIDs.value.isEmpty) return;

    final currentStop = _selectStationID.value;
    _stationIDs.value.sort();
    final index = _stationIDs.value.indexOf(currentStop);
    if (index != -1) {
      _NearbyStationsPageState._updateMarkerStyle(currentStop);
      _tabController.animateTo(index);
    }
  }


  @override
  void didUpdateWidget(covariant BusStopList oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget called");
  }



  @override
  void dispose() {
    _streamController.close(); // 关闭 StreamController
    // 釋放 TabController
    _tabController.dispose();


    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadData() async {
    final List<Map<String, dynamic>> data = await fetchBusStopInfo();

    // _streamController.add(data); // 向数据流中添加新数据
    return data;
  }
  Future<List<Map<String, dynamic>>> _processData(String stationID, List<Map<String, dynamic>> stopEstimatedTime,) async {
    try {
      // print('=== 開始處理資料，stationID: $stationID ===');
      // print('原始數據數量: ${stopEstimatedTime.length}');

      /// -----------------------------
      /// 1. 過濾並去重
      /// -----------------------------
      final routeMap = <String, Map<String, dynamic>>{};

      for (final item in stopEstimatedTime) {
        // 只處理符合 StationID 的項目
        if (item["StationID"] != stationID) {
          continue;
        }

        // print('處理項目: ${item["RouteName"]}, StationID: ${item["StationID"]}');

        final routeNameObj = item["RouteName"];
        String? routeName;

        // 處理 RouteName 可能是 Map 或 String 的情況
        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
          // print('RouteName 是 Map: $routeNameObj, 提取: $routeName');
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
          //  print('RouteName 是 String: $routeName');
        }

        final direction = item["Direction"];

        if (routeName == null || routeName.isEmpty) {
          //  print('跳過：routeName 為空');
          continue;
        }

        final routeKey = "${routeName}_$direction";
        final currentTime = _parseTimeToMinutes(item["time"]);

        // print('routeKey: $routeKey, currentTime: $currentTime');

        // 只保留每條路線最近的一班車
        final existing = routeMap[routeKey];
        if (existing == null ||
            (currentTime != -1 && currentTime < _parseTimeToMinutes(existing["time"]))) {
          routeMap[routeKey] = item;
          //    print('加入/更新: $routeKey');
        }
      }

      final stationData = routeMap.values.toList();
      // print('過濾後數據數量: ${stationData.length}');

      if (stationData.isEmpty) {
        //   print('無數據，返回空列表');
        return [];
      }

      /// -----------------------------
      /// 2. 批次獲取路線資訊 - 修正查詢方式
      /// -----------------------------
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

      // print('需要查詢的路線名稱: $routeNames');

      final Map<String, Map<String, dynamic>> routeInfoCache = {};

      if (routeNames.isNotEmpty) {
        try {
          // 方法1：使用 JSON_UNQUOTE 和 JSON_EXTRACT（最標準）
          final nameList = routeNames.map((name) => "'$name'").join(',');

          //  print('執行 SQL 查詢，條件: $nameList');

          final query = """
        SELECT *
FROM Bus.bus_route
WHERE City = 'Taichung'
  AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))
      IN ($nameList)
""";

          //  print('SQL 查詢: $query');

          final results = await mysqlSelect(query);
          // print('查詢結果數量: ${results.length}');

          // 建立路線名稱到數據的映射
          for (final result in results) {
            //  print('處理查詢結果: ${result}');

            final routeNameField = result["RouteName"];
            String? routeName;

            // 解析 RouteName 欄位
            if (routeNameField is Map) {
              routeName = routeNameField["Zh_tw"] as String?;
              //   print('RouteName 是 Map: $routeNameField, 提取: $routeName');
            } else if (routeNameField is String) {
              try {
                // 嘗試解析 JSON 字串
                final parsed = json.decode(routeNameField) as Map<String, dynamic>;
                routeName = parsed["Zh_tw"] as String?;
                // print('RouteName 是 JSON String: $routeNameField, 解析後: $parsed, 提取: $routeName');
              } catch (e) {
                routeName = routeNameField;
                //  print('解析 JSON 失敗，使用原始字串: $routeNameField');
              }
            }

            if (routeName != null && routeName.isNotEmpty) {
              routeInfoCache[routeName] = result;
              // print('快取路線: $routeName -> ${result["RouteID"]}');

              // 打印詳細資訊以便調試
              //  print('出發站名: ${result["DepartureStopNameZh"]}');
              //  print('目的站名: ${result["DestinationStopNameZh"]}');
            }
          }

          //print('快取大小: ${routeInfoCache.length}');
          // print('快取內容: ${routeInfoCache.keys.toList()}');

        } catch (e) {
          print('批次查詢失敗: $e');

          // 降級方案：逐個查詢
          print('開始逐個查詢...');
          for (final routeName in routeNames) {
            try {
              print('查詢路線: $routeName');

              // 方法2：使用 LIKE 查詢 JSON
              final query = """
              SELECT * FROM Bus.Bus_Taichung_Route 
              WHERE RouteName LIKE '%"Zh_tw": "$routeName"%'
              OR JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName'
            """;

              final results = await mysqlSelect(query);

              if (results.isNotEmpty) {
                routeInfoCache[routeName] = results.first;
                // print('找到路線 $routeName: ${results.first["RouteID"]}');
              } else {
                print('未找到路線 $routeName');
              }
            } catch (e2) {
              print('查詢單一路線失敗 $routeName: $e2');
            }
          }
        }
      }

      /// -----------------------------
      /// 3. 合併路線資訊
      /// -----------------------------
      final List<Map<String, dynamic>> processedData = [];

      print('開始合併路線資訊...');

      for (final item in stationData) {


        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        final direction = item["Direction"];

        if (routeName == null) {
          print('跳過：routeName 為空');
          continue;
        }

        final resultItem = Map<String, dynamic>.from(item);
        final routeInfo = routeInfoCache[routeName];
        final hasValidInfo = routeInfo != null && routeInfo.isNotEmpty;

        print('路線 $routeName 找到資訊: $hasValidInfo');

        // 設置路線 ID
        if (hasValidInfo) {
          resultItem["RouteID"] = routeInfo!["RouteID"]?.toString() ?? "未知";

        } else {
          resultItem["RouteID"] = "未知";

        }

        // 設置站名資訊
        String? departureName;
        String? destinationName;

        if (hasValidInfo) {
          departureName = routeInfo!["DepartureStopNameZh"]?.toString();
          destinationName = routeInfo!["DestinationStopNameZh"]?.toString();



          // 如果沒有從資料庫獲取到，嘗試其他欄位名稱
          if (departureName == null) {
            departureName = routeInfo["DepartureStopName"]?.toString();

          }

          if (destinationName == null) {
            destinationName = routeInfo["DestinationStopName"]?.toString();

          }
        }

        resultItem["DepartureStopName"] = departureName ?? "未知出發站";
        resultItem["DestinationStopName"] = destinationName ?? "未知目的站";



        // 根據方向設置 "from" 和 "to"
        final isDirection1 = direction == 1;
        resultItem["from"] = isDirection1
            ? destinationName ?? "未知目的地"
            : departureName ?? "未知出發地";
        resultItem["to"] = isDirection1
            ? departureName ?? "未知出發地"
            : destinationName ?? "未知目的地";

        processedData.add(resultItem);

      }

      print('=== 處理完成，返回 ${processedData.length} 筆資料 ===');
      return processedData;
    } catch (e) {
      print('處理資料失敗: $e');
      print(e);
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
              return const Center(child: Text('沒有資料'));
            }

            if (_stationIDs.value.isEmpty) {
              return const SizedBox();
            }

            return DefaultTabController(
              length: _stationIDs.value.length,
              child: Builder(
                builder: (context) {
                  final tabController = _tabController;
                  return Column(
                    children: [
                      // ---------- 自訂 AppBar ----------
                      PreferredSize(
                        preferredSize: const Size.fromHeight(120),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
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
                                  setState(() {
                                    _indexNotifier.value--;
                                  });
                                  _NearbyStationsPageState._clearMarkerStyle(context);
                                  _stationIDs.value = [];
                                  _stopName.value = "";
                                  _selectStationID.value = "";
                                  _selectStationGroupID.value = "";
                                }
                              },
                            ),
                            actions: [
                              // 刷新按鈕
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
                                  onPressed: _loadData,
                                ),
                              ),
                              // 更多選項按鈕
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
                                      title: '站牌資訊',
                                      value: 'info',
                                      color: const Color(0xFF1A73E8),
                                    ),
                                    _buildPopupMenuItem(
                                      icon: Icons.favorite_border_rounded,
                                      title: '加入收藏',
                                      value: 'favorite',
                                      color: const Color(0xFFFF3B30),
                                    ),
                                    _buildPopupMenuItem(
                                      icon: Icons.sort_rounded,
                                      title: '排序方式',
                                      value: 'sort',
                                      color: const Color(0xFF34C759),
                                    ),
                                  ],
                                  onSelected: (String action) async {
                                    if (action == 'favorite') {
                                      favorite_feature dbHelper = favorite_feature();
                                      final output = await dbHelper.addFavorite(
                                        StopName: widget.stop,
                                        table: "FavoritesStop",
                                        city: "Taichung",
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
                                    } else if (action == 'sort') {
                                      _showSortDialog(context);
                                    } else if (action == 'info') {
                                      // 處理站牌資訊
                                    }
                                  },
                                ),
                              ),
                            ],
                            bottom: _buildTabBar(snapshot.data!, tabController),
                          ),
                        ),
                      ),
                      // ---------- Tab 內容 ----------
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: List.generate(
                            _stationIDs.value.length,
                                (index) {
                              return FutureBuilder(
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

                                  if (!contentSnapshot.hasData) {
                                    return const Center(
                                      child: Text("No content available"),
                                    );
                                  }

                                  return contentSnapshot.data!;
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  PreferredSize _buildTabBar(List<Map<String, dynamic>> station, TabController? tabController) {
    return PreferredSize(
      // 1. 高度縮小至 60
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          // 2. 移除陰影 (No Shadow)
        ),
        child: tabController == null
            ? const Center(child: CircularProgressIndicator())
            : AnimatedBuilder(
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
                          // 3. 美化：選中時使用淺藍背景，未選中時使用極淡灰色或透明
                          color: isSelected
                              ? const Color(0xFF1A73E8).withOpacity(0.08)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1A73E8)
                                : Colors.grey[200]!,
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
                                  size: 14, // 縮小圖示以符合高度
                                  color: isSelected
                                      ? const Color(0xFF1A73E8)
                                      : Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "站牌 $label",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF1A73E8)
                                        : Colors.grey[700],
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
                                fontSize: 10, // 縮小字體節省空間
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
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
  Future<Widget> _buildTabContent(String direction,List<Map<String, dynamic>> stopEstimatedTime) async {
    List<Map<String, dynamic>> finalList=await _processData(direction,stopEstimatedTime);




    return ValueListenableBuilder<SortType>(
      valueListenable: _sortNotifier,
      builder: (context, sortType, _) {
        final sortedList = [...finalList];

        switch(sortType) {
          case SortType.nameAsc:
            sortedList.sort((a, b) => getChineseName(a['RouteName']["Zh_tw"]).compareTo(getChineseName(b['RouteName']["Zh_tw"])));
            break;
          case SortType.nameDesc:
            sortedList.sort((a, b) => getChineseName(b['RouteName']["Zh_tw"]).compareTo(getChineseName(a['RouteName']["Zh_tw"])));
            break;
          case SortType.timeAsc:
            sortedList.sort(_timeAscComparator);
            break;
          case SortType.timeDesc:
            sortedList.sort(_timeDescComparator);
            break;
        }

        return _buildTabContentUI(direction, sortedList); // 改這裡：傳給 UI builder 而不是 Future
      },
    );


  }
  int _timeAscComparator(a, b) {
    if (a["time"] == "即將到站") return -1;
    if (b["time"] == "即將到站") return 1;
    if (a["time"] == "班次結束") return 1;
    if (b["time"] == "班次結束") return -1;
    return _parseTimeToMinutes(a['time']).compareTo(_parseTimeToMinutes(b['time']));
  }

  int _timeDescComparator(a, b) {
    if (a["time"] == "即將到站") return 1;
    if (b["time"] == "即將到站") return -1;
    if (a["time"] == "班次結束") return -1;
    if (b["time"] == "班次結束") return 1;
    return _parseTimeToMinutes(b['time']).compareTo(_parseTimeToMinutes(a['time']));
  }

  Widget _buildTabContentUI(String direction, List<Map<String, dynamic>> finalList) {
    return RefreshIndicator(
      onRefresh: () async => await _loadData(),
      child:   ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: ValueKey(_sortNotifier.value), // 每次排序不同 key
        items: finalList,
        areItemsTheSame: (a, b) => a["RouteID"] == b["RouteID"],
        itemBuilder: (context, animation, stop, index) {
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

          return SizeFadeTransition(
            animation: animation,
            curve: Curves.easeInOut,
            sizeFraction: 0.9,
            child: Column(
              children: [
                Container(
                  height: 53.0,
                  child: ListTile(
                    onTap: () async {
                      await GetBusInfo(
                          routeId: (stop["RouteID"]),
                          city: "Taichung");
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
                            routeID: (stop["RouteID"]),
                            mark: Mark.fromMap({
                              "highlight": [widget.stop],
                              "direction": stop['Direction'] == 0 ? 1 : 0,
                            }),      hasSubRoutes:stop["HasSubRoutes"],

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

                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? Colors.white
                              : (stop["color"] == '2'
                              ? const Color.fromRGBO(255, 85, 104, 1)
                              : (stop["color"] == "班次結束"
                              ? const Color.fromRGBO(149, 149, 149, 1.0)
                              : (stop["color"] == "min"
                              ? const Color.fromRGBO(13, 168, 255, 1)
                              : const Color.fromRGBO(
                              68, 68, 68, 1)))),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          stop["RouteName"]["Zh_tw"] ?? "未知站名",
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
                        const SizedBox(width: 8),
                        Text(
                          "往 ${stop["to"] ?? "未知方向"}",
                          style: const TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: Color.fromRGBO(136, 136, 136, 1),
                          ),
                        ),
                      ],
                    ),
                    trailing: PlateNumb != null
                        ? bubble(plateNum: PlateNumb)
                        : null,
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

    void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                // 標題
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
                    const Text(
                      "選擇排序方式",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 排序選項
                _buildSortOption('站序 1→10', SortType.nameAsc, Icons.numbers_rounded, const Color(0xFF1A73E8)),
                _buildSortOption('站序 10→1', SortType.nameDesc, Icons.numbers_rounded, const Color(0xFF1A73E8)),
                _buildSortOption('時間 早→晚', SortType.timeAsc, Icons.access_time_rounded, const Color(0xFF34C759)),
                _buildSortOption('時間 晚→早', SortType.timeDesc, Icons.access_time_rounded, const Color(0xFFFF9500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, SortType type, IconData icon, Color color) {
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
              color: _sortNotifier.value == type ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: _sortNotifier.value == type
                  ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                  : Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                // 圖標
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _sortNotifier.value == type ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: _sortNotifier.value == type ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),

                // 標題
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _sortNotifier.value == type ? color : Colors.black87,
                    ),
                  ),
                ),

                // 選取指示器
                if (_sortNotifier.value == type)
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
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
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
      // print('[Cache] 請求遠程數據 $cacheKey');
      final data = await _fetchData(stationName);
      _updateCache(cacheKey, data);
      return data;
    });
  }

  // 生成快取鍵（格式：城市_站點名）
  String _generateKey(String stationName) => '${_currentCity}_$stationName';

  // 實際數據獲取方法（此處應調用實際 API，示例中用 GetBusStopInfo）
  Future<List<Map<String, dynamic>>> _fetchData(String stationName) async {
    return await GetBusStopInfo(stopName:stationName, city:_currentCity);
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
    List<dynamic> info = await GetBusStopInfo(stopName:stop, city:city);
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