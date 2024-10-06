import 'dart:convert';

import 'package:com.rsmn574.app/pages/bus_time.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Const/regularConst.dart';
import '../database/getData.dart';
import '../database/shared_perferences.dart';
import 'package:quickalert/quickalert.dart';
import '../pages/busStopInfo.dart';

class tab extends StatefulWidget {
  final List<IconData> icons;
  final List<String> items;
  final List<String> id;

  const tab({
    Key? key,
    required this.items,
    required this.icons,
    required this.id,
  }) : super(key: key);

  @override
  State<tab> createState() => _TabPageState();
}

class _TabPageState extends State<tab> {
  int current = 0;
  final PageController pageController = PageController();
  List<String>? favoriteStops;
  List<String>? favoriteRoutes;

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // 初始化时加载收藏列表
  }

  Future<void> _loadFavorites() async {
    favoriteStops = await loadList('favoritesBusStop');
    favoriteRoutes = await loadList('favoritesBusRoute');
    setState(() {}); // 更新 UI
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: Column(
        children: [
          _buildTabBar(), // 构建标签栏
          Expanded(child: _buildPageView()), // 使用 Expanded 包裹 PageView
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
        itemCount: widget.id.length,
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          switch (widget.id[index]) {
            case "route":
              return _buildList('favoritesBusRoute', _buildRouteListItem);
            case "stop":
              return _buildList('favoritesBusStop', _buildStopListItem);
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

  Widget _buildList(String key, Widget Function(String) itemBuilder) {
    return FutureBuilder<List<String>?>(
      future: loadList(key), // 从 SharedPreferences 加载
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }  else if (key=='favoritesBusRoute' && snapshot.hasData) {
          final List<String>? items = snapshot.data;
          return ListView.builder(
            itemCount: items?.length ?? 0,
            itemBuilder: (context, index) {
              return itemBuilder(items![index]);
            },
          );
        } else if (snapshot.hasData) {
          final List<String>? items = snapshot.data;
          return ListView.builder(
            itemCount: items?.length ?? 0,
            itemBuilder: (context, index) {
              return itemBuilder(items![index]);
            },
          );
        } else {
          return const Center(child: Text('沒有任何收藏'));
        }
      },
    );
  }

  Widget _buildStopListItem(String stop) {
    print(stop);
    return _buildListItem(stop, () => _showConfirmDialog(context, stop,"favoritesBusStop"), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BusStopInfo(stop)),
      );
    });
  }

  Widget _buildRouteListItem(String route) {

    return _buildListItemRoute(route, () => _showConfirmDialog(context, route,"favoritesBusRoute"),() async {
      await GetBusInfo(int.parse(json.decode(route)["route"]), "Taichung");
     List baseData= await mysqlSelect("SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))='${json.decode(route)["route"]}'");



      Navigator.push(
        context,
        MaterialPageRoute(builder: (context,) => BusTime(
          routeName:json.decode(route)["route"],
            departureStopName:json.decode(route)["DepartureStopNameZh"],
            destinationStopName:json.decode(route)["DestinationStopNameZh"],
            operators: "",
          routeMapImageUrl:baseData[0]["RouteMapImageUrl"],


        )),
      );
    });
  }

  Widget _buildListItem(String title, VoidCallback onConfirm, [VoidCallback? onTap]) {
    return ListTile(
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: onConfirm,
      ),
      onLongPress: () => _dialogBuilder(context),
      onTap: onTap,
    );
  }
  Widget _buildListItemRoute(String jsonData, VoidCallback onConfirm, [VoidCallback? onTap]) {
    return ListTile(
      title: Text(json.decode(jsonData)["route"]),
      subtitle: Text('起點 ${json.decode(jsonData)["DepartureStopNameZh"]}\n  終點 ${json.decode(jsonData)["DestinationStopNameZh"]} '),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: onConfirm,
      ),
      onLongPress: () => _dialogBuilder(context),
      onTap: onTap,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                _buildDialogOptions(),
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

  void _showConfirmDialog(BuildContext context, String item,String SharedPreferencesList) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: '確定取消收藏嗎',
      confirmBtnText: '確認',
      cancelBtnText: '取消',
      confirmBtnColor: Colors.green,
      onCancelBtnTap: () => Navigator.pop(context),
      onConfirmBtnTap: () {
        _removeFavorite(context, item,SharedPreferencesList);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _removeFavorite(BuildContext context, String item,String SharedPreferencesList) async {
    List<String>? currentFavorites = await loadList(SharedPreferencesList);
    currentFavorites?.remove(item); // 移除指定的项

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(SharedPreferencesList, currentFavorites ?? []);
    await _loadFavorites(); // 重新加载收藏列表
  }
}
