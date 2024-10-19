import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart'; // 导入定位包
import '../Const/regularClass.dart'; // 确保导入正确的 Provider

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with WidgetsBindingObserver {
  GoogleMapController? _controller;
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // 监听应用生命周期
    _loadInitialLocation();  // 加载初始位置
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 处理应用生命周期
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle("[]"); // 重新应用地图样式
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  // 加载初始 GPS 定位位置
  Future<void> _loadInitialLocation() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
    });
  }

  // 检查位置权限
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    return permission != LocationPermission.deniedForever;
  }

  @override
  Widget build(BuildContext context) {
    if (_initialPosition == null) {
      return Center(
        child: LoadingAnimationWidget.stretchedDots(
          color: Colors.black,
          size: 40,
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (controller) {
        _controller = controller;
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _initialPosition!, // 使用 GPS 定位的初始位置
              zoom: 17.0,
            ),
          ),
        );
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(0, 0), // 默认初始位置
        zoom: 1.0,
      ),
      trafficEnabled: true, // 启用交通层
      mapType: MapType.normal,
      myLocationEnabled: true,  // 显示用户位置
      myLocationButtonEnabled: true,  // 显示定位按钮
    );
  }
}
