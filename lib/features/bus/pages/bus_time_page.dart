import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:com.rsmn574.app/features/bus/widgets/bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/database/sql/favorite_feature.dart';
import 'package:com.rsmn574.app/features/bus/data/get_bus_time.dart';
import 'package:com.rsmn574.app/features/bus/data/bus_position_estimator.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';
import 'package:com.rsmn574.app/task/task.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/widget/map.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_stop_info_page.dart';

import '../../../widget/AppLoading.dart';

late String? nearestStop;

class Mark {
  final List<dynamic>? highlight;

  /// TDX 的實際 Direction（0 / 1），不是 Tab 索引。
  final int? direction;

  Mark({this.highlight, this.direction});
  // 從 Map 創建 Mark 的工廠構造函數
  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      highlight: map['highlight'] ?? [],
      direction: map['direction'] ?? 0,
    );
  }
}

int globalHighlightedIndex = 0;

bool _isEnglishLocale(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

String _localizedBusText(dynamic value, {required bool isEnglish}) {
  if (value is! Map) return value?.toString() ?? '';

  final preferred = value[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;

  return value[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
}

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

  const BusTime(
      {Key? key,
        required this.routeName,
        required this.routeID,
        this.departureStopName,
        this.destinationStopName,
        this.operators,
        this.routeMapImageUrl,
        required this.city,
        this.mark,
        required this.hasSubRoutes,
        required this.data})
      : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime> with SingleTickerProviderStateMixin {
  ValueNotifier<int> remainingSecondsNotifier = ValueNotifier(40);
  final ScrollController _scrollController = ScrollController();
  List<dynamic> stopNamesWithTime1 = [];
  List<dynamic> stopNamesWithTime2 = [];
  late final TabController _tabController;
  final Set<Marker> markers = {};
  final Set<Marker> _stopMarkers = {};
  final Set<Marker> _busMarkers = {};
  Timer? _timer;
  Timer? _busPositionTimer;
  bool _isLoadingBusPositions = false;
  final BusPositionEstimator _busPositionEstimator = const BusPositionEstimator();
  final Map<int, List<LatLng>> _routePointsByDirection = {};
  int _busPositionRequestId = 0;
  bool _initialDirectionApplied = false;
  final ValueNotifier<String> _directionNotifier = ValueNotifier("");
  final ValueNotifier<Map<String, dynamic>?> _dataNotifier =
  ValueNotifier(null);
  ValueNotifier<bool> isTimerOn = ValueNotifier(false);

  // 儲存 Tab 索引與實際 TDX Direction 的對應關係
  List<int> _tabDirections = [0];
  // 避免 Async Race Condition 的請求世代計數器
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();

    if (widget.hasSubRoutes == false) {
      _tabController = TabController(length: 1, vsync: this);
      // 單 Tab 優先採用傳入的 mark.direction，沒有才預設 1
      _tabDirections = [widget.mark?.direction ?? 1];
    } else {
      _tabController = TabController(length: 2, vsync: this);
      _tabDirections = [1, 0];
    }

    _tabController.addListener(_handleTabChange);
    _loadData();
    // 車輛位置獨立更新，不必重載站牌與路線資料。
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

    final currentTabIndex = _tabController.index.clamp(0, _tabDirections.length - 1);
    final currentDirection = _tabDirections[currentTabIndex];
    final currentStops = (currentTabIndex == 0) ? stopNamesWithTime1 : stopNamesWithTime2;

    _loadShape(currentDirection);
    _loadMarkers(currentStops);
    _loadBusPositions(currentDirection);
  }

  void _scrollToIndex(int index) {
    const itemHeight = 54.5;
    const separatorHeight = 9.0;
    final scrollPosition = (itemHeight + separatorHeight) * index;
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
    try {
      final data = await getShape(
        widget.city,
        _tdxRouteName(widget.data, widget.routeName),
        widget.routeID,
      );

      if (!mounted) return {};

      final Set<Polyline> polylines = {};

      for (final item in data) {
        final d = item['Direction'];
        final itemDir = (d is int) ? d : int.tryParse(d?.toString() ?? '');
        if (itemDir != direction) continue;

        final encoded = item['EncodedPolyline'];
        if (encoded is! String || encoded.isEmpty) continue;

        final decodedPoints = decodePolyline(encoded);
        if (decodedPoints.length < 2) continue;

        // 保留方向對應的路線座標，供公車位置推估使用。
        // 若同方向有多筆 Shape，選擇第一條有效完整線形；不任意拼接不相連的線段。
        _routePointsByDirection.putIfAbsent(direction, () => decodedPoints);

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

      context.read<PolylineProvider>().setPolylines(polylines);
      return polylines;
    } catch (e, stack) {
      debugPrint('Load Shape Error: $e');
      debugPrintStack(stackTrace: stack);

      if (mounted) {
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

  /// 解析可確認的座標／速度／時間欄位；欄位缺失時只顯示原始 GPS，避免假造推估值。
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

  /// 每次更新車輛 Marker；資料不足時回退至真實 GPS，不執行位置外推。
  Future<void> _loadBusPositions(int direction) async {
    if (_isLoadingBusPositions || !mounted) return;
    _isLoadingBusPositions = true;
    final requestId = ++_busPositionRequestId;

    try {
      final response = await fetchBusRealtimePosition(
        _tdxRouteName(widget.data, widget.routeName),
        widget.city,
        widget.routeID,
      );

      if (!mounted || requestId != _busPositionRequestId) return;

      final now = DateTime.now();
      final routePoints = _routePointsByDirection[direction] ?? const <LatLng>[];
      final nextMarkers = <Marker>{};

      for (final bus in response) {
        final rawDirection = bus['Direction'];
        final busDirection = rawDirection is int
            ? rawDirection
            : int.tryParse(rawDirection?.toString() ?? '');
        if (busDirection != null && busDirection != direction) continue;

        final dynamic rawPosition = bus['BusPosition'] ??
            bus['Position'] ??
            bus['GPSPosition'];
        final Map position = rawPosition is Map ? rawPosition : bus;

        // 僅解析實際存在且可轉換的座標欄位，不將缺值補成 0。
        final lat = _numberFrom(position['PositionLat'] ??
            position['Latitude'] ?? position['latitude']);
        final lon = _numberFrom(position['PositionLon'] ??
            position['Longitude'] ?? position['longitude']);
        if (lat == null || lon == null ||
            !lat.isFinite || !lon.isFinite ||
            lat < -90 || lat > 90 || lon < -180 || lon > 180) {
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
          bus['GPSTime'] ?? bus['GpsTime'] ?? bus['UpdateTime'] ??
              bus['SrcRecTime'] ?? bus['SrcTransTime'],
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
            bus['BusID']?.toString() ?? plate ?? '${lat}_$lon';
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
              snippet: '路線：${_tdxRouteName(widget.data, widget.routeName)} · $statusText',
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
      // API 失敗時保留既有 Marker，不讓短暫網路錯誤清空地圖。
      debugPrint('載入即時公車位置失敗：$e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoadingBusPositions = false;
    }
  }

  void _startAutoReload() {
    _timer?.cancel();
    remainingSecondsNotifier.value = 40;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSecondsNotifier.value > 1) {
        remainingSecondsNotifier.value = remainingSecondsNotifier.value - 1;
      } else {
        remainingSecondsNotifier.value = 40;
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _busPositionTimer?.cancel();
    _busPositionRequestId++;
    _tabController.removeListener(_handleTabChange);
    _scrollController.dispose();
    _directionNotifier.dispose();
    _dataNotifier.dispose();
    remainingSecondsNotifier.dispose();
    isTimerOn.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final int requestId = ++_loadRequestId;

    try {
      // 1. 下載基礎資料
      final List<Map<String, dynamic>> routeStopsData = await getBusStopOfRoute(
        city: widget.city,
        routeId: widget.routeID,
      );
      final busTimeData = await fetchBusTime(
        _tdxRouteName(widget.data, widget.routeName),
        widget.city,
        widget.routeID,
      );

      if (requestId != _loadRequestId || !mounted) return;

      // 2. 解析路線資料中實際存在的 Direction 集合
      final Set<int> availableDirsSet = {};
      for (var item in routeStopsData) {
        final d = item['Direction'];
        final parsedDir = (d is int) ? d : int.tryParse(d?.toString() ?? '');
        if (parsedDir != null) {
          availableDirsSet.add(parsedDir);
        }
      }
      // 2. 解析路線資料中實際存在的 Direction 集合（保留 API 原始回傳順序，不使用 ..sort()）
      final List<int> availableDirs = [];
      for (var item in routeStopsData) {
        final d = item['Direction'];
        final parsedDir = (d is int) ? d : int.tryParse(d?.toString() ?? '');
        if (parsedDir != null && !availableDirs.contains(parsedDir)) {
          availableDirs.add(parsedDir);
        }
      }

      // 3. 根據實際資料建立 Tab 與 Direction 的對應關係
      if (widget.hasSubRoutes == false) {
        // 單 Tab：使用實際資料中唯一存在的 Direction
        if (availableDirs.isNotEmpty) {
          _tabDirections = [availableDirs.first];
        } else {
          _tabDirections = [1];
        }
      } else {
        // 雙 Tab：若同時包含 1 與 0，維持 Tab 0 = Direction 1、Tab 1 = Direction 0
        if (availableDirs.contains(1) && availableDirs.contains(0)) {
          _tabDirections = [1, 0];
        } else if (availableDirs.length >= 2) {
          _tabDirections = availableDirs.sublist(0, 2);
        } else if (availableDirs.length == 1) {
          _tabDirections = [availableDirs.first, availableDirs.first == 1 ? 0 : 1];
        } else {
          _tabDirections = [1, 0];
        }
      }
      // 4. 設定初始 Tab (依據外部傳入之實際 Direction)
      final int? targetDirection = widget.mark?.direction;
      if (!_initialDirectionApplied && targetDirection != null) {
        final targetIndex = _tabDirections.indexOf(targetDirection);
        if (targetIndex != -1 && targetIndex < _tabController.length) {
          _tabController.animateTo(targetIndex);
        }
      }
      _initialDirectionApplied = true;

      // 5. 依據對應 Direction 獲取資料
      stopNamesWithTime1 = await fetchStopNamesWithTime(
        _tabDirections[0],
        busTimeData,
        routeStopsData,
      );

      if (_tabDirections.length > 1) {
        stopNamesWithTime2 = await fetchStopNamesWithTime(
          _tabDirections[1],
          busTimeData,
          routeStopsData,
        );
      } else {
        stopNamesWithTime2 = [];
      }

      if (requestId != _loadRequestId || !mounted) return;

      // 6. 確定當前選中的 Tab 及 Direction
      final int currentTabIndex = _tabController.index.clamp(0, _tabDirections.length - 1);
      final int currentDirection = _tabDirections[currentTabIndex];
      final List<dynamic> currentStops =
      currentTabIndex == 0 ? stopNamesWithTime1 : stopNamesWithTime2;

      // 7. 最近站點定位邏輯
      int? nearestIndex;
      try {
        final loc = Provider.of<LocationProvider>(context, listen: false);
        double minDist = double.infinity;

        for (int i = 0; i < currentStops.length; i++) {
          final pos = currentStops[i]['StopPosition'];
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
          nearestStop = currentStops[nearestIndex]['stopName'];
        } else {
          nearestStop = null;
          nearestIndex = null;
        }
      } catch (e) {
        debugPrint("⚠️ 定位獲取失敗: $e");
      }

      void safeScrollToIndex(int index) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(index);
        });
      }

      if (widget.mark?.highlight?.isNotEmpty ?? false) {
        final String highlightStation = widget.mark!.highlight!.first;
        final int hIndex =
        currentStops.indexWhere((e) => e["stopName"] == highlightStation);

        if (hIndex != -1) {
          globalHighlightedIndex = hIndex;
          safeScrollToIndex(hIndex);
        }
      } else if (nearestIndex != null) {
        safeScrollToIndex(nearestIndex);
      }

      if (isTimerOn.value) _startAutoReload();

      // 8. 載入當前選定方向的 Marker 與 Shape
      _loadMarkers(currentStops);
      _loadShape(currentDirection);
      _loadBusPositions(currentDirection);

      // 9. 通知 UI 更新
      final isEnglish = _isEnglishLocale(context);
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
      };
    } catch (e, s) {
      debugPrint("❌ _loadData 發生重大錯誤: $e\n$s");
    }
  }

  Future<List<Map<String, dynamic>>> fetchStopNamesWithTime(
      int direction,
      List<dynamic> busTimeData,
      List<Map<String, dynamic>> routeStopsData) async {
    List<Map<String, dynamic>> stopNamesWithTime = [];
    String hasPlateNum = "";

    // 尋找對應 Direction 的路線站點資料
    Map<String, dynamic>? targetRouteStop;
    for (var item in routeStopsData) {
      final d = item['Direction'];
      final parsedDir = (d is int) ? d : int.tryParse(d?.toString() ?? '');
      if (parsedDir == direction) {
        targetRouteStop = item;
        break;
      }
    }

    if (targetRouteStop == null || targetRouteStop["Stops"] == null) {
      return stopNamesWithTime; // 回傳空列表，不進行錯誤 fallback
    }

    List<dynamic> stopData;
    try {
      stopData = json.decode(targetRouteStop["Stops"]);
    } catch (e) {
      debugPrint("Decode Stops Error: $e");
      return stopNamesWithTime;
    }

    // 精確過濾該 Direction 的動態到站時間資料
    final dirBusTimeData = busTimeData.where((s) {
      final d = s['Direction'];
      final parsedDir = (d is int) ? d : int.tryParse(d?.toString() ?? '');
      return parsedDir == direction;
    }).toList();

    final isEnglish = _isEnglishLocale(context);

    for (var stop in stopData) {
      final stopName = _localizedBusText(
        stop["StopName"],
        isEnglish: false,
      );
      final displayStopName = _localizedBusText(
        stop["StopName"],
        isEnglish: isEnglish,
      );
      String stopUID = stop["StopUID"] ?? '';

      Map<String, dynamic> nextBusTime = await getTimeList(
          stopUID, dirBusTimeData);

      bool isHighlighted = false;
      if (widget.mark != null && widget.mark!.highlight != null) {
        final markDir = widget.mark!.direction;
        isHighlighted = widget.mark!.highlight!.contains(stopName) &&
            markDir == direction;
      }

      final plate = nextBusTime["PlateNumb"] ?? '';
      String displayPlate = '';
      if (plate.isNotEmpty) {
        if (hasPlateNum != plate) {
          hasPlateNum = plate;
          displayPlate = plate;
        }
      }

      stopNamesWithTime.add({
        "stopName": stopName,
        "displayStopName": displayStopName,
        "nextBusTime": nextBusTime["time"],
        'color': nextBusTime["color"],
        "PlateNumb": displayPlate,
        "Estimates": nextBusTime["Estimates"].toString(),
        "StopPosition": stop["StopPosition"],
        "StopID": stop['StopID'],
        "StopUID": stopUID,
        "isHighlighted": isHighlighted
      });
    }

    return stopNamesWithTime;
  }

  Future<Map<String, dynamic>> getTimeList(String stopUID, List<dynamic> busTimeData) async {
    final stop = busTimeData.firstWhere(
          (s) => s['StopUID'] == stopUID,
      orElse: () => null,
    );

    if (busTimeData.isEmpty || stop == null) {
      return _buildResult(AppLocalizations.of(context)!.text_339,
          AppLocalizations.of(context)!.text_317, "", null);
    }

    if (stop["EstimateTime"] != null) {
      isTimerOn.value = true;
      int estimateTime = stop["EstimateTime"];

      if (estimateTime == 0) {
        return _buildResult(AppLocalizations.of(context)!.text_316, "0",
            stop["PlateNumb"] ?? "", stop);
      }

      int result = (estimateTime / 60).floor();
      return _buildResult(
        result < 1 ? AppLocalizations.of(context)!.text_316 : AppLocalizations.of(context)!.nearStopMinutes(result.toString()),
        result < 3 ? "2" : "min",
        result < 3 ? (stop["PlateNumb"] ?? "") : "",
        stop,
      );
    }

    if (stop["NextBusTime"] != null) {
      try {
        DateTime nextBusTime =
        DateTime.parse(stop["NextBusTime"]).toLocal();
        Duration difference = nextBusTime.difference(DateTime.now());

        int totalMinutes = difference.inMinutes;

        if (totalMinutes < 0) {
          return _buildResult(
              totalMinutes > -5
                  ? AppLocalizations.of(context)!.text_340
                  : AppLocalizations.of(context)!.text_317,
              AppLocalizations.of(context)!.text_317,
              "",
              stop);
        } else if (totalMinutes < 60) {
          isTimerOn.value = true;

          if (totalMinutes < 1) {
            return _buildResult(AppLocalizations.of(context)!.text_316, "0",
                stop["PlateNumb"] ?? "", stop);
          } else if (totalMinutes < 3) {
            return _buildResult(
                "$totalMinutes 分鐘", "2", stop["PlateNumb"] ?? "", stop);
          } else {
            return _buildResult( AppLocalizations.of(context)!.nearStopMinutes(totalMinutes.toString()), "min", "", stop);
          }
        } else {
          String formattedTime =
              "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}";
          return _buildResult(formattedTime, "", "", stop);
        }
      } catch (_) {}
    }

    return _buildResult(AppLocalizations.of(context)!.text_317,
        AppLocalizations.of(context)!.text_317, "", stop);
  }

  Map<String, dynamic> _buildResult(
      String time, String color, String plateNumb, dynamic stop) {
    if (stop == null) {
      return {
        "time": time,
        "color": color,
        "PlateNumb": plateNumb,
        "Estimates": "",
        "StopPosition": "",
        "StopID": "",
      };
    }
    return {
      "time": time,
      "color": color,
      "PlateNumb": plateNumb,
      "Estimates": stop["Estimates"] ?? "",
      "StopPosition": stop["StopPosition"]?.toString() ?? "",
      "StopID": stop['StopID'] ?? "",
    };
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 70,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A73E8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
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
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A73E8),
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

    if (result == 100) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: AppLocalizations.of(context)!.text_341,
        text: '${routeInfo[0]} 已加入收藏',
        confirmBtnColor: const Color(0xFF1A73E8),
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
              color: Colors.white,
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
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    size: 30,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.text_227,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Linkify(
                    onOpen: (link) async {
                      if (!await launchUrl(Uri.parse(link.url))) {
                        throw Exception('Could not launch ${link.url}');
                      }
                    },
                    text: widget.routeMapImageUrl,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.w500,
                    ),
                    linkStyle: const TextStyle(
                      color: Color(0xFF1A73E8),
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
                          color: const Color(0xFFEEF3FB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.text_44,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A73E8),
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
              return Scaffold(
                body:  const AppLoading(),
              );
            }

            final routeInfo = data['routeInfo'] as List;
            final stopNamesWithTime1 = data['stopNamesWithTime1'] as List;
            final stopNamesWithTime2 = data['stopNamesWithTime2'] as List;

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
                                  appBar: AppBar(
                                    elevation: 0,
                                    leading: Container(
                                      height: 150,
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                            Brightness.dark
                                            ? Color(0xFF2C2C2C)
                                            : Color(0xFFEEF3FB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.arrow_back_ios_rounded,
                                            size: 20),
                                        color: const Color(0xFF1A73E8),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                    toolbarHeight: kToolbarHeight,
                                    title: Text(
                                      routeInfo[0],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A73E8),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    centerTitle: true,
                                    actions: [
                                      Container(
                                        margin: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                              Brightness.dark
                                              ? Color(0xFF2C2C2C)
                                              : Color(0xFFEEF3FB),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(
                                              Icons.more_vert_rounded,
                                              size: 20,
                                              color: Color(0xFF1A73E8)),
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(16),
                                          ),
                                          elevation: 8,
                                          itemBuilder: (BuildContext context) =>
                                          <PopupMenuItem<String>>[
                                            _buildPopupMenuItem(
                                              icon: Icons.info_outline_rounded,
                                              title:
                                              AppLocalizations.of(context)!
                                                  .text_16,
                                              subtitle:
                                              AppLocalizations.of(context)!
                                                  .text_344,
                                              value: 'A',
                                            ),
                                            _buildPopupMenuItem(
                                              icon: Icons
                                                  .favorite_outline_rounded,
                                              title:
                                              AppLocalizations.of(context)!
                                                  .text_334,
                                              subtitle:
                                              AppLocalizations.of(context)!
                                                  .text_345,
                                              value: 'B',
                                            ),
                                            _buildPopupMenuItem(
                                              icon: Icons.map_rounded,
                                              title:
                                              AppLocalizations.of(context)!
                                                  .text_227,
                                              subtitle:
                                              AppLocalizations.of(context)!
                                                  .text_346,
                                              value: 'C',
                                            ),
                                            _buildPopupMenuItem(
                                              icon: Icons.history_rounded,
                                              title:
                                              AppLocalizations.of(context)!
                                                  .text_347,
                                              subtitle:
                                              AppLocalizations.of(context)!
                                                  .text_348,
                                              value: 'D',
                                            ),
                                          ],
                                          onSelected: (String action) async {
                                            switch (action) {
                                              case 'A':
                                                _showDevelopmentDialog(
                                                    AppLocalizations.of(
                                                        context)!
                                                        .text_16);
                                                break;
                                              case 'B':
                                                await _addRouteToFavorites(
                                                    routeInfo);
                                                break;
                                              case 'C':
                                                _showRouteMapDialog();
                                                break;
                                              case 'D':
                                                _navigateToBusDetail();
                                                break;
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                    bottom: _buildTabBar(routeInfo),
                                  ),
                                  body: Stack(
                                    children: [
                                      Container(
                                        color: bgColorWhite,
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: widget.hasSubRoutes
                                              ? [
                                            _buildTabContent(
                                                stopNamesWithTime1),
                                            _buildTabContent(
                                                stopNamesWithTime2),
                                          ]
                                              : [
                                            _buildTabContent(
                                                stopNamesWithTime1)
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
                                              borderRadius:
                                              BorderRadius.circular(12),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 8, sigmaY: 8),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[700]!
                                                        .withOpacity(0.7),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .pause_circle_filled_rounded,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Flexible(
                                                          child: Text(
                                                            AppLocalizations.of(
                                                                context)!
                                                                .text_349,
                                                            maxLines: 1,
                                                            overflow: TextOverflow
                                                                .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                              FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          )),
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
                                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 16, vertical: 10),
                                                        decoration: BoxDecoration(
                                                          color: (isWarning
                                                              ? const Color(0xFFFF9500)
                                                              : const Color(0xFF1A73E8))
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
                                        )
                                    ],
                                  ),
                                ),
                              )));
                    })
              ],
            );
          },
        ));
  }

  PreferredSize _buildTabBar(List routeInfo) {
    // 依據 Tab 對應的實際 Direction 決定要顯示起站名還是終點站名
    final tab0Dir = _tabDirections.isNotEmpty ? _tabDirections[0] : 1;
    final tab0Text = (tab0Dir == 0) ? routeInfo[2] : routeInfo[1];

    final tab1Dir = _tabDirections.length > 1 ? _tabDirections[1] : 0;
    final tab1Text = (tab1Dir == 1) ? routeInfo[1] : routeInfo[2];

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF3FB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
              color: const Color(0xFF1A73E8).withOpacity(0.3),
              width: 1.5,
            )
                : Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                  isSelected ? const Color(0xFF1A73E8) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List stopNamesWithTime) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        _startAutoReload();
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 40),
        controller: _scrollController,
        itemCount: stopNamesWithTime.length,
        itemBuilder: (context, index) {
          final stop = stopNamesWithTime[index];
          final PlateNumb = stop["PlateNumb"];

          final color = stop["color"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["color"] == '2'
              ? const Color.fromRGBO(225, 85, 104, 0.1)
              : (stop["color"] == AppLocalizations.of(context)!.text_317
              ? const Color.fromRGBO(69, 69, 69, 0.1)
              : (stop["color"] == "min"
              ? const Color.fromRGBO(13, 168, 255, 0.1)
              : const Color.fromRGBO(68, 68, 68, 0.1))));

          return Container(
              key: ValueKey(stop['StopUID'] ?? index.toString()),
              margin: const EdgeInsets.symmetric(
                horizontal: 4.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              height: 54.5,
              child: ListTile(
                onTap: () {
                  _dialogBuilder(context, PlateNumb, stop["stopName"],
                      stop["Estimates"], stop);
                },
                leading: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    stop["nextBusTime"]!,
                    maxLines: 1,
                    style: TextStyle(
                        fontFamily: 'MiSans-normal',
                        fontSize: 17,
                        color: stop["color"] == '0'
                            ? Colors.white
                            : (stop["color"] == '2'
                            ? const Color.fromRGBO(255, 85, 104, 1)
                            : (stop["color"] ==
                            AppLocalizations.of(context)!.text_317
                            ? const Color.fromRGBO(149, 149, 149, 1.0)
                            : (stop["color"] == "min"
                            ? const Color.fromRGBO(13, 168, 255, 1)
                            : const Color.fromRGBO(
                            68, 68, 68, 1))))),
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                        child: Text(
                          stop["displayStopName"] ?? stop["stopName"]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'MiSans',
                            fontSize: stop["isHighlighted"] == true ? 18 : 17,
                            fontWeight: stop["isHighlighted"] == true
                                ? FontWeight.w900
                                : (stop["color"] == "0"
                                ? FontWeight.w600
                                : FontWeight.normal),
                            color: stop["isHighlighted"] == true
                                ? Colors.blue[800]
                                : (stop["color"] ==
                                AppLocalizations.of(context)!.text_317
                                ? const Color.fromRGBO(136, 136, 136, 1)
                                : Colors.black),
                            letterSpacing:
                            stop["isHighlighted"] == true ? 1.0 : 0.5,
                            shadows: stop["isHighlighted"] == true
                                ? [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2.0,
                                color: Colors.blue.withOpacity(0.5),
                              )
                            ]
                                : [],
                          ),
                        )),
                    if (nearestStop != null)
                      if (stop["stopName"] == nearestStop) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(13, 168, 255, 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Color.fromRGBO(13, 168, 255, 0.6)),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.text_350,
                            maxLines: 1,
                            style: TextStyle(
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
              ));
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            color: Color.fromRGBO(231, 231, 231, 1),
            height: 9,
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
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
                  )),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(String stopName) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FB),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.directions_bus,
            size: 30,
            color: Color(0xFF1A73E8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stopName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A73E8),
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
            color: Colors.grey[600],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleOptionTap(context, type, data),
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
        highlightColor: const Color(0xFFEEF3FB),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
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
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1A73E8).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.text_44,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
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

  void _showNextBusInfo(BuildContext context, estimates) {
    List<Map<String, dynamic>> estimatesList = [];

    if (estimatesList != 'null') {
      try {
        String correctedJsonString = estimates
            .replaceAllMapped(
            RegExp(r'(\w+):'), (match) => '"${match[1]}":')
            .replaceAllMapped(
            RegExp(r'(\d+)(?=,|\})'), (match) => '${match[0]}')
            .replaceAllMapped(RegExp(r'(\w+-\w+)'),
                (match) => '"${match[0]}"')
            .replaceAllMapped(RegExp(r'\"(?!\d)'), (match) => '"')
            .replaceAllMapped(
            RegExp(r'\"(?!\w+-\w+)'), (match) => '"');

        estimatesList =
        List<Map<String, dynamic>>.from(jsonDecode(correctedJsonString));

        if (kDebugMode) {
          print("other" + estimates);
        }
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 2,
            title: Text(
              AppLocalizations.of(context)!.text_352,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
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
                  color: Colors.white,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
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

  Future<void> _setupArrivalNotification(BuildContext context, stop) async {

    Navigator.of(context).pop();
    // await startReminder(
    //   transportType: 'bus',
    //   routeName: _tdxRouteName(widget.data, widget.routeName),
    //   routeID: widget.routeID.toString(),
    //   city: widget.city,
    //   stopID: stop["StopID"],
    //   UserStartingStopName: '',
    //   UserDestinationStopName: stop["stopName"],
    // );
  }

  Future<void> _addToFavorites(BuildContext context, String stopId) async {
    favorite_feature dbHelper = favorite_feature();
    var output;
    final result = await dbHelper.addFavoriteStop(
      stopName: stopId,
      city: widget.city,
    );

    if (result == 100) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: output,
      );
    } else if (result == -1) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: output,
      );
    } else if (result == 200) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Oops...',
        text: output,
      );
    }
  }

  void _navigateToRoutePlanning(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class BusDetailPage extends StatefulWidget {
  final String routeId;
  final String city;

  const BusDetailPage({
    super.key,
    required this.routeId,
    required this.city,
  });

  @override
  State<BusDetailPage> createState() => _BusDetailPageState();
}

class _BusDetailPageState extends State<BusDetailPage> {
  List<Map<String, dynamic>>? allBuses;
  List<Map<String, dynamic>>? filteredBuses;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      List<Map<String, dynamic>> data =
          await getHistoryData(widget.city, widget.routeId, sum!) ?? [];
      setState(() {
        allBuses = data;
        filteredBuses = List.from(data);
      });
    } catch (e) {
      setState(() {
        allBuses = [];
        filteredBuses = [];
      });
    }
  }

  void search(String query) {
    if (allBuses == null) return;

    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    setState(() {
      filteredBuses = allBuses!
          .where((bus) => _localizedBusText(
        bus['StopName'],
        isEnglish: isEnglish,
      ).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatTime(String gpsTime) {
    try {
      DateTime dateTime = DateTime.parse(gpsTime).toLocal();
      return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.text_362;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.text_363,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.text_364,
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged: search,
            ),
          ),
          Expanded(
            child: filteredBuses == null
                ? const Center(
                child: CircularProgressIndicator(color: Colors.blue))
                : filteredBuses!.isEmpty
                ? Center(
              child: Text(
                AppLocalizations.of(context)!.text_365,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredBuses!.length,
              itemBuilder: (context, index) {
                final bus = filteredBuses![index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '公車號碼: ${bus['PlateNumb']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '路線: ${_localizedBusText(
                            bus['RouteName'],
                            isEnglish: Localizations.localeOf(context)
                                .languageCode ==
                                'en',
                          )}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '站點: ${_localizedBusText(
                            bus['StopName'],
                            isEnglish: Localizations.localeOf(context)
                                .languageCode ==
                                'en',
                          )}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '時間: ${formatTime(bus['GPSTime'])}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '方向: ${bus['Direction'] == 0 ? AppLocalizations.of(context)!.text_366 : AppLocalizations.of(context)!.text_367}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}