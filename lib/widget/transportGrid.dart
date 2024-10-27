import 'package:com.rsmn574.app/Bike.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/bus.dart';

import '../database/getData.dart';
import '../home.dart';

class TransportGrid extends StatelessWidget {
  final Function(String) onClick; // 声明接收字符串消息的回调

  const TransportGrid({super.key,required this.onClick});

  @override
  Widget build(BuildContext context) {
    // 定义交通方式选项
    final List<Map<String, String>> transportOptions = [
      {'icon': 'assets/icons/airplane-outline.svg', 'text': '飛機', 'route': 'plane'},
      {'icon': 'assets/icons/tram.svg', 'text': '火車', 'route': 'train'},
      {'icon': 'assets/icons/bus-outline.svg', 'text': '公車', 'route': 'bus'},
      {'icon': 'assets/icons/subway-outline.svg', 'text': '捷運', 'route': 'metro'},
      {'icon': 'assets/icons/train-outline.svg', 'text': '高鐵', 'route': 'HSR'},
      {'icon': 'assets/icons/bicycle-outline.svg', 'text': 'Ubike', 'route': 'bike'},
      {'icon': 'assets/icons/car.svg', 'text': '計程車', 'route': 'taxi'},
      {'icon': 'assets/icons/bus-outline.svg', 'text': '客運', 'route': 'Intercity Bus'},
    ];

    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth > 600 ? 32 : 27;
    double crossAxisSpacing = screenWidth > 600 ? 45 : 20;
    double mainAxisSpacing = 10;

    return Container(
      margin: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 使用 SizedBox 限制高度，确保 GridView 有大小
            SizedBox(
              height: 200, // 设置一个具体的高度，根据需要调整
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // 禁止内部滚动
                itemCount: transportOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                ),
                itemBuilder: (context, index) {
                  final option = transportOptions[index];
                  return _buildTransportCard(
                    context,
                    option['icon']!,
                    option['text']!,
                    option['route']!,
                    iconSize,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, String icon, String text, String route, double iconSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onTransportTap(context, route, text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                width: iconSize,
                height: iconSize,
              ),
              const SizedBox(height: 7),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTransportTap(BuildContext context, String route, String text) {
    debugPrint("$text 页面跳转");
    if (route == "bus") {


      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Bus(),
        ),
      );
    } else if(route == "bike"){
      onClick("bike");

    } else {
      Navigator.pushNamed(context, route);
    }
  }
}
