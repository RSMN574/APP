import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/bus.dart';

class TransportGrid extends StatelessWidget {
  const TransportGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度
    double screenWidth = MediaQuery.of(context).size.width;

    // 图标和间距大小根据屏幕宽度进行微调
    double iconSize = screenWidth > 600 ? 32 : 27; // 根据屏幕宽度调整图标大小
    double crossAxisSpacing = screenWidth > 600 ? 45 : 20; // 交叉轴间距
    double mainAxisSpacing = 10; // 调整为10，缩小上下两排的间距

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
        child: GridView.builder(
          shrinkWrap: true, // 使网格自适应内容高度
          itemCount: 8, // 8个交通方式
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 强制为4列
            crossAxisSpacing: crossAxisSpacing, // 设置交叉轴间距
            mainAxisSpacing: mainAxisSpacing, // 设置主轴间距为10，缩小上下排的距离
          ),
          itemBuilder: (context, index) {
            return _buildTransportCard(
                context,
                _getIconPath(index),
                _getTransportText(index),
                _getRoute(index),
                iconSize
            );
          },
        ),
      ),
    );
  }

  // 获取每个图标的路径
  String _getIconPath(int index) {
    switch (index) {
      case 0: return 'assets/icons/airplane-outline.svg';
      case 1: return 'assets/icons/tram.svg';
      case 2: return 'assets/icons/bus-outline.svg';
      case 3: return 'assets/icons/subway-outline.svg';
      case 4: return 'assets/icons/train-outline.svg';
      case 5: return 'assets/icons/bicycle-outline.svg';
      case 6: return 'assets/icons/car.svg';
      case 7: return 'assets/icons/bus-outline.svg';
      default: return '';
    }
  }

  // 获取每个交通方式的文本
  String _getTransportText(int index) {
    switch (index) {
      case 0: return "飛機";
      case 1: return "火車";
      case 2: return "公車";
      case 3: return "捷運";
      case 4: return "高鐵";
      case 5: return "Ubike";
      case 6: return "計程車";
      case 7: return "客運";
      default: return '';
    }
  }

  // 获取每个交通方式的页面路由
  String _getRoute(int index) {
    switch (index) {
      case 0: return "plane";
      case 1: return "train";
      case 2: return "bus";
      case 3: return "metro";
      case 4: return "HSR";
      case 5: return "Ubike";
      case 6: return "taxi";
      case 7: return "Intercity Bus";
      default: return '';
    }
  }

  Widget _buildTransportCard(BuildContext context, String icon, String text, String route, double iconSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          debugPrint("$text 页面跳转");
          if(route=="bus"){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Bus(
                 ),
              ),
            );
          }else{
            Navigator.pushNamed(context, route);
          }

        },
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
}
