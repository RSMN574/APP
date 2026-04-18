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



class BusState extends State<Bus> {
  final List<IconData> icons = [Icons.favorite, Icons.favorite, Icons.route, Icons.airport_shuttle];
  final List<String> items = ["收藏路線", "收藏站牌", "規劃", "接駁車"];
  final List<String> id = ["route", "stop", "routeplan", "shuttleBus"];
  int _current = 0;
  final PageController pageController = PageController();
  ValueNotifier<List<Map<String, dynamic>>> favoriteStops = ValueNotifier([]);
  ValueNotifier<List<Map<String, dynamic>>> favoriteRoutes = ValueNotifier([]);
  List busData = [];
  final List<String> _list = ['全部', '臺中市', '臺北市','新北市','桃園市',"臺南市","高雄市","基隆市","新竹市","公路客運"];
  final List<String> _listID = ['all', 'Taichung', 'Taipei','NewTaipei',"Taoyuan","Tainan","Kaohsiung","Keelung","Hsinchu","InterCity"];
  ValueNotifier<String> currentCityNotifier = ValueNotifier<String>("全部");
  ValueNotifier<String> correspondingIDNotifier = ValueNotifier<String>("");
  final ValueNotifier<String> _dropdownValueNotifier = ValueNotifier<String>('路線');
  final ValueNotifier<double> suggestionsHeightNotifier = ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  final ValueNotifier<List> suggestions = ValueNotifier<List>([]);

  // 顏色定義 - 使用航班主題
  final Color _primaryColor = const Color(0xFF1A73E8);
  final Color _secondaryColor = const Color(0xFFEEF3FB);


  Future? _suggestionFuture; // 用來存住請求的結果
  String _lastQuery = "";      // 用來紀錄上次搜尋的內容，避免重複請求
  Future<int> updateCurrent() async {
    favoriteRoutes.value = await _loadFavorites("FavoritesRoute", city: correspondingIDNotifier.value);
    favoriteStops.value = await _loadFavorites("FavoritesStop", city: correspondingIDNotifier.value);
    return 200;
  }

