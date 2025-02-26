import 'package:flutter/material.dart';
import '../Const/regularConst.dart';

// 常量文件，包含颜色、图标和标签名称等
class TabWidget extends StatefulWidget {
  const TabWidget({super.key, required this.items, required this.icons, required this.id, required this.buildPageView,});
  final Widget Function(BuildContext, PageController) buildPageView; // 外部传入的 PageView 构建函数

  final List<String> items ; // 标签名称列表
  final List<IconData> icons ; // 标签对应的图标
  final List<String> id ; // 页面 ID 列表

  @override
  _TabWidgetState createState() => _TabWidgetState();
}

class _TabWidgetState extends State<TabWidget> {
  int _current = 0; // 当前选中的标签索引
  final PageController pageController = PageController(); // 页面控制器

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTabBar(), // 构建标签栏
          Expanded(
            child: widget.buildPageView(context, pageController),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 90,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: widget.items.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (ctx, index) => _buildTabItem(index),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final bool isSelected = _current == index;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _current = index; // 更新当前选中标签的索引
            });
            pageController.animateToPage(
              _current,
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: [
                  busBlue.withOpacity(0.7),
                  busBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSelected ? 16 : 10),
              border: isSelected ? Border.all(color: busBlue, width: 2.5) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icons[index],
                    size: isSelected ? 26 : 22,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.items[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: busBlue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}


