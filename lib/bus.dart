import 'dart:async';
import 'dart:convert';
import 'package:com.rsmn574.app/pages/busStopInfo.dart';
import 'package:com.rsmn574.app/pages/bus_time.dart';
import 'package:com.rsmn574.app/pages/routePlanning.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/BusList.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'database/SQL/favorite_feature.dart';
import 'database/getData.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';


class Bus extends StatefulWidget {
  const Bus({Key? key}) : super(key: key);

  @override
  State<Bus> createState() => BusState();
}

class BusState extends State<Bus>  {

  final List<IconData> icons=[Icons.favorite, Icons.favorite, Icons.route,Icons.airport_shuttle];
  final List<String> items=["收藏路線", "收藏站牌",  "規劃","接駁車"];
  final List<String> id=["route", "stop",  "routeplan","shuttleBus"];
  int _current = 0;
  final PageController pageController = PageController();
  ValueNotifier<List<Map<String, dynamic>>> favoriteStops = ValueNotifier([]);
  ValueNotifier<List<Map<String, dynamic>>> favoriteRoutes = ValueNotifier([]);
  List busData=[];
  final List<String> _list = ['全部', '臺中市','臺北市'];
  final List<String> _listID = ['all', 'Taichung','Taipei'];
  ValueNotifier<String> currentCityNotifier = ValueNotifier<String>("全部");
  ValueNotifier<String> correspondingIDNotifier = ValueNotifier<String>("");
  final ValueNotifier<String> _dropdownValueNotifier = ValueNotifier<String>('路線');
  final ValueNotifier<double> suggestionsHeightNotifier = ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  final ValueNotifier<List> suggestions = ValueNotifier<List>([]);


  // 更新當前值
  Future<int> updateCurrent() async {
    favoriteRoutes.value=await  _loadFavorites("FavoritesRoute",city: correspondingIDNotifier.value);

     favoriteStops.value=await  _loadFavorites("FavoritesStop",city: correspondingIDNotifier.value);

    return 200;
  }
  @override
  void initState() {
    super.initState();
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;
    if (_list.contains(currentCity)) {
      currentCityNotifier.value = currentCity; // 正确赋值
    }
    _initializeFavorites();
    updatedCorrespondingID();
    _getData();
    updateCurrent();

  }
  @override
  void dispose() {
    super.dispose();
  }

  // 异步初始化函数
  Future<void> _initializeFavorites() async {
    // await _loadFavorites(); // 初始化时加载收藏列表
    try {
      favorite_feature dbHelper = favorite_feature(); // 创建实例
      await dbHelper.initDatabase(); // 正确通过实例调用数据库初始化
    } catch (e) {
      print('Error initializing database: $e');
    }
  }


