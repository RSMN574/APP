import 'package:flutter/material.dart';

class TransportGrid extends StatelessWidget {
  const TransportGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0), // 外层的边距
        child: GridView.count(
          primary: false,
          padding: const EdgeInsets.all(10),
          // 网格的内边距
          crossAxisSpacing: 10,
          // 网格横向间距
          mainAxisSpacing: 10,
          // 网格纵向间距
          crossAxisCount: 4,
          // 每行显示三个图标
          children: <Widget>[
            _buildTransportCard(
                context, Icons.flight, "飛機", Colors.blue, "plane"),
            _buildTransportCard(
                context, Icons.train, "火車", Colors.red, "train"),
            _buildTransportCard(
                context, Icons.directions_bus, "巴士", Colors.green, "bus"),
            _buildTransportCard(
                context, Icons.subway, "捷運", Colors.purple, "metro"),
            _buildTransportCard(
                context, Icons.directions_railway, "高鐵", Colors.orange,
                "HSR"),
            _buildTransportCard(
                context, Icons.directions_bike, "Ubike", Colors.brown, "Ubike"),
            _buildTransportCard(
                context, Icons.local_taxi, "計程車", Colors.yellow, "taxi"),
            _buildTransportCard(
                context, Icons.directions_bus, "客運", Colors.teal,
                "Intercity Bus"),
          ],
        )
    );
  }
}
  // 可点击的卡片
  Widget _buildTransportCard(BuildContext context, IconData icon, String text, Color color, String route) {
    return GestureDetector(
      onTap: () {
        debugPrint("$text 页面跳转");
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // 设置背景颜色的透明度
          borderRadius: BorderRadius.circular(15), // 圆角
          boxShadow: [
            BoxShadow(
              color: Colors.black12, // 阴影颜色
              blurRadius: 8, // 模糊半径
              offset: Offset(2, 2), // 阴影偏移
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 40, // 图标大小
            ),
            SizedBox(height: 10), // 图标与文字之间的间距
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
