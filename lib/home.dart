import 'dart:convert';

import 'package:com.rsmn574.app/utils/MRTColor.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/widget/img_swiper.dart';
import 'package:com.rsmn574.app/widget/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'database/getBusTime.dart';
import 'database/getData.dart';
import 'firebase/placeAPI.dart';


import 'widget/transportGrid.dart';
import 'package:event_bus/event_bus.dart';
ValueNotifier<List> youBikeStations = ValueNotifier<List>([]);
class detailPageDataEvent {
  final List message;
  detailPageDataEvent(this.message);
}
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}
EventBus eventBus = EventBus(); // 全局事件總線
class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin<Home> , MRTColor{
  DateTime _selectedTime= DateTime.now();
  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH時mm分');
  Future<void> _selectDateTime(BuildContext context) async {
    // 选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // 选择时间
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTime ?? DateTime.now()),
      );

      if (pickedTime != null) {
        // 合并日期和时间
        setState(() {
          _selectedTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  @override
  bool get wantKeepAlive => true; // 返回 true，以保持状态
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _placePredictions = [];
  var _placePrediction;
  double _bottomSheetHeightMin = 0.2;
  // int _int.value = 0;
  GoogleMapController? _mapController;
  PersistentBottomSheetController? _bottomSheetController;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;
  final ValueNotifier<List> dataNotifier = ValueNotifier<List>([]);

  final ValueNotifier<int> _indexNotifier = ValueNotifier<int>(0);
  // 获取当前位置
  void _getCurrentLocation() async {
    try {
      // 使用高精度设置
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      // 获取当前位置
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        print('获取到的当前位置: $_currentPosition');
      });

      // 更新地图的摄像机位置到当前定位
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 15.0, // 设置合适的缩放级别
        ),
      ));
    } catch (e) {
      print('无法获取当前位置: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // 初始时，确保焦点在搜索框外
    _searchFocusNode.unfocus();
// 地图创建时调用获取当前定位
    _getCurrentLocation();
    //showBusStops();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight = screenHeight -
        (screenHeight * _bottomSheetHeightMin) -
        appBarHeight -
        bottomNavBarHeight;

    return WillPopScope(
      onWillPop: () async {
        if (_indexNotifier.value > 0) {

            _indexNotifier.value--; // 返回到上一个索引
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
                  child: map(
                    onMapCreated: (controller) {
                      // 自定义逻辑

                    },
                  )),
            ), ValueListenableBuilder<int>(
              valueListenable: _indexNotifier,
              builder: (context, index, child) {
                return IndexedStack(
                  index: index,
                  children: [
                    _buildMainContent(context),
                    _buildSearchContent(context),
                    _buildPlaceDetails(_placePrediction),
                    _buildPlaceWays(_placePrediction),
                    _buildDetailPage(),
                  ],
                );
              },
            ),
            // IndexedStack(
            //   index: _indexNotifier.value,
            //   children: <Widget>[
            //     _buildMainContent(context),
            //     _buildSearchContent(context),
            //     _buildPlaceDetails(_placePrediction),
            //     _buildPlaceWays(_placePrediction),
            //     _buildDetailPage()
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchData() async {
    youBikeStations.value =
        await mysqlSelect("SELECT * FROM Bike.Bike_taichung_Station;");

    _loadBikeMarkers(); // 更新標記
  }

  Future<void> _loadBikeMarkers() async {
    BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(8, 8)), // 調整大小
      'assets/img/ubike_icon.png',
    );
    Set<Marker> cache = {};
    for (var station in youBikeStations.value) {
      final marker = Marker(
        markerId: MarkerId(station["StationUID"]),
        icon: customIcon,
        position: LatLng(
          json.decode(station["StationPosition"])["PositionLat"],
          json.decode(station["StationPosition"])["PositionLon"],
        ),
        infoWindow: InfoWindow(
          title: json.decode(station["StationName"])["Zh_tw"],
          snippet: "Capacity: ${station["BikesCapacity"]}",
        ),
      );
      cache.add(marker);
    }
    // 获取 MarkerProvider 的实例，并调用 setMarker 方法
    Provider.of<MarkerProvider>(context, listen: false).setMarker(cache);
  }
  Future<void> _loadMarkers(PositionLat,PositionLon,MarkerID) async {
    // BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
    //   ImageConfiguration(size: Size(8, 8)), // 調整大小
    //   'assets/img/ubike_icon.png',
    // );
    print(PositionLat+PositionLon);
    final marker = Marker(
      markerId:MarkerId(MarkerID),
      // icon: customIcon,
      position: LatLng(
        PositionLat,
        PositionLon,
      ),
      // infoWindow: InfoWindow(
      //   title: json.decode(station["StationName"])["Zh_tw"],
      //   snippet: "Capacity: ${station["BikesCapacity"]}",
      // ),
    );
    // 获取 MarkerProvider 的实例，并调用 setMarker 方法
    Provider.of<MarkerProvider>(context, listen: false).setMarker({marker});
  }
  Future<void> _handleClick(String type) async {
    if (type == "bike") {
      _fetchData();

      // 显示第二个 BottomSheet
      _bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
              height: 300, // 设置您想要的高度
              width: double.infinity, // 宽度填满
              child: _buildBikeContent(context));
        },
      );

      // 监听 BottomSheet 是否关闭
      _bottomSheetController!.closed.then((_) {
        // 这里可以处理 BottomSheet 关闭后的逻辑
        // 获取 MarkerProvider 的实例，并调用 setMarker 方法
        Provider.of<MarkerProvider>(context, listen: false).setMarker({});
      });
    }
  }

  Widget _buildMainContent(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.43,
      minChildSize: _bottomSheetHeightMin,
      maxChildSize: 1.0,
      builder: (BuildContext context, ScrollController scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 60),
              height: 800,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    // WeatherWidget(),
                    TransportGrid(onClick: _handleClick),
                    const ImgSwiper()
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildSearchBar(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _indexNotifier.value = 1; // 切换到搜索内容
        });
        // 显示搜索框并聚焦
        FocusScope.of(context).requestFocus(_searchFocusNode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 25,
              offset: Offset(0, 0),
              spreadRadius: 0,
            )
          ],
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
        ),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '搜尋',
            prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
            contentPadding: EdgeInsets.symmetric(vertical: 10.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 拖拽手柄
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: TextField(
                        controller: _routeController,
                        focusNode: _searchFocusNode,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          hintText: '輸入目的地...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 20.0),
                          prefixIcon: Icon(Icons.search, color: Colors.blue[300]),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search, color: Colors.white),
                              onPressed: () {
                                _loadPredictions();
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                        ),
                        onChanged: (value) => setState(() => _placePredictions.clear()),
                        onSubmitted: (value) {
                          _loadPredictions();
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    if (_placePredictions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(), // 禁止內部滾動
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _placePredictions.map((prediction) {
                                  final mainText = prediction['structured_formatting']['main_text'];
                                  final secondaryText = prediction['structured_formatting']['secondary_text'];

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.location_on,
                                              color: Colors.blue[700]),
                                        ),
                                        title: Text(mainText,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                              fontSize: 15,
                                            )),
                                        subtitle: Text(secondaryText,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            )),
                                        onTap: () {
                                          final locationProvider =
                                          Provider.of<LocationProvider>(context,
                                              listen: false);
                                          String origin =
                                              '${locationProvider.latitude},${locationProvider.longitude}';


                                          setState(() {
                                            _destinationController.text =
                                            prediction["description"];
                                            _placePrediction = prediction;
                                            _indexNotifier.value = 2; // 切换到地点详细信息
                                          });
                                        },
                                      ),
                                      if (_placePredictions.indexOf(prediction) !=
                                          _placePredictions.length - 1)
                                        Divider(
                                          height: 1,
                                          color: Colors.grey[200],
                                          indent: 16,
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: Material(
            borderRadius: BorderRadius.circular(24),
            elevation: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
                splashRadius: 24,
                onPressed: () {
                  setState(() {
                    _indexNotifier.value = 0;
                    _searchFocusNode.unfocus();
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceDetails(dynamic place) {
    final locationProvider = Provider.of<LocationProvider>(context);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          // 向左滑动
          setState(() {
            if (_indexNotifier.value > 0) {
              _indexNotifier.value--; // 返回上一页
            }
          });
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: _bottomSheetHeightMin,
        maxChildSize: 1.0,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  // 拖拽手柄
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (_indexNotifier.value > 0)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Material(
                          borderRadius: BorderRadius.circular(24),
                          elevation: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
                              splashRadius: 24,
                              onPressed: () {
                                setState(() {
                                  _indexNotifier.value--; // 返回上一页
                                  _searchFocusNode.unfocus(); // 隐藏键盘
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (place != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Text(
                            '起點',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: TextField(
                                controller: _originController,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                                decoration: InputDecoration(
                                  hintText: '選擇起點(現在位置)',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15.0, horizontal: 20.0),
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.search, color: Colors.white),
                                      onPressed: () {
                                        _loadPredictions();
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                ),
                                onChanged: (value) {},
                                onSubmitted: (value) {
                                  _loadPredictions();
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Text(
                            '終點',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: TextField(
                                controller: _destinationController,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                                decoration: InputDecoration(
                                  hintText: '選擇終點',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15.0, horizontal: 20.0),
                                  suffixIcon: Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.search, color: Colors.white),
                                      onPressed: () {
                                        _loadPredictions();
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                ),
                                onChanged: (value) {},
                                onSubmitted: (value) {
                                  _loadPredictions();
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    InkWell(
                      onTap: () async {
                        await _selectDateTime(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.blue[700]),
                            const SizedBox(width: 10.0),
                            Text(
                              '選擇時間',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _selectedTime == null
                                  ? '選擇時間'
                                  : dateFormat.format(_selectedTime!),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {


                            _indexNotifier.value = 3; // 切换到地点详细信息

                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          backgroundColor: Colors.blue,
                          elevation: 2,
                        ),
                        child: const Text(
                          '出發',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        "未選擇地點",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _loadPredictions() async {
    PlacesService placesService = PlacesService();
    try {
      List<dynamic> predictions = await placesService.getPlaceAutocomplete(
          _routeController.text, context);
      setState(() {
        _placePredictions = predictions;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildBikeContent(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.33, // 初始大小
      minChildSize: _bottomSheetHeightMin, // 最小大小
      maxChildSize: 0.6, // 最大大小
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // 这里是您想要展示的内容，例如：
                if (_indexNotifier.value > 0)
            Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                borderRadius: BorderRadius.circular(24),
                elevation: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
                    splashRadius: 24,
                    onPressed: () {
                      setState(() {
                        _indexNotifier.value--; // 返回上一页
                        _searchFocusNode.unfocus(); // 隐藏键盘
                      });
                    },
                  ),
                ),
              ),
            ),
          ), Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Bike Stations",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // 添加更多内容或组件
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceWays(dynamic place) {
    // 获取路线数据
    Future<Map<String, dynamic>> _getDirections() async {
      DateFormat dataFormat = DateFormat("yyyy-MM-ddTHH:mm:ss");
      PlacesService placesService = PlacesService();
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      LatLng? destination = await placesService.getLatLngFromPlaceId(place["place_id"]);
      _loadMarkers(destination?.latitude, destination?.longitude, place["place_id"]);
      return await getDirections(
        "${locationProvider.latitude}%2C${locationProvider.longitude}",
        "${destination?.latitude}%2C${destination?.longitude}",
        dataFormat.format(_selectedTime!),
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          // 向左滑动

            if (_indexNotifier.value > 0) {
              _indexNotifier.value--; // 返回上一页
            }

        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: _bottomSheetHeightMin,
        maxChildSize: 1.0,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(

            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _getDirections(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: LoadingAnimationWidget.stretchedDots(
                          color: Colors.black,
                          size: 40,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('錯誤: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text('沒有資料'));
                    }

                    final data = snapshot.data!;
                    final routes = data['data']['routes'] as List<dynamic>;

                    return SafeArea(

                      child: Padding(
                        padding: EdgeInsets.only(top: 25), // 确保底部不被遮挡
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: routes.length,
                          padding: EdgeInsets.only(top: 20), // 额外的底部间距
                          itemBuilder: (context, index) {
                            final route = routes[index];
                            final sections = route['sections'] as List<dynamic>;

                            // 合并类型相同的段落
                            List<Map<String, dynamic>> mergedJourney = [];
                            for (var segment in sections) {
                              if (mergedJourney.isNotEmpty &&
                                  mergedJourney.last['type'] == segment['type']) {
                                mergedJourney.last['travelSummary']['duration'] +=
                                segment['travelSummary']['duration'];
                                mergedJourney.last['travelSummary']['length'] +=
                                segment['travelSummary']['length'];

                                if (segment.containsKey('intermediateStops')) {
                                  mergedJourney.last['intermediateStops'] ??= [];
                                  mergedJourney.last['intermediateStops']
                                      .addAll(segment['intermediateStops']);
                                }

                                mergedJourney.last['arrival'] = segment['arrival'];
                              } else {
                                mergedJourney.add(segment);
                              }
                            }

                            mergedJourney.removeWhere((segment) => segment['type'] == 'waiting');
                            mergedJourney.removeWhere((segment) => segment['type'] == 'pedestrian-station');

                            return Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildSectionCard(mergedJourney, route['travel_time']),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                // 返回按钮
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_indexNotifier.value > 0) {
                          _indexNotifier.value--;
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.blue[800],
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }




  Widget _buildSectionCard(List<dynamic> sections, travelTime ){
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth > 600 ? 32 : 27;
    // 調用方法計算圓角半徑
    double radius = calculateCornerRadius(context);
    return // Generated code for this Row Widget...

      GestureDetector(
          onTap: () {
            eventBus.fire(detailPageDataEvent(sections));

            // 導航至詳細資訊頁面，並傳遞數據

             _indexNotifier.value++;

          },
          child:  Container(

        width: MediaQuery.of(context).size.width * 0.94,
        padding: EdgeInsets.all(12), // 为内容添加适当的内边距
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

          mainAxisSize: MainAxisSize.min, // 根据内容动态调整高度
          children: [
            Align(
              alignment: AlignmentDirectional(-1, -1),
              child: Text(
                _formatDuration(travelTime) ,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8), // 上方间距
              child:ConstrainedBox(
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width)*0.94,
    child:  Align(
      alignment: Alignment.centerLeft, // 靠左對齊
      child:  Wrap(
        crossAxisAlignment: WrapCrossAlignment.center, // 確保換行時內容仍然對齊
      spacing: 4, // 子组件之间的水平间距
      runSpacing: 6, // 子组件之间的垂直间距
      alignment: WrapAlignment.start, // 左对齐

    children: sections.asMap().entries.map((entry) {
        int index = entry.key; // 当前索引
        var i = entry.value; // 当前元素

        // 根据 transport.mode 构建组件
        Widget transportWidget;
        if (i["transport"]["mode"] == "pedestrian" && i["type"] != "pedestrian-station") {

          transportWidget =Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [ Icon(Icons.directions_walk, color: Colors.grey[600], size: 24),Text(style: TextStyle(

                color: Colors.grey[600],
              ), _formatDurationMin(i["travelSummary"]["duration"]))]);


        } else if (i["transport"]["mode"] == "Bus") {
          transportWidget = Container(

            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Color(0xFF01BC9F), width: 2), // 邊框顏色加粗
            ),
            padding: EdgeInsets.symmetric(horizontal:8 ,vertical:3 ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // 讓 Icon 與 Text 對齊
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(Icons.directions_bus, color: Color(0xFF01BC9F), size: 24), // Icon 顏色
                // SizedBox(width: 4),
                Text(
                  i["transport"]["name"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // 字體加粗
                    color: Color(0xFF01BC9F), // 文字顏色
                    fontSize: 16, // 適當調整字體大小
                  ),
                ),
              ],
            ),
          );


        } else if (i["transport"]["mode"] == "MRT") {
          print(i["transport"]);
          transportWidget = Container(
            decoration: BoxDecoration(
              color: MRTColor.getColorByLineName(i["transport"]["name"]), // 获取颜色
              borderRadius: BorderRadius.circular(radius),
            ),
            padding: EdgeInsets.symmetric(horizontal:8 ,vertical:3 ),
            child: Text(

              i["transport"]["name"],
              style: TextStyle(

                color: Colors.white,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }  else if (i["transport"]["mode"] == "HSR") {
          print(i["transport"]["mode"] );
          transportWidget = SizedBox(
            width: 24,
            height: 24,
            child: Image.network(
              "https://raw.githubusercontent.com/RSMN574/assets/refs/heads/main/logo/HSR-logo.png",
              fit: BoxFit.contain, // 确保图片完整显示
            ),
          );
        } else if (i["transport"]["mode"] == "HighwayBus") {

          transportWidget = Icon(Icons.directions_bus, color: Colors.black, size: 24);
        }else if (i["transport"]["mode"] == "TRA") {
          transportWidget = SizedBox(
            width: 24,
            height: 24,
            child: Image.network(
              "https://raw.githubusercontent.com/RSMN574/assets/refs/heads/main/logo/TRA-logo.png",
              fit: BoxFit.contain, // 确保图片完整显示
            ),
          );
        }
        else {
          transportWidget = Container(width: 0,);

        }

        // 添加箭头图标
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            transportWidget,
            if (index < sections.length - 1)
              Icon(Icons.arrow_right_rounded,      color: Colors.grey[600], size: 24),
          ],
        );
      }).toList(),
    ),
              ))

            ),

            Padding(
              padding: EdgeInsets.only(top: 8), // 行间距
              child: Wrap(

                children: sections.asMap().entries.map((entry) {
                  int index = entry.key; // 当前索引
                  var i = entry.value; // 当前元素
               if (i["transport"]["mode"] == "Bus") {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        SizedBox(width: 4),
                        Text(
                          i["departure"]["place"]["name"]+"-"+i["arrival"]["place"]["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (index < sections.length - 1) // Adjust the condition to avoid showing arrow on the last element
                          Icon(
                            Icons.arrow_right_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                      ],
                    );

                  } else if(i["transport"]["mode"]=="MRT"){

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        SizedBox(width: 4),
                        Text(
                          i["departure"]["place"]["name"]+"-"+i["arrival"]["place"]["name"],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (index < sections.length - 1) // Adjust the condition to avoid showing arrow on the last element
                          Icon(
                            Icons.arrow_right_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                      ],
                    );
                  }
                  else
                  {
                    return  Container(width: 1,);
                  }
                }).toList(),
              )
            ),
          ],
        ),
      ));





  }
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600; // 计算小时
    final minutes = (seconds % 3600) ~/ 60; // 剩余部分计算分钟
    final remainingSeconds = ((seconds % 3600) % 60).round(); // 秒数四舍五入

    if (hours > 0) {
      return '$hours 小時 $minutes 分';
    } else {
      return '$minutes 分';
    }
  }
  String _formatDurationMin(int seconds) {
    final hours = seconds ~/ 3600; // 计算小时
    final minutes = (seconds % 3600) ~/ 60; // 剩余部分计算分钟
    final remainingSeconds = ((seconds % 3600) % 60).round(); // 秒数四舍五入


      return '$minutes ';

  }
  Widget _buildDetailPage(){

    eventBus.on<detailPageDataEvent>().listen((event) {
      print( "event.message"); // 更新 UI
    print( event.message); // 更新 UI
      dataNotifier.value=event.message;
    });
   return  DraggableScrollableSheet(
      initialChildSize: 0.33, // 初始大小
      minChildSize: _bottomSheetHeightMin, // 最小大小
      maxChildSize: 0.6, // 最大大小
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: _buildTravelSteps(),
            ),
          ),
        );
      },
    );

  }
// 行程步驟 UI（完整美化版）
  List<Widget> _buildTravelSteps() {
    return dataNotifier.value.map((step) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主標題（帶操作按鈕）
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getStepTitle(step),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                _buildActionButton(step), // 根據類型顯示不同操作按鈕
              ],
            ),
            SizedBox(height: 12),

            // 詳細行程內容
            _buildStepContent(step),

            // 分隔線
            Divider(height: 24, thickness: 1, color: Colors.grey[300]),
          ],
        ),
      );
    }).toList();
  }

// 構建步驟標題
  String _getStepTitle(Map<String, dynamic> step) {
    switch (step['type']) {
      case 'pedestrian':
        return "步行 ${step['travelSummary']['length']?.toStringAsFixed(0) ?? ''}米";
      case 'transit':
        return "${step['transport']['shortName']} · ${step['travelSummary']['duration']}分鐘";
      default:
        return step['type'];
    }
  }

// 構建操作按鈕
  Widget _buildActionButton(Map<String, dynamic> step) {
    switch (step['type']) {
      case 'pedestrian':
        return TextButton.icon(
          icon: Icon(Icons.directions, size: 18, color: Colors.blue),
          label: Text("步行導航", style: TextStyle(color: Colors.blue)), onPressed: () {  },
          // onPressed: () => _startNavigation(step),
        );
      case 'transit':
        return TextButton.icon(
          icon: Icon(Icons.notifications_active, size: 18, color: Colors.orange),
          label: Text("關注路線", style: TextStyle(color: Colors.orange)), onPressed: () {  },
          // onPressed: () => _followRoute(step),
        );
      default:
        return SizedBox.shrink();
    }
  }

// 構建行程內容
  Widget _buildStepContent(Map<String, dynamic> step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 時間與地點區塊
        _buildTimeBlock(
          icon: Icons.access_time,
          time: _formatTime(step['departure']['time']),
          place: step['departure']['place']['name']??"未知地點",
          duration: step['travelSummary']['duration'],
        ),

        // 交通資訊區塊
        if (step['type'] == 'transit') ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.directions_transit, size: 16, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                "預計車程：${step['travelSummary']['duration']}分鐘",
                style: TextStyle(color: Colors.grey[600]),
              ),
              Spacer(),
              Text(
                "${step['transport']['fare']}元",
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],

        // 卡路里消耗提示
        if (step['type'] == 'pedestrian') ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text(
                "本段預計消耗 ${_calculateCalories(step)} 大卡",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],

        // 換乘提示
        if (step['type'] == 'pedestrian-station') ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "站內換乘${step['travelSummary']['length']}米（約${step['travelSummary']['duration']}分鐘）",
                    style: TextStyle(color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 實時公交信息
        if (step['type'] == 'transit') ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "實時信息",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                _buildRealTimeInfo(step),
              ],
            ),
          ),
        ],
      ],
    );
  }

// 其他工具函式
  String _formatTime(String isoTime) {
    final time = DateTime.parse(isoTime);
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  int _calculateCalories(Map<String, dynamic> step, { double weight = 60}) {
    final duration = step['travelSummary']['duration'] ?? 0;
    final metValue = 3.5;
    final timeInHours = duration / 60;
    final calories = metValue * weight * timeInHours;
    return calories.toInt();
  }
  Widget _buildRealTimeInfo(Map<String, dynamic> step) {
    // 模擬實時數據
    final nextDeparture = step['intermediateStops'].isNotEmpty
        ? _formatTime(step['intermediateStops'].first['departure']['time'])
        : "06:00";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("下一班車：$nextDeparture 發出"),
        SizedBox(height: 4),
        Text("預計到達：${_formatTime(step['arrival']['time'])}"),
        SizedBox(height: 8),
        ElevatedButton.icon(
          icon: Icon(Icons.refresh, size: 18),
          label: Text("刷新實時信息"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[50],
            foregroundColor: Colors.green[800],
          ), onPressed: () {  },
          // onPressed: () => _refreshRealTime(step),
        ),
      ],
    );
  }
  Widget _buildTimeBlock({required IconData icon, required String time, required String place, required int duration}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              "$place · 約$duration分鐘",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
