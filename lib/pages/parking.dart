
import 'dart:convert';
import 'dart:ui';

import 'package:com.rsmn574.app/database/getData.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Const/regularClass.dart';
import '../database/EV_station/EV_station.dart';
import '../database/park/getPark.dart';
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
  List<Map<String, dynamic>>  _filteredStations = [];
  List<Map<String, dynamic>>  allParking=[]; // 所有公車資料
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
      /// 1. 取得 MySQL 的靜態停車資料 + 強制轉型成 Map<String, dynamic>
      List<Map<String, dynamic>> data =
      (await mysqlSelect("SELECT * FROM CarPark.OffStreetCarPark_Taichung;") ?? [])
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();

      print("MySQL data: $data");

      /// 2. 取得 TDX 車位即時資料
      List liveRaw = await fetchParkLiveStatus("Taichung");

      /// 強制轉型為 List<Map<String, dynamic>>
      List<Map<String, dynamic>> liveData =
      liveRaw.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

      print("LiveData: $liveData");

      /// 3. 建立 CarParkID → LiveData 的 Map，快速查找
      Map<String, Map<String, dynamic>> liveMap = {
        for (var item in liveData) item["CarParkID"]: item
      };

      /// 4. 合併 MySQL 靜態資料 + TDX 即時資料
      List<Map<String, dynamic>> merged = data.map((park) {
        String id = park["CarParkID"];
        Map<String, dynamic>? live = liveMap[id];

        return {
          ...park,
          "TotalSpaces": live?["TotalSpaces"],
          "AvailableSpaces": live?["AvailableSpaces"],
          "Availabilities": live?["Availabilities"],
          "ServiceStatus": live?["ServiceStatus"],
          "FullStatus": live?["FullStatus"],
          "ChargeStatus": live?["ChargeStatus"],
          "DataCollectTime": live?["DataCollectTime"],
        };
      }).toList();

      /// 5. 依距離排序
      merged.sort((a, b) {
        var pa = jsonDecode(a["CarParkPosition"]);
        var pb = jsonDecode(b["CarParkPosition"]);

        double da = calculateApproxDistance(
          locationProvider.latitude,
          locationProvider.longitude,
          pa["PositionLat"],
          pa["PositionLon"],
        );

        double db = calculateApproxDistance(
          locationProvider.latitude,
          locationProvider.longitude,
          pb["PositionLat"],
          pb["PositionLon"],
        );

        return da.compareTo(db);
      });

      /// 6. 更新 UI
      setState(() {
        allParking = merged;
        _filteredStations = List.from(merged);
        _isLoading = false;
      });

      /// 7. 重新載入地圖標記
      await _loadMarkers();
    } catch (e) {
      print("Fetch data error: $e");

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
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              '停車資訊',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A73E8).withOpacity(0.2),
                  ),
                ),
                child: DropdownButton<String>(
                  value: selectedCity,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A73E8)),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: regions.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_city_rounded,
                            size: 16,
                            color: const Color(0xFF1A73E8).withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(city),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCity = value;
                      });
                      // 加載對應城市的資料

                    }
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF1A73E8).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: _isLoading
              ?  Center( child:
           LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),
          )
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
                                onChanged: _filterStations,
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
                                        onTap:(){
                                      _searchController.clear();
                                      setState(() {

                                      _filterStations('');
                                      });
                                      },
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
  Widget _buildStationList( List<Map<String, dynamic>>  nearestStations ,scrollController) {
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

// ========================
// 主卡片
// ========================
// 分離的列表建構方法
//   Widget _buildStationList(List<Map<String, dynamic>> nearestStations, ScrollController scrollController) {
//     if (nearestStations.isEmpty) {
//       return _buildEmptySearchState();
//     }
//
//     return ListView.builder(
//       controller: scrollController,
//       physics: const BouncingScrollPhysics(),
//       itemCount: nearestStations.length,
//       itemBuilder: (context, index) {
//         final station = nearestStations[index];
//         return _buildModernStationCard(station);
//       },
//     );
//   }
//
// // 空狀態顯示
//   Widget _buildEmptySearchState() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.all(40),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     const Color(0xFF1A73E8).withOpacity(0.1),
//                     const Color(0xFF1A73E8).withOpacity(0.05),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.local_parking_rounded,
//                 size: 50,
//                 color: Color(0xFF1A73E8),
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               '找不到停車場',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF1A73E8),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '請嘗試不同的搜尋條件',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// 主卡片
// 主卡片 - 縮小版本
// 進階版本 - 稍微多一點資訊
  Widget _buildModernStationCard(Map<String, dynamic> park) {
    final capacityLevel = _getCapacityLevel(park);
    final capacityColor = _getCapacityColor(park);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StationDetailPage(station: park),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
          highlightColor: const Color(0xFFEEF3FB).withOpacity(0.3),
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：名稱和容量
                Row(
                  children: [
                    // 停車場圖標
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        size: 18,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 名稱和容量標籤
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            json.decode(park["CarParkName"])["Zh_tw"] ?? "未命名停車場",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: capacityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      capacityLevel,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getCapacityText(park),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: capacityColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 地址
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        park["Address"] ?? "無地址資訊",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 車位資訊和費用
                Row(
                  children: [
                    // 車位資訊
                    Expanded(
                      child: _buildAdvancedAvailabilityInfo(park),
                    ),

                    const SizedBox(width: 12),

                    // 費用資訊
                    Expanded(
                      child: _buildFareInfo(park),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 操作按鈕
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallActionButton(
                        icon: Icons.phone_rounded,
                        label: "聯絡",
                        color: const Color(0xFF34C759),
                        onTap: () => _makeCall(park["Telephone"]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallActionButton(
                        icon: Icons.directions_rounded,
                        label: "導航",
                        color: const Color(0xFF1A73E8),
                        onTap: () => _navigateToPark(park),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallActionButton(
                        icon: Icons.share_rounded,
                        label: "分享",
                        color: const Color(0xFFAF52DE),
                        onTap: () => _shareParkInfo(park),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// 新增：獲取容量文字描述
  String _getCapacityText(Map<String, dynamic> park) {
    final total = park["TotalSpaces"];
    final available = park["AvailableSpaces"];

    if (total == null || available == null) return "無資料";

    double ratio = (available / total).clamp(0.0, 1.0);

    if (ratio >= 0.5) return "充足";
    if (ratio >= 0.2) return "普通";
    return "緊張";
  }

// 進階車位資訊
  Widget _buildAdvancedAvailabilityInfo(Map<String, dynamic> park) {
    final total = park["TotalSpaces"];
    final available = park["AvailableSpaces"];
    final color = _getCapacityColor(park);

    if (total == null || available == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "無車位資訊",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.car_rental_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              "$available / $total",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (available / total).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

// 費用資訊
  Widget _buildFareInfo(Map<String, dynamic> park) {
    final fare = park["FareDescription"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.monetization_on_rounded,
              size: 14,
              color: const Color(0xFFFF9500),
            ),
            const SizedBox(width: 4),
            Text(
              "費用",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          fare != null && fare.isNotEmpty ? fare : "無資訊",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

// 小型操作按鈕
  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// 新增：獲取容量等級圖示
  String _getCapacityLevel(Map<String, dynamic> park) {
    final total = park["TotalSpaces"];
    final available = park["AvailableSpaces"];

    if (total == null || available == null) return "⚪"; // 無資料

    double ratio = (available / total).clamp(0.0, 1.0);

    if (ratio >= 0.5) return "🟢"; // 充足
    if (ratio >= 0.2) return "🟡"; // 普通
    return "🔴"; // 緊張
  }

// 新增：獲取容量顏色
  Color _getCapacityColor(Map<String, dynamic> park) {
    final total = park["TotalSpaces"];
    final available = park["AvailableSpaces"];

    if (total == null || available == null) return const Color(0xFF8E8E93); // 灰色

    double ratio = (available / total).clamp(0.0, 1.0);

    if (ratio >= 0.5) return const Color(0xFF34C759); // 綠色
    if (ratio >= 0.2) return const Color(0xFFFF9500); // 橙色
    return const Color(0xFFFF3B30); // 紅色
  }


// 空狀態顯示 - 縮小版本
  Widget _buildEmptySearchState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_parking_rounded,
                size: 36,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '找不到停車場',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '請嘗試不同的搜尋條件',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


// 輔助方法
  void _makeCall(String? phoneNumber) {
    if (phoneNumber != null) {
      // 撥打電話邏輯
      print("Call: $phoneNumber");
    }
  }

  void _navigateToPark(Map<String, dynamic> park) {
    // 導航邏輯
    print("導航到: ${park["Address"]}");
  }

  void _shareParkInfo(Map<String, dynamic> park) {
    // 分享邏輯
    print("分享: ${park["CarParkID"]}");
  }
}

class StationDetailPage extends StatelessWidget {
  final Map<String, dynamic> station;

  const StationDetailPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final stationName = json.decode(station["CarParkName"])["Zh_tw"] ?? "停車場詳情";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          stationName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.share_rounded,
                size: 18,
                color: Color(0xFF1A73E8),
              ),
            ),
            onPressed: () => _shareStationInfo(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 概覽卡片
            _buildOverviewCard(),

            // 詳細資訊區塊
            _buildInfoSection('基本資訊', [
              _buildInfoItem(Icons.qr_code_rounded, '停車場 ID', station["CarParkID"]),
              _buildInfoItem(Icons.location_on_rounded, '地址', station["Address"]),
              _buildInfoItem(Icons.phone_rounded, '聯絡電話', station["Telephone"]),
            ]),

            // 將現有的 _buildInfoItem 調用更新為：

// 費用資訊區塊（更新收費方式）
            _buildInfoSection('費用資訊', [
              _buildInfoItem(Icons.monetization_on_rounded, '收費方式', station["FareDescription"]),
              _buildInfoItem(Icons.credit_card_rounded, '收費種類',
                  ParkingTypeHelper.getChargeTypes(station["ChargeTypes"]).join(', ')),
            ]),

// 設施服務區塊（更新停車種類）
            _buildInfoSection('設施服務', [
              _buildInfoItem(Icons.local_parking_rounded, '停車種類',
                  ParkingTypeHelper.getCarParkType(station["CarParkType"])),
              _buildInfoItem(Icons.description_rounded, '營運描述', station["Description"]),
            ]),

            // 其他資訊區塊
            _buildInfoSection('其他資訊', [
              _buildBooleanItem(Icons.access_time_rounded, '全年無休', station["IsFreeParkingOutOfHours"] == "1"),
              _buildBooleanItem(Icons.ev_station, '充電樁', station["EVRechargingAvailable"] == "1"),
              _buildBooleanItem(Icons.nightlight_rounded, '可過夜', station["OvernightPermitted"] == "1"),
              _buildBooleanItem(Icons.sensors_rounded, '車輛偵測', station["VehicleDetection"] == "1"),
              _buildBooleanItem(Icons.wheelchair_pickup, '無障礙車位', station["WheelchairAccessible"] == "1"),
            ]),

            // 位置資訊區塊
            _buildInfoSection('位置資訊', [
              _buildLocationItem(),
            ]),

            // 操作按鈕
            _buildActionButtons(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 概覽卡片
  Widget _buildOverviewCard() {
    final totalSpaces = station["TotalSpaces"];
    final availableSpaces = station["AvailableSpaces"];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  json.decode(station["CarParkName"])["Zh_tw"] ?? "停車場",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 車位狀態
          if (totalSpaces != null && availableSpaces != null)
            _buildAvailabilityInfo()
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Text(
                    '無即時車位資訊',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 車位資訊
  Widget _buildAvailabilityInfo() {
    final total = station["TotalSpaces"];
    final available = station["AvailableSpaces"];
    final ratio = (available / total).clamp(0.0, 1.0);
    final bool isLowAvailability = ratio <= 0.3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLowAvailability
            ? const Color(0xFFFF3B30).withOpacity(0.05)
            : const Color(0xFF34C759).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowAvailability
              ? const Color(0xFFFF3B30).withOpacity(0.2)
              : const Color(0xFF34C759).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '剩餘車位',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLowAvailability ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                ),
              ),
              Text(
                '$available / $total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isLowAvailability ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                isLowAvailability ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 資訊區塊標題
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // 資訊項目
  Widget _buildInfoItem(IconData icon, String title, dynamic value) {
    final displayValue = value?.toString() ?? "無資料";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 布林值項目
  Widget _buildBooleanItem(IconData icon, String title, bool value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF34C759).withOpacity(0.1) : const Color(0xFFFF3B30).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? const Color(0xFF34C759).withOpacity(0.3) : const Color(0xFFFF3B30).withOpacity(0.3),
              ),
            ),
            child: Text(
              value ? "是" : "否",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 位置資訊項目
  Widget _buildLocationItem() {
    final position = json.decode(station["CarParkPosition"]);
    final lat = position["PositionLat"];
    final lon = position["PositionLon"];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.map_rounded,
              size: 18,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '地理位置',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '緯度: $lat, 經度: $lon',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                size: 18,
                color: Color(0xFF1A73E8),
              ),
            ),
            onPressed: () => _openInMaps(lat, lon),
          ),
        ],
      ),
    );
  }

  // 操作按鈕
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone_rounded,
              label: '撥打電話',
              color: const Color(0xFF34C759),
              onTap: () => _makeCall(station["Telephone"]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.directions_rounded,
              label: '開始導航',
              color: const Color(0xFF1A73E8),
              onTap: () => _navigateToStation(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 輔助方法
  String _formatListToString(dynamic list) {
    if (list == null) return "無資料";
    if (list is String) return list;
    if (list is List) return list.join(", ");
    return list.toString();
  }

  void _shareStationInfo() {
    final stationName = json.decode(station["CarParkName"])["Zh_tw"] ?? "停車場";
    // 分享邏輯
    print("分享: $stationName");
  }

  void _makeCall(String? phoneNumber) {
    if (phoneNumber != null) {
      // 撥打電話邏輯
      print("撥打: $phoneNumber");
    }
  }

  void _navigateToStation() {
    // 導航邏輯
    print("開始導航");
  }

  void _openInMaps(dynamic lat, dynamic lon) {
    // 打開地圖邏輯
    print("打開地圖: $lat, $lon");
  }
}// 新增輔助方法來映射不同類型

class ParkingTypeHelper {
  // ---------------------------
  // 停車場類型
  // ---------------------------
  static String getCarParkType(dynamic type) {
    const Map<int, String> typeMap = {
      1: '平面',
      2: '立體',
      3: '地下',
      4: '立體停車塔',
      5: '立體機械式',
      6: '同時涵蓋2種以上',
      254: '其他',
      255: '未知',
    };
    int t = _parseSingle(type);
    return typeMap[t] ?? '未知';
  }

  // ---------------------------
  // 收費類型
  // ---------------------------
  static List<String> getChargeTypes(dynamic types) {
    const Map<int, String> chargeMap = {
      1: '計時',
      2: '計次',
      3: '月租',
      4: '免費',
      254: '其他',
      255: '未知',
    };
    return _parseList(types, chargeMap);
  }

  // ---------------------------
  // 停車導引類型
  // ---------------------------
  static String getParkingGuideType(dynamic type) {
    const Map<int, String> guideMap = {
      1: '自行找尋停車位',
      2: '有導引輔助設施協助尋找停車位',
      3: '人工導引停找車位',
      4: '代客泊車',
      5: '混合型',
      254: '其他',
      255: '未知',
    };
    int t = _parseSingle(type);
    return guideMap[t] ?? '未知';
  }

  // ---------------------------
  // 停車類型資訊
  // ---------------------------
  static List<String> getParkingTypes(dynamic types) {
    const Map<int, String> parkingMap = {
      1: '停車轉乘公共運輸',
      2: '臨時停車接送',
      3: '停車後轉使用公共自行車',
      4: '停車後步行',
      5: '活動專用停車場',
      6: '休息站專用停車場',
      7: '服務區專用停車場',
      8: '貨車及大型車停車場',
      9: '共享汽車租用服務停車場',
      10: '共乘服務停車場',
      254: '其他',
      255: '未知',
    };
    return _parseList(types, parkingMap);
  }

  // ---------------------------
  // 停車場服務類型
  // ---------------------------
  static List<String> getParkingSiteTypes(dynamic types) {
    const Map<int, String> siteMap = {
      1: '軌道場站',
      2: '機場場站',
      3: '船舶場站',
      4: '商圈',
      5: '餐廳',
      6: '運動場',
      7: '飯店',
      8: '觀光地標',
      9: '電影院',
      10: '觀光景點',
      11: '學校',
      12: '美術博物館',
      13: '展覽中心',
      14: '會議中心',
      15: '宗教機構',
      16: '賣場',
      17: '動物園',
      18: '高速公路',
      19: '政府部門',
      20: '住宅區',
      21: '夜市',
      22: '市場',
      23: '公園',
      254: '其他',
      255: '未知',
    };
    return _parseList(types, siteMap);
  }

  // ---------------------------
  // 圖標對應
  // ---------------------------
  static IconData getTypeIcon(int? type) {
    switch (type) {
      case 1:
        return Icons.terrain_rounded; // 平面
      case 2:
        return Icons.account_balance_rounded; // 立體
      case 3:
        return Icons.subway_rounded; // 地下
      case 4:
        return Icons.vertical_align_top_rounded; // 停車塔
      case 5:
        return Icons.settings_rounded; // 機械式
      default:
        return Icons.local_parking_rounded;
    }
  }

  // ---------------------------
  // 顏色對應
  // ---------------------------
  static Color getTypeColor(int? type) {
    switch (type) {
      case 1:
        return const Color(0xFF34C759); // 綠色
      case 2:
        return const Color(0xFF1A73E8); // 藍色
      case 3:
        return const Color(0xFFFF9500); // 橙色
      case 4:
        return const Color(0xFFAF52DE); // 紫色
      case 5:
        return const Color(0xFFFF3B30); // 紅色
      default:
        return const Color(0xFF8E8E93); // 灰色
    }
  }

  // ---------------------------
  // 私有方法：解析單一值
  // ---------------------------
  static int _parseSingle(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // 私有方法：解析 List 或 JSON 字串
  static List<String> _parseList(dynamic value, Map<int, String> map) {
    if (value == null) return ['無資料'];

    List<int> list = [];

    if (value is List) {
      list = value.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    } else if (value is String) {
      try {
        final parsed = json.decode(value);
        if (parsed is List) {
          list = parsed.map((e) => int.tryParse(e.toString()) ?? 0).toList();
        } else {
          list = [int.tryParse(parsed.toString()) ?? 0];
        }
      } catch (_) {
        list = [int.tryParse(value) ?? 0];
      }
    } else if (value is int) {
      list = [value];
    } else {
      list = [0];
    }

    return list.map((e) => map[e] ?? '未知').toList();
  }
}