import 'package:flutter/material.dart';

import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_page.dart';
// 保持原有的 import
import '../const/regular_class.dart';
import '../l10n/app_localizations.dart';
import '../test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class TransportGrid extends StatefulWidget {
  final Function(String) onClick;
  const TransportGrid({super.key, required this.onClick});

  @override
  State<TransportGrid> createState() => _TransportGridState();
}

class _TransportGridState extends State<TransportGrid> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<Map<String, String>> transportOptions = [
    {
      'icon': 'assets/icons/airplane-outline.svg',
      'text': AppLocalizations.of(context)!.text_589,
      'route': 'plane'
    },
    {
      'icon': 'assets/icons/tram.svg',
      'text': AppLocalizations.of(context)!.text_585,
      'route': 'train'
    },
    {
      'icon': 'assets/icons/bus-outline.svg',
      'text': AppLocalizations.of(context)!.text_588,
      'route': 'bus'
    },
    {
      'icon': 'assets/icons/subway-outline.svg',
      'text': AppLocalizations.of(context)!.text_587,
      'route': 'metro'
    },
    {
      'icon': 'assets/icons/train-outline.svg',
      'text': AppLocalizations.of(context)!.text_586,
      'route': 'HSR'
    },
    {
      'icon': 'assets/icons/bicycle-outline.svg',
      'text': 'Ubike',
      'route': 'bike'
    },
    {
      'icon': 'assets/icons/car.svg',
      'text': AppLocalizations.of(context)!.text_691,
      'route': 'taxi'
    },
    {
      'icon': 'assets/icons/bus-outline.svg',
      'text': AppLocalizations.of(context)!.text_590,
      'route': 'IntercityBus'
    },
    {
      'icon': 'assets/icons/parking.svg',
      'text': AppLocalizations.of(context)!.text_497,
      'route': 'parking'
    },
    {
      'icon': 'assets/icons/ev-station.svg',
      'text': AppLocalizations.of(context)!.text_523,
      'route': 'EVStation'
    },
    // {'icon': 'assets/icons/road.svg', 'text': '路況', 'route': 'traffic'},
    // {'icon': 'assets/icons/motorcycle.svg', 'text': '租車', 'route': 'rent'},
    // {'icon': 'assets/icons/motorcycle.svg', 'text': 'test', 'route': 'test'},
    // {'icon': 'assets/icons/motorcycle.svg', 'text': '時速表', 'route': 'speedometer'},
  ];

  @override
  Widget build(BuildContext context) {
    const int itemsPerPage = 8;
    final int totalPages = (transportOptions.length / itemsPerPage).ceil();

    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth > 600 ? 32 : 26;
    double crossAxisSpacing = screenWidth > 600 ? 30 : 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 220, // 稍微壓縮高度使視覺更緊湊
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) =>
                    setState(() => _currentPage = page),
                itemCount: totalPages,
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * itemsPerPage;
                  final end = (start + itemsPerPage) > transportOptions.length
                      ? transportOptions.length
                      : start + itemsPerPage;
                  final subList = transportOptions.sublist(start, end);

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: subList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: crossAxisSpacing,
                      mainAxisSpacing: 0,
                      childAspectRatio: 0.85, // 調整比例讓內容更置中
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
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildPageIndicator(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, String icon, String text,
      String route, double iconSize) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 動態定義顏色
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color iconColor = isDark
        ? Theme.of(context).colorScheme.primaryContainer
        : Colors.blue.shade800;
    final Color textColor =
        isDark ? Colors.white.withOpacity(0.9) : Colors.blueGrey.shade800;

    return InkWell(
      onTap: () => _onTransportTap(context, route, text),
      borderRadius: BorderRadius.circular(20),
      // 深色模式下點擊水波紋稍微亮一點
      splashColor: primaryColor.withOpacity(isDark ? 0.1 : 0.05),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.02)
                      ]
                    : [
                        Colors.blue.withOpacity(0.08),
                        Colors.blue.withOpacity(0.03)
                      ],
              ),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
              // 深色模式下圖示用 primary 或較亮的藍，避免看不見
              colorFilter: ColorFilter.mode(
                  isDark ? primaryColor : Colors.blue.shade700,
                  BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600, // 稍微加粗提高可讀性
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
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
          width: _currentPage == index ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _currentPage == index
                ? Colors.blue.shade600
                : Colors.blue.withOpacity(0.15),
          ),
        ),
      ),
    );
  }

  // 保持原有跳轉邏輯
  void _onTransportTap(BuildContext context, String route, String text) {
    debugPrint("$text 頁面跳轉");
    if (route == "bus") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const Bus()));
    } else if (route == "bike") {
      widget.onClick("bike");
    } else {
      Navigator.pushNamed(context, route);
    }
  }
}
