import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
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
    _loadInitialLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 保持地图控制器的状态，并在 app 进入后台或前台时适当处理
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // app 进入后台，可以保存地图状态
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // app 回到前台，可以恢复地图状态
      if (_controller != null) {
        _controller?.setMapStyle("[]"); // 重新应用样式（根据需要）
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  // 加载用户的初始位置
  Future<void> _loadInitialLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    setState(() {
      _initialPosition = LatLng(locationProvider.latitude, locationProvider.longitude);
    });
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
              target: _initialPosition!, // 使用用户的初始位置
              zoom: 17.0,
            ),
          ),
        );
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(0, 0), // 默认起始位置
        zoom: 1.0,
      ),
      trafficEnabled: true, // 启用交通层
      mapType: MapType.normal,
    );
  }
}
