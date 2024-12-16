import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'Const/regularConst.dart';
import 'database/schedule.dart';

class Commute extends StatefulWidget {
  @override
  _CommuteState createState() => _CommuteState();
}

class _CommuteState extends State<Commute> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> scheduleData = [];

  @override
  void initState() {
    super.initState();
    fetchScheduleData(); // 初始化时获取数据
  }

  Future<void> fetchScheduleData() async {
    final db = schedule();
    final data = await db.getSchedule("schedule", "臺中市");
    setState(() {
      scheduleData = data;
    });
  }

  // 下拉刷新方法
  Future<void> _onRefresh() async {
    await fetchScheduleData(); // 重新获取数据
  }

  Widget _buildCommutePage() {
    return RefreshIndicator(
      onRefresh: _onRefresh, // 下拉刷新时调用
      child: ListView.builder(
        itemCount: scheduleData.length,
        itemBuilder: (context, index) {
          final item = scheduleData[index];
          return _buildScheduleCard(item);
        },
      ),
    );
  }
  Future<void> _dialogBuilder(BuildContext context, Map<String, dynamic> data) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
              Column(
                children: [
                  _buildDialogOption(context, Icons.info, "資訊", "info"),
                  _buildDialogOption(context, Icons.edit, "編輯", "edit"),
                  _buildDialogOption(context, Icons.delete, "移除", "remove",data),
                ],
              ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: busBlue,
                  ),
                  child: const Text(
                    '關閉',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogOption(BuildContext context, IconData icon, String title, String id,[Map<String, dynamic>? other]) {
    return InkWell(
      onTap: () async {
        // 处理对话框选项点击事件
        if(id=="remove"){
          final db = schedule();
         int result=await  db.removeSchedule(city: other?['city'], type: other?['type'], table: 'schedule', UserStartingStopName: other?['UserStartingStopName'], UserDestinationStopName: other?['UserDestinationStopName']
              , StartingStopName: other?['StartingStopName'], FinalStopName: other?['FinalStopName'], route: other?['Route']);
          if (result == -1) {
            // 如果已经存在相同的记录，提示用户
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('行程錯誤'))
            );
          } else if (result == 100) {
            // 成功添加行程，提示用户
            fetchScheduleData();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('行程刪除成功！'))
            );
          } else {
            // 添加行程失败，提示用户
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('行程刪除失败。'))
            );
          }

        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: busBlue),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
  Widget _buildScheduleCard(Map<String, dynamic> data) {
    return GestureDetector(
        onLongPress: () => _dialogBuilder(context,data), // 传递上下文和当前数据
    child: Container(

      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '路線: ${data['Route']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              // 顯示交通工具類型
              Text(
                '類型: ${data['type'] ?? '未知'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '路線起點: ${data['StartingStopName']}', // 顯示路線起始站
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              Expanded(
                child: Text(
                  '路線終點: ${data['FinalStopName']}', // 顯示路線終點站
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '用戶上車: ${data['UserStartingStopName'] ?? '未設定'}', // 顯示用戶選擇的上車站
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              Expanded(
                child: Text(
                  '用戶下車: ${data['UserDestinationStopName'] ?? '未設定'}', // 顯示用戶選擇的下車站
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '城市: ${data['city']}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    ));
  }

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
    final List<Widget> _pages = [
      _buildCommutePage(),
      Center(child: Text('旅行頁面', style: TextStyle(fontSize: 24))),
    ];

    return Column(
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
      ],
    );
  }
}

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
        color: Colors.white,
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
