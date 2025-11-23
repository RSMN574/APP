
import 'dart:convert';
import 'dart:ui';

import 'package:com.rsmn574.app/database/getData.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Const/regularClass.dart';
import '../database/EV_station/EV_station.dart';
import '../utils/convert.dart';
import '../widget/map.dart';

class Parking extends StatefulWidget {
  const Parking({super.key});

  @override
  State<Parking> createState() => _ParkingState();
}

class _ParkingState extends State<Parking> {
  final List<String> regions = [
    '臺中市',
  ];
  String selectedCity="臺中市";
  GoogleMapController? _mapController;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredStations = [];
  List<dynamic>? allParking=[]; // 所有公車資料
  bool _isLoading = true;
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _fetchData();
  }
// 在 class 內宣告
  final FocusNode _searchFocusNode = FocusNode();
  Future<void> _fetchData() async {
    print('Fetching data...');
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    try {
      List<Map<dynamic, dynamic>> data = await mysqlSelect(
          "SELECT * FROM CarPark.OffStreetCarPark_Taichung;"
      ) ?? [];

      print('Raw data: $data');

      List<Map<dynamic, dynamic>> findNearestStations(
          List<dynamic> stations,
          double userLat,
          double userLon, {
            int count = 5,
          }) {
        List<Map<dynamic, dynamic>> sortedStations = List.from(stations)
          ..sort((a, b) {
            print(json.decode(a["CarParkPosition"])["PositionLat"]);
            double distanceA = calculateApproxDistance(
              userLat,
              userLon,
             (json.decode(a["CarParkPosition"])["PositionLat"]),
              (json.decode(a["CarParkPosition"])["PositionLon"]),
            );
            double distanceB = calculateApproxDistance(
              userLat,
              userLon,
             (json.decode(b["CarParkPosition"])["PositionLat"]),
             (json.decode(b["CarParkPosition"])["PositionLon"]),
            );
            return distanceA.compareTo(distanceB);
          });

        return sortedStations.toList();
      }

      List<dynamic> nearestStations = findNearestStations(
        data,
        locationProvider.latitude,
        locationProvider.longitude,
        count: 5,
      );

      print('Nearest stations: $nearestStations');

      setState(() {
        allParking = nearestStations;
        _filteredStations = List.from(nearestStations);
        _isLoading = false;
      });

      try {
        await _loadMarkers();
      } catch (e) {
        print('LoadMarkers error: $e');
      }
    } catch (e) {
      print('Fetch data error: $e');
      setState(() {
        allParking = [];
        _filteredStations = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMarkers() async {
    Set<Marker> markerCache = {};

    for (var i in _filteredStations) {
      final marker = Marker(
        markerId: MarkerId(i["CarParkID"]),
        position: LatLng(
          json.decode(i["CarParkPosition"])["PositionLat"],
          json.decode(i["CarParkPosition"])["PositionLon"],
        ),
        infoWindow: InfoWindow(
          title: json.decode(i["CarParkName"])["Zh_tw"],
          snippet: i["CarParkID"],
        ),
        onTap: () {
          setState(() {
            _searchController.text =  json.decode(i["CarParkName"])["Zh_tw"];
            _filterStations(_searchController.text);
          });
        },
      );
      markerCache.add(marker);
    }

    // ⭐ 關鍵：延後更新 provider 避免 build 過程呼叫
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MarkerProvider>(context, listen: false)
          .setMarkers(markerCache);
    });
  }

  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }
  @override
  void dispose() {
     Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
  }


  void _filterStations(String query) {
    query = query.trim().toLowerCase();

    final filtered = allParking?.where((station) {
      final name =  json.decode(station['CarParkName'])["Zh_tw"]?.toString().toLowerCase() ?? '';
      final address = station['Address']?.toString().toLowerCase() ?? '';
      return name.contains(query) || address.contains(query);
    }).toList();

    setState(() => _filteredStations = filtered!);

    // ❗不直接呼叫 _loadMarkers()，改成等 build 完成後再更新 markers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarkers();
    });

    // 若只剩一筆 → 聚焦地圖
    if (filtered?.length == 1) {
      final station = filtered!.first;
      final lat = json.decode(station["CarParkPosition"])["PositionLat"];
      final lon =  json.decode(station["CarParkPosition"])["PositionLon"];

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lon),
            zoom: 17,
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    return WillPopScope(
        onWillPop: () async {
          Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
          return true; // 允許頁面返回
        },
        child:Scaffold(
          appBar: AppBar(
            title: const Text(
              '停車資訊',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade800,
                    Colors.green.shade500,
                    Colors.greenAccent.shade200,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.3),

            // ⭐ 這裡加上 Dropdown
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // 半透明白背景
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.white, // 下拉清單背景
                    value: selectedCity,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),

                    items: regions.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(
                          city,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedCity = value!;
                      });

                      // 👉 你要加載資料就在這裡觸發
                      // loadDataForCity(selectedCity);
                    },
                  ),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
            children: [
              // 地圖元件放在背景中
              map(  onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },),
              // DraggableScrollableSheet 實現可拖曳、調整高度的面板
              DraggableScrollableSheet(
                initialChildSize: 0.3, // 初始高度佔螢幕比例
                minChildSize: 0.3, // 最小高度
                maxChildSize: 0.8, // 最大高度
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 拖曳指示條，帶有模糊效果
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                width: 40,
                                height: 5,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                        // 搜尋輸入框
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '搜尋站點名稱或地址',
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black54),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {

                                    _filterStations('');
                                  });
                                },
                              )
                                  : null,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.black54,
                              ),
                            ),
                            onChanged: _filterStations,
                          ),
                        ),
                        // 站點列表，使用 DraggableScrollableSheet 提供的 scrollController
                        Expanded(
                          child: _buildStationList(
                            _filteredStations,
                            scrollController,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ));
  }



