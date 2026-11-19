import 'package:com.rsmn574.app/features/bus/pages/bus_history_page.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_route_view_model.dart';
import 'package:com.rsmn574.app/const/arrival_status_colors.dart';
import 'package:com.rsmn574.app/widget/arrival_chip.dart';
import 'dart:async';
import 'package:com.rsmn574.app/features/bus/pages/bus_schedule_page.dart';
import 'dart:ui';

import 'package:com.rsmn574.app/features/bus/widgets/bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/database/sql/favorite_feature.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_provider.dart';
import 'package:com.rsmn574.app/features/bus/data/bus_position_estimator.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/models/bus_route.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_estimates_parser.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_stop_time_formatter.dart';
import 'package:com.rsmn574.app/features/notification/services/arrival_reminder_task.dart';
import 'package:com.rsmn574.app/core/utils/convert.dart';
import 'package:com.rsmn574.app/widget/map.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_stop_info_page.dart';

import '../../../const/app_colors.dart';
import '../../../const/surface_decoration.dart';
import '../../../firebase/analytics_service.dart';
import '../../../widget/AppLoading.dart';
import '../../../widget/app_custom_bar.dart';

class Mark {
  final List<dynamic>? highlight;

  /// TDX 的實際 Direction（0 / 1），不是 Tab 索引。
  final int? direction;

  Mark({this.highlight, this.direction});

  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      highlight: map['highlight'] ?? [],
      direction: map['direction'] ?? 0,
    );
  }
}

