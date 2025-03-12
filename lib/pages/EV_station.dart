import 'dart:convert';

import 'package:com.rsmn574.app/database/getData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Const/regularClass.dart';
import '../utils/convert.dart';

class EVStation extends StatefulWidget {
  const EVStation({super.key});

  @override
  State<EVStation> createState() => _EVStationState();
}

class _EVStationState extends State<EVStation> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredStations = [];
  List<dynamic>? allEV=[]; // 所有公車資料
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
    final locationProvider =
    Provider.of<LocationProvider>(context, listen: false);
    try {
      List<Map<String, dynamic>> data =
          await mysqlSelect("SELECT * FROM EV_Charging.EV_station;")?? [];
      List<Map<String, dynamic>> findNearestStations(
          List<dynamic> stations,
          double userLat,
          double userLon, {
            int count = 5,
          }) {
        List<Map<String, dynamic>> sortedStations = List.from(stations)
          ..sort((a, b) {
            double distanceA = calculateEuclideanDistance(
              userLat,
              userLon,
              double.parse( a["PositionLat"]),
              double.parse( a["PositionLon"]),
            );
            double distanceB = calculateEuclideanDistance(
              userLat,
              userLon,
              double.parse ( b["PositionLat"]),
              double.parse(b["PositionLon"]),
            );
            return distanceA.compareTo(distanceB);
          });

        return sortedStations.toList();
      }

// 呼叫函式
      List<dynamic> nearestStations = findNearestStations(
        data,
        locationProvider.latitude,locationProvider.longitude,

        count: 5,
      );
      setState(() {
        allEV = nearestStations;
        _filteredStations = List.from(nearestStations); // 初始時顯示所有數據
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        allEV = [];
        _filteredStations = [];
        _isLoading = false;
      });
    }
  }


  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }


  void _filterStations(String query) {
    query = query.trim().toLowerCase();
    // if (query.isEmpty) {
    //   setState(() => _filteredStations = List.from(allEV));
    //   return;
    // }

    final filtered = allEV?.where((station) {
      final name = station['StationNameZh_tw']?.toString().toLowerCase() ?? '';
      final address = station['LocationCityRoadRoad']?.toString().toLowerCase() ?? '';
      return name.contains(query) || address.contains(query);
    }).toList();

    setState(() => _filteredStations = filtered!);
  }



  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('充電樁資訊'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋站點名稱或地址',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
              ),
              onChanged: _filterStations,
            ),
          ),
          Expanded(
            child: _buildStationList(_filteredStations),
          ),
        ],
      ),
    );
  }


// 新增的搜尋指示器
  Widget _buildSearchIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isSearching
          ? IconButton(
        icon: Icon(Icons.close, color: Colors.red[400]),
        onPressed: () {
          _searchController.clear();
          FocusScope.of(context).unfocus();
        },
      )
          : Icon(Icons.electric_bolt, color: Colors.amber[600]),
    );
  }

// 分離的列表建構方法
  Widget _buildStationList(List<dynamic> nearestStations) {
    if (nearestStations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '找不到符合的充電站',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: nearestStations.length,
      itemBuilder: (context, index) {
        final station = nearestStations[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            // onTap: () => _onStationSelected(station),
            splashColor: Colors.green.withOpacity(0.1),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[50]!,
                    Colors.blueGrey[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.charging_station_rounded,
                      color: Colors.green[800], size: 28),
                ),
                title: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.green[900],
                    letterSpacing: 0.8,
                  ),
                  child: Text(
                    station['StationNameZh_tw'] ?? '未命名充電站',
                  ),
                ),
                subtitle: _buildModernInfoSection(station),
                trailing: RotationTransition(
                  turns: _searchFocusNode.hasFocus
                      ? const AlwaysStoppedAnimation(0.25)
                      : const AlwaysStoppedAnimation(0.0),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.green[400], size: 20),
                ),
              ),
            ),
          ),
        );
      },
    );   // ... 保持之前的列表項建構邏輯
      }

// 現代化資訊區塊建構方法
  Widget _buildModernInfoSection(Map<String, dynamic> station) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildModernInfoItem(
          icon: Icons.pin_drop_rounded,
          text: '${station['LocationCityRoadCity']} ${station['LocationCityRoadTown']}',
          color: Colors.teal[700]!,
        ),
        _buildModernDivider(),
        if (station['ChargingRate'] != null)
          _buildModernInfoItem(
            icon: Icons.bolt_rounded,
            text: '充電: ${station['ChargingRate']}',
            color: Colors.amber[700]!,
          ),
        if (station['ParkingRate'] != null)
          _buildModernInfoItem(
            icon: Icons.local_parking_rounded,
            text: '停車: ${station['ParkingRate']}',
            color: Colors.blue[700]!,
          ),
        if (station['PositionLat'] != null)
          _buildModernInfoItem(
            icon: Icons.explore_rounded,
            text: '座標: ${station['PositionLat']}, ${station['PositionLon']}',
            color: Colors.brown[600]!,
          ),
        const SizedBox(height: 12),
        if (station['Telephone'] != null)
          _buildActionChip(
            icon: Icons.phone_rounded,
            label: station['Telephone'],
            // onTap: () => _callStation(station),
          ),
      ],
    );
  }

  Widget _buildModernInfoItem({required IconData icon, required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        color: Colors.green[100]!.withOpacity(0.5),
        thickness: 1,
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: Colors.green[800]),
        label: Text(label),
        backgroundColor: Colors.green[50],
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onPressed: onTap,
      ),
    );
  }
}
