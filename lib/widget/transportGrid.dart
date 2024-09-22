import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TransportGrid extends StatelessWidget {
  const TransportGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240, // 高度可以根據需求調整
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[200]!, // 使用淡灰色邊框以保持簡潔
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          primary: false,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          crossAxisCount: 4,
          children: <Widget>[
            _buildTransportCard(context, 'assets/icons/airplane-outline.svg', "飛機", "plane"),
            _buildTransportCard(context, 'assets/icons/tram.svg', "火車", "train"),
            _buildTransportCard(context, "assets/icons/bus-outline.svg", "巴士", "bus"),
            _buildTransportCard(context, "assets/icons/subway-outline.svg", "捷運", "metro"),
            _buildTransportCard(context, "assets/icons/train-outline.svg", "高鐵", "HSR"),
            _buildTransportCard(context, "assets/icons/bicycle-outline.svg", "Ubike", "Ubike"),
            _buildTransportCard(context, "assets/icons/car.svg", "計程車", "taxi"),
            _buildTransportCard(context, "assets/icons/bus-outline.svg", "客運", "Intercity Bus"),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, String icon, String text, String route) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          debugPrint("$text 页面跳转");
          Navigator.pushNamed(context, route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white, // 使用純白背景
            borderRadius: BorderRadius.circular(16), // 使用較大圓角
            border: Border.all(
              color: Colors.grey[300]!, // 淡灰色邊框，避免過於搶眼
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                width: 30,  // 設置寬度
                height: 30, // 設置高度
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87, // 使用深灰色文字
                  fontWeight: FontWeight.bold, // 文字加粗，保持清晰
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
