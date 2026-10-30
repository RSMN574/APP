import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// 請替換為你專案的實際路徑
import '../../../const/app_colors.dart';
import '../../../const/regular_class.dart';
import '../../../const/app_design_tokens.dart'; // 引入設計 Token
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

class _HomeState extends State<_HomeContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  PersistentBottomSheetController? _bikeBottomSheetController;

  final ValueNotifier<double> _sheetExtent = ValueNotifier(0.43);
  LatLng _currentPosition = const LatLng(25.0330, 121.5654);
  BitmapDescriptor? _bikeMarkerIcon;

  // 恢復這個狀態，用來控制首頁 Bottom Sheet 的顯示與隱藏
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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

    // 點擊 Ubike 時，隱藏首頁面板
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
          snippet: "Capacity: ${station.bikesCapacity}",
        ),
        onTap: () => _updateSelectedStation(station),
      ));
      clusterItems.add(youbike(station.stationUID, LatLng(lat, lon)));
    }

    provider.setMarkers(markerCache);
    provider.setItems(clusterItems);
  }

  void _openBikeBottomSheet() {
    final bikeProvider = context.read<BikeProvider>();
    final controller = showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: bikeProvider,
        child: Builder(builder: _buildBikeContent),
      ),
    );
    _bikeBottomSheetController = controller;

    controller.closed.whenComplete(() {
      if (!mounted || !identical(_bikeBottomSheetController, controller)) return;
      _bikeBottomSheetController = null;
      Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
      Provider.of<MarkerProvider>(context, listen: false).setItems([]);
      context.read<BikeProvider>().clearSelection();

      // 關閉 Ubike 面板後，恢復首頁面板
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
            // 1. 地圖層
            Positioned.fill(
              child: HomeMap(
                sheetExtent: _sheetExtent,
                onMapCreated: (controller) => _mapController = controller,
                initialPosition: _currentPosition,
                clusterManagers: {_bikeCluster}, // 傳入 ClusterManager
              ),
            ),

            // 2. 首頁 Bottom Sheet (根據 _showMainContent 決定是否顯示)
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
  // 以下完整沿用左邊的 Ubike UI 邏輯，僅優化顏色主題
  // ==========================================
  Widget _buildBikeContent(BuildContext context) {
    final bike = context.watch<BikeProvider>();
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
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

  Widget _buildContentSection(
      BuildContext context, String stationName, BikeAvailability data) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.infoContainer,
                    borderRadius: AppRadius.roundedSm, // 使用 Token: 8
                  ),
                  child: Icon(
                    Icons.pin_drop,
                    color: colors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stationName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
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
                    color: colors.textSecondary,
                  ),
                  onPressed: () {
                    _updateSelectedStation(null);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildMetricTile(
              context,
              icon: Icons.pedal_bike,
              color: colors.success,
              title: AppLocalizations.of(context)!.text_134,
              value: rentBikes,
              widthFactor: 0.5,
            ),
            const SizedBox(width: 12),
            _buildMetricTile(
              context,
              icon: Icons.local_parking,
              color: colors.info,
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
            color: colors.mutedBackground,
            borderRadius: AppRadius.roundedLg, // 使用 Token: 16
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.text_136,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
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
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.roundedLg, // 使用 Token: 16
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
                    color: theme.colorScheme.surface, // 改為主題 surface
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
                        color: colors.textSecondary, // 改為 textSecondary
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
    final colors = context.appColors;

    return Row(
      children: [
        _buildTypeChip(
          context,
          icon: Icons.pedal_bike,
          label: AppLocalizations.of(context)!.text_137,
          value: general,
          color: colors.textPrimary, // 改為 textPrimary
        ),
        const SizedBox(width: 12),
        _buildTypeChip(
          context,
          icon: Icons.electric_bike,
          label: AppLocalizations.of(context)!.text_138,
          value: electric,
          color: colors.info, // 改為 info 語意色
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
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // 改為主題 surface
          borderRadius: AppRadius.roundedMd, // 使用 Token: 12
          border: Border.all(color: colors.border), // 改為 border 語意色
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.roundedSm, // 使用 Token: 8
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
                    color: colors.textHint, // 改為 textHint
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