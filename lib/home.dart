import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'Const/regularClass.dart';
import 'firebase/placeAPI.dart';
import 'widget/WeatherCard.dart';
import 'widget/transportGrid.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _routeController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _placePredictions = [];
  var _placePrediction;
  double _bottomSheetHeightMin = 0.2;
  int _index = 0;
  GoogleMapController? _mapController;

  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);

  void setIndex(int num) {
    setState(() {
      _index = num;
    });
  }

  @override
  void initState() {
    super.initState();
    // 初始时，确保焦点在搜索框外
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
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
                    target: _initialPosition,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
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
      initialChildSize: 0.3,
      minChildSize: _bottomSheetHeightMin,
      maxChildSize: 1.0,
      builder: (BuildContext context, ScrollController scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 800,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    WeatherWidget(),
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
        padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                      Container(
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
                    Text("地點: ${place['structured_formatting']['main_text']}"),
                    Text("副地點: ${place['structured_formatting']['secondary_text']}"),
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
