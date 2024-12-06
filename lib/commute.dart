import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Commute extends StatefulWidget {
  @override
  _CommuteState createState() => _CommuteState();
}

class _CommuteState extends State<Commute> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    Center(child: Text('上班通勤頁面', style: TextStyle(fontSize: 24))),
    Center(child: Text('旅行頁面', style: TextStyle(fontSize: 24))),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        // 模擬 AppBar
        CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
        // PageView
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
        ),
        // CustomBottomNavigationBar

      ],
    );

}}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:Colors.white ,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              index: 0,
              icon: Icons.directions_bus,
              label: '上班通勤',
            ),
            _buildTabItem(
              index: 1,
              icon: Icons.airplanemode_active,
              label: '旅行',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

