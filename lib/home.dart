import 'dart:async';
import 'dart:convert';
import 'package:com.rsmn574.app/utils/MRTColor.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/widget/WeatherCard.dart' hide WeatherData;
import 'package:com.rsmn574.app/widget/img_swiper.dart';
import 'package:com.rsmn574.app/widget/map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'database/bike/getBike.dart';
import 'database/bus/getBusTime.dart';
import 'database/getData.dart';
import 'database/getWeather.dart';
import 'firebase/placeAPI.dart';

import 'models/WeatherData.dart';
import 'widget/transportGrid.dart';


ValueNotifier<List> youBikeStations = ValueNotifier<List>([]);

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

// EventBus eventBus = EventBus(); // 全局事件總線

class _HomeState extends State<Home>
    with AutomaticKeepAliveClientMixin<Home> {
  DateTime _selectedTime = DateTime.now().add(Duration(minutes: 1));
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedStation; // null 代表沒選任何站點

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _selectedStation = null;
    });
  }


  final DateFormat dateFormat = DateFormat('yyyy年M月d日 HH時mm分');


  @override
  bool get wantKeepAlive => true; // 返回 true，以保持状态

  final FocusNode _searchFocusNode = FocusNode();
  double _bottomSheetHeightMin = 0.2;
  GoogleMapController? _mapController;
  PersistentBottomSheetController? _bottomSheetController;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;
  final ValueNotifier<List> dataNotifier = ValueNotifier<List>([]);


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

  bool _showMainContent = true; // 預設顯示主內容

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final PageStorageBucket _bucket = PageStorageBucket(); // 用於存儲頁面狀態

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    const double _bottomSheetHeightMin = 0.3; // 這個變數應該來自你的程式碼
    final mapHeight = screenHeight -
        (screenHeight * _bottomSheetHeightMin) -
        appBarHeight -
        bottomNavBarHeight;

    return WillPopScope(
      onWillPop: () async {

        return true; // 在索引为0时允许默认返回导航
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SizedBox(
                height: mapHeight,
                child: map(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  // onCameraMove: (CameraPosition position) {},
                  onCameraIdle: () {},
                ),
              ),
            ),
            _buildMainContent(context)
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
    // 延迟执行以确保在构建完成后访问 context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<MarkerProvider>(context, listen: false);

      BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(8, 8)), // 调整大小
        'assets/img/ubike_icon.png',
      );

      Set<Marker> markerCache = {};
      List<youbike> clusterItems = [];

      for (var station in youBikeStations.value) {
        final lat = json.decode(station["StationPosition"])["PositionLat"];
        final lon = json.decode(station["StationPosition"])["PositionLon"];
        final stationId = station["StationUID"];
        final stationName = json.decode(station["StationName"])["Zh_tw"];

        final marker = Marker(
          markerId: MarkerId(stationId),
          icon: customIcon,
          position: LatLng(lat, lon),
          infoWindow: InfoWindow(
            title: stationName,
            snippet: "Capacity: ${station["BikesCapacity"]}",
          ),
          onTap: () {
            _updateSelectedStation(station); // 這個函數用來記錄目前選中的站點，並打開下方的資訊面板
          },
        );
        markerCache.add(marker);

        clusterItems.add(youbike(stationId, LatLng(lat, lon)));
      }

      provider.setMarkers(markerCache);
      provider.setItems(clusterItems);
    });
  }

