
import 'dart:convert';

import 'package:com.rsmn574.app/pages/bus_time.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:flutter/material.dart';

import 'Const/regularConst.dart';
import 'database/getData.dart';
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

  Widget _buildCommutePage(String category) {
    final filteredData = scheduleData.where((item) {
      return item["category"] == category;
    }).toList();;

    // final filteredData = scheduleData;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: filteredData.length,
        itemBuilder: (context, index) {

          final item = filteredData[index];

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
                  _buildDialogOption(context, Icons.info, "資訊", "info",data),
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
                const SnackBar(content: Text('行程錯誤！'))
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
          Navigator.pop(context); // 关闭弹窗
        }else  if(id=="info"){
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Text(
                  '路線資訊',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: busBlue,  // 自定义颜色
                  ),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),  // 添加一些间距
                    Text(
                      '路線起點: ${other?['StartingStopName']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500, // 加粗部分文本
                      ),
                    ),
                    SizedBox(height: 8),  // 每行文本之间的间距
                    Text(
                      '路線終點: ${other?['FinalStopName']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '用戶上車站: ${other?['UserStartingStopName']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '用戶下車站: ${other?['UserDestinationStopName']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              );
            },
          );

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
        onTap: () async {

          await GetBusInfo( routeid: data["routeID"], city: cityNameConverter( data['city']));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context,) => BusTime(
              routeName:data['Route'],
              departureStopName:data["StartingStopName"],
              destinationStopName:data["FinalStopName"],
              operators: "",

              city:   cityNameConverter( data['city']), routeID: data["routeID"],



            )),
          );
        },
    child:Container(
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
          // 路線标题
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '路線: ${data['Route']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // 顯示交通工具類型
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '類型: ${data['type'] ?? '未知'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),

          // 起點與終點區域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '起點: ${data['UserStartingStopName'] ?? '未設定'}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16), // 在兩者之間添加間距
              Expanded(
                child: Text(
                  '終點: ${data['UserDestinationStopName'] ?? '未設定'}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),  // 增加底部间隔

          // 城市部分
          Text(
            '城市: ${data['city']}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    )
    );
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
      _buildCommutePage("commute"),
      _buildCommutePage("trip"),
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
