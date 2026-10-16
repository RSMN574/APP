import 'package:com.rsmn574.app/features/ev_charging/state/ev_station_provider.dart';
import 'dart:convert';
import 'dart:ui';

import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/features/ev_charging/data/ev_station_repository.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/utils/share.dart';
import 'package:com.rsmn574.app/widget/map.dart';

import '../../../widget/AppLoading.dart';

class EVStation extends StatefulWidget {
  const EVStation({super.key});

  @override
  State<EVStation> createState() => _EVStationState();
}

class _EVStationState extends State<EVStation> {
  late final List<String> regions = [AppLocalizations.of(context)!.text_6];
  late String selectedCity = AppLocalizations.of(context)!.text_6;
  GoogleMapController? _mapController;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredStations = [];
  List<dynamic>? allEV = [];
  bool _isLoading = true;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    if (mounted) {
      Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
    }
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
  }

  Future<void> _fetchData() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    try {
      List<Map<String, dynamic>> data =
          await mysqlSelect("SELECT * FROM EV_Charging.EV_station;") ?? [];

      List<Map<String, dynamic>> findNearestStations(
        List<dynamic> stations,
        double userLat,
        double userLon, {
        int count = 5,
      }) {
        List<Map<String, dynamic>> sortedStations = List.from(stations)
          ..sort((a, b) {
            double distanceA = calculateApproxDistance(
              userLat,
              userLon,
              double.parse(a["PositionLat"]),
              double.parse(a["PositionLon"]),
            );
            double distanceB = calculateApproxDistance(
              userLat,
              userLon,
              double.parse(b["PositionLat"]),
              double.parse(b["PositionLon"]),
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

      setState(() {
        allEV = nearestStations;
        _filteredStations = List.from(nearestStations);
        _isLoading = false;
      });
      _loadMarkers();
    } catch (e) {
      setState(() {
        allEV = [];
        _filteredStations = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMarkers() async {
    Set<Marker> markerCache = {};

    for (var i in _filteredStations) {
      final marker = Marker(
        markerId: MarkerId(i["StationID"]),
        position: LatLng(
          double.parse(i["PositionLat"]),
          double.parse(i["PositionLon"]),
        ),
        infoWindow: InfoWindow(
          title: i["StationNameZh_tw"],
          snippet: i["StationID"],
        ),
        onTap: () {
          setState(() {
            _searchController.text = i["StationNameZh_tw"];
            _filterStations(_searchController.text);
          });
        },
      );
      markerCache.add(marker);
    }
    Provider.of<MarkerProvider>(context, listen: false).setMarkers(markerCache);
  }

  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {});
  }

  void _filterStations(String query) {
    query = query.trim().toLowerCase();

    final filtered = allEV?.where((station) {
      final name = station['StationNameZh_tw']?.toString().toLowerCase() ?? '';
      final address =
          station['LocationCityRoadRoad']?.toString().toLowerCase() ?? '';
      return name.contains(query) || address.contains(query);
    }).toList();

    setState(() => _filteredStations = filtered!);
    _loadMarkers();

    if (filtered?.length == 1) {
      final station = filtered?.first;
      final lat = double.parse(station["PositionLat"]);
      final lon = double.parse(station["PositionLon"]);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lon),
            zoom: 17.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            AppLocalizations.of(context)!.text_369,
            style: const TextStyle(
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
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF3FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1A73E8).withOpacity(0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCity,
                  icon: const Icon(Icons.arrow_drop_down_rounded,
                      color: Color(0xFF1A73E8)),
                  style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: Colors.white,
                  items: regions.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_city_rounded,
                            size: 16,
                            color: const Color(0xFF1A73E8).withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(city,
                              style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ?  const AppLoading()
            : Stack(
                children: [
                  map(onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  }),
                  DraggableScrollableSheet(
                    initialChildSize: 0.3,
                    minChildSize: 0.3,
                    maxChildSize: 0.8,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16,
                              color: Color(0x0A000000),
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 拖曳指示器
                            Center(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 12),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // 搜尋輸入框
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFD),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEEF3FB),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  decoration: InputDecoration(
                                    hintText:
                                        AppLocalizations.of(context)!.text_139,
                                    hintStyle:
                                        TextStyle(color: Colors.grey[500]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF1A73E8),
                                        size: 20,
                                      ),
                                    ),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                    Icons.clear_rounded,
                                                    color: Colors.grey),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  _filterStations('');
                                                },
                                              )
                                            : null,
                                  ),
                                  onChanged: _filterStations,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 站點列表
                            Expanded(
                              child: _buildStationList(
                                  _filteredStations, scrollController),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStationList(List<dynamic> nearestStations, scrollController) {
    if (nearestStations.isEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: nearestStations.length,
      itemBuilder: (context, index) {
        final station = nearestStations[index];
        return _buildModernStationCard(station);
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A73E8).withOpacity(0.1),
                    const Color(0xFF1A73E8).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ev_station_rounded,
                size: 50,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.text_371,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.text_372,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStationCard(Map<String, dynamic> station) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 16, left: 4, right: 4), // 增加左右微距防止陰影切到
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StationDetailPage(station: station),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16), // 縮減 padding 爭取空間
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題列
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // 對齊中心
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF28A745)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.ev_station_rounded,
                          size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station['StationNameZh_tw'] ??
                                AppLocalizations.of(context)!.text_373,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${station['LocationCityRoadCity'] ?? ''}${station['LocationCityRoadTown'] ?? ''}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                // 資訊網格：改用 Expanded 防止費率內容撐爆橫向空間
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.bolt_rounded,
                          title: AppLocalizations.of(context)!.text_374,
                          value: station['ChargingRate'] ??
                              AppLocalizations.of(context)!.text_375,
                          color: const Color(0xFF1A73E8),
                        ),
                      ),
                      Container(height: 24, width: 1, color: Colors.grey[300]),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.local_parking_rounded,
                          title: AppLocalizations.of(context)!.text_376,
                          value: station['ParkingRate'] ??
                              AppLocalizations.of(context)!.text_377,
                          color: const Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 按鈕列：使用 Wrap 確保在小螢幕下會自動換行，不會出現 Yellow Tape (溢出錯誤)
                Wrap(
                  spacing: 8, // 水平間距
                  runSpacing: 8, // 垂直間距 (如果換行的話)
                  alignment: WrapAlignment.start,
                  children: [
                    if (station['Telephone'] != null &&
                        station['Telephone'] != "")
                      _buildActionChip(
                        icon: Icons.phone_rounded,
                        label: AppLocalizations.of(context)!.text_378,
                        color: const Color(0xFF1A73E8),
                        onTap: () =>
                            StationActions.makeCall(station['Telephone']),
                      ),
                    _buildActionChip(
                      icon: Icons.directions_rounded,
                      label: AppLocalizations.of(context)!.text_379,
                      color: const Color(0xFF34C759),
                      onTap: () {
                        double lat = double.tryParse(
                                station['PositionLat'].toString()) ??
                            0.0;
                        double lng = double.tryParse(
                                station['PositionLon'].toString()) ??
                            0.0;
                        StationActions.openNavigation(
                            lat,
                            lng,
                            station['StationNameZh_tw'] ??
                                AppLocalizations.of(context)!.text_380);
                      },
                    ),
                    _buildActionChip(
                      icon: Icons.share_rounded,
                      label: AppLocalizations.of(context)!.text_381,
                      color: const Color(0xFFAF52DE),
                      onTap: () => StationActions.shareStation(station),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

// 輔助組件微調：確保文字不會擠壓到圖示
  Widget _buildInfoItem(
      {required IconData icon,
      required String title,
      required String value,
      required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(child: Text(title,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ), maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class StationDetailPage extends StatefulWidget {
  final Map<String, dynamic> station;

  const StationDetailPage({Key? key, required this.station}) : super(key: key);

  @override
  _StationDetailPageState createState() => _StationDetailPageState();
}

class _StationDetailPageState extends State<StationDetailPage> {
  List<MergedConnector> _mergedConnectors = [];

  @override
  void initState() {
    super.initState();
    _fetchChargingPoints().then((points) {
      _mergeConnectors(points);
    });
  }

  Future<void> _mergeConnectors(List<Map<String, dynamic>> points) async {
    var connectorMap = <String, MergedConnector>{};

    for (final point in points) {
      final rawConnectors = point['Connectors'];
      List<dynamic> connectors;

      if (rawConnectors is List) {
        connectors = rawConnectors;
      } else if (rawConnectors is String && rawConnectors.isNotEmpty) {
        try {
          connectors = List<dynamic>.from(jsonDecode(rawConnectors));
        } catch (e) {
          connectors = [];
        }
      } else {
        connectors = [];
      }

      for (final c in connectors) {
        final type = c['Type']?.toString() ?? "";
        final quantity = c['Quantity'] ?? 0;

        final key =
            [type, point['ChargingRate'] ?? "", point['Floor'] ?? ""].join('|');

        final connector = MergedConnector(
          type: type,
          power: type,
          rate: point['ChargingRate'] ?? "",
          floor: point['Floor'] ?? "",
          quantity: quantity,
          points: [point['ChargingPointID']],
        );

        if (connectorMap.containsKey(key)) {
          connectorMap[key] = connectorMap[key]!.mergeWith(connector);
        } else {
          connectorMap[key] = connector;
        }
      }
    }

    List<dynamic> connectorLiveStatus =
        (await context
                .read<EvStationProvider>()
                .connectorLiveStatus(widget.station["StationID"])) ??
            [];

    final mergedConnectors = connectorLiveStatus.map((status) {
      final connectorType = status["ConnectorType"]?.toString() ?? "";
      final matchedItem = connectorMap.entries
          .firstWhere(
            (entry) => entry.key.startsWith("$connectorType|"),
            orElse: () => MapEntry(
              "",
              MergedConnector(
                type: connectorType,
                power: connectorType,
                rate: "",
                floor: "",
                quantity: 0,
                points: [],
                ConnectorStatus: (status["ConnectorStatus"] ?? 0).toString(),
              ),
            ),
          )
          .value;

      return MergedConnector(
        type: matchedItem.type,
        power: matchedItem.power,
        rate: matchedItem.rate,
        floor: matchedItem.floor,
        quantity: matchedItem.quantity,
        points: matchedItem.points,
        ConnectorStatus: (status["ConnectorStatus"] ?? 0).toString(),
      );
    }).toList();

    setState(() {
      _mergedConnectors = mergedConnectors.isNotEmpty
          ? mergedConnectors
          : connectorMap.values.toList();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchChargingPoints() async {
    try {
      List<Map<String, dynamic>> chargingPoint = await mysqlSelect(
            "SELECT * FROM EV_Charging.ChargingPoint_Taichung WHERE StationID='${widget.station["StationID"]}';",
          ) ??
          [];
      return chargingPoint;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.station['StationNameZh_tw'] ??
              AppLocalizations.of(context)!.text_382,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
      ),
      body: _mergedConnectors.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildModernConnectorCard(_mergedConnectors[index]),
                      childCount: _mergedConnectors.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernConnectorCard(MergedConnector connector) {
    final status = _getConnectorStatus(
        int.tryParse(connector.ConnectorStatus ?? '0') ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getColor(connector.type),
                  _getColor(connector.type).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(connector.type),
              size: 24,
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Flexible(child: Text(
                _getTypeName(connector.type),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ), maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status['color'].withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status['icon'],
                      size: 14,
                      color: status['color'],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status['text'],
                      style: TextStyle(
                        fontSize: 12,
                        color: status['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.layers_rounded,
                        size: 14,
                        color: Color(0xFF1A73E8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connector.floor,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF34C759).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.electrical_services_rounded,
                        size: 14,
                        color: Color(0xFF34C759),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${connector.quantity} 個接口',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: Color(0xFF1A73E8),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(AppLocalizations.of(context)!.text_383,
                            '${connector.power}kW', Icons.bolt_rounded),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        _buildDetailItem(AppLocalizations.of(context)!.text_374,
                            connector.rate, Icons.attach_money_rounded),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        _buildDetailItem(AppLocalizations.of(context)!.text_384,
                            '${connector.quantity}', Icons.power_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.text_385,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A73E8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...connector.points.map((point) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A73E8)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '充電點 ID: $point',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getConnectorStatus(int status) {
    switch (status) {
      case 1:
        return {
          'text': AppLocalizations.of(context)!.text_386,
          'color': const Color(0xFF34C759),
          'icon': Icons.check_circle_rounded,
        };
      case 2:
        return {
          'text': AppLocalizations.of(context)!.text_387,
          'color': const Color(0xFFFF9500),
          'icon': Icons.ev_station_rounded,
        };
      case 3:
        return {
          'text': AppLocalizations.of(context)!.text_388,
          'color': const Color(0xFFFF3B30),
          'icon': Icons.build_rounded,
        };
      default:
        return {
          'text': AppLocalizations.of(context)!.text_321,
          'color': Colors.grey[600]!,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  String _getTypeName(String type) {
    final typeNames = {
      '1': 'Type 1',
      '2': 'Type 2',
      '3': 'CHAdeMO',
      '4': 'CCS1',
      '5': 'CCS2',
      '6': AppLocalizations.of(context)!.text_389,
    };
    return typeNames[type] ?? AppLocalizations.of(context)!.text_390;
  }

  IconData _getIcon(String type) {
    const icons = {
      '1': Icons.ev_station_rounded,
      '2': Icons.bolt_rounded,
      '3': Icons.flash_on_rounded,
      '4': Icons.electric_car_rounded,
      '5': Icons.electric_car_rounded,
      '6': Icons.battery_charging_full_rounded,
    };
    return icons[type] ?? Icons.power_rounded;
  }

  Color _getColor(String type) {
    const colors = {
      '1': Color(0xFF1A73E8),
      '2': Color(0xFF34C759),
      '3': Color(0xFFFF9500),
      '4': Color(0xFFAF52DE),
      '5': Color(0xFF5856D6),
      '6': Color(0xFFFF3B30),
    };
    return colors[type] ?? Colors.grey;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A73E8).withOpacity(0.1),
                    const Color(0xFF1A73E8).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.ev_station_rounded,
                size: 50,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.text_391,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.text_392,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MergedConnector {
  final String type;
  final String power;
  final String rate;
  final String floor;
  final int quantity;
  final List<String> points;
  final String? ConnectorStatus;

  MergedConnector({
    required this.type,
    required this.power,
    required this.rate,
    required this.floor,
    required this.quantity,
    required this.points,
    this.ConnectorStatus,
  });

  MergedConnector mergeWith(MergedConnector other) {
    return MergedConnector(
      type: type,
      power: power,
      rate: rate,
      floor: floor,
      quantity: quantity + other.quantity,
      points: [...points, ...other.points],
      ConnectorStatus: ConnectorStatus,
    );
  }
}