  Future<List<Map<String, dynamic>>> _loadFavorites(String key, {required String city}) async {
    favorite_feature db=favorite_feature();
    final favorites = await db.getFavorites(key, correspondingIDNotifier.value,city);
    return favorites;
  }
Future <List>_getData()async{
  busCurrentCity=correspondingIDNotifier.value;

    busData= await  GetBus(correspondingIDNotifier.value);

    return []; // 返回一个空列表，避免 Future 没有返回值的问题


}
  Future<List<dynamic>> _updateSuggestions(String id) async {
    suggestions.value.clear(); // 僅清空一次

    if (id == "route") {
      final String input = busIdController.text;
      final List<dynamic> suggestionsForRoute = [];

      for (var route in busData) {
        final routeName = json.decode(route["RouteName"])["Zh_tw"];
        if (routeName.contains(input)) {
          if (input == routeName) {
            suggestions.value.insert(0, route);
            suggestionsForRoute.insert(0, route);
          } else {
            suggestions.value.add(route);
            suggestionsForRoute.add(route);
          }
        }
      }

      return suggestionsForRoute;
    }

    else if (id == "stop") {
      final String input = busIdController.text;
      final rawData = await mysqlSelect(
          "SELECT StationName FROM Bus.Bus_${correspondingIDNotifier.value}_Stop "
              "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE '%$input%'"
      );

      final seen = <String>{};

      for (var item in rawData) {
        final name = json.decode(item["StationName"])["Zh_tw"];
        if (seen.contains(name)) continue;
        seen.add(name);

        if (input == name) {
          suggestions.value.insert(0, name);
        } else {
          suggestions.value.add(name);
        }
      }

      return suggestions.value;
    }

    return suggestions.value;
  }

// 返回每个隐藏的菜单项
  SelectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: busBlue),
            Text(text),
          ],
        )
    );
  }
  // 提取 AppBar 為獨立 Widget
  AppBar  _buildAppBar() {
    return AppBar(

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
      actions: [
        PopupMenuButton<String>(
          iconColor:   Colors.black,
          itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
            this.SelectView(Icons.confirmation_number, '票價說明', 'A'),
            this.SelectView(Icons.warning, '通阻消息', 'B'),

          ],
          onSelected: (String action) async {
            // 点击选项的时候
            switch (action) {
              case 'A':

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: busBlue,
                          elevation: 0,
                          title: const Text(
                            "票價說明",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        body: SingleChildScrollView(

                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dropdown
                              Container(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: CustomDropdown<String>(
                                  hintText: '選擇城市',
                                  items: _list,
                                  initialItem: currentCityNotifier.value,

                                  onChanged: (value) {
                                    // Handle selection change
                                    updatedCorrespondingID();
                                    _getData();
                                    currentCityNotifier.value = value!;

                                  },
                                ),
                              ),
                              // Title
                              const Text(
                                "票價細則",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Description with better styling
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child:
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "1. 臺中市民、市民的新住民配偶及臺中就學的外縣市學生，"
                                          "使用綁定市民限定乘車優惠的電子票證可享「10公里免費＋超過10公里車資上限10元」的雙十優惠。",
                                      style: TextStyle(fontSize: 16, height: 1.5),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "2. 非市民搭乘依里程計費，投現上車應付車資全票20元、半票11元，"
                                          "超過基本里程再依實際搭乘距離計算下車應付車資；另使用電子票證，"
                                          "刷卡上車應付車資全票僅扣15元(享有5元的優惠)、半票11元，超過基本里程再依實際搭乘距離計算下車應付車資。",
                                      style: TextStyle(fontSize: 16, height: 1.5),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "3. 臺中市委託發行敬老愛心卡先享有雙十乘車優惠，即搭乘距離在10公里內不會扣點，"
                                          "搭乘超過10公里最多扣10點。",
                                      style: TextStyle(fontSize: 16, height: 1.5),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "4. 電子票證包含悠遊卡 (EASYCARD)、一卡通 (iPASS)、愛金卡 (icash2.0)。",
                                      style: TextStyle(fontSize: 16, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )

                  ),
                );

                break;
              case "B":

                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Scaffold(
                          appBar: AppBar(
                            backgroundColor: busBlue,
                            elevation: 0,
                            title: const Text(
                              "通阻消息",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          body:ValueListenableBuilder<String>(
                              valueListenable: currentCityNotifier,
                              builder: (context, currentCity, child) {
                                return FutureBuilder<dynamic>(
                                  future: fetchByUrl(
                                    "https://tdx.transportdata.tw/api/basic/v2/Bus/Alert/City/${ correspondingIDNotifier.value}?%24top=10&%24format=JSON",
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(child: Text('Error: ${snapshot.error}'));
                                    } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                                      return const Center(child: Text('No data available.'));
                                    } else {
                                      final data = snapshot.data as List;
                                      return  Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Custom Dropdown
                                            CustomDropdown<String>(
                                              hintText: '選擇城市',
                                              items: _list,
                                              initialItem: currentCityNotifier.value,
                                              onChanged: (value) {
                                                setState(()  {
                                                  currentCityNotifier.value=value!;
                                                  updatedCorrespondingID();
                                                  _getData();
                                                  // 重新觸發 FutureBuilder
                                                  updateCurrent();


                                                });
                                              },

                                            ),
                                            const SizedBox(height: 16), // 增加間距
                                            // Expanded ListView
                                            Expanded(
                                              child: ListView.builder(
                                                itemCount: data.length,
                                                itemBuilder: (context, index) {
                                                  final alert = data[index];
                                                  return Container(
                                                      margin: const EdgeInsets.only(bottom: 12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.05), // 微弱陰影
                                                            offset: const Offset(0, 4),
                                                            blurRadius: 8,
                                                          ),
                                                        ],
                                                      ),
                                                      child: ValueListenableBuilder<String>(
                                                          valueListenable: currentCityNotifier,
                                                          builder: (context, currentCity, child) {
                                                            return ListTile(
                                                              contentPadding: const EdgeInsets.all(16.0),
                                                              title: Text(
                                                                alert['Title'] ?? '無標題',
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 18,
                                                                  color: Colors.black,
                                                                ),
                                                              ),
                                                              subtitle: Text(
                                                                alert['Description'] ?? '無描述',
                                                                style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                            );})
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );


                                    }
                                  },
                                );})
                      )

                  ),
                );


                break;

            }
          },
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    updateCurrent();
    return Scaffold(
      appBar: _buildAppBar(),
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
                initialItem: currentCityNotifier.value,
                onChanged: (value) {

                  setState(()  {
                    currentCityNotifier.value=value!;
                    updatedCorrespondingID();
                    _getData();
                    // 重新觸發 FutureBuilder
                    updateCurrent();
                    // _updateSuggestions("route");
                  });

                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 70,
                child: Row(
                  children: [

                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        boxShadow: const [
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
                            items: <String>['路線', '站牌', ]
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
                              double screenHeight = MediaQuery.of(context).size.height;
                              double bottomInset = MediaQuery.of(context).viewInsets.bottom;
                              double appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
                              if (_dropdownValueNotifier.value == "路線") {
                                 await _updateSuggestions('route');
                                 setState(() {
                                   suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 14 - 70;
                                 });
                              } else if (_dropdownValueNotifier.value == "站牌") {
                                await _updateSuggestions('stop');
                                setState(() {
                                  suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 14 - 70;
                                });
                              }
                            } else {
                              suggestions.value.clear();
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

                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              color: Colors.grey[700],
                              onPressed: () {
                                busIdController.clear();
                                _dropdownValueNotifier.value = '路線';
                                suggestions.value.clear();
                                suggestionsHeightNotifier.value = 0;
                              },
                            ),
                          ),
                          style: const TextStyle(color: Colors.black87, fontSize: 16),
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
                        child: suggestions.value.isNotEmpty
                            ? _dropdownValueNotifier.value == "路線"
                            ?
                        // Buslist(suggestions:suggestions.value )
                        FutureBuilder(
                          future: _updateSuggestions('route',), // 等待 _updateSuggestions() 完成
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(), // 显示加载指示器
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("加载失败: ${snapshot.error}"), // 显示错误信息
                              );
                            } else {
                              // 数据加载完成后，显示 Buslist
                              return Buslist(
                                suggestions: snapshot.data ?? [],
                                city: correspondingIDNotifier.value == 'all'
                                    ? "Taipei,Taichung"
                                    : correspondingIDNotifier.value,
                              );

                            }
                          },
                        )
                            : _dropdownValueNotifier.value == "站牌"
                            ? BusStopList(suggestions.value)
                            : const Center(child: Text("請選擇"))
                            : const Center(child: Text("沒有找到結果", style: TextStyle(color: Colors.grey))),
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
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white.withOpacity(0.95)
            : Colors.grey[900]!.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildPageView()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white.withOpacity(0.7)
            : Colors.grey[850]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) => _buildTabItem(index),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final bool isSelected = _current == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _current = index;
            updateCurrent();
          });
          pageController.animateToPage(
            _current,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 90,
                height: 60,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [
                      busBlue.withOpacity(0.9),
                      busBlue.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                    color: busBlue.withOpacity(0.5),
                    width: 1.5,
                  )
                      : null,
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: busBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: isSelected ? 24 : 20,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(top: 4),
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: busBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
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
              return _buildList('FavoritesRoute', _buildRouteListItem);
            case "stop":
              return _buildList('FavoritesStop', _buildStopListItem);
            case "routeplan":
              return RoutePlanner();
          default:
              return const Center(child: Text("開發中"));
          }
        },
      ),
    );
  }

  Widget _buildList(String key, Widget Function(dynamic) itemBuilder) {

      ValueNotifier<List<Map<String, dynamic>>>? notifier;

      if (key == "FavoritesRoute") {
        notifier = favoriteRoutes;
      } else if (key == "FavoritesStop") {
        notifier = favoriteStops;
      } else {
        return const Center(child: Text("無效的選項"));
      }

      return FutureBuilder<int>(
        future: updateCurrent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("載入失敗"));
          } else if (!snapshot.hasData || notifier!.value.isEmpty) {
            return Center(child: _NoFavoritesWidget());
          }

          final items = notifier?.value;
          return ListView.separated(
            itemCount: items!.length,
            itemBuilder: (context, index) => itemBuilder(items[index]),
            separatorBuilder: (context, index) => const Divider(
              color: Color.fromRGBO(231, 231, 231, 1), // 分隔線顏色
              height: 9, // 間距
              thickness: 1, // 粗細
              indent: 20, // 左側間距
              endIndent: 20, // 右側間距
            ),
          );
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
  Widget _buildStopListItem( stop) {
    return _buildListItem(stop["stopName"], () => _showConfirmDialog(context, stop["stopName"],"FavoritesStop"), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BusStopInfo(stop["stopName"], city:correspondingIDNotifier.value ,)),
      );
    });
  }