  @override
  void initState() {
    super.initState();
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;
    if (_list.contains(currentCity)) {
      currentCityNotifier.value = currentCity;
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

  Future<void> _initializeFavorites() async {
    try {
      favorite_feature dbHelper = favorite_feature();
      await dbHelper.initDatabase();
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadFavorites(String key, {required String city}) async {
    favorite_feature db = favorite_feature();
    final favorites = await db.getFavorites(key, correspondingIDNotifier.value, city);
    return favorites;
  }

  Future<List> _getData() async {
    busCurrentCity = correspondingIDNotifier.value;
    busData = await getBusRoute(city:correspondingIDNotifier.value);
    return [];
  }

  Future<List<dynamic>> _updateSuggestions(String id) async {
    suggestions.value.clear();

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
    } else if (id == "stop") {
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

// 精緻風格的 AppBar
  AppBar _buildAppBar() {
    return AppBar(
      // backgroundColor: _primaryColor,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_bus,
              color: Color(0xFF1A73E8),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "公車資訊",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,

            ),
          ),
        ],
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, size: 24),
          onPressed: _showInfoMenu,
        ),
      ],
    );
  }

  void _showInfoMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.confirmation_number_rounded,
              title: '票價說明',
              subtitle: '查看公車票價資訊',
              onTap: _navigateToFareInfo,
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              icon: Icons.warning_amber_rounded,
              title: '通阻消息',
              subtitle: '查看交通中斷資訊',
              onTap: _navigateToAlertInfo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A73E8),
                      const Color(0xFF1A73E8).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,

                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,

                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }


  void _navigateToFareInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(

            elevation: 0,
            title: const Text("票價說明"),
          ),
          body: _buildFareInfoContent(),
        ),
      ),
    );
  }

  Widget _buildFareInfoContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCityDropdown(false),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "票價細則",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppThemes.getPrimary(context),
                    ),
                  ),
                ),
                // 內容
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoText("1. 臺中市民、市民的新住民配偶及臺中就學的外縣市學生，使用綁定市民限定乘車優惠的電子票證可享「10公里免費＋超過10公里車資上限10元」的雙十優惠。"),
                    const SizedBox(height: 12),
                    _buildInfoText("2. 非市民搭乘依里程計費，投現上車應付車資全票20元、半票11元，超過基本里程再依實際搭乘距離計算下車應付車資；另使用電子票證，刷卡上車應付車資全票僅扣15元(享有5元的優惠)、半票11元，超過基本里程再依實際搭乘距離計算下車應付車資。"),
                    const SizedBox(height: 12),
                    _buildInfoText("3. 臺中市委託發行敬老愛心卡先享有雙十乘車優惠，即搭乘距離在10公里內不會扣點，搭乘超過10公里最多扣10點。"),
                    const SizedBox(height: 12),
                    _buildInfoText("4. 電子票證包含悠遊卡 (EASYCARD)、一卡通 (iPASS)、愛金卡 (icash2.0)。"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  void _navigateToAlertInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            // backgroundColor: _primaryColor,
            elevation: 0,
            title: const Text("通阻消息"),
          ),
          body: ValueListenableBuilder<String>(
            valueListenable: currentCityNotifier,
            builder: (context, currentCity, child) {
              return FutureBuilder<dynamic>(
                future: fetchByUrl(
                  "https://tdx.transportdata.tw/api/basic/v2/Bus/Alert/City/${correspondingIDNotifier.value}?%24top=10&%24format=JSON",
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                    return _buildNoDataWidget();
                  } else {
                    final data = snapshot.data as List;
                    return _buildAlertList(data);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlertList(List data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCityDropdown(false),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final alert = data[index];
                return _buildAlertCard(alert);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning, color: Color(0xFF1A73E8), size: 20),
        ),
        title: Text(
          alert['Title'] ?? '無標題',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          alert['Description'] ?? '無描述',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暫無通阻消息',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown([bool includeAll = true] ) {
    final filteredList = includeAll
        ? _list
        : _list.where((item) => item != '全部').toList();

    return Container(
      // margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(

            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              size: 20,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '選擇城市',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemes.getOnSurface(context),
            ),
          ),
          const Spacer(),
          // 為 CustomDropdown 提供明確的寬度約束
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              // 自動切換背景色：淺色白 / 深色 0xFF1C1C1E
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.15),
              ),
              boxShadow: [
                if (Theme.of(context).brightness == Brightness.light)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // 下拉選單整體的背景與形狀
                dropdownColor: AppThemes.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                isExpanded: true,

                // 設定目前的數值與圖示
                value: currentCityNotifier.value == '全部' && !includeAll
                    ? null
                    : currentCityNotifier.value,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded, // 圓角箭頭
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),

                // --- 1. 平時顯示在框框內的樣子 ---
                selectedItemBuilder: (BuildContext context) {
                  return filteredList.map<Widget>((String value) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded, // 縣市定位圖示
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },

                // --- 2. 點開後的清單佈局 ---
                items: filteredList.map((String value) {
                  final isSelected = currentCityNotifier.value == value;
                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return DropdownMenuItem<String>(
                    value: value,

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        // 選中時高亮：深色模式使用 10% 透明白，淺色用品牌淡藍
                        // color: isSelected
                        //     ? (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFEEF3FB))
                        //     : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // 狀態小圓點
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentCityNotifier.value = value;
                      updatedCorrespondingID();
                      _getData();
                      updateCurrent();
                    });
                  }
                },
              ),
            ),
          )
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    updateCurrent();
    return Scaffold(

      appBar: _buildAppBar(),

      body: GestureDetector(
        onTap: () => hideKeyboard(context),
        child: Column(
          children: [
            // 城市選擇
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCityDropdown(),
            ),

            // 搜尋區域
            _buildSearchSection(),

            // 主要內容區域
            Expanded(
              child: Stack(
                children: [
                  _buildMainContent(),
                  _buildSuggestionsOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 搜尋類型下拉選單
          Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppThemes.getSurface(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _dropdownValueNotifier,
              builder: (context, value, child) {



                return    SizedBox(
                  width: 130, // 稍微增加一點寬度以容納圖示
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppThemes.getCardColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                      ),
                      boxShadow: [
                        if (Theme.of(context).brightness == Brightness.light)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _dropdownValueNotifier.value,
                        isExpanded: true,
                        dropdownColor: AppThemes.getCardColor(context),
                        borderRadius: BorderRadius.circular(16),
                        icon: Icon(
                          Icons.unfold_more_rounded, // 換一個更有質感的圖示
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        // --- 1. 平時顯示在框框內的樣子 ---
                        selectedItemBuilder: (BuildContext context) {
                          return ['路線', '站牌'].map<Widget>((String value) {
                            return Container(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    value == '路線' ? Icons.alt_route_rounded : Icons.place_rounded,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },

                        // --- 2. 點開後的清單佈局 ---
                        items: <String>['路線', '站牌'].map((String value) {
                          final isSelected = _dropdownValueNotifier.value == value;
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          return DropdownMenuItem<String>(
                            value: value,
                            // 移除預設 padding 以便 AnimatedContainer 填滿

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                // 選中時的高亮色：淺色用淡藍，深色用白透明
                                // color: isSelected
                                //     ? (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFEEF3FB))
                                //     : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  // 狀態圓點
                                  // Container(
                                  //   width: 7,
                                  //   height: 7,
                                  //   decoration: BoxDecoration(
                                  //     color: isSelected
                                  //         ? Theme.of(context).colorScheme.primary
                                  //         : Colors.grey.withOpacity(0.5),
                                  //     shape: BoxShape.circle,
                                  //   ),
                                  // ),
                                  // const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _dropdownValueNotifier.value = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 搜尋輸入框
          Expanded(
            child: Container(

              decoration: BoxDecoration(
                // 自動切換背景色：淺色白 / 深色 0xFF1C1C1E
                color: AppThemes.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                ),
                boxShadow: [
                  if (Theme.of(context).brightness == Brightness.light)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
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
                        suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 200;
                      });
                    } else if (_dropdownValueNotifier.value == "站牌") {
                      await _updateSuggestions('stop');
                      setState(() {
                        suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 200;
                      });
                    }
                  } else {
                    suggestions.value.clear();
                    suggestionsHeightNotifier.value = 0;
                  }
                },
                controller: busIdController,
                decoration: InputDecoration(
                  hintText: '搜尋公車路線或站牌...',
                  hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark?Colors.grey[400]:Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[700], size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    color: Theme.of(context).brightness == Brightness.dark?Colors.grey[400]:Colors.grey[700],
                    onPressed: () {
                      busIdController.clear();
                      suggestions.value.clear();
                      suggestionsHeightNotifier.value = 0;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(  color: Theme.of(context).brightness == Brightness.dark?Colors.grey[400]:Colors.black87, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _current = index;
            updateCurrent();
          });
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
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [
                const Color(0xFF1A73E8),
                const Color(0xFF1A73E8).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [
                Colors.white,
                Colors.grey[50]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF1A73E8).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: isSelected
                ? Border.all(color: const Color(0xFF1A73E8).withOpacity(0.2), width: 1.5)
                : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFEEF3FB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icons[index],
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                items[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1A73E8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      itemCount: id.length,
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        switch (id[index]) {
          case "route":
            return _buildFavoriteRoutes();
          case "stop":
            return _buildFavoriteStops();
          case "routeplan":
            return RoutePlanner();
          default:
            return _buildComingSoon();
        }
      },
    );
  }

  Widget _buildFavoriteRoutes() {
    return _buildFavoriteList(
      favoriteRoutes,
      _buildRouteCard,
      '收藏路線',
    );
  }

  Widget _buildFavoriteStops() {
    return _buildFavoriteList(
      favoriteStops,
      _buildStopCard,
      '收藏站牌',
    );
  }

  Widget _buildFavoriteList(
      ValueNotifier<List<Map<String, dynamic>>> notifier,
      Widget Function(Map<String, dynamic>) itemBuilder,
      String emptyMessage,
      ) {
    return FutureBuilder<int>(
      future: updateCurrent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('載入失敗: ${snapshot.error}'));
        } else if (!snapshot.hasData || notifier.value.isEmpty) {
          return _buildEmptyState(emptyMessage);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifier.value.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) => itemBuilder(notifier.value[index]),
        );
      },
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return _buildInfoCard(
      title: route["routeName"]?.toString() ?? '',
      subtitle: '${route["DepartureStopNameZh"]} - ${route["DestinationStopNameZh"]}',
      onTap: () => _navigateToRouteDetails(route),
      onRemove: () => _showConfirmDialog(context, route["routeName"], "FavoritesRoute"),
    );
  }

  Widget _buildStopCard(Map<String, dynamic> stop) {
    return _buildInfoCard(
      title: stop["stopName"]?.toString() ?? '',
      onTap: () => _navigateToStopDetails(stop),
      onRemove: () => _showConfirmDialog(context, stop["stopName"], "FavoritesStop"),
    );
  }

  Widget _buildInfoCard({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            onRemove != null ? Icons.directions_bus : Icons.favorite,
            color: _primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        )
            : null,
        trailing: onRemove != null
            ? IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: onRemove,
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暫無$message',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快去添加一些喜歡的吧！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '功能開發中',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return ValueListenableBuilder<double>(
      valueListenable: suggestionsHeightNotifier,
      builder: (context, height, child) {
        if (height <= 0) return const SizedBox();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: suggestions.value.isNotEmpty
                ? _buildSuggestionsList()
                : const Center(child: Text("沒有找到結果", style: TextStyle(color: Colors.grey))),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    if (_dropdownValueNotifier.value == "路線") {
      // 關鍵：如果 _suggestionFuture 是空的，或是搜尋關鍵字變了，才重新抓取
      // 假設你的搜尋文字存在 _searchController.text
      if (_suggestionFuture == null || _lastQuery != busIdController.text) {
        _lastQuery = busIdController.text;
        _suggestionFuture = _updateSuggestions('route');
      }

      return FutureBuilder(
        future: _suggestionFuture, // 使用存好的變數，返回時它依然是同一個對象
        builder: (context, snapshot) {
          // 如果已經有舊資料了，即便在 loading 也不要顯示轉圈圈（這樣返回才不會閃爍）
          if (snapshot.hasData) {
            return Buslist(
              suggestions: snapshot.data ?? [],
              city: correspondingIDNotifier.value == 'all' ? "Taipei,Taichung" : correspondingIDNotifier.value,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Buslist(
            suggestions: const [],
            city: correspondingIDNotifier.value == 'all' ? "Taipei,Taichung" : correspondingIDNotifier.value,
          );
        },
      );
    } else {
      return BusStopList(suggestions.value);
    }
  }

  // 其他方法保持不變，但使用新的顏色變數
  void updatedCorrespondingID() {
    int index = _list.indexOf(currentCityNotifier.value);
    if (index != -1) {
      correspondingIDNotifier.value = _listID[index];
    }
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _navigateToRouteDetails(Map<String, dynamic> route) async {

    List baseData = await mysqlSelect("""SELECT *
FROM Bus.bus_route
WHERE City = '${correspondingIDNotifier.value}'
  AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))
      = '${route["routeName"]}'
""");
// 1. 取得原始資料
    String rawCity = correspondingIDNotifier.value;
    String rawRouteID = route["RouteID"].toString();

    // 2. 判斷城市並決定是否補 0
    // 定義需要補 0 的城市清單 (依據 TDX 經驗，基隆、新竹、新竹縣、屏東較常需要)
    final List<String> needsPaddingCities = [
      'Keelung',
      'Hsinchu',
      'HsinchuCounty',
      'Pingtung',
      'InterCity' // 公路客運也建議檢查
    ];

    String finalRouteID;
    if (needsPaddingCities.contains(rawCity)) {
      // 如果在清單內，補足 4 位數
      finalRouteID = rawRouteID.padLeft(4, '0');
      print("📍 城市 $rawCity 需要補0，轉換後 ID: $finalRouteID");
    } else {
      finalRouteID = rawRouteID;
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusTime(
          routeName: route["routeName"],
          departureStopName: route["DepartureStopNameZh"],
          destinationStopName: route["DestinationStopNameZh"],
          operators: "",
          routeMapImageUrl: baseData[0]["RouteMapImageUrl"],
          city: correspondingIDNotifier.value,
          routeID: finalRouteID,
            hasSubRoutes:route["HasSubRoutes"]
        ),
      ),
    );
  }

  void _navigateToStopDetails(Map<String, dynamic> stop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopInfo(
          stop["stopName"],
          city: correspondingIDNotifier.value,
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String item, String SharedPreferencesList) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: '確定取消收藏嗎',
      confirmBtnText: '確認',
      cancelBtnText: '取消',
      confirmBtnColor: Colors.green,
      onCancelBtnTap: () => Navigator.pop(context),
      onConfirmBtnTap: () {
        _removeFavorite(context, item, SharedPreferencesList);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _removeFavorite(BuildContext context, String item, String SharedPreferencesList) async {
    favorite_feature db = favorite_feature();
    if (SharedPreferencesList == "FavoritesRoute") {
      await db.removeFavorite(routeName: item, city: correspondingIDNotifier.value, table: SharedPreferencesList);
    } else if (SharedPreferencesList == "FavoritesStop") {
      await db.removeFavorite(stopName: item, city: correspondingIDNotifier.value, table: SharedPreferencesList);
    }
    setState(() {});
  }

  Widget BusStopList(List suggestions) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: index == 0 ? _secondaryColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.place, size: 16, color: Color(0xFF1A73E8)),
            ),
            title: Text(
              suggestions[index].toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusStopInfo(
                    suggestions[index].toString(),
                    city: correspondingIDNotifier.value,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

