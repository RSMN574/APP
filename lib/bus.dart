import 'dart:convert';
import 'package:com.rsmn574.app/pages/busStopInfo.dart';
import 'package:com.rsmn574.app/pages/bus_time.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/BusList.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Const/regularConst.dart';
import 'database/getData.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'database/shared_perferences.dart';

class Bus extends StatefulWidget {
  const Bus({Key? key}) : super(key: key);

  @override
  State<Bus> createState() => BusState();
}

class BusState extends State<Bus> {
  final List<IconData> icons=[Icons.favorite, Icons.favorite, Icons.route];
  final List<String> items=["收藏路線", "收藏站牌",  "規劃"];
  final List<String> id=["route", "stop",  "routeplan"];
  int current = 0;
  final PageController pageController = PageController();
  List<String>? favoriteStops;
  List<String>? favoriteRoutes;
  @override
  void initState() {
    super.initState();
    _loadFavorites(); // 初始化时加载收藏列表
  }

  final List<String> _list = ['全部', '臺中市'];
  final ValueNotifier<String> _dropdownValueNotifier = ValueNotifier<String>('路線');
  final ValueNotifier<double> suggestionsHeightNotifier = ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  List suggestions = [];
  Future<void> _loadFavorites() async {
    favoriteStops = await loadList('favoritesBusStop');
    favoriteRoutes = await loadList('favoritesBusRoute');
    setState(() {}); // 更新 UI
  }

