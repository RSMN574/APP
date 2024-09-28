import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Const/regularConst.dart';
import '../database/shared_perferences.dart';
import 'package:quickalert/quickalert.dart';

import '../pages/busStopInfo.dart';

class tab extends StatefulWidget {
  final List<IconData> icons;
  final List<String> items;
  final List<String> id;

  tab({
    required this.items,
    required this.icons,
    required this.id,
  });

  @override
  State<tab> createState() => _TabPageState();
}

class _TabPageState extends State<tab> {
  int current = 0;
  PageController pageController = PageController();
  List<String>? favoriteStops;

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // 初始化时加载收藏列表
  }

  Future<void> _loadFavorites() async {
    favoriteStops = await loadList('favoritesBusStop');
    setState(() {}); // 更新 UI
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: Column(
        children: [
          _buildTabBar(), // 构建标签栏
          Expanded( // 使用 Expanded 包裹 PageView
            child: _buildPageView(), // 构建 PageView
          ),
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
        itemBuilder: (ctx, index) {
          return _buildTabItem(index);
        },
      ),
    );
  }

  Widget _buildTabItem(int index) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              current = index;
            });
            pageController.animateToPage(
              current,
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
              color: current == index ? Colors.white70 : Colors.white54,
              borderRadius: BorderRadius.circular(current == index ? 12 : 7),
              border: current == index ? Border.all(color: busBlue, width: 2.5) : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icons[index],
                    size: current == index ? 23 : 20,
                    color: current == index ? Colors.black : Colors.grey.shade400,
                  ),
                  Text(widget.items[index]),
                ],
              ),
            ),
          ),
        ),
        if (current == index)
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

  Widget _buildPageView() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      width: double.infinity,
      child: PageView.builder(
        itemCount: widget.icons.length,
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          switch (widget.id[index]) {
            case "route":
              return const Center(child: Text("Route Page"));
            case "stop":
              return _buildStopList(); // 使用 FutureBuilder 加载停靠站列表
            case "home":
              return const Center(child: Text("Home Page"));
            case "map":
              return Center(child: Text(widget.items[index]));
            case "city":
              return const Center(child: Text("City Page"));
            default:
              return const Center(child: Text("Unknown"));
          }
        },
      ),
    );
  }

  Widget _buildStopList() {
    return FutureBuilder<List<String>?>(
      future: loadList('favoritesBusStop'), // 从 SharedPreferences 加载
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          favoriteStops = snapshot.data; // 更新收藏的停靠站
          return ListView.builder(
            itemCount: favoriteStops?.length ?? 0,
            itemBuilder: (context, index) {
              return _buildStopListItem(favoriteStops![index]);
            },
          );
        } else {
          return const Center(child: Text('No favorite stops found.'));
        }
      },
    );
  }

  Widget _buildStopListItem(String stop) {
    return ListTile(
      title: Text(stop),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () {
          _showConfirmDialog(context, stop); // 显示确认对话框
        },
      ),
      onLongPress: () {
        _dialogBuilder(context);
      },onTap: (){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusStopInfo(
              stop
          ),
        ),
      );
    },
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
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
              mainAxisSize: MainAxisSize.min, // 自适应内容的高度
              children: [
                const SizedBox(height: 20), // 添加间距
                _buildDialogOptions(),
                const SizedBox(height: 20), // 添加间距
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭对话框
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: busBlue, // 设置按钮背景色
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

  Widget _buildDialogOptions() {
    return Column(
      children: [
        _buildDialogOption(context, Icons.info, "資訊", "info"),
        _buildDialogOption(context, Icons.route, "路線規劃", "route"),
      ],
    );
  }

  Widget _buildDialogOption(BuildContext context, IconData icon, String title, String id) {
    return InkWell(
      onTap: () async {
        // 处理对话框选项点击事件
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10), // 添加上下间距
        child: Row(
          children: [
            Icon(icon, color: busBlue), // 设置图标颜色
            const SizedBox(width: 10), // 添加间距
            Text(
              title,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String stop) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: '確定取消收藏嗎',
      confirmBtnText: '確認',
      cancelBtnText: '取消',
      confirmBtnColor: Colors.green,
      onCancelBtnTap: () {
        Navigator.pop(context);
      },
      onConfirmBtnTap: () {
        _removeFavorite(context, stop); // 传递上下文以便在完成时重新加载
        Navigator.pop(context);
      },
    );
  }

  Future<void> _removeFavorite(BuildContext context, String stop) async {
    List<String>? currentFavorites = await loadList('favoritesBusStop');
    currentFavorites?.remove(stop); // 移除指定的项

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoritesBusStop', currentFavorites ?? []); // 保存更新后的列表
    await _loadFavorites(); // 重新加载收藏列表
  }
}
