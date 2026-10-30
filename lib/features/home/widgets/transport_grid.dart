import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_page.dart';

// 保持原有的 import
import '../../../const/app_colors.dart';
import '../../../const/surface_decoration.dart';
import '../../../l10n/app_localizations.dart';


class TransportGrid extends StatefulWidget {
  final Function(String) onClick;
  final bool isCollapsed; // 新增：控制是否為收合狀態

  const TransportGrid({
    super.key,
    required this.onClick,
    this.isCollapsed = false, // 預設為 false，保持向後相容
  });

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
  ];

  @override
  Widget build(BuildContext context) {
    // 如果是收合狀態，顯示精簡的橫向列表
    if (widget.isCollapsed) {
      return _buildCollapsedLayout(context);
    }

    // 半展開 / 完全展開狀態：保留原本的網格與分頁邏輯
    return _buildExpandedLayout(context);
  }

  // ==========================================
  // 狀態 A：收合 (Collapsed) - 精簡橫向列表
  // ==========================================
  Widget _buildCollapsedLayout(BuildContext context) {
    // 收合時只取前 5 個最常用的交通工具
    final quickOptions = transportOptions.take(5).toList();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      height: 85, // 控制收合時的高度
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickOptions.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final option = quickOptions[index];
          return _buildQuickCard(
            context,
            option['icon']!,
            option['text']!,
            option['route']!,
          );
        },
      ),
    );
  }

  // ==========================================
  // 狀態 B & C：半展開/全展開 - 原始網格分頁
  // ==========================================
  Widget _buildExpandedLayout(BuildContext context) {
    const int itemsPerPage = 8;
    final totalPages = (transportOptions.length / itemsPerPage).ceil();
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: SurfaceDecoration.cardShadow(context, radius: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                itemCount: totalPages,
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * itemsPerPage;
                  final end = (start + itemsPerPage) > transportOptions.length
                      ? transportOptions.length
                      : start + itemsPerPage;

                  final subList = transportOptions.sublist(start, end);

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: subList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: screenWidth > 600 ? 24 : 8,
                      mainAxisSpacing: 4,
                      childAspectRatio: screenWidth > 600 ? 0.95 : 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final option = subList[index];

                      return _buildTransportCard(
                        context,
                        option['icon']!,
                        option['text']!,
                        option['route']!,
                        screenWidth > 600 ? 30 : 26,
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

  // 原本的網格卡片
  Widget _buildTransportCard(BuildContext context, String icon, String text,
      String route, double iconSize) {
    final colors = context.appColors;

    return InkWell(
      onTap: () => _onTransportTap(context, route, text),
      borderRadius: BorderRadius.circular(20),
      splashColor: colors.info.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.infoContainer,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(colors.info, BlendMode.srcIn),
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
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 新增：收合狀態的精簡卡片
  Widget _buildQuickCard(
      BuildContext context, String icon, String text, String route) {
    final colors = context.appColors;

    return InkWell(
      onTap: () => _onTransportTap(context, route, text),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: colors.infoContainer.withOpacity(0.5), // 稍微淡化背景
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(colors.info, BlendMode.srcIn),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    final colors = context.appColors;
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
                ? colors.info
                : colors.info.withOpacity(0.15),
          ),
        ),
      ),
    );
  }

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