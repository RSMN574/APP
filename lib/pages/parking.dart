import 'package:com.rsmn574.app/database/getData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Const/regularClass.dart';
import '../utils/convert.dart';

class Parking extends StatefulWidget {
  const Parking({super.key});

  @override
  State<Parking> createState() => _ParkingState();
}

class _ParkingState extends State<Parking> {
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
        allParking = nearestStations;
        _filteredStations = List.from(nearestStations); // 初始時顯示所有數據
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        allParking = [];
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

    final filtered = allParking?.where((station) {
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

        ],
      ),
    );
  }




}

