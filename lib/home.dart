import 'package:com.rsmn574.app/features/weather/widgets/weather_card.dart';
import 'package:com.rsmn574.app/widget/img_swiper.dart';
import 'package:com.rsmn574.app/widget/map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'const/regular_class.dart';
import 'const/regular_const.dart';
import 'models/bike.dart';
import 'features/youbike/state/bike_provider.dart';
import 'features/youbike/widgets/bike_default_content.dart';

import 'l10n/app_localizations.dart';
import 'widget/transport_grid.dart';

const ClusterManager _bikeCluster = ClusterManager(
  clusterManagerId: ClusterManagerId("bike"),
);

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BikeProvider(),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeState();
}

class _HomeState extends State<_HomeContent>
    with AutomaticKeepAliveClientMixin<_HomeContent> {
  @override
  bool get wantKeepAlive => true;

  final FocusNode _searchFocusNode = FocusNode();
  final double _bottomSheetHeightMin = 0.2;
  GoogleMapController? _mapController;
  PersistentBottomSheetController? _bottomSheetController;
  BitmapDescriptor? _bikeMarkerIcon;
  static const LatLng _initialPosition = LatLng(25.0330, 121.5654);
  LatLng _currentPosition = _initialPosition;

  // 获取当前位置
  void _getCurrentLocation() async {
    try {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 15.0,
        ),
      ));
    } catch (_) {
      if (mounted) {
        debugPrint(AppLocalizations.of(context)!.text_129);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.unfocus();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _showMainContent = true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    const bottomNavBarHeight = kBottomNavigationBarHeight;
    const double mainSheetMin = 0.3;
    final mapHeight = screenHeight -
        (screenHeight * mainSheetMin) -
        appBarHeight -
        bottomNavBarHeight;

    return PopScope(
      canPop: true,
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
                  onCameraIdle: () {},
                  clusterManagers: {
                    _bikeCluster,
                  },
                ),
              ),
            ),
            if (_showMainContent) _buildMainContent(context),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchData() async {
    await context.read<BikeProvider>().loadStations(context);
    if (mounted && _bottomSheetController != null) {
      await _loadBikeMarkers();
    }
  }

  Future<void> _loadBikeMarkers() async {
    final provider = Provider.of<MarkerProvider>(context, listen: false);
    final customIcon = _bikeMarkerIcon ??= await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(8, 8)),
      'assets/img/ubike_icon.png',
    );

    if (!mounted || _bottomSheetController == null) return;

    final markerCache = <Marker>{};
    final clusterItems = <youbike>[];

    for (final station in context.read<BikeProvider>().stations) {
      final lat = station.stationPosition.positionLat;
      final lon = station.stationPosition.positionLon;
      if (lat == 0 || lon == 0 || lat.abs() > 90 || lon.abs() > 180) {
        continue;
      }
      final stationId = station.stationUID;
      final stationName = station.stationName.zhTw;

      final marker = Marker(
        clusterManagerId: _bikeCluster.clusterManagerId,
        markerId: MarkerId(stationId),
        icon: customIcon,
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(
          title: stationName,
          snippet: "Capacity: ${station.bikesCapacity}",
        ),
        onTap: () => _updateSelectedStation(station),
      );
      markerCache.add(marker);

      clusterItems.add(youbike(stationId, LatLng(lat, lon)));
    }

    provider.setMarkers(markerCache);
    provider.setItems(clusterItems);
  }

  Future<void> _handleClick(String type) async {
    if (type == 'taxi') {
      await Navigator.of(context).pushNamed(type);
      return;
    }
    if (type != 'bike') return;
    if (_bottomSheetController != null) return;

    setState(() => _showMainContent = false);
    _openBikeBottomSheet();
    await _fetchData();
  }

  void _openBikeBottomSheet() {
    final bikeProvider = context.read<BikeProvider>();
    final controller = showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 讓 Container 自己控制背景
      builder: (_) => ChangeNotifierProvider.value(
        value: bikeProvider,
        child: Builder(builder: _buildBikeContent),
      ),
    );
    _bottomSheetController = controller;

    controller.closed.whenComplete(() {
      if (!mounted || !identical(_bottomSheetController, controller)) return;
      _bottomSheetController = null;
      Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
      Provider.of<MarkerProvider>(context, listen: false).setItems([]);
      context.read<BikeProvider>().clearSelection();
      setState(() {
        _showMainContent = true;
      });
    });
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
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)), // LMG: 增加圓角
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    TransportGrid(onClick: _handleClick),
                    const ImgSwiper(),
                    const WeatherAlertCard(
                      cityName: '台中市',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSelectedStation(YouBikeStation? station) {
    final bike = context.read<BikeProvider>();
    if (station != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(station.stationPosition.positionLat,
                station.stationPosition.positionLon),
            zoom: 23.0,
          ),
        ),
      );

      bike.selectStation(station);
    } else {
      bike.clearSelection();
    }
    final refreshBottomSheet = _bottomSheetController?.setState;
    if (refreshBottomSheet != null) {
      refreshBottomSheet(() {});
    }
  }

  Widget _buildBikeContent(BuildContext context) {
    final bike = context.watch<BikeProvider>();
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
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

                final stationName = bike.selectedStation!.stationName.zhTw;
                final data = snapshot.data!;

                return _buildContentSection(context, stationName, data);
              },
            ),
    );
  }

  Widget _buildAvailabilityError(String text, IconData icon) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
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
            await context.read<BikeProvider>().loadStations(context,force: true);
            if (mounted && _bottomSheetController != null) {
              await _loadBikeMarkers();
            }
          },
          child: const Text('無法載入站點，點此重試'),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.stretchedDots(
            color: colors.primary,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_133,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
      BuildContext context, String stationName, BikeAvailability data) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 站點標題
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.15), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.pin_drop,
                    color: colors.onPrimaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stationName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: colors.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _updateSelectedStation(null);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 主要數據卡片
          _buildCompactDataGrid(
            context,
            rentBikes: data.availableRentBikes.toString(),
            returnSpots: data.availableReturnBikes.toString(),
            generalBikes: data.generalBikes.toString(),
            electricBikes: data.electricBikes.toString(),
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
        Row(
          children: [
            _buildMetricTile(
              context,
              icon: Icons.pedal_bike,
              color: const Color(0xFF34C759),
              title: AppLocalizations.of(context)!.text_134,
              value: rentBikes,
              widthFactor: 0.5,
            ),
            const SizedBox(width: 12),
            _buildMetricTile(
              context,
              icon: Icons.local_parking,
              color: const Color(0xFF1A73E8),
              title: AppLocalizations.of(context)!.text_135,
              value: returnSpots,
              widthFactor: 0.5,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.text_136,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
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
          label: AppLocalizations.of(context)!.text_137,
          value: general,
          color: Colors.grey[700]!,
        ),
        const SizedBox(width: 12),
        _buildTypeChip(
          context,
          icon: Icons.electric_bike,
          label: AppLocalizations.of(context)!.text_138,
          value: electric,
          color: const Color(0xFF1A73E8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
}