bool _isEnglishLocale(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

String _localizedBusRouteName(BusRoute route, {required bool isEnglish}) {
  if (isEnglish && route.routeEn.isNotEmpty) return route.routeEn;
  return route.routeZh;
}

String _localizedDepartureName(BusRoute route, {required bool isEnglish}) {
  if (isEnglish && route.departureStopNameEn.isNotEmpty) {
    return route.departureStopNameEn;
  }
  return route.departureStopNameZh;
}

String _localizedDestinationName(BusRoute route, {required bool isEnglish}) {
  if (isEnglish && route.destinationStopNameEn.isNotEmpty) {
    return route.destinationStopNameEn;
  }
  return route.destinationStopNameZh;
}

String _tdxRouteName(BusRoute route, dynamic fallback) {
  return route.routeZh.isNotEmpty ? route.routeZh : fallback?.toString() ?? '';
}

class BusTime extends StatefulWidget {
  final routeName;
  final departureStopName;
  final destinationStopName;
  final operators;
  final routeMapImageUrl;
  final city;
  final bool hasSubRoutes;
  final String routeID;
  final Mark? mark;
  final BusRoute data;

  const BusTime({
    Key? key,
    required this.routeName,
    required this.routeID,
    this.departureStopName,
    this.destinationStopName,
    this.operators,
    this.routeMapImageUrl,
    required this.city,
    this.mark,
    required this.hasSubRoutes,
    required this.data,
  }) : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime> with SingleTickerProviderStateMixin {
  // ✅ P0：抽出站牌列表高度常數，供滾動與 UI 共用，避免硬編碼耦合。
  static const double _stopItemHeight = 54.5;
  static const double _stopSeparatorHeight = 9.0;

  // QA B1：載入、方向判定、站序組合與自動更新倒數交給 ViewModel。
  late final BusRouteViewModel _vm;
  ValueNotifier<int> get remainingSecondsNotifier => _vm.remainingSeconds;
  ValueNotifier<bool> get isTimerOn => _vm.autoReloadOn;
  final ScrollController _scrollController = ScrollController();
  List<dynamic> stopNamesWithTime1 = [];
  List<dynamic> stopNamesWithTime2 = [];
  late final TabController _tabController;
  final Set<Marker> _stopMarkers = {};
  final Set<Marker> _busMarkers = {};
  Timer? _busPositionTimer;
  final BusPositionEstimator _busPositionEstimator =
  const BusPositionEstimator();
  final Map<int, List<LatLng>> _routePointsByDirection = {};
  int _busPositionRequestId = 0;
  final ValueNotifier<String> _directionNotifier = ValueNotifier("");
  final ValueNotifier<Map<String, dynamic>?> _dataNotifier =
  ValueNotifier(null);

  // ✅ P0：原本 top-level 可變變數改為 State 成員，避免跨頁共用。
  String? _nearestStop;

  // 儲存 Tab 索引與實際 TDX Direction 的對應關係
  List<int> _tabDirections = [0];

  // 避免 Async Race Condition 的請求世代計數器（資料載入由 ViewModel 處理）
  int _shapeRequestId = 0;

  // 供 _scrollToHighlightOrNearest 使用的最近站點索引
  int? _nearestIndexForScroll;

  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.logFeatureOpened('bus_time'));

    if (widget.hasSubRoutes == false) {
      _tabController = TabController(length: 1, vsync: this);
      _tabDirections = [widget.mark?.direction ?? 1];
    } else {
      _tabController = TabController(length: 2, vsync: this);
      _tabDirections = [1, 0];
    }

    _tabController.addListener(_handleTabChange);

    _vm = BusRouteViewModel(
      dataSource: context.read<BusProvider>(),
      city: widget.city?.toString() ?? '',
      routeId: widget.routeID,
      tdxRouteName: _tdxRouteName(widget.data, widget.routeName),
      hasSubRoutes: widget.hasSubRoutes,
      tabCount: _tabController.length,
      preferredDirection: widget.mark?.direction,
      highlightStops: widget.mark?.highlight,
    )..onAutoReload = _loadData;

    // 初次載入：_loadData 需要讀取 Localizations（InheritedWidget），
    // 不能在 initState 內同步呼叫，改到第一個 frame 之後。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });

    // 車輛位置獨立更新
    _busPositionTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _loadBusPositions(_currentDirection),
    );
  }

  int get _currentDirection {
    if (_tabDirections.isEmpty) return widget.mark?.direction ?? 1;
    final index = _tabController.index.clamp(0, _tabDirections.length - 1);
    return _tabDirections[index];
  }

  void _publishMarkers() {
    if (!mounted) return;
    final combined = <Marker>{..._stopMarkers, ..._busMarkers};
    Provider.of<MarkerProvider>(context, listen: false).setMarkers(combined);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    final tabIndex = _tabController.index.clamp(0, _tabDirections.length - 1);
    final direction = _tabDirections[tabIndex];
    final currentStops =
    tabIndex == 0 ? stopNamesWithTime1 : stopNamesWithTime2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadShape(direction);
      _loadMarkers(currentStops);
      _loadBusPositions(direction);
    });
  }

  void _scrollToIndex(int index) {
    // ✅ P0：改用類別常數，與 _buildTabContent 的高度保持一致。
    final scrollPosition = (_stopItemHeight + _stopSeparatorHeight) * index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<Set<Polyline>> _loadShape(int direction) async {
    if (!mounted) return {};
    final requestId = ++_shapeRequestId;
    final provider = context.read<BusProvider>();
    try {
      final data = await provider.fetchRouteShape(
        city: widget.city,
        routeName: _tdxRouteName(widget.data, widget.routeName),
        routeID: widget.routeID,
      );

      if (!mounted || requestId != _shapeRequestId) return {};

      final Set<Polyline> polylines = {};

      for (final item in data) {
        final d = item['Direction'];
        final itemDir = (d is int) ? d : int.tryParse(d?.toString() ?? '');
        if (itemDir != direction) continue;

        final encoded = item['EncodedPolyline'];
        if (encoded is! String || encoded.isEmpty) continue;

        final decodedPoints = decodePolyline(encoded);
        if (decodedPoints.length < 2) continue;

        // ✅ P0：改為覆寫，Shape 更新時能反映到位置推估用座標。
        _routePointsByDirection[direction] = decodedPoints;

        polylines.add(
          Polyline(
            polylineId: PolylineId(
              '${widget.routeName}_${item['ShapeID'] ?? polylines.length}',
            ),
            points: decodedPoints,
            width: 4,
            color: Colors.blue,
          ),
        );
      }

      if (!mounted || requestId != _shapeRequestId) return {};
      context.read<PolylineProvider>().setPolylines(polylines);
      return polylines;
    } catch (e, stack) {
      debugPrint('Load Shape Error: $e');
      debugPrintStack(stackTrace: stack);

      if (mounted && requestId == _shapeRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.text_338),
          ),
        );
      }

      return {};
    }
  }

  Future<void> _loadMarkers(List<dynamic> stops) async {
    _stopMarkers.clear();

    for (final stop in stops) {
      final pos = stop['StopPosition'];
      if (pos is! Map ||
          pos['PositionLat'] is! num ||
          pos['PositionLon'] is! num) {
        continue;
      }

      final stopId = stop['StopID']?.toString() ?? 'Unknown';
      _stopMarkers.add(
        Marker(
          markerId: MarkerId('stop_$stopId'),
          position: LatLng(
            (pos['PositionLat'] as num).toDouble(),
            (pos['PositionLon'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: stop['displayStopName'] ?? stop['stopName'] ?? 'Unknown',
            snippet: stopId,
          ),
        ),
      );
    }

    _publishMarkers();
  }

  /// 解析可確認的座標／速度／時間欄位；欄位缺失時只顯示原始 GPS。
  double? _numberFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  DateTime? _dateTimeFrom(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim())?.toLocal();
    }
    return null;
  }

  Future<void> _loadBusPositions(int direction) async {
    if (!mounted) return;

    final requestId = ++_busPositionRequestId;
    print(widget.routeName);
    try {
      final response = await context.read<BusProvider>().fetchRealtimePositions(
        routeName: _tdxRouteName(widget.data, widget.routeName),
        city: widget.city,
        routeID: widget.routeID,
      );

      if (!mounted || requestId != _busPositionRequestId) return;
      if (direction != _currentDirection) return;

      final now = DateTime.now();
      final routePoints =
          _routePointsByDirection[direction] ?? const <LatLng>[];
      final nextMarkers = <Marker>{};

      for (final bus in response) {
        final rawDirection = bus['Direction'];
        final busDirection = rawDirection is int
            ? rawDirection
            : int.tryParse(rawDirection?.toString() ?? '');
        if (busDirection != null && busDirection != direction) continue;

        final dynamic rawPosition =
            bus['BusPosition'] ?? bus['Position'] ?? bus['GPSPosition'];
        final Map position = rawPosition is Map ? rawPosition : bus;

        final lat = _numberFrom(position['PositionLat'] ??
            position['Latitude'] ??
            position['latitude']);
        final lon = _numberFrom(position['PositionLon'] ??
            position['Longitude'] ??
            position['longitude']);
        if (lat == null ||
            lon == null ||
            !lat.isFinite ||
            !lon.isFinite ||
            lat < -90 ||
            lat > 90 ||
            lon < -180 ||
            lon > 180) {
          if (kDebugMode) {
            debugPrint('略過缺少有效 GPS 座標的公車資料，欄位：${bus.keys.toList()}');
          }
          continue;
        }

        final gpsPosition = LatLng(lat, lon);
        final speedKmh = _numberFrom(
          bus['Speed'] ?? bus['VehicleSpeed'] ?? position['Speed'],
        );
        final heading = _numberFrom(
          bus['Azimuth'] ?? bus['Bearing'] ?? bus['Heading'],
        );
        final gpsTime = _dateTimeFrom(
          bus['GPSTime'] ??
              bus['GpsTime'] ??
              bus['UpdateTime'] ??
              bus['SrcRecTime'] ??
              bus['SrcTransTime'],
        );

        BusPositionEstimate? estimate;
        if (speedKmh != null && gpsTime != null && routePoints.length >= 2) {
          estimate = _busPositionEstimator.estimate(
            sample: BusGpsSample(
              position: gpsPosition,
              speedKmh: speedKmh,
              recordedAt: gpsTime,
              headingDegrees: heading,
            ),
            now: now,
            routePoints: routePoints,
          );
        }

        final displayedPosition = estimate?.position ?? gpsPosition;
        final plate = bus['PlateNumb']?.toString();
        final vehicleId = bus['VehicleID']?.toString() ??
            bus['BusID']?.toString() ??
            plate ??
            '${lat}_$lon';
        final isEstimated = estimate?.isEstimated ?? false;
        final statusText = gpsTime == null
            ? 'GPS 時間未提供，顯示原始位置'
            : (isEstimated ? '推估位置' : 'GPS 位置');

        nextMarkers.add(
          Marker(
            markerId: MarkerId('bus_$vehicleId'),
            position: displayedPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            rotation: heading ?? 0,
            infoWindow: InfoWindow(
              title: plate != null && plate.isNotEmpty ? '公車 $plate' : '即時公車',
              snippet:
              '路線：${_tdxRouteName(widget.data, widget.routeName)} · $statusText',
            ),
            zIndexInt: 2,
          ),
        );
      }

      if (!mounted || requestId != _busPositionRequestId) return;
      _busMarkers
        ..clear()
        ..addAll(nextMarkers);
      _publishMarkers();
      debugPrint('🚌 公車 Marker 更新完成：${nextMarkers.length} 台；方向 $direction');
    } catch (e, stackTrace) {
      debugPrint('載入即時公車位置失敗：$e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    _busPositionTimer?.cancel();
    _busPositionRequestId++;
    _shapeRequestId++;
    _tabController.removeListener(_handleTabChange);
    _scrollController.dispose();
    _directionNotifier.dispose();
    _dataNotifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = _isEnglishLocale(context);
    try {
      await _vm.load(l10n: l10n, isEnglish: isEnglish);
    } catch (_) {
      // 已有資料時保留舊資料，只提示更新失敗（錯誤已由 ViewModel 上報）。
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.text_338)),
        );
      }
      return;
    }
    if (!mounted) return;

    if (_vm.status == BusRouteLoadStatus.error) {
      _dataNotifier.value ??= {
        'routeInfo': [
          widget.routeName?.toString() ?? '',
          widget.departureStopName?.toString() ?? '',
          widget.destinationStopName?.toString() ?? '',
        ],
        'stopNamesWithTime1': const [],
        'stopNamesWithTime2': const [],
        'error': _vm.error.toString(),
      };
      return;
    }

    _tabDirections = _vm.directions;
    final initialTab = _vm.takeInitialTabIndex();
    if (initialTab != null) _tabController.animateTo(initialTab);
    stopNamesWithTime1 = _vm.stopsForTab(0);
    stopNamesWithTime2 = _vm.stopsForTab(1);

    final tabIndex = _tabController.index.clamp(0, _tabDirections.length - 1);
    final currentDirection = _tabDirections[tabIndex];
    final currentStops =
        tabIndex == 0 ? stopNamesWithTime1 : stopNamesWithTime2;

    _updateNearestStop(currentStops);
    _scrollToHighlightOrNearest(currentStops);
    _loadMarkers(currentStops);
    _loadShape(currentDirection);
    _loadBusPositions(currentDirection);

    final displayRouteName =
        _localizedBusRouteName(widget.data, isEnglish: isEnglish);
    final displayDeparture =
        _localizedDepartureName(widget.data, isEnglish: isEnglish);
    final displayDestination =
        _localizedDestinationName(widget.data, isEnglish: isEnglish);

    _dataNotifier.value = {
      'routeInfo': [
        displayRouteName.isNotEmpty ? displayRouteName : widget.routeName,
        displayDeparture.isNotEmpty
            ? displayDeparture
            : widget.departureStopName,
        displayDestination.isNotEmpty
            ? displayDestination
            : widget.destinationStopName,
      ],
      'stopNamesWithTime1': stopNamesWithTime1,
      'stopNamesWithTime2': stopNamesWithTime2,
      'error': null,
    };
  }

  void _updateNearestStop(List<dynamic> stops) {
    int? nearestIndex;
    // ✅ P0：改用 State 成員 _nearestStop，不再寫入 top-level 變數。
    _nearestStop = null;
    try {
      final loc = Provider.of<LocationProvider>(context, listen: false);
      double minDist = double.infinity;

      for (int i = 0; i < stops.length; i++) {
        final pos = stops[i]['StopPosition'];
        if (pos?['PositionLat'] != null && pos?['PositionLon'] != null) {
          final dist = calculateApproxDistance(
            loc.latitude,
            loc.longitude,
            pos['PositionLat'],
            pos['PositionLon'],
          );
          if (dist < minDist) {
            minDist = dist;
            nearestIndex = i;
          }
        }
      }

      if (nearestIndex != null && minDist <= 7000) {
        _nearestStop = stops[nearestIndex]['stopName'];
      } else {
        _nearestStop = null;
        nearestIndex = null;
      }
    } catch (e) {
      debugPrint("⚠️ 定位獲取失敗: $e");
    }
    _nearestIndexForScroll = nearestIndex;
  }

  void _scrollToHighlightOrNearest(List<dynamic> stops) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final highlight = widget.mark?.highlight;
      if (highlight != null && highlight.isNotEmpty) {
        final idx = stops.indexWhere((e) => e['stopName'] == highlight.first);
        if (idx != -1) {
          // ✅ P0：移除只寫不讀的 globalHighlightedIndex。
          _scrollToIndex(idx);
          return;
        }
      }
      if (_nearestIndexForScroll != null) {
        _scrollToIndex(_nearestIndexForScroll!);
      }
    });
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final colors = context.appColors;

    return PopupMenuItem<String>(
      value: value,
      height: 70,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDevelopmentDialog(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: AppThemes.getSurface(context),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    size: 30,
                    color: Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$featureName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.text_32,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.appColors.mutedBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addRouteToFavorites(List routeInfo) async {
    favorite_feature dbHelper = favorite_feature();

    final result = await dbHelper.addFavoriteRoute(widget.data);

    if (!mounted) return;

    if (result == 100) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: AppLocalizations.of(context)!.text_341,
        text: '${routeInfo[0]} 已加入收藏',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
        animType: QuickAlertAnimType.slideInUp,
      );
    } else if (result == -1) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: AppLocalizations.of(context)!.text_342,
        text: '${routeInfo[0]} 已在收藏列表中',
        confirmBtnColor: const Color(0xFFFF9500),
      );
    } else if (result == 200) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: AppLocalizations.of(context)!.text_343,
        text: AppLocalizations.of(context)!.text_299,
        confirmBtnColor: const Color(0xFFFF3B30),
      );
    }
  }

  void _showRouteMapDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemes.getSurface(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.text_227,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appColors.mutedBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Linkify(
                    onOpen: (link) async {
                      if (!await launchUrl(Uri.parse(link.url))) {
                        throw Exception('Could not launch ${link.url}');
                      }
                    },
                    text: widget.routeMapImageUrl,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    linkStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.appColors.mutedBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 每日預定班表（TDX DailyStopTimeTable）。與本頁的預估到站時間分開顯示。
  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BusSchedulePage(
          city: widget.city?.toString() ?? '',
          routeName: widget.routeName?.toString() ?? '',
          routeId: widget.routeID,
        ),
      ),
    );
  }

  void _navigateToBusDetail() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BusDetailPage(
          routeId: widget.routeID.toString(),
          city: widget.city,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          Provider.of<MarkerProvider>(context, listen: false).setMarkers({});
          Provider.of<PolylineProvider>(context, listen: false)
              .clearPolylines();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _dataNotifier,
        builder: (context, data, child) {
          if (data == null) {
            return Scaffold(body: const AppLoading());
          }

          final error = data['error'];
          if (error != null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.routeName?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: _buildErrorState(error.toString()),
            );
          }

          final routeInfo = data['routeInfo'] as List;
          final stops1 = data['stopNamesWithTime1'] as List;
          final stops2 = data['stopNamesWithTime2'] as List;

          return Stack(
            children: [
              const Positioned.fill(child: map()),
              DraggableScrollableSheet(
                initialChildSize: 1,
                minChildSize: 0.2,
                maxChildSize: 1.0,
                builder: (BuildContext context,
                    ScrollController scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: DefaultTabController(
                        length: _tabController.length,
                        child: Scaffold(
                          appBar: AppCustomBar(
                            title: routeInfo[0],
                            bottom: _buildTabBar(routeInfo),

                            actions: [
                              Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 20,
                                  ),
                                  iconColor: colorScheme.primary,
                                  color: colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                  elevation: 8,
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    _buildPopupMenuItem(
                                      icon: Icons.info_outline_rounded,
                                      title: AppLocalizations.of(context)!.text_16,
                                      subtitle: AppLocalizations.of(context)!.text_344,
                                      value: 'A',
                                    ),
                                    _buildPopupMenuItem(
                                      icon: Icons.favorite_outline_rounded,
                                      title: AppLocalizations.of(context)!.text_334,
                                      subtitle: AppLocalizations.of(context)!.text_345,
                                      value: 'B',
                                    ),
                                    _buildPopupMenuItem(
                                      icon: Icons.map_rounded,
                                      title: AppLocalizations.of(context)!.text_227,
                                      subtitle: AppLocalizations.of(context)!.text_346,
                                      value: 'C',
                                    ),
                                    _buildPopupMenuItem(
                                      icon: Icons.history_rounded,
                                      title: AppLocalizations.of(context)!.text_347,
                                      subtitle: AppLocalizations.of(context)!.text_348,
                                      value: 'D',
                                    ),
                                    _buildPopupMenuItem(
                                      icon: Icons.schedule_rounded,
                                      title: AppLocalizations.of(context)!.busScheduleMenuTitle,
                                      subtitle: AppLocalizations.of(context)!.busScheduleMenuSubtitle,
                                      value: 'E',
                                    ),
                                  ],
                                  onSelected: (String action) async {
                                    switch (action) {
                                      case 'A':
                                        _showDevelopmentDialog(
                                            AppLocalizations.of(context)!.text_16);
                                        break;
                                      case 'B':
                                        await _addRouteToFavorites(routeInfo);
                                        break;
                                      case 'C':
                                        _showRouteMapDialog();
                                        break;
                                      case 'D':
                                        _navigateToBusDetail();
                                        break;
                                      case 'E':
                                        _navigateToSchedule();
                                        break;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          body: Stack(
                            children: [
                              Container(
                                color: colorScheme.surface,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: widget.hasSubRoutes
                                      ? [
                                    _buildTabContent(stops1),
                                    _buildTabContent(stops2),
                                  ]
                                      : [
                                    _buildTabContent(stops1),
                                  ],
                                ),
                              ),
                              if (isTimerOn.value == false)
                                Positioned(
                                  bottom: 12,
                                  left: 16,
                                  right: 16,
                                  child: Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 8,
                                          sigmaY: 8,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[700]!.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.pause_circle_filled_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  AppLocalizations.of(context)!.text_349,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else if (isTimerOn.value == true)
                                Positioned(
                                  bottom: 12,
                                  left: 16,
                                  right: 16,
                                  child: Center(
                                    child: ValueListenableBuilder<int>(
                                      valueListenable: remainingSecondsNotifier,
                                      builder: (context, remainingTime, child) {
                                        final isWarning = remainingTime <= 10;

                                        return GestureDetector(
                                          onTap: () {
                                            _loadData();
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 8,
                                                sigmaY: 8,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (isWarning
                                                      ? const Color(0xFFFF9500)
                                                      : Theme.of(context).colorScheme.primary)
                                                      .withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isWarning
                                                          ? Icons.warning_amber_rounded
                                                          : Icons.autorenew_rounded,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "$remainingTime 秒",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );;
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.text_338,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            // 原始例外（含 API URL）只在 Debug 顯示，不給一般使用者看。
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              // 原本誤用 text_44（「關閉」），按鈕實際動作是重新載入。
              label: Text(AppLocalizations.of(context)!.text_420),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildTabBar(List routeInfo) {
    final tab0Dir = _tabDirections.isNotEmpty ? _tabDirections[0] : 1;
    final tab0Text = (tab0Dir == 0) ? routeInfo[2] : routeInfo[1];

    final tab1Dir = _tabDirections.length > 1 ? _tabDirections[1] : 0;
    final tab1Text = (tab1Dir == 1) ? routeInfo[1] : routeInfo[2];

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SizedBox(
        height: 80, // 強制內部高度 = 80
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16), // 移除 vertical
            decoration: BoxDecoration(
              color: AppThemes.getSurface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (stopNamesWithTime1.isNotEmpty)
                  Expanded(
                    child: _buildTabButton(
                      icon: Icons.directions_bus,
                      text: tab0Text,
                      isSelected: _tabController.index == 0,
                      onTap: () => _tabController.animateTo(0),
                    ),
                  ),
                const SizedBox(width: 12),
                if (widget.hasSubRoutes && stopNamesWithTime2.isNotEmpty)
                  Expanded(
                    child: _buildTabButton(
                      icon: Icons.swap_horiz,
                      text: tab1Text,
                      isSelected: _tabController.index == 1,
                      onTap: () => _tabController.animateTo(1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 64, // 固定高度，避免溢出
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 關鍵：避免撐開
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTabContent(List stopNamesWithTime) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        _vm.restartCountdownIfLive();
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 40),
        controller: _scrollController,
        itemCount: stopNamesWithTime.length,
        itemBuilder: (context, index) {
          final stop = stopNamesWithTime[index];
          final PlateNumb = stop["PlateNumb"];

          final ArrivalStatus status =

              stop['arrivalStatus'] as ArrivalStatus? ?? ArrivalStatus.ended;

          final arrivalColors = context.arrivalColors;

          return Container(
            key: ValueKey(stop['StopUID'] ?? index.toString()),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            height: _stopItemHeight,
            child: ListTile(
              onTap: () {
                _dialogBuilder(context, PlateNumb, stop["stopName"],
                    stop["Estimates"], stop);
              },
              leading: ArrivalChip(
                status: status,
                label: stop["nextBusTime"] ?? '',
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      stop["displayStopName"] ?? stop["stopName"]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(

                        fontSize: stop["isHighlighted"] == true ? 18 : 17,
                        fontWeight: stop["isHighlighted"] == true
                            ? FontWeight.w900
                            : (status == ArrivalStatus.arriving
                            ? FontWeight.w600
                            : FontWeight.normal),
                        // 高亮站使用 Token（深色模式 #1565C0 對近黑底只有 3.42:1）
                        color: stop["isHighlighted"] == true
                            ? arrivalColors.highlight
                            : (status.isInactive
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface),
                        letterSpacing:
                        stop["isHighlighted"] == true ? 1.0 : 0.5,
                        shadows: stop["isHighlighted"] == true
                            ? [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2.0,
                            color: arrivalColors.highlight.withValues(alpha: 0.4),
                          )
                        ]
                            : [],
                      ),
                    ),
                  ),
                  // ✅ P0：改用 State 成員 _nearestStop。
                  if (_nearestStop != null)
                    if (stop["stopName"] == _nearestStop) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(13, 168, 255, 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color.fromRGBO(13, 168, 255, 0.6)),
                        ),
                        child: Text(
                          l10n.text_350,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(13, 168, 255, 1),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
              trailing:
              PlateNumb != null ? bubble(plateNum: PlateNumb) : null,
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            color: colorScheme.outlineVariant,
            height: _stopSeparatorHeight,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          );
        },
      ),
    );
  }

  Future<void> _dialogBuilder(
      BuildContext context, plateNumb, stopName, estimates, stop) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: SurfaceDecoration.dialog(context),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogHeader(
                      stop["displayStopName"] ?? stopName.toString(),
                    ),
                    const SizedBox(height: 24),
                    _buildDialogOptions(context, estimates, stopName, stop),
                    const SizedBox(height: 24),
                    _buildCloseButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(String stopName) {
    final colors = context.appColors;
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: SurfaceDecoration.muted(context, radius: 15),
          child: Icon(
            Icons.directions_bus,
            size: 30,
            color: colors.info,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stopName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.info,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.text_351,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  Widget _buildDialogOptions(BuildContext context, estimates, stopName, stop) {
    return Column(
      children: [
        _buildDialogOption(
          context: context,
          icon: Icons.schedule_outlined,
          title: AppLocalizations.of(context)!.text_352,
          subtitle: AppLocalizations.of(context)!.text_353,
          type: "info",
          data: {'estimates': estimates},
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.place_outlined,
          title: AppLocalizations.of(context)!.text_354,
          subtitle: AppLocalizations.of(context)!.text_355,
          type: "stop",
          data: {"stop": stopName},
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.notifications_outlined,
          title: AppLocalizations.of(context)!.text_356,
          subtitle: AppLocalizations.of(context)!.text_357,
          type: "notification",
          data: stop,
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.favorite_outline,
          title: AppLocalizations.of(context)!.text_334,
          subtitle: AppLocalizations.of(context)!.text_358,
          type: "favorite",
          data: {"id": stopName},
        ),
        const SizedBox(height: 12),
        _buildDialogOption(
          context: context,
          icon: Icons.route_outlined,
          title: AppLocalizations.of(context)!.text_359,
          subtitle: AppLocalizations.of(context)!.text_360,
          type: "route",
          data: {},
        ),
      ],
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String type,
    required Map<String, dynamic> data,
  }) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleOptionTap(context, type, data),
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.info.withOpacity(0.1),
        highlightColor: colors.mutedBackground,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: SurfaceDecoration.outlined(context),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: SurfaceDecoration.muted(context),
                child: Icon(
                  icon,
                  size: 20,
                  color: colors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.text_44,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _handleOptionTap(
      BuildContext context, String type, Map<String, dynamic> data) {
    switch (type) {
      case "info":
        _showNextBusInfo(context, data['estimates']);
        break;
      case "stop":
        _navigateToStopInfo(context, data['stop']);
        break;
      case "notification":
        _setupArrivalNotification(context, data);
        break;
      case "favorite":
        _addToFavorites(context, data['id']);
        break;
      case "route":
        _navigateToRoutePlanning(context);
        break;
    }
  }

  void _showNextBusInfo(BuildContext context, dynamic estimates) {
    final estimatesList = BusEstimatesParser.parse(estimates?.toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 2,
            title: Text(
              AppLocalizations.of(context)!.text_352,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          ),
          body: estimatesList.isNotEmpty
              ? ListView.builder(
            itemCount: estimatesList.length,
            itemBuilder: (context, index) {
              final bus = estimatesList[index];
              return Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus,
                        color: Colors.blue),
                  ),
                  title: Text(
                    '公車 ${bus["PlateNumb"] ?? AppLocalizations.of(context)!.text_321}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '預估時間: ${((bus["EstimateTime"] ?? 0) / 60).round()} 分鐘',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  trailing: (bus["IsLastBus"] ?? false)
                      ? const Icon(Icons.warning, color: Colors.red)
                      : const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ),
              );
            },
          )
              : Center(
            child: Text(
              AppLocalizations.of(context)!.text_361,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToStopInfo(BuildContext context, String stopName) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BusStopInfo(
              stopName,
              city: widget.city,
            )));
  }

  Future<void> _setupArrivalNotification(
      BuildContext context,
      dynamic stop,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    final stopId =
    (stop['StopID'] ?? stop['StopId'] ?? stop['stopID'])?.toString();

    final stopName =
    (stop['stopName'] ?? stop['StopName'] ?? stop['name'])?.toString();

    if (stopId == null ||
        stopId.isEmpty ||
        stopName == null ||
        stopName.isEmpty) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('站牌資料不完整，無法建立提醒')),
      );
      return;
    }

    Navigator.of(context).pop();

    try {
      await startReminder(
        transportType: 'bus',
        routeName: _tdxRouteName(
          widget.data,
          widget.routeName,
        ),
        routeID: widget.routeID.toString(),
        city: widget.city,
        stopID: stopId,
        UserStartingStopName: '',
        UserDestinationStopName: stopName,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text('已設定到站提醒：$stopName'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('建立公車到站提醒失敗：$e');
      debugPrintStack(stackTrace: stackTrace);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('提醒設定失敗，請稍後再試'),
        ),
      );
    }
  }

  Future<void> _addToFavorites(BuildContext context, String stopName) async {
    final dbHelper = favorite_feature();
    try {
      final result = await dbHelper.addFavoriteStop(
        stopName: stopName,
        city: widget.city,
      );

      if (!context.mounted) return;

      if (result == 100) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: AppLocalizations.of(context)!.text_341,
          text: '$stopName 已加入收藏',
          confirmBtnColor: Theme.of(context).colorScheme.primary,
        );
      } else if (result == -1) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: AppLocalizations.of(context)!.text_342,
          text: '$stopName 已在收藏列表中',
          confirmBtnColor: const Color(0xFFFF9500),
        );
      } else if (result == 200) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: AppLocalizations.of(context)!.text_343,
          text: AppLocalizations.of(context)!.text_299,
          confirmBtnColor: const Color(0xFFFF3B30),
        );
      }
    } catch (e, st) {
      debugPrint('add favorite stop failed: $e\n$st');
      if (context.mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: AppLocalizations.of(context)!.text_299,
        );
      }
    }
  }

  void _navigateToRoutePlanning(BuildContext context) {
    Navigator.of(context).pop();
  }
}
