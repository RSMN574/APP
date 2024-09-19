import 'package:flutter/material.dart';

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
            _buildTransportCard(context, Icons.flight, "飛機", "plane"),
            _buildTransportCard(context, Icons.train, "火車", "train"),
            _buildTransportCard(context, Icons.directions_bus, "巴士", "bus"),
            _buildTransportCard(context, Icons.subway, "捷運", "metro"),
            _buildTransportCard(context, Icons.directions_railway, "高鐵", "HSR"),
            _buildTransportCard(context, Icons.directions_bike, "Ubike", "Ubike"),
            _buildTransportCard(context, Icons.local_taxi, "計程車", "taxi"),
            _buildTransportCard(context, Icons.directions_bus, "客運", "Intercity Bus"),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, IconData icon, String text, String route) {
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
              Icon(
                icon,
                color: Colors.black87, // 深灰色圖標，簡單且醒目
                size: 40,
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