  Future<void> _updateSuggestions(id) async {
    suggestions.clear();

    if (id == "route") {
      for (var route in busName) {
        String routeName = json.decode(route["RouteName"])["Zh_tw"];
        if (routeName.contains(busIdController.text)) {
          if (busIdController.text == routeName) {
            suggestions.insert(0, route);
          } else {
            suggestions.add(route);
          }
        }
      }
    } else if (id == "stop") {
      var i = await mysqlSelect("SELECT StationName FROM Bus.Bus_Taichung_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE '%${busIdController.text}%'");
      for (var a in i) {
        if (busIdController.text == json.decode(a["StationName"])["Zh_tw"]) {
          suggestions.insert(0, json.decode(a["StationName"])["Zh_tw"]);
        } else {
          suggestions.add(json.decode(a["StationName"])["Zh_tw"]);
        }
      }
      suggestions = (suggestions.toSet().toList());
    }

    setState(() {
      double screenHeight = MediaQuery.of(context).size.height;
      double bottomInset = MediaQuery.of(context).viewInsets.bottom;
      double appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
      suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 14 - 70;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: busBlue,
        elevation: 0,
        title: const Text(
          "公車",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          hideKeyboard(context);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: CustomDropdown<String>(
                hintText: 'Select City',
                items: _list,
                initialItem: _list[0],
                onChanged: (value) {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 70,
                child: Row(
                  children: [


                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12, // 陰影顏色
                            blurRadius: 6, // 陰影模糊半徑
                            offset: Offset(0, 3), // 陰影位置
                          ),
                        ],
                        borderRadius: BorderRadius.circular(20), // 容器圓角
                      ),
                      child: ValueListenableBuilder<String>(
                        valueListenable: _dropdownValueNotifier,
                        builder: (context, value, child) {
                          return DropdownButtonFormField<String>(
                            value: value,
                            onChanged: (String? newValue) {
                              _dropdownValueNotifier.value = newValue!;
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white, // 淺灰色背景
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0), // 圓角
                                borderSide: BorderSide.none, // 無邊框
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 調整內邊距
                            ),
                            style: const TextStyle(
                              color: Colors.black87, // 下拉選單文字顏色
                              fontSize: 16, // 字體大小
                            ),
                            dropdownColor: Colors.white, // 下拉選單背景色
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54), // 下拉箭頭圖標
                            items: <String>['路線', '站牌', '業者']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    color: Colors.black87, // 選項文字顏色
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),

                    Expanded(
                      child: Container(
                        decoration: ShapeDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 25,
                              offset: Offset(0, 0),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: TextField(
                          onChanged: (text) async {
                            if (text.isNotEmpty) {
                              if (_dropdownValueNotifier.value == "路線") {
                                await _updateSuggestions('route');
                              } else if (_dropdownValueNotifier.value == "站牌") {
                                await _updateSuggestions('stop');
                              }
                            } else {
                              suggestions.clear();
                              suggestionsHeightNotifier.value = 0;
                            }
                          },
                          controller: busIdController,
                          decoration: InputDecoration(
                            hintText: '搜尋...',
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[700], size: 24),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent, // Fill color will be applied by ShapeDecoration
                            // focusedBorder: OutlineInputBorder(
                            //   borderRadius: BorderRadius.circular(30.0),
                            //   borderSide: BorderSide(color: busBlue, width: 2.0),
                            // ),
                            // enabledBorder: OutlineInputBorder(
                            //   borderRadius: BorderRadius.circular(30.0),
                            //   borderSide: BorderSide(color: Colors.grey[300]!, width: 2.0),
                            // ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              color: Colors.grey[700],
                              onPressed: () {
                                busIdController.clear();
                                _dropdownValueNotifier.value = '路線';
                                suggestions.clear();
                                suggestionsHeightNotifier.value = 0;
                              },
                            ),
                          ),
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      ),
                    )

                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  tab(context),
                  ValueListenableBuilder<double>(
                    valueListenable: suggestionsHeightNotifier,
                    builder: (context, height, child) {
                      return Container(
                        color: bgColor,
                        height: height,
                        child: suggestions.isNotEmpty
                            ? _dropdownValueNotifier.value == "路線"
                            ? Buslist(suggestions: suggestions)
                            : _dropdownValueNotifier.value == "站牌"
                            ? BusStopList(suggestions)
                            : const Center(child: Text("请选择一个有效的选项"))
                            : const Center(child: Text("没有找到匹配的结果", style: TextStyle(color: Colors.grey))),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }




  Widget tab(BuildContext context) {

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
        itemCount: items.length,
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
                    icons[index],
                    size: current == index ? 23 : 20,
                    color: current == index ? Colors.black : Colors.grey.shade400,
                  ),
                  Text(items[index]),
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
        itemCount: id.length,
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          switch (id[index]) {
            case "route":
              return _buildList('favoritesBusRoute', _buildRouteListItem);
            case "stop":
              return _buildList('favoritesBusStop', _buildStopListItem);
            case "home":
              return const Center(child: Text("Home Page"));
            case "map":
              return Center(child: Text(items[index]));
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
        }  else if (key=='favoritesBusRoute' && snapshot.data != null && snapshot.data!.isNotEmpty  ) {

          final List<String>? items = snapshot.data;
          return ListView.separated(
            itemCount: items?.length ?? 0,
            itemBuilder: (context, index) {
              return itemBuilder(items![index]);
            }, separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              color: Color.fromRGBO(231, 231, 231, 1), // 分隔線的顏色
              height: 9, // 分隔線與上下元素的間距
              thickness: 1, // 分隔線的粗細
              indent: 20, // 分隔線距離左側的間距
              endIndent: 20, // 分隔線距離右側的間距

            );

          },
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final List<String>? items = snapshot.data;
          return ListView.builder(
            itemCount: items?.length ?? 0,
            itemBuilder: (context, index) {
              return itemBuilder(items![index]);
            },
          );
        } else {
          return  Center(child:_NoFavoritesWidget());
        }
      },
    );
  }
  Widget _NoFavoritesWidget() {
    return Container(
      color: Colors.white, // 白色底
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插入提示圖片，可以替換為你需要的圖片
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            // 顯示「沒有任何收藏的」提示文字
            Text(
              '沒有任何收藏的',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '快去添加一些喜歡的吧！',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStopListItem(String stop) {

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
        icon: const Icon(Icons.favorite, color: Color.fromRGBO(51, 51, 51, 1)),
        onPressed: onConfirm,
      ),
      onLongPress: () => _dialogBuilder(context),
      onTap: onTap,
    );
  }
  Widget _buildListItemRoute(String jsonData, VoidCallback onConfirm, [VoidCallback? onTap]) {
    return








      ListTile(
        title: Text(json.decode(jsonData)["route"]
          ,style:
          const TextStyle(
              fontFamily: "MiSans-Demibold",
              fontSize: 21

          ),
        ),
        subtitle: Text('${json.decode(jsonData)["DepartureStopNameZh"]}-${json.decode(jsonData)["DestinationStopNameZh"]} '
          ,style:
          const TextStyle(
              fontSize: 15,
              color: Color.fromRGBO(136, 136, 136, 1)

          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Color.fromRGBO(51, 51, 51, 1)),
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

Widget BusStopList(suggestions) {
  return ListView.builder(
    itemCount: suggestions.length,
    itemBuilder: (context, index) {
      return
Container(
 padding: EdgeInsets.only(left: 6.3),
  decoration: BoxDecoration(
      color: index==0?Color.fromRGBO(238, 238, 238, 0.85) :Colors.white,
      borderRadius: BorderRadius.circular(10),
       ),

      child:
ListTile(

  title: Text(suggestions[index].toString(),
  style:TextStyle(

      fontFamily: "MiSans-Medium"
  )


  ),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BusStopInfo(suggestions[index].toString())),
    );
  },
),


  );



    },
  );
















}
