import 'package:com.rsmn574.app/widget/googlemap.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/WeatherCard.dart';
import 'package:com.rsmn574.app/widget/transportGrid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class home extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return  Stack(
      children: [
        // Google Map
        MapWidget(),

        // Bottom Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.3, // BottomSheet 的初始高度
          minChildSize: 0.2,      // 最小高度
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