// 分離的列表建構方法
  Widget _buildStationList(List<dynamic> nearestStations ,scrollController) {
    if (nearestStations.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      controller: scrollController, // 確保使用提供的controller
      physics: const BouncingScrollPhysics(),
      itemCount: nearestStations.length,
      itemBuilder: (context, index) {
        final station = nearestStations[index];
        return _buildModernStationCard(station);
      },
    );
  }
// 空狀態顯示
  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty),
          const SizedBox(height: 24),
          Text(
            '找不到符合條件的停車場',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請嘗試不同的搜尋關鍵字',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
// ========================
// 主卡片
// ========================
  Widget _buildModernStationCard(Map<String, dynamic> park) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        // onTap: () => Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => StationDetailPage(station: park),
        //   ),
        // ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green[50]!.withOpacity(0.6),
                Colors.blueGrey[50]!.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.green[100]!.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildParkTitle(park),
                          const SizedBox(height: 4),
                          _buildParkSubtitle(park),
                        ],
                      ),
                    ),
                    _buildNavigationArrow(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernInfoGrid(park),
                const SizedBox(height: 12),
                _buildActionChips(park),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildParkTitle(Map<String, dynamic> park) {
    return Row(
      children: [
        Icon(Icons.local_parking, size: 20, color: Colors.green[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            json.decode(park["CarParkName"])["Zh_tw"] ?? "未命名停車場",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.green[900],
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildParkSubtitle(Map<String, dynamic> park) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            park["Address"] ?? "無地址資訊",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildModernInfoGrid(Map<String, dynamic> park) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildGridItem(Icons.monetization_on, "停車費率",
                park["FareDescription"] ?? "-"),
            VerticalDivider(width: 1, color: Colors.grey[200]),
            _buildGridItem(Icons.info_outline, "描述",
                park["Description"] ?? "-"),
          ],
        ),
      ),
    );
  }
  Widget _buildGridItem(IconData icon, String title, String value) {
    final maxLength = 12;
    final truncatedValue = (value ?? "-").length > maxLength
        ? '${value.substring(0, maxLength)}...'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(height: 8),
          Tooltip(
            message: value,
            child: Text(
              truncatedValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  Widget _buildActionChips(Map<String, dynamic> park) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (park["Telephone"] != null)
          _buildActionButton(
            icon: Icons.phone_in_talk_rounded,
            label: "聯絡",
            color: Colors.blue[100]!,
            onTap: () => print("Call: ${park["Telephone"]}"),
          ),
        _buildActionButton(
          icon: Icons.directions_rounded,
          label: "導航",
          color: Colors.green[100]!,
          onTap: () => print("導航到 ${park["Address"]}"),
        ),
        _buildActionButton(
          icon: Icons.share_rounded,
          label: "分享",
          color: Colors.purple[100]!,
          onTap: () => print("分享 ${park["CarParkID"]}"),
        ),
      ],
    );
  }
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, // 主體白底
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.5), // 使用傳入顏色做邊框
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

// 導航箭頭
  Widget _buildNavigationArrow() {
    return RotationTransition(
      turns: _searchFocusNode.hasFocus
          ? const AlwaysStoppedAnimation(0.25)
          : const AlwaysStoppedAnimation(0.0),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.green[400],
        size: 20,
      ),
    );
  }
}

// ==== 資料模型 ====
