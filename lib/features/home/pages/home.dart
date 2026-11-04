import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';

// 請替換為你專案的實際路徑
import '../../../const/app_colors.dart';
import '../../../const/regular_class.dart';
import '../../../const/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/bike.dart';
import '../../youbike/state/bike_provider.dart';
import '../../youbike/widgets/bike_default_content.dart';

import '../widgets/home_bottom_sheet.dart';
import '../widgets/home_map.dart';

const ClusterManager _bikeCluster = ClusterManager(
  clusterManagerId: ClusterManagerId("bike"),
);

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BikeProvider()),
        ChangeNotifierProvider(create: (_) => MarkerProvider()), // ← Home 專屬
      ],
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();
  @override
  State<_HomeContent> createState() => _HomeState();
}

class _HomeState extends State<_HomeContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  PersistentBottomSheetController? _bikeBottomSheetController;

  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.43);
  LatLng _currentPosition = const LatLng(25.0330, 121.5654);
  BitmapDescriptor? _bikeMarkerIcon;

  bool _showMainContent = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _sheetExtent.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _currentPosition = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 15.0),
        ),
      );
    } catch (_) {
      if (mounted) {
        debugPrint(AppLocalizations.of(context)!.text_129);
      }
    }
  }

  Future<void> _handleTransportClick(String type) async {
    if (type == 'taxi') {
      await Navigator.of(context).pushNamed(type);
      return;
    }
    if (type != 'bike') return;
    if (_bikeBottomSheetController != null) return;

    setState(() => _showMainContent = false);
    _openBikeBottomSheet();
    await _fetchBikeData();
  }

  Future<void> _fetchBikeData() async {
    await context.read<BikeProvider>().loadStations(context);
    if (mounted && _bikeBottomSheetController != null) {
      await _loadBikeMarkers();
    }
  }

  Future<void> _loadBikeMarkers() async {
    final provider = Provider.of<MarkerProvider>(context, listen: false);
    final customIcon = _bikeMarkerIcon ??= await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(8, 8)),
      'assets/img/ubike_icon.png',
    );

    if (!mounted || _bikeBottomSheetController == null) return;

    final markerCache = <Marker>{};
    final clusterItems = <youbike>[];

    for (final station in context.read<BikeProvider>().stations) {
      final lat = station.stationPosition.positionLat;
      final lon = station.stationPosition.positionLon;
      if (lat == 0 || lon == 0 || lat.abs() > 90 || lon.abs() > 180) continue;

      markerCache.add(Marker(
        clusterManagerId: _bikeCluster.clusterManagerId,
        markerId: MarkerId(station.stationUID),
        icon: customIcon,
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(
          title: station.stationName.zhTw,
          snippet: "可借: ${station.bikesCapacity}",
        ),
        onTap: () => _updateSelectedStation(station),
      ));
      clusterItems.add(youbike(station.stationUID, LatLng(lat, lon)));
    }

    provider.setMarkers(markerCache);
    provider.setItems(clusterItems);
  }

  // 修改這裡：改用 DraggableScrollableSheet 包裝
  void _openBikeBottomSheet() {
    final bikeProvider = context.read<BikeProvider>();
    final controller = showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: bikeProvider,
        child: Builder(builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.25,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return _buildBikeContent(context, scrollController);
            },
          );
        }),
      ),
    );
    _bikeBottomSheetController = controller;

    controller.closed.whenComplete(() {
      if (!mounted || !identical(_bikeBottomSheetController, controller)) return;
      _bikeBottomSheetController = null;
      Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
      Provider.of<MarkerProvider>(context, listen: false).setItems([]);
      context.read<BikeProvider>().clearSelection();

      setState(() {
        _showMainContent = true;
      });
    });
  }

  void _updateSelectedStation(YouBikeStation? station) {
    final bike = context.read<BikeProvider>();
    if (station != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              station.stationPosition.positionLat,
              station.stationPosition.positionLon,
            ),
            zoom: 23.0,
          ),
        ),
      );
      bike.selectStation(station);
    } else {
      bike.clearSelection();
    }

    final refreshBottomSheet = _bikeBottomSheetController?.setState;
    if (refreshBottomSheet != null) {
      refreshBottomSheet(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final cityName = Provider.of<CityProvider>(context).city;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: HomeMap(
                sheetExtent: _sheetExtent,
                onMapCreated: (controller) => _mapController = controller,
                initialPosition: _currentPosition,
                clusterManagers: {_bikeCluster},
              ),
            ),
            if (_showMainContent)
              Positioned.fill(
                child: HomeBottomSheet(
                  sheetExtent: _sheetExtent,
                  cityName: cityName,
                  onTransportClick: _handleTransportClick,
                  onExtentChanged: (newExtent) {
                    _sheetExtent.value = newExtent;
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Ubike UI 邏輯 (支援拖曳)
  // ==========================================
  Widget _buildBikeContent(BuildContext context, ScrollController scrollController) {
    final bike = context.watch<BikeProvider>();
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // 頂部拖曳把手
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // 內容區塊
          Expanded(
            child: bike.selectedStation == null
                ? bike.isLoadingStations
                ? _buildLoadingState(context)
                : bike.stationError != null
                ? _buildStationLoadError()
                : BikeDefaultContent(
              stations: bike.stations,
              onStationSelected: _updateSelectedStation,
            )
                : FutureBuilder<BikeAvailability?>(
              future: bike.availabilityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState(context);
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildAvailabilityError(
                    snapshot.hasError
                        ? AppLocalizations.of(context)!.text_131
                        : AppLocalizations.of(context)!.text_132,
                    snapshot.hasError
                        ? Icons.error_outline
                        : Icons.info_outline,
                  );
                }

                final station = bike.selectedStation!;
                final data = snapshot.data!;

                return _buildContentSection(context, scrollController, station, data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityError(String text, IconData icon) {
    final colors = context.appColors;
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.textHint),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                final station = context.read<BikeProvider>().selectedStation;
                if (station != null) _updateSelectedStation(station);
              },
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationLoadError() {
    return SizedBox(
      height: 300,
      child: Center(
        child: TextButton(
          onPressed: () async {
            await context
                .read<BikeProvider>()
                .loadStations(context, force: true);
            if (mounted && _bikeBottomSheetController != null) {
              await _loadBikeMarkers();
            }
          },
          child: const Text('無法載入站點，點此重試'),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.stretchedDots(
            color: colors.info,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_133,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }

  int _estimateWalkingMinutes(double distanceMeters) {
    return (distanceMeters / 80).ceil();
  }

  // --- 修改這裡：接收 scrollController，並使用 CustomScrollView 或 Sliver 以支援 DraggableScrollableSheet
  Widget _buildContentSection(
      BuildContext context,
      ScrollController scrollController,
      YouBikeStation station,
      BikeAvailability data,
      ) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final bike = context.watch<BikeProvider>();

    final double distance = _calculateDistance(
      _currentPosition.latitude,
      _currentPosition.longitude,
      station.stationPosition.positionLat,
      station.stationPosition.positionLon,
    );
    final String distanceText = _formatDistance(distance);
    final int walkMinutes = _estimateWalkingMinutes(distance);

    final int totalDocks = station.bikesCapacity;
    final int availableSpots = int.tryParse(data.availableReturnBikes.toString()) ?? 0;
    final double occupancyRate = totalDocks > 0 ? (availableSpots / totalDocks).clamp(0.0, 1.0) : 0.0;

    final otherStations = bike.stations
        .where((s) => s.stationUID != station.stationUID)
        .map((s) {
      final dist = _calculateDistance(
        _currentPosition.latitude,
        _currentPosition.longitude,
        s.stationPosition.positionLat,
        s.stationPosition.positionLon,
      );
      return {'station': s, 'distance': dist};
    })
        .toList()
      ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    final nearbyStations = otherStations.take(3).toList();

    return ListView(
      controller: scrollController, // 綁定控制項
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // 頂部標題列
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.mutedBackground,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Text(
                          'YouBike 2.0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '站點代號 #${station.stationUID}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    station.stationName.zhTw,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.directions_walk, size: 16, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '步行約 $walkMinutes 分鐘',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '距離 $distanceText',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final url = 'https://www.google.com/maps/dir/?api=1&destination=${station.stationPosition.positionLat},${station.stationPosition.positionLon}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text('路線指引'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.infoContainer,
                foregroundColor: colors.info,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedLg,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 主要數據卡片 (可借 / 可還)
        Row(
          children: [
            _buildMetricTile(
              context,
              icon: Icons.pedal_bike,
              color: colors.success,
              title: '可借車輛',
              value: data.availableRentBikes.toString(),
              unit: '台',
            ),
            const SizedBox(width: 12),
            _buildMetricTile(
              context,
              icon: Icons.local_parking,
              color: colors.info,
              title: '可還空位',
              value: data.availableReturnBikes.toString(),
              unit: '位',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 總車柱與進度條區塊
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.mutedBackground,
            borderRadius: AppRadius.roundedLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '總車柱 $totalDocks 柱',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.pedal_bike, size: 14, color: colors.textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        '${data.generalBikes}',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.electric_bike, size: 14, color: colors.info),
                      const SizedBox(width: 4),
                      Text(
                        '${data.electricBikes}',
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: occupancyRate,
                  minHeight: 8,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.info),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 地址與更新時間
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: colors.textHint),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        station.stationAddress.zhTw,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: colors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '車況即時檢修正常',
                      style: TextStyle(fontSize: 13, color: colors.success),
                    ),
                  ),
                  Text(
                    '詳情 >',
                    style: TextStyle(fontSize: 13, color: colors.info),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 周邊其他站點
        if (nearbyStations.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '周邊其他站點',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '即時動態',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearbyStations.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = nearbyStations[index];
                final s = item['station'] as YouBikeStation;
                final dist = item['distance'] as double;
                return GestureDetector(
                  onTap: () => _updateSelectedStation(s),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: AppRadius.roundedLg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.stationName.zhTw,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              _formatDistance(dist),
                              style: TextStyle(fontSize: 11, color: colors.textHint),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.pedal_bike, size: 14, color: colors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${s.bikesCapacity} 台',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.local_parking, size: 14, color: colors.info),
                            const SizedBox(width: 4),
                            Text(
                              '24 位',
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMetricTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String value,
        required String unit,
      }) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.roundedLg,
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}