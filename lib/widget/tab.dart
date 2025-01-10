import 'package:flutter/cupertino.dart';
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
      margin: const EdgeInsets.all(5),
      child: Column(
        children: [
          _buildTabBar(), // 构建标签栏
          Expanded(child: widget.buildPageView(context, pageController)), // 使用 Expanded 包裹 PageView
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: widget.items.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) => _buildTabItem(index),
      ),
    );
  }

  Widget _buildTabItem(int index) {
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
            margin: const EdgeInsets.all(5),
            width: 100,
            height: 55,
            decoration: BoxDecoration(
              color: _current == index ? Colors.white70 : Colors.white54,
              borderRadius: BorderRadius.circular(_current == index ? 12 : 7),
              border: _current == index
                  ? Border.all(color: busBlue, width: 2.5)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icons[index],
                    size: _current == index ? 23 : 20,
                    color: _current == index ? Colors.black : Colors.grey.shade400,
                  ),
                  Text(widget.items[index]),
                ],
              ),
            ),
          ),
        ),
        if (_current == index)
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: busBlue,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }



}

