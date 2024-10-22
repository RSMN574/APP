import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'Const/regularClass.dart';
import 'firebase/placeAPI.dart';
import 'firebase/routeAPI.dart';
import 'widget/WeatherCard.dart';
import 'widget/transportGrid.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin<Home>{
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

  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;


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
  }
  @override
  Widget build(BuildContext context) {

    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight = screenHeight - (screenHeight * _bottomSheetHeightMin) - appBarHeight - bottomNavBarHeight;

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
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {

                    _mapController = controller;
                    _getCurrentLocation();
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ),
            IndexedStack(
              index: _index,
              children: <Widget>[
                _buildMainContent(context),
                _buildSearchContent(context),
                _buildPlaceDetails(_placePrediction),
              ],
            ),
          ],
        ),
      ),
    );
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
              margin: const EdgeInsets.only(top:60),
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
                    const TransportGrid(),
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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
                            final mainText = _placePredictions[index]['structured_formatting']['main_text'];
                            final secondaryText = _placePredictions[index]['structured_formatting']['secondary_text'];

                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.blue),
                              title: Text(mainText, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(secondaryText, style: const TextStyle(color: Colors.grey)),
                              onTap: () {
                                final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                                String origin = '${locationProvider.latitude},${locationProvider.longitude}';
                                print(_placePredictions[index]);

                                setState(() {
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

      if(place != null){
        _destinationController.text=place['structured_formatting']['main_text'];
        _originController.text="現在位置";
      }


    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx < -200) { // 向左滑动
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
                        padding: EdgeInsets.all(8.0),
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.arrow_back, color: Colors.blue),
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
                          Text(
                            '起點', // 起点标签
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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
                                  hintText: '選擇起點',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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

                                },
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
                          Text(
                            '終點', // 终点标签
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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

                                },
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
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // 触发导航或出发逻辑
                          getDirections("${locationProvider.latitude},${locationProvider.longitude}","place_id:${place["place_id"]}");
                          // 实现出发按钮逻辑
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Text('出發', style: TextStyle(fontSize: 18.0)),
                      ),
                    ),
                  ] else ...[
                    Text("未選擇地點"),
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
      List<dynamic> predictions = await placesService.getPlaceAutocomplete(_routeController.text);
      setState(() {
        _placePredictions = predictions;
      });
    } catch (e) {
      print('Error: $e');
    }
  }
}
