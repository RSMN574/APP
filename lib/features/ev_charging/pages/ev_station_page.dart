import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:com.rsmn574.app/const/regular_class.dart';

import 'package:com.rsmn574.app/database/get_data.dart';

import 'package:com.rsmn574.app/features/ev_charging/state/ev_station_provider.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/utils/share.dart';
import 'package:com.rsmn574.app/widget/map.dart';

import '../../../const/app_colors.dart';
import '../../../const/surface_decoration.dart';
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
        return true;
      },
      child: Scaffold(
        backgroundColor: colors.cardBackground,
        appBar: AppBar(
          backgroundColor: colors.cardBackground,
          foregroundColor: colors.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l10n.text_369,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.info,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: colors.info),
          actions: [
            Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: SurfaceDecoration.outlined(context, radius: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  isExpanded: true,
                  value: selectedCity,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: colors.info,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return regions.map<Widget>((city) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: colors.info,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  items: regions.map((city) {
                    final isSelected = selectedCity == city;
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.info
                                  : colors.textHint.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              city,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? colors.info : colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedCity = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const AppLoading()
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
                  decoration: SurfaceDecoration.dialog(context),
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
                            color: colors.textHint,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // 搜尋輸入框
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Container(
                          decoration: SurfaceDecoration.outlined(
                            context,
                            radius: 16,
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: l10n.text_139,
                              hintStyle: TextStyle(
                                color: colors.textHint,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: colors.info,
                                  size: 20,
                                ),
                              ),
                              suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: colors.textHint,
                                ),
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
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
                color: colors.infoContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.ev_station_rounded,
                size: 50,
                color: colors.info,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.text_371,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.info,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text_372,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStationCard(Map<String, dynamic> station) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin:
      const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      decoration: SurfaceDecoration.cardShadow(context, radius: 20),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題列
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.successContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.ev_station_rounded,
                        size: 22,
                        color: colors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station['StationNameZh_tw'] ?? l10n.text_373,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${station['LocationCityRoadCity'] ?? ''}${station['LocationCityRoadTown'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textHint,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 資訊網格
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: SurfaceDecoration.muted(context, radius: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.bolt_rounded,
                          title: l10n.text_374,
                          value: station['ChargingRate'] ?? l10n.text_375,
                          color: colors.info,
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: colors.divider,
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.local_parking_rounded,
                          title: l10n.text_376,
                          value: station['ParkingRate'] ?? l10n.text_377,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 按鈕列
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children: [
                    if (station['Telephone'] != null &&
                        station['Telephone'] != "")
                      _buildActionChip(
                        icon: Icons.phone_rounded,
                        label: l10n.text_378,
                        color: colors.info,
                        onTap: () =>
                            StationActions.makeCall(station['Telephone']),
                      ),
                    _buildActionChip(
                      icon: Icons.directions_rounded,
                      label: l10n.text_379,
                      color: colors.success,
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
                            station['StationNameZh_tw'] ?? l10n.text_380);
                      },
                    ),
                    _buildActionChip(
                      icon: Icons.share_rounded,
                      label: l10n.text_381,
                      color: colors.info,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final colors = context.appColors;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.cardBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.station['StationNameZh_tw'] ?? l10n.text_382,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.info,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.info),
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final status = _getConnectorStatus(
        int.tryParse(connector.ConnectorStatus ?? '0') ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: SurfaceDecoration.cardShadow(context, radius: 20),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          iconColor: colors.info,
          collapsedIconColor: colors.info,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getColor(connector.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(connector.type),
              size: 24,
              color: _getColor(connector.type),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  _getTypeName(connector.type),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                    color: colors.infoContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.layers_rounded,
                        size: 14,
                        color: colors.info,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connector.floor,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.info,
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
                    color: colors.successContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.success.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.electrical_services_rounded,
                        size: 14,
                        color: colors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.evConnectorCount(connector.quantity),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.success,
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
            decoration: SurfaceDecoration.muted(context, radius: 10),
            child: Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: colors.info,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration:
                    SurfaceDecoration.muted(context, radius: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                          l10n.text_383,
                          '${connector.power}kW',
                          Icons.bolt_rounded,
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: colors.divider,
                        ),
                        _buildDetailItem(
                          l10n.text_374,
                          connector.rate,
                          Icons.attach_money_rounded,
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: colors.divider,
                        ),
                        _buildDetailItem(
                          l10n.text_384,
                          '${connector.quantity}',
                          Icons.power_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration:
                    SurfaceDecoration.muted(context, radius: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.text_385,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.info,
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
                                  color: colors.infoContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: colors.info,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.evChargingPointId(point),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
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
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colors.info),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.info,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getConnectorStatus(int status) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 1:
        return {
          'text': l10n.text_386,
          'color': colors.success,
          'icon': Icons.check_circle_rounded,
        };
      case 2:
        return {
          'text': l10n.text_387,
          'color': colors.warning,
          'icon': Icons.ev_station_rounded,
        };
      case 3:
        return {
          'text': l10n.text_388,
          'color': colors.danger,
          'icon': Icons.build_rounded,
        };
      default:
        return {
          'text': l10n.text_321,
          'color': colors.textHint,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  String _getTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    final typeNames = {
      '1': 'Type 1',
      '2': 'Type 2',
      '3': 'CHAdeMO',
      '4': 'CCS1',
      '5': 'CCS2',
      '6': l10n.text_389,
    };
    return typeNames[type] ?? l10n.text_390;
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
    final colors = context.appColors;
    // 使用 AppColors 的語意色，避免深色模式下硬編碼色過暗/過亮。
    final map = {
      '1': colors.info,
      '2': colors.success,
      '3': colors.warning,
      '4': colors.info,
      '5': colors.info,
      '6': colors.danger,
    };
    return map[type] ?? colors.textHint;
  }

  Widget _buildEmptyState() {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
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
                color: colors.infoContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.ev_station_rounded,
                size: 50,
                color: colors.info,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.text_391,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.info,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.text_392,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
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