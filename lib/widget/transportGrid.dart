
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/bus.dart';



import 'package:flutter_svg/flutter_svg.dart';

import '../test.dart';

class TransportGrid extends StatefulWidget {
  final Function(String) onClick;

  const TransportGrid({super.key, required this.onClick});

  @override
  State<TransportGrid> createState() => _TransportGridState();
}

class _TransportGridState extends State<TransportGrid> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> transportOptions = [
    {'icon': 'assets/icons/airplane-outline.svg', 'text': '飛機', 'route': 'plane'},
    {'icon': 'assets/icons/tram.svg', 'text': '火車', 'route': 'train'},
    {'icon': 'assets/icons/bus-outline.svg', 'text': '公車', 'route': 'bus'},
    {'icon': 'assets/icons/subway-outline.svg', 'text': '捷運', 'route': 'metro'},
    {'icon': 'assets/icons/train-outline.svg', 'text': '高鐵', 'route': 'HSR'},
    {'icon': 'assets/icons/bicycle-outline.svg', 'text': 'Ubike', 'route': 'bike'},
    {'icon': 'assets/icons/car.svg', 'text': '計程車', 'route': 'taxi'},
    {'icon': 'assets/icons/bus-outline.svg', 'text': '客運', 'route': 'Intercity Bus'},
    // 添加更多項目測試分頁
    {'icon': 'assets/icons/parking.svg', 'text': '停車資訊', 'route': 'parking'},
    {'icon': 'assets/icons/ev-station.svg', 'text': '充電樁', 'route': 'EVStation'},
    // {'icon': 'assets/icons/motorcycle.svg', 'text': '路況', 'route': 'traffic'},
    // {'icon': 'assets/icons/motorcycle.svg', 'text': '租車', 'route': 'rent'},
    // {'icon': 'assets/icons/motorcycle.svg', 'text': 'test', 'route': 'test'},
  ];

  @override
  Widget build(BuildContext context) {
    const int itemsPerPage = 8; // 每頁顯示8個項目
    final int totalPages = (transportOptions.length / itemsPerPage).ceil();

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
            SizedBox(
              height: 230, // 調高以容納 GridView 內的所有項目
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: totalPages,
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * itemsPerPage;
                  final end = (start + itemsPerPage) > transportOptions.length
                      ? transportOptions.length
                      : start + itemsPerPage;
                  final subList = transportOptions.sublist(start, end);

                  return  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true, // 確保 GridView 不會試圖填滿無限空間
                    itemCount: subList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: mainAxisSpacing,
                      childAspectRatio: 0.7, // 調整此比例（根據實際需求微調）
                    ),
                    itemBuilder: (context, index) {
                      final option = subList[index];
                      return _buildTransportCard(
                        context,
                        option['icon']!,
                        option['text']!,
                        option['route']!,
                        iconSize,
                      );
                    },
                  );
                  ;
                },
              ),
            ),

            _buildPageIndicator(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, String icon, String text, String route, double iconSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        decoration: const BoxDecoration(
          color: Colors.white,

        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onTransportTap(context, route, text),
            splashColor: Colors.blue[100],
            highlightColor: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize + 14,
                    height: iconSize + 14,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        icon,
                        width: iconSize,
                        height: iconSize,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          width: _currentPage == index ? 22 : 8,  // 當前頁面指示器加寬
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),  // 圓角實現膠囊效果
            color: _currentPage == index
                ? Colors.blue[700]!.withOpacity(0.9)
                : Colors.grey[300]!,
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
    } else if (route == "bike") {
      widget.onClick("bike");
    }else if (route == "test") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => test(),
        ),
      );
    } else {
      Navigator.pushNamed(context, route);
    }
  }
}