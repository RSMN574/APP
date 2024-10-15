import 'package:com.rsmn574.app/widget/WeatherCard.dart';
import 'package:com.rsmn574.app/widget/transportGrid.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'Const/regularClass.dart';
import 'firebase/placeAPI.dart';
import 'firebase/routeAPI.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double _bottomSheetHeightMin = 0.2;
  final TextEditingController _routeController = TextEditingController();
  GoogleMapController? _mapController;

  // 保存自动填充的预测结果
  List<dynamic> _placePredictions = [];

  // 初始地图位置
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654); // 台北市经纬度

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final bottomNavBarHeight = kBottomNavigationBarHeight;
    final mapHeight = screenHeight - (screenHeight * _bottomSheetHeightMin) - appBarHeight - bottomNavBarHeight;

    return GestureDetector(
      child: Stack(
        children: [
          // Google Map 只会在第一次加载时显示，保持在后台
          Positioned.fill(
            child: Container(
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
          // Bottom Sheet
          DraggableScrollableSheet(
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
                    child: searchBar(),
                  ),
                ],
              );
            },
          ),
          // 自动填充建议列表，显示在BottomSheet和其他元素之上
          if (_placePredictions.isNotEmpty)
            Positioned(
              top: appBarHeight + 10,
              left: 16,
              right: 16,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _placePredictions.length,
                    itemBuilder: (context, index) {
                      // 使用中文主标题显示
                      final mainText = _placePredictions[index]['structured_formatting']['main_text'];
                      final secondaryText = _placePredictions[index]['structured_formatting']['secondary_text'];

                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(mainText), // 主标题使用中文
                        subtitle: Text(secondaryText), // 显示次级地址
                        onTap: () async {
                          final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                          print( _placePredictions[index]["place_id"]);
                         String origin=locationProvider.latitude.toString()+","+locationProvider.longitude.toString();
                          var i=await getDirections(  origin,"place_id:${_placePredictions[index]['place_id']}");
                          print(i);

                          // 点击建议后更新搜索框并隐藏建议列表
                          // _routeController.text = _placePredictions[index]['description'];
                          setState(() {
                            _placePredictions.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget searchBar() {
    return Container(
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
        controller: _routeController,
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
        // 当用户按下搜索按钮时触发建议列表
        onSubmitted: (value) async {
          if (value.isNotEmpty) {
            _loadPredictions();
          }
        },
        // 当用户输入时隐藏建议列表
        onChanged: (value) {
          setState(() {
            _placePredictions.clear();
          });
        },
      ),
    );
  }

  // 搜索按钮点击后调用的函数
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
