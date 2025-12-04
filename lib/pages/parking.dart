
import 'dart:convert';
import 'dart:ui';

import 'package:com.rsmn574.app/database/getData.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
// 車位資訊卡片
  Widget _buildAvailabilityCard(Map<String, dynamic> park) {
    final total = park["TotalSpaces"];
    final available = park["AvailableSpaces"];

    if (total == null || available == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFFF9500), size: 20),
            SizedBox(width: 12),
            Text(
              "無即時車位資訊",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    double ratio = (available / total).clamp(0.0, 1.0);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.car_rental_rounded,
                color: isLowAvailability ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "剩餘車位",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLowAvailability ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                ),
              ),
              const Spacer(),
              Text(
                "$available / $total",
                style: TextStyle(
                  fontSize: 16,
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
          const SizedBox(height: 8),
          Text(
            isLowAvailability ? "車位緊張，建議尋找其他停車場" : "車位充足",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// 資訊卡片
  Widget _buildInfoCard(Map<String, dynamic> park) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 費用資訊
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    size: 18,
                    color: Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "停車費率",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        park["FareDescription"] ?? "無費率資訊",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 分隔線
          Container(
            height: 1,
            color: Colors.grey[200],
          ),

          // 描述資訊
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
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
                        "停車場描述",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        park["Description"] ?? "無描述資訊",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 操作按鈕
  Widget _buildActionButtons(Map<String, dynamic> park) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone_rounded,
            label: "聯絡",
            color: const Color(0xFF34C759),
            onTap: () => _makeCall(park["Telephone"]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.directions_rounded,
            label: "導航",
            color: const Color(0xFF1A73E8),
            onTap: () => _navigateToPark(park),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.share_rounded,
            label: "分享",
            color: const Color(0xFFAF52DE),
            onTap: () => _shareParkInfo(park),
          ),
        ),
      ],
    );
  }

// 操作按鈕組件
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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

// ==== 資料模型 ====
class StationDetailPage extends StatelessWidget {
  final Map<String, dynamic> station;

  const StationDetailPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(json.decode(station["CarParkName"])["Zh_tw"] ?? "停車場詳情"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _item("停車場 ID", station["CarParkID"]),
            _item("名稱", json.decode(station["CarParkName"])["Zh_tw"]),
            _item("地址", station["Address"]),
            _item("電話", station["Telephone"]),
            _item("營運描述", station["Description"]),
            _item("收費方式", station["FareDescription"]),
            _item("經緯度",
                "${json.decode(station["CarParkPosition"])["PositionLat"]}}, "
                    "${json.decode(station["CarParkPosition"])["PositionLon"]}"
            ),
            const SizedBox(height: 20),

            // 🚗 停車格項目（例如停車類型 List）
            _item("停車種類 (ParkingTypes)", station["ParkingTypes"].toString()),
            _item("收費種類 (ChargeTypes)", station["ChargeTypes"].toString()),

            const SizedBox(height: 20),

            // 其他 boolean 項目 (例如是否有監視器)
            _item("是否全年無休", station["IsFreeParkingOutOfHours"] == 1 ? "是" : "否"),
            _item("是否有警衛", station["SecurityGuard"] == 1 ? "是" : "否"),
            _item("是否可過夜", station["OvernightPermitted"] == 1 ? "是" : "否"),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value?.toString() ?? "無資料"),
        ],
      ),
    );
  }
}