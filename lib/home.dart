import 'package:com.rsmn574.app/widget/googlemap.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/WeatherCard.dart';
import 'package:com.rsmn574.app/widget/transportGrid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Home extends StatelessWidget {
  double _bottomSheetHeightMin = 0.2; // 初始的 Bottom Sheet 高度

  @override
  Widget build(BuildContext context) {
    // 获取设备屏幕高度
    final screenHeight = MediaQuery.of(context).size.height;
    // 获取 AppBar 高度
    final appBarHeight = AppBar().preferredSize.height;
    // 获取底部导航栏高度
    final bottomNavBarHeight = kBottomNavigationBarHeight; // 默认底部导航栏高度

    // 计算地图的高度
    final mapHeight = screenHeight -
        (screenHeight * _bottomSheetHeightMin) -
        appBarHeight -
        bottomNavBarHeight;

    return  Stack(
      children: [
        // Google Map
        Container(
          height: mapHeight, // 使用计算的高度
          child:  MapWidget(),
      ),
        // Bottom Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.3, // BottomSheet 的初始高度
          minChildSize:_bottomSheetHeightMin,      // 最小高度
          maxChildSize: 1.0,      // 最大高度設置為 1.0 (全螢幕)
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    // 這裡是 home 組件的內容
                    WeatherWidget(),
                    const TransportGrid(),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