void updatedCorrespondingID(){
  // 查找 currentCity 在 _list 中的索引
  int index = _list.indexOf(currentCityNotifier.value);

  if (index != -1 ) {
  // 获取 _listID 中对应的值

      correspondingIDNotifier.value = _listID[index];


  } else {
  print('City not found in the list');

  }// 调用异步初始化函数

}
  Widget _buildRouteListItem( route) {

    return _buildListItemRoute(route, () => _showConfirmDialog(context, route["routeName"],"FavoritesRoute"),() async {

      await GetBusInfo( routeid: route["routeID"], city: correspondingIDNotifier.value);
      List baseData= await mysqlSelect("SELECT * FROM Bus.Bus_${ correspondingIDNotifier.value}_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))='${route["routeName"]}'");

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context,) => BusTime(
          routeName:(route)["routeName"],
          departureStopName:(route)["DepartureStopNameZh"],
          destinationStopName:(route)["DestinationStopNameZh"],
          operators: "",
          routeMapImageUrl:baseData[0]["RouteMapImageUrl"],
          city:  correspondingIDNotifier.value, routeID: (route["routeID"]),


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
  Widget _buildListItemRoute( jsonData, VoidCallback onConfirm, [VoidCallback? onTap]) {
    return

      ListTile(
        title: Text((jsonData["routeName"]).toString()
          ,style:
          const TextStyle(
              fontFamily: "MiSans-Demibold",
              fontSize: 21

          ),
        ),
        subtitle: Text('${jsonData["DepartureStopNameZh"].toString()}-${jsonData["DestinationStopNameZh"].toString()} '
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
    favorite_feature db=favorite_feature();
    if(SharedPreferencesList=="FavoritesRoute"){
     await db.removeFavorite(routeName: item, city: correspondingIDNotifier.value, table: SharedPreferencesList,);

    }else if(SharedPreferencesList=="FavoritesStop"){
     await db.removeFavorite(stopName: item, city: correspondingIDNotifier.value, table: SharedPreferencesList,);

    }
setState(() {

});
    // await _loadFavorites(); // 重新加载收藏列表
  }
  Widget BusStopList(List suggestions) {
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
                  MaterialPageRoute(builder: (context) => BusStopInfo(suggestions[index].toString(), city: correspondingIDNotifier.value,)),
                );
              },
            ),


          );



      },
    );





  }

}

