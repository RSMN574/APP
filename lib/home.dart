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

Set<Marker> _bikeMarkers = {};
ValueNotifier<List> youBikeStations = ValueNotifier<List>([]);

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

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
  int _index = 0;
  GoogleMapController? _mapController;
  PersistentBottomSheetController? _bottomSheetController;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;

  Future<void> showBusStops() async {
    var i = await mysqlSelect('SELECT * FROM Bus.Bus_Taichung_Stop');
  }

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
        if (_index > 0) {
          setState(() {
            _index--; // 返回到上一个索引
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
                  child: map(
                    onMapCreated: (controller) {
                      // 自定义逻辑

                    },
                  )),
            ),
            IndexedStack(
              index: _index,
              children: <Widget>[
                _buildMainContent(context),
                _buildSearchContent(context),
                _buildPlaceDetails(_placePrediction),
                _buildPlaceWays(_placePrediction),
              ],
            ),
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
          _index = 1; // 切换到搜索内容
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _routeController,
                        focusNode: _searchFocusNode, // 绑定焦点节点
                        autofocus: false, // 不在加载时自动获取焦点
                        decoration: InputDecoration(
                          hintText: '搜尋',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 20.0),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Colors.blue),
                            onPressed: () {
                              _loadPredictions();
                              // 隐藏键盘
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _placePredictions.clear();
                          });
                        },
                        onSubmitted: (value) {
                          _loadPredictions();
                          // 隐藏键盘
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    if (_placePredictions.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _placePredictions.length,
                          itemBuilder: (context, index) {
                            final mainText = _placePredictions[index]
                                ['structured_formatting']['main_text'];
                            final secondaryText = _placePredictions[index]
                                ['structured_formatting']['secondary_text'];

                            return ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: Colors.blue),
                              title: Text(mainText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(secondaryText,
                                  style: const TextStyle(color: Colors.grey)),
                              onTap: () {
                                final locationProvider =
                                    Provider.of<LocationProvider>(context,
                                        listen: false);
                                String origin =
                                    '${locationProvider.latitude},${locationProvider.longitude}';
                                print(_placePredictions[index]);

                                setState(() {
                                  _destinationController.text =
                                      _placePredictions[index]["description"];
                                  _placePrediction = _placePredictions[index];
                                  _index = 2; // 切换到地点详细信息
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 30,
          left: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            child: Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () {
              setState(() {
                _index = 0; // 返回主页面
                _searchFocusNode.unfocus(); // 隐藏键盘
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceDetails(dynamic place) {

    final locationProvider = Provider.of<LocationProvider>(context);
    //
    //   if(place != null){
    //     _destinationController.text=place['structured_formatting']['main_text'];
    //     _originController.text="現在位置";
    //   }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          // 向左滑动
          setState(() {
            if (_index > 0) {
              _index--; // 返回上一页
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  if (_index > 0)
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.arrow_back, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _index--; // 返回上一页
                              _searchFocusNode.unfocus(); // 隐藏键盘
                            });
                          },
                        ),
                      ),
                    ),
                  if (place != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        children: [
                          const Text(
                            '起點', // 起点标签
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              child: TextField(
                                controller: _originController,
                                decoration: InputDecoration(
                                  hintText: '選擇起點(現在位置)',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15.0, horizontal: 20.0),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search, color: Colors.blue),
                                    onPressed: () {
                                      _loadPredictions();
                                      // 隐藏键盘
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                                onChanged: (value) {},
                                onSubmitted: (value) {
                                  _loadPredictions();
                                  // 隐藏键盘
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        children: [
                          const Text(
                            '終點', // 终点标签
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              child: TextField(
                                controller: _destinationController,
                                decoration: InputDecoration(
                                  hintText: '選擇終點',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15.0, horizontal: 20.0),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search, color: Colors.blue),
                                    onPressed: () {
                                      _loadPredictions();
                                      // 隐藏键盘
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                                onChanged: (value) {},
                                onSubmitted: (value) {
                                  _loadPredictions();
                                  // 隐藏键盘
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    InkWell(
                      onTap: () async {
                        await _selectDateTime(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.blue),
                            const SizedBox(width: 10.0),
                            const Text(
                              '選擇時間',
                              style: TextStyle(fontSize: 16.0, color: Colors.blue),
                            ),
                            const Spacer(),
                            Text(
                              _selectedTime == null
                                  ? '選擇時間'
                                  : dateFormat.format(_selectedTime!),
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _index = 3; // 切换到地点详细信息
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          backgroundColor: Colors.blue, // 按钮背景颜色
                        ),
                        child: const Text(
                          '出發',
                          style: TextStyle(fontSize: 18.0, color: Colors.white),
                        ),
                      ),
                    ),

                  ] else ...[
                    const Text(
                      "未選擇地點",
                      style: TextStyle(fontSize: 16.0, color: Colors.grey),
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
                Padding(
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

  Widget _buildPlaceWays(dynamic place,) {
    // 获取交通方式的图标


    // 获取路线数据
    Future<Map<String, dynamic>> _getDirections() async {
      DateFormat dataFormat=DateFormat("yyyy-MM-ddTHH:mm:ss");
      PlacesService placesService = PlacesService();
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      LatLng? destination =
          await placesService.getLatLngFromPlaceId(place["place_id"]);
      _loadMarkers(destination?.latitude,destination?.longitude,place["place_id"]);
      return await getDirections(
        "${locationProvider.latitude}%2C${locationProvider.longitude}",
        "${destination?.latitude}%2C${destination?.longitude}",dataFormat.format(_selectedTime!),
      );
    }
//  "${24.150784}%2C${120.646877}",
    // "${locationProvider.latitude}%2C${locationProvider.longitude}",
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) {
          // 向左滑动
          setState(() {
            if (_index > 0) {
              _index--; // 返回上一页
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
              color: bgColor, // 白色背景
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12, // 微弱阴影效果
                  offset: Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getDirections(), // 调用异步方法
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.stretchedDots(
                      color: Colors.black,
                      size: 40,
                    ),
                  );// 加载中的占位组件
                } else if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}')); // 错误提示
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('沒有資料')); // 无数据占位
                }

                // 使用数据生成 UI
                final data = snapshot.data!;
                final routes = data['data']['routes'] as List<dynamic>;


                return ListView.builder(
                  controller: scrollController,
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    final sections = route['sections'] as List<dynamic>;
                    final totalTime = route['travel_time'];
                    final totalPrice = route['total_price'] ?? 0;
                    // 合并类型相同的段落
                    List<Map<String, dynamic>> mergedJourney = [];
                    for (var segment in sections) {

                      if (mergedJourney.isNotEmpty &&
                          mergedJourney.last['type'] == segment['type']) {
                        // 更新 travelSummary
                        mergedJourney.last['travelSummary']['duration'] +=
                        segment['travelSummary']['duration'];
                        mergedJourney.last['travelSummary']['length'] +=
                        segment['travelSummary']['length'];

                        // 合并 intermediateStops
                        if (segment.containsKey('intermediateStops')) {
                          mergedJourney.last['intermediateStops'] ??= [];
                          mergedJourney.last['intermediateStops']
                              .addAll(segment['intermediateStops']);
                        }

                        // 更新到达信息
                        mergedJourney.last['arrival'] = segment['arrival'];
                      } else {
                        mergedJourney.add(segment);
                      }


                    }
                    // 移除 type 为 "waiting" 的段落
                    mergedJourney.removeWhere((segment) => segment['type'] == 'waiting');
                    mergedJourney.removeWhere((segment) => segment['type'] == 'pedestrian-station');

                    return
                      Column(children: [ const SizedBox(height: 20,),_buildSectionCard(mergedJourney,route['travel_time'])]);

                  },
                );

              },
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

      Container(

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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
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
              children: [ const Icon(Icons.directions_walk, color: Colors.black, size: 24),Text(_formatDurationMin(i["travelSummary"]["duration"]))]);
        } else if (i["transport"]["mode"] == "Bus") {
          transportWidget = Row(
            mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
          Icon(Icons.directions_bus, color: Colors.black, size: 24),

          Text(
            i["transport"]["name"],
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
                      ],
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
          transportWidget =  SvgPicture.asset(
            "assets/icons/train-outline.svg",
            width: iconSize,
            height: iconSize,
          );
        } else if (i["transport"]["mode"] == "HighwayBus") {

          transportWidget = Icon(Icons.question_mark, color: Colors.black, size: 24);
        }  else {
          transportWidget = Container(width: 0,);

        }

        // 添加箭头图标
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            transportWidget,
            if (index < sections.length - 1)
              Icon(Icons.arrow_right_rounded, color: Colors.black, size: 24),
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
      );





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
}