//////////////////////////////////////////////////////
  Future<void> _handleClick(String type) async {
    if (type == "bike") {
      setState(() {
        _showMainContent = false; // 隱藏主內容
      });
      _fetchData();
      // 显示第二个 BottomSheet
      _bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) {
          return _buildBikeContent(context);
        },
      );

      // 监听 BottomSheet 是否关闭
      _bottomSheetController!.closed.then((_) {
        // 这里可以处理 BottomSheet 关闭后的逻辑
        // 获取 MarkerProvider 的实例，并调用 setMarker 方法
        Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
        setState(() {
          _showMainContent = true; // 主內容
          _selectedStation = null;
        });
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
              decoration: BoxDecoration(
                color: AppThemes.getSurface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    // WeatherWidget(),
                    TransportGrid(onClick: _handleClick),
                    const ImgSwiper(),
                    // 插入天氣卡片
                    WeatherAlertCard(cityName: '臺中市',),

                  ],
                ),
              ),
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   child: _buildSearchBar(),
            // ),
          ],
        );
      },
    );
  }




  Future<Map<String, dynamic>?>? _bikeAvailabilityFuture;

  void _updateSelectedStation(Map<String, dynamic> station) {
   if(station.isNotEmpty){
     _mapController?.animateCamera(
       CameraUpdate.newCameraPosition(
         CameraPosition(
           target: LatLng(json.decode(station["StationPosition"])["PositionLat"], json.decode(station["StationPosition"])["PositionLon"]),
           zoom: 23.0, // 可根據需求調整放大倍率
         ),
       ),
     );

     setState(() {
       _selectedStation = station;
       _bikeAvailabilityFuture =
           getBikeAvailability("Taichung", station["StationID"]);
     });
   }else{
     setState(() {
       _selectedStation = null;
       
     });
   }
    // 這裡可以控制 bottom sheet 彈出
    _bottomSheetController = showBottomSheet(
        context: context,
        builder: (context) {
          return _buildBikeContent(context);
        });
    // 监听 BottomSheet 是否关闭
    _bottomSheetController!.closed.then((_) {
      // 这里可以处理 BottomSheet 关闭后的逻辑
      // 获取 MarkerProvider 的实例，并调用 setMarker 方法
      Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
      setState(() {
        _showMainContent = true; // 主內容
      });
    });
  }

  Widget _buildBikeContent(BuildContext context) {
    return   Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _selectedStation == null
          // ? _buildPlaceholder('請選擇站點', Icons.location_off_outlined)
      ?BikeDefaultContent(onStationSelected:_updateSelectedStation )
          : FutureBuilder<Map<String, dynamic>?>(
        future: _bikeAvailabilityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildPlaceholder(
              snapshot.hasError ? '資料載入失敗' : '暫無可用資料',
              snapshot.hasError
                  ? Icons.error_outline
                  : Icons.info_outline,
            );
          }

          final stationName =
          json.decode(_selectedStation!["StationName"])["Zh_tw"];
          final data = snapshot.data!;

          return _buildContentSection(context, stationName, data);
        },
      ),
    );



  }

  /// Loading 狀態 widget
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center( child:
          LoadingAnimationWidget.stretchedDots(
            color: Colors.black,
            size: 40,
          ),
          ),
          const SizedBox(height: 16),
          const Text(
            '載入中...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, String stationName, Map<String, dynamic> data) {
    final rentDetails = data["AvailableRentBikesDetail"] ??
        {"GeneralBikes": 0, "ElectricBikes": 0};

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 站點標題 (已新增關閉按鈕)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                // 左側圖標和標題
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.pin_drop,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stationName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),
                  ),
                ),

                // 新增的關閉按鈕
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // 移除默認的最小點擊區域
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    // 處理關閉邏輯，例如：
                    _updateSelectedStation({});
                    // 或者調用回調函數：
                    // widget.onClose?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 主要數據卡片 (保持不變)
          _buildCompactDataGrid(
            context,
            rentBikes: data["AvailableRentBikes"]?.toString() ?? '0',
            returnSpots: data["AvailableReturnBikes"]?.toString() ?? '0',
            generalBikes: rentDetails["GeneralBikes"]?.toString() ?? '0',
            electricBikes: rentDetails["ElectricBikes"]?.toString() ?? '0',
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDataGrid(
    BuildContext context, {
    required String rentBikes,
    required String returnSpots,
    required String generalBikes,
    required String electricBikes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 第一行：主要指標
        Row(
          children: [
            _buildMetricTile(
              context,
              icon: Icons.pedal_bike,
              color: Colors.green[600]!,
              title: '可租借',
              value: rentBikes,
              widthFactor: 0.5,
            ),
            const SizedBox(width: 8),
            _buildMetricTile(
              context,
              icon: Icons.local_parking,
              color: Colors.blue[600]!,
              title: '可歸還',
              value: returnSpots,
              widthFactor: 0.5,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 第二行：車型分布
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '車輛類型',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildBikeTypeRow(
                context,
                general: generalBikes,
                electric: electricBikes,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    double widthFactor = 1.0,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeTypeRow(BuildContext context,
      {required String general, required String electric}) {
    return Row(
      children: [
        _buildTypeChip(
          context,
          icon: Icons.pedal_bike,
          label: '普通車',
          value: general,
          color: Colors.grey[700]!,
        ),
        const SizedBox(width: 8),
        _buildTypeChip(
          context,
          icon: Icons.electric_bike,
          label: '電輔車',
          value: electric,
          color: Colors.blue[600]!,
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // 更灵活的模糊搜索版本（包含/开头/结尾匹配）
  List<Map<String, dynamic>> fuzzySearchStations(String keyword) {
    if (keyword.isEmpty) return [];

    final keywordLower = keyword.toLowerCase();

    return youBikeStations.value.where((station) {
      try {
        final stationName = json.decode(station["StationName"])["Zh_tw"].toString().toLowerCase();

        // 多种匹配方式
        return stationName.contains(keywordLower) ||  // 包含
            stationName.startsWith(keywordLower) || // 开头
            stationName.endsWith(keywordLower);    // 结尾
      } catch (e) {
        return false;
      }
    }).map((e) => e as Map<String, dynamic>).toList();
  }
  Widget _buildPlaceholder(String text, IconData icon) {
    return Container(
      height: 300,
      color: bgColor,
      child: Column(
        children: [
          // 搜尋框
          Container(
            decoration: ShapeDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 25,
                  offset: Offset(0, 0),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (searchText) {
                setState(() {}); // 觸發UI更新
              },
              decoration: InputDecoration(
                hintText: '搜尋站點名稱或地址',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 動態顯示搜尋結果或預設內容
          Expanded(
            child: _searchController.text.isEmpty
                ? BikeDefaultContent(onStationSelected:_updateSelectedStation)// 顯示預設內容
                : _buildSearchResults(), // 顯示搜尋結果
          ),
        ],
      ),
    );
  }

// 搜尋結果列表
  Widget _buildSearchResults() {
    final List<Map<String, dynamic>> results = fuzzySearchStations(_searchController.text);

    if (results.isEmpty) {
      return Center(
        child: Text(
          '找不到符合「${_searchController.text}」的站點',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final station = results[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              )
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.grey.shade50,
              ],
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // 点击处理逻辑
            },
            splashColor: Colors.blue.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标区域
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.electric_bike_rounded,
                      color: Colors.red[600],
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 文字信息区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          json.decode(station["StationName"])["Zh_tw"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          json.decode(station["StationAddress"])["Zh_tw"],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 车辆数量指示器
                  // Column(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   crossAxisAlignment: CrossAxisAlignment.end,
                  //   children: [
                  //     Text(
                  //       '可借',
                  //       style: TextStyle(
                  //         fontSize: 12,
                  //         color: Colors.grey[500],
                  //       ),
                  //     ),
                  //     // const SizedBox(height: 4),
                  //     // Container(
                  //     //   padding: const EdgeInsets.symmetric(
                  //     //     horizontal: 12,
                  //     //     vertical: 6,
                  //     //   ),
                  //     //   decoration: BoxDecoration(
                  //     //     color: (station["AvailableRentBikes"] ?? 0) > 0
                  //     //         ? Colors.green.withOpacity(0.15)
                  //     //         : Colors.red.withOpacity(0.15),
                  //     //     borderRadius: BorderRadius.circular(8),
                  //     //     border: Border.all(
                  //     //       color: (station["AvailableRentBikes"] ?? 0) > 0
                  //     //           ? Colors.green.withOpacity(0.3)
                  //     //           : Colors.red.withOpacity(0.3),
                  //     //       width: 1,
                  //     //     ),
                  //     //   ),
                  //     //   child: Text(
                  //     //     '${station["AvailableRentBikes"] ?? 0}',
                  //     //     style: TextStyle(
                  //     //       fontSize: 16,
                  //     //       fontWeight: FontWeight.w700,
                  //     //       color: (station["AvailableRentBikes"] ?? 0) > 0
                  //     //           ? Colors.green[800]
                  //     //           : Colors.red[800],
                  //     //     ),
                  //     //   ),
                  //     // ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



}


class HomeProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _showMainContent = true;

  int get currentIndex => _currentIndex;
  bool get showMainContent => _showMainContent;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setShowMainContent(bool show) {
    if (_showMainContent != show) {
      _showMainContent = show;
      notifyListeners();
    }
  }
}
class BikeProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _stations = [];
  Map<String, dynamic>? _selectedStation;
  Map<String, dynamic>? _availabilityData;
  bool _isLoading = false;

  List<Map<String, dynamic>> get stations => _stations;
  Map<String, dynamic>? get selectedStation => _selectedStation;
  Map<String, dynamic>? get availabilityData => _availabilityData;
  bool get isLoading => _isLoading;

  // 加載站點列表
  Future<void> loadStations() async {
    try {
      _stations = await mysqlSelect("SELECT * FROM Bike.Bike_taichung_Station;");
      notifyListeners();
    } catch (e) {
      // 處理錯誤
      print('加載站點失敗: $e');
    }
  }

  // 選中站點
  void selectStation(Map<String, dynamic> station) {
    _selectedStation = station;
    _loadAvailability(station['StationID']);
    notifyListeners();
  }

  void clearSelectedStation() {
    _selectedStation = null;
    _availabilityData = null;
    notifyListeners();
  }

  // 加載站點可用性
  Future<void> _loadAvailability(String stationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _availabilityData = await getBikeAvailability('Taichung', stationId);
    } catch (e) {
      _availabilityData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
class BikeMarkerManager {
  static BitmapDescriptor? _customIcon;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _customIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(8, 8)),
      'assets/img/ubike_icon.png',
    );
    _isInitialized = true;
  }

  static Set<Marker> buildMarkers(List<Map<String, dynamic>> stations, Function(Map<String, dynamic>) onTap) {
    final markers = <Marker>{};
    for (var station in stations) {
      final lat = json.decode(station["StationPosition"])["PositionLat"];
      final lon = json.decode(station["StationPosition"])["PositionLon"];
      final stationId = station["StationUID"];
      final stationName = json.decode(station["StationName"])["Zh_tw"];

      markers.add(
        Marker(
          markerId: MarkerId(stationId),
          icon: _customIcon!,
          position: LatLng(lat, lon),
          infoWindow: InfoWindow(
            title: stationName,
            snippet: "Capacity: ${station["BikesCapacity"]}",
          ),
          onTap: () => onTap(station),
        ),
      );
    }
    return markers;
  }

  static List<youbike> buildClusterItems(List<Map<String, dynamic>> stations) {
    return stations.map((station) {
      final lat = json.decode(station["StationPosition"])["PositionLat"];
      final lon = json.decode(station["StationPosition"])["PositionLon"];
      return youbike(station["StationUID"], LatLng(lat, lon));
    }).toList();
  }
}
class BikeDefaultContent extends StatefulWidget {
  final Function(Map<String, dynamic>) onStationSelected; // 新增回調

  const BikeDefaultContent({
    super.key,
    required this.onStationSelected, // 必傳參數
  });
  @override
  State<BikeDefaultContent> createState() => _BikeState();
}

class _BikeState extends State<BikeDefaultContent> {
  TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedStation;
  final List<String> _searchHistory = [];
  static const int _maxHistoryCount = 5;

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _selectedStation = null;
    });
  }

  List<Map<String, dynamic>> fuzzySearchStations(String keyword) {
    if (keyword.isEmpty) return [];
    _addToSearchHistory(keyword);
    final keywordLower = keyword.toLowerCase();

    return youBikeStations.value.where((station) {
      try {
        final stationName = json.decode(station["StationName"])["Zh_tw"].toString().toLowerCase();
        return stationName.contains(keywordLower) ||
            stationName.startsWith(keywordLower) ||
            stationName.endsWith(keywordLower);
      } catch (e) {
        return false;
      }
    }).map((e) => e as Map<String, dynamic>).toList();
  }

  void _addToSearchHistory(String query) {
    if (query.isEmpty) return;
    setState(() {
      _searchHistory.removeWhere((item) => item == query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _maxHistoryCount) {
        _searchHistory.removeLast();
      }
    });
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
  }

  Widget _buildDefaultContent(IconData icon, String text) {
    return SingleChildScrollView( // 添加滾動以防止溢出
      child: Column(
        mainAxisSize: MainAxisSize.min, // 重要：讓 Column 只佔用需要的空間
        children: [
          // 美化後的圖標和文字
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24, bottom: 16), // 減少 padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, // 縮小尺寸
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 28, // 縮小圖標
                    color: const Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14, // 縮小字體
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 美化後的歷史記錄標題
          if (_searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 減少 padding
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 14, // 縮小圖標
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '最近搜尋',
                    style: TextStyle(
                      fontSize: 13, // 縮小字體
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          // 美化後的歷史記錄列表
          if (_searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 減少 padding
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _searchHistory.map((query) => _buildHistoryChip(query)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String query) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = query;
          setState(() {});
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 減少 padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFEEF3FB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                query,
                style: const TextStyle(
                  fontSize: 12, // 縮小字體
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeFromHistory(query),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 10, // 縮小圖標
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // 確保有固定高度
      color: const Color(0xFFF8FAFD),
      child: Column(
        children: [
          // 搜尋框區域 - 使用固定高度
          SizedBox(
            height: 80, // 固定高度
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(12), // 減少 margin
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12), // 縮小圓角
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (searchText) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '搜尋站點...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14, // 縮小字體
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 6), // 減少 padding
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.grey[700],
                          size: 20, // 縮小圖標
                        ),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _clearSearch,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.clear_rounded,
                              size: 16, // 縮小圖標
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, // 減少 padding
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 內容區域 - 使用 Expanded 確保正確佈局
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildDefaultContent(Icons.location_off_outlined, '請選擇站點')
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchResults() {
    final List<Map<String, dynamic>> results = fuzzySearchStations(_searchController.text);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 28,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '找不到符合「${_searchController.text}」的站點',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final station = results[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              widget.onStationSelected(station);
            },
            splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
            highlightColor: const Color(0xFFEEF3FB),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 圖標區域
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF34C759),
                          const Color(0xFF34C759).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.electric_bike_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 文字資訊區域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          json.decode(station["StationName"])["Zh_tw"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          json.decode(station["StationAddress"])["Zh_tw"],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
