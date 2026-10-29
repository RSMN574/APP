import 'package:flutter/material.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/surface_decoration.dart';

/// 通用分頁元件：上方一排 Tab，下方 PageView。
///
/// 樣式統一使用 `SurfaceDecoration` + `AppColors`，支援深色模式。
class TabWidget extends StatefulWidget {
  final List<String> items;
  final List<IconData> icons;
  final List<String> id;
  final Widget Function(BuildContext context, PageController controller)
  buildPageView;

  const TabWidget({
    super.key,
    required this.items,
    required this.icons,
    required this.id,
    required this.buildPageView,
  });

  @override
  State<TabWidget> createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> {
  int _current = 0;
  final PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            itemCount: widget.items.length,
            itemBuilder: (ctx, index) => _buildTabItem(index),
          ),
        ),
        Expanded(
          child: widget.buildPageView(context, pageController),
        ),
      ],
    );
  }

  Widget _buildTabItem(int index) {
    final colors = context.appColors;
    final bool isSelected = _current == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _current = index);
          pageController.animateToPage(
            _current,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 100,
          height: 76,
          decoration: isSelected
              ? SurfaceDecoration.selected(context, radius: 16)
              : SurfaceDecoration.outlined(context, radius: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.info.withOpacity(0.12)
                      : colors.mutedBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icons[index],
                  size: 18,
                  color: colors.info,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.items[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.info,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}