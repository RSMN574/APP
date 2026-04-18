import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../Const/regularClass.dart';

class map extends StatefulWidget {
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final CameraPosition? initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final Function()? onCameraIdle;
  final bool myLocationEnabled;
  final bool buildingsEnabled;      // 新增：控制 3D 建築
  final bool zoomControlsEnabled;   // 新增：控制縮放按鈕
  final bool compassEnabled;        // 新增：控制指南針
  final bool trafficEnabled;        // 新增：控制交通流量
  final bool indoorViewEnabled;     // 新增：控制室內地圖

  const map({
    Key? key,
    this.markers,
    this.polylines,
    this.initialCameraPosition,
    this.onMapCreated,
    this.myLocationEnabled = true,
    this.buildingsEnabled = false,    // 預設關閉，減少渲染負擔
    this.zoomControlsEnabled = false,
    this.compassEnabled = false,
    this.trafficEnabled = false,
    this.indoorViewEnabled = false,
    this.onCameraMove,
    this.onCameraIdle,
  }) : super(key: key);

  @override
  State<map> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<map>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  GoogleMapController? _mapController;
  Timer? _locationTimer;
  bool _isMapReady = false;

  // 使用快取避免頻繁重建
  Set<Marker>? _cachedMarkers;
  Set<Polyline>? _cachedPolylines;

  static const LatLng _defaultPosition = LatLng(25.0330, 121.5654);
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _defaultPosition,
    zoom: 15,
  );

  LatLng _currentPosition = _defaultPosition;
  bool _hasAnimatedToCurrent = false;

  // 防抖用的 Timer
  Timer? _cameraMoveTimer;
  CameraPosition? _lastCameraPosition;

  final String _mapStyle = '''
[
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didUpdateWidget(map oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 只在必要時更新地圖元素
    if (oldWidget.markers != widget.markers && _isMapReady) {
      _updateMarkersSafely();
    }

    if (oldWidget.polylines != widget.polylines && _isMapReady) {
      _updatePolylinesSafely();
    }
  }

  /// 安全更新標記（使用防抖）
  void _updateMarkersSafely() {
    if (!_isMapReady || !mounted) return;

    // 取消之前的更新
    _cameraMoveTimer?.cancel();

    _cameraMoveTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted && _isMapReady) {
        setState(() {
          // 觸發重建
        });
      }
    });
  }

  /// 安全更新 Polyline
  void _updatePolylinesSafely() {
    if (!_isMapReady || !mounted) return;

    _cameraMoveTimer?.cancel();
    _cameraMoveTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted && _isMapReady) {
        setState(() {});
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (!mounted) return;

      _currentPosition = LatLng(position.latitude, position.longitude);

      if (_mapController != null && !_hasAnimatedToCurrent && _isMapReady) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 15),
        );
        _hasAnimatedToCurrent = true;
      }
    } catch (e) {
      debugPrint('無法獲取位置: $e');
    }
  }

  /// 處理相機移動（加入防抖）
  void _onCameraMove(CameraPosition position) {
    _lastCameraPosition = position;

    // 防抖：避免頻繁觸發
    if (_cameraMoveTimer?.isActive ?? false) {
      _cameraMoveTimer?.cancel();
    }

    _cameraMoveTimer = Timer(const Duration(milliseconds: 16), () {
      if (mounted && widget.onCameraMove != null) {
        widget.onCameraMove!(position);
      }
    });
  }

  /// 處理相機閒置
  void _onCameraIdle() {
    _cameraMoveTimer?.cancel();
    if (mounted && widget.onCameraIdle != null) {
      widget.onCameraIdle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 獲取 markers 和 polylines（使用 select 避免不必要的重建）
    final markers = widget.markers ??
        (context.watch<MarkerProvider>().markers);

    final polylines = widget.polylines ??
        (context.watch<PolylineProvider>().polylines);

    return RepaintBoundary(
      child: GoogleMap(
        // 基本配置
        initialCameraPosition: widget.initialCameraPosition ?? _initialCameraPosition,

        // 效能優化配置
        buildingsEnabled: widget.buildingsEnabled,     // 關閉 3D 建築
        zoomControlsEnabled: widget.zoomControlsEnabled,
        compassEnabled: widget.compassEnabled,
        trafficEnabled: widget.trafficEnabled,
        indoorViewEnabled: widget.indoorViewEnabled,

        // 地圖元素
        markers: markers,
        polylines: polylines,

        // 定位功能
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: widget.myLocationEnabled,

        // 手勢識別
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
          ),
        },

        // 回調函數
        onMapCreated: (controller) {
          if (!_isMapReady) {
            _mapController = controller;
            controller.setMapStyle(_mapStyle);
            _isMapReady = true;
            widget.onMapCreated?.call(controller);

            // 如果還沒定位到目前位置，再次嘗試
            if (!_hasAnimatedToCurrent) {
              _getCurrentLocation();
            }
          }
        },

        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
      ),
    );
  }

  @override
  void dispose() {
    _cameraMoveTimer?.cancel();
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}