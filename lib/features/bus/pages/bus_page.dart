import 'dart:async';
import 'dart:convert';
import 'package:com.rsmn574.app/features/bus/pages/bus_stop_info_page.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_time_page.dart';
import 'package:com.rsmn574.app/features/bus/pages/route_planning_page.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/features/bus/widgets/bus_list.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/database/sql/favorite_feature.dart';
import 'package:com.rsmn574.app/database/get_data.dart';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_provider.dart';

Timer? _debounceTimer; // 在你的 State 類別頂部宣告這個變數

class Bus extends StatefulWidget {
  const Bus({Key? key}) : super(key: key);

  @override
  State<Bus> createState() => BusState();
}

enum SearchType {
  route,
  stop,
}

final ValueNotifier<SearchType> _dropdownValueNotifier =
    ValueNotifier(SearchType.route);

class MenuItemData {
  final String id;
  final String title;
  final IconData icon;

  const MenuItemData({
    required this.id,
    required this.title,
    required this.icon,
  });
}

final List<CityItem> cities = [
  CityItem(name: '全部', id: 'all'),
  CityItem(name: '臺中市', id: 'Taichung'),
  CityItem(name: '臺北市', id: 'Taipei'),
  CityItem(name: '新北市', id: 'NewTaipei'),
  CityItem(name: '桃園市', id: 'Taoyuan'),
  CityItem(name: '臺南市', id: 'Tainan'),
  CityItem(name: '高雄市', id: 'Kaohsiung'),
  CityItem(name: '基隆市', id: 'Keelung'),
  CityItem(name: '新竹市', id: 'Hsinchu'),
  CityItem(name: '公路客運', id: 'InterCity'),
];
final List<MenuItemData> menuItems = [
  MenuItemData(
    id: 'route',
    title: 'text_1',
    icon: Icons.favorite,
  ),
  MenuItemData(
    id: 'stop',
    title: 'text_2',
    icon: Icons.favorite,
  ),
  MenuItemData(
    id: 'routeplan',
    title: 'text_3',
    icon: Icons.route,
  ),
  MenuItemData(
    id: 'shuttleBus',
    title: 'text_4',
    icon: Icons.airport_shuttle,
  ),
];

class BusState extends State<Bus> {
  int _current = 0;
  final PageController pageController = PageController();
  ValueNotifier<List<Map<String, dynamic>>> favoriteStops = ValueNotifier([]);
  ValueNotifier<List<BusRoute>> favoriteRoutes = ValueNotifier([]);
  List<BusRoute> busData = [];
  ValueNotifier<String> currentCityNotifier = ValueNotifier<String>("全部");
  ValueNotifier<String> correspondingIDNotifier = ValueNotifier<String>("");

  final ValueNotifier<double> suggestionsHeightNotifier =
      ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  final ValueNotifier<List> suggestions = ValueNotifier<List>([]);

  // 顏色定義 - 使用航班主題
  final Color _primaryColor = const Color(0xFF1A73E8);
  final Color _secondaryColor = const Color(0xFFEEF3FB);

  Future<List<dynamic>>? _suggestionFuture; // 確保有寫 List<dynamic> 用來存住請求的結果
  String _lastQuery = ""; // 用來紀錄上次搜尋的內容，避免重複請求
// 修正後的 updateCurrent 方法
  Future<int> updateCurrent() async {
    try {
      final db = FavoriteService();
      final city = correspondingIDNotifier.value;

      final routes = await db.getFavoriteRoutes(city: city);

      favoriteRoutes.value = routes.map((e) {
        final routeName = e['routeName']?.toString() ?? '';
        final operatorName = e['operatorName']?.toString() ?? '';

        return BusRoute.fromJson({
          'RouteUID': e['routeUID']?.toString() ?? '',
          'RouteID': e['routeID']?.toString() ?? '',
          'RouteName': jsonEncode({
            'Zh_tw': routeName,
            'En': e['routeNameEn']?.toString() ?? routeName,
          }),
          'HasSubRoutes': e['hasSubRoutes'] == 1 || e['hasSubRoutes'] == true,
          'Operators': jsonEncode([
            {
              'OperatorName': {
                'Zh_tw': operatorName,
                'En': operatorName,
              }
            }
          ]),
          'SubRoutes': jsonEncode([
            {
              'FirstBusTime': e['firstBusTime']?.toString() ?? '',
              'LastBusTime': e['lastBusTime']?.toString() ?? '',
            }
          ]),
          'DepartureStopNameZh': e['departureStopNameZh']?.toString() ?? '',
          'DepartureStopNameEn': e['departureStopNameEn']?.toString() ?? '',
          'DestinationStopNameZh': e['destinationStopNameZh']?.toString() ?? '',
          'DestinationStopNameEn': e['destinationStopNameEn']?.toString() ?? '',
          'TicketPriceDescriptionZh': e['ticketPriceDescriptionZh'],
          'TicketPriceDescriptionEn': e['ticketPriceDescriptionEn'],
          'RouteMapImageUrl': e['routeMapImageUrl'],
          'City': e['city']?.toString() ?? '',
          'CityCode': e['cityCode']?.toString() ?? '',
          'UpdateTime': DateTime.now().toIso8601String(),
          'VersionID': '0',
        });
      }).toList();

      final stops = await db.getFavoriteStops(city: city);
      favoriteStops.value = stops;

      return 200;
    } catch (e) {
      print('更新收藏數據失敗: $e');
      return 500;
    }
  }

  @override
  void initState() {
    super.initState();
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;

// 檢查城市是否存在於列表中
    if (cities.any((city) => city.name == currentCity)) {
      currentCityNotifier.value = currentCity;
    }
    _initializeFavorites();
    updatedCorrespondingID();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_getData());
    });
    updateCurrent();
  }

  @override
  void dispose() {
    pageController.dispose();
    favoriteStops.dispose();
    favoriteRoutes.dispose();
    suggestionsHeightNotifier.dispose();
    busIdController.dispose();
    suggestions.dispose();
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

  Future<List<dynamic>> _loadFavorites(String key,
      {required String city}) async {
    FavoriteService db = FavoriteService();

    if (key == "FavoritesRoute") {
      // 返回 BusRoute 列表
      return await db.getFavoriteBusRoutes(city: city);
    } else if (key == "FavoritesStop") {
      // 返回 Map 列表
      return await db.getFavoriteStops(city: city);
    }

    return [];
  }

  Future<List<BusRoute>> _getData() async {
    final city = correspondingIDNotifier.value;
    busCurrentCity = city;

    try {
      final routes = await context.read<BusProvider>().loadRoutes(city);
      if (!mounted) return routes;
      setState(() {
        busData = routes;
      });
      return routes;
    } catch (error) {
      if (mounted) {
        setState(() {
          busData = [];
        });
      }
      debugPrint('Unable to load bus routes for $city: $error');
      return [];
    }
  }

  Future<List<dynamic>> _updateSuggestions(String id) async {
    suggestions.value.clear();

    if (id == "route") {
      final String input = busIdController.text;
      final List<dynamic> suggestionsForRoute = [];

      for (final route in busData) {
        final locale = Localizations.localeOf(context);

        final routeName =
            locale.languageCode == 'en' ? route.routeEn : route.routeZh;

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
      final locale = Localizations.localeOf(context);
      final rawData;
      if (locale.languageCode == 'zh') {
        rawData = await mysqlSelect(
            "SELECT StationName FROM Bus.Bus_${correspondingIDNotifier.value}_Stop "
            "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE '%$input%'");
      } else if (locale.languageCode == 'en') {
        rawData = await mysqlSelect(
            "SELECT StationName FROM Bus.Bus_${correspondingIDNotifier.value}_Stop "
            "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.En')) LIKE '%$input%'");
      } else {
        rawData = await mysqlSelect(
            "SELECT StationName FROM Bus.Bus_${correspondingIDNotifier.value}_Stop "
            "WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE '%$input%'");
      }

      final seen = <String>{};
      for (var item in rawData) {
        final name = locale.languageCode == 'en'
            ? json.decode(item["StationName"])["En"]
            : json.decode(item["StationName"])["Zh_tw"];
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
          Text(
            AppLocalizations.of(context)!.text_16,
            style: const TextStyle(
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
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
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
              title: AppLocalizations.of(context)!.text_17,
              subtitle: AppLocalizations.of(context)!.text_18,
              onTap: _navigateToFareInfo,
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              icon: Icons.warning_amber_rounded,
              title: AppLocalizations.of(context)!.text_19,
              subtitle: AppLocalizations.of(context)!.text_20,
              onTap: _navigateToAlertInfo,
            ),
          ],
        ),
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
            title: Text(AppLocalizations.of(context)!.text_17),
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
                    AppLocalizations.of(context)!.text_21,
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
                    _buildInfoText(AppLocalizations.of(context)!.text_22),
                    const SizedBox(height: 12),
                    _buildInfoText(AppLocalizations.of(context)!.text_23),
                    const SizedBox(height: 12),
                    _buildInfoText(AppLocalizations.of(context)!.text_24),
                    const SizedBox(height: 12),
                    _buildInfoText(
                        "4. 電子票證包含悠遊卡 (EASYCARD)、一卡通 (iPASS)、愛金卡 (icash2.0)。"),
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
            title: Text(AppLocalizations.of(context)!.text_19),
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
                  } else if (!snapshot.hasData ||
                      (snapshot.data as List).isEmpty) {
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
          alert['Title'] ?? AppLocalizations.of(context)!.text_25,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          alert['Description'] ?? AppLocalizations.of(context)!.text_26,
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
            AppLocalizations.of(context)!.text_27,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown([bool includeAll = true]) {
    final filteredList = includeAll
        ? cities
        : cities
            .where(
              (city) => city.name != AppLocalizations.of(context)!.text_5,
            )
            .toList();
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
            AppLocalizations.of(context)!.text_28,
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
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                // 下拉選單整體的背景與形狀
                dropdownColor: AppThemes.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                isExpanded: true,

                // 設定目前的數值與圖示
                value: currentCityNotifier.value ==
                            AppLocalizations.of(context)!.text_5 &&
                        !includeAll
                    ? null
                    : currentCityNotifier.value,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded, // 圓角箭頭
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),

                // --- 1. 平時顯示在框框內的樣子 ---
                selectedItemBuilder: (BuildContext context) {
                  return filteredList.map<Widget>((CityItem city) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              city.name,
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
                items: filteredList.map((CityItem city) {
                  final isSelected = currentCityNotifier.value == city.name;

                  return DropdownMenuItem<String>(
                    value: city.name,
                    child: Row(
                      children: [
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
                            city.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
            // 搜尋類型下拉選單
            Container(
              width: 130,
              margin: const EdgeInsets.only(left: 4, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppThemes.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ValueListenableBuilder<SearchType>(
                valueListenable: _dropdownValueNotifier,
                builder: (context, value, child) {
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<SearchType>(
                      value: _dropdownValueNotifier.value,
                      isExpanded: true,
                      dropdownColor: AppThemes.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return SearchType.values.map<Widget>((type) {
                          final isSelected =
                              _dropdownValueNotifier.value == type;
                          final icon = type == SearchType.route
                              ? Icons.alt_route_rounded
                              : Icons.place_rounded;

                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type == SearchType.route ? '路線' : '站牌',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (SearchType? newValue) {
                        if (newValue != null) {
                          _dropdownValueNotifier.value = newValue;
                        }
                      },
                      items: SearchType.values.map((type) {
                        final isSelected = _dropdownValueNotifier.value == type;
                        final icon = type == SearchType.route
                            ? Icons.alt_route_rounded
                            : Icons.place_rounded;

                        return DropdownMenuItem<SearchType>(
                          value: type,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[800]
                                            : const Color(0xFFEEF3FB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : const Color(0xFF1A73E8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    type == SearchType.route ? '路線' : '站牌',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[300]
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1A73E8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),

            // 分隔線
            Container(
              width: 1,
              height: 32,
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),

            // 搜尋輸入框
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 4),
                decoration: BoxDecoration(
                  color: AppThemes.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (text) async {
                    if (text.isNotEmpty) {
                      double screenHeight = MediaQuery.of(context).size.height;
                      double bottomInset =
                          MediaQuery.of(context).viewInsets.bottom;
                      double appBarHeight = AppBar().preferredSize.height +
                          MediaQuery.of(context).padding.top;

                      if (_dropdownValueNotifier.value == SearchType.route) {
                        await _updateSuggestions('route');
                        suggestionsHeightNotifier.value =
                            screenHeight - bottomInset - appBarHeight - 200;
                      } else if (_dropdownValueNotifier.value ==
                          SearchType.stop) {
                        await _updateSuggestions('stop');
                        suggestionsHeightNotifier.value =
                            screenHeight - bottomInset - appBarHeight - 200;
                      }
                    } else {
                      suggestions.value.clear();
                      suggestionsHeightNotifier.value = 0;
                    }
                  },
                  controller: busIdController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.text_30,
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[500]
                          : Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : const Color(0xFF1A73E8),
                        size: 20,
                      ),
                    ),
                    suffixIcon: busIdController.text.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : const Color(0xFFEEF3FB),
                              shape: BoxShape.circle,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                busIdController.clear();
                                suggestions.value.clear();
                                suggestionsHeightNotifier.value = 0;
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        itemCount: menuItems.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) => _buildTabItem(index),
      ),
    );
  }

  String _menuTitle(String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'route':
        return l10n.text_1;
      case 'stop':
        return l10n.text_2;
      case 'routeplan':
        return l10n.text_3;
      case 'shuttleBus':
        return l10n.text_4;
      default:
        return id;
    }
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
                ? Border.all(
                    color: const Color(0xFF1A73E8).withOpacity(0.2), width: 1.5)
                : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFEEF3FB),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  menuItems[index].icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _menuTitle(menuItems[index].id),
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
      itemCount: menuItems.length,
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        switch (menuItems[index].id) {
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
    return _buildFavoriteList<BusRoute>(
      favoriteRoutes,
      _buildRouteCard,
      AppLocalizations.of(context)!.text_1,
    );
  }

  Widget _buildFavoriteStops() {
    return _buildFavoriteList(
      favoriteStops,
      _buildStopCard,
      AppLocalizations.of(context)!.text_2,
    );
  }

  Widget _buildFavoriteList<T>(
    ValueNotifier<List<T>> notifier,
    Widget Function(T) itemBuilder,
    String emptyMessage,
  ) {
    return FutureBuilder<int>(
      future: updateCurrent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('載入失敗: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || notifier.value.isEmpty) {
          return _buildEmptyState(emptyMessage);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifier.value.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            return itemBuilder(notifier.value[index]);
          },
        );
      },
    );
  }

  Widget _buildRouteCard(BusRoute route) {
    final locale = Localizations.localeOf(context);

    return _buildInfoCard(
      title: locale.languageCode == 'en'
          ? (route.routeEn?.isNotEmpty == true ? route.routeEn! : route.routeZh)
          : route.routeZh,
      subtitle: locale.languageCode == 'en'
          ? '${route.departureStopNameEn} - ${route.destinationStopNameEn}'
          : '${route.departureStopNameZh} - ${route.destinationStopNameZh}',
      onTap: () => _navigateToRouteDetails(route),
      onRemove: () => _showConfirmDialog(
        context,
        route.routeUID,
        "FavoritesRoute",
      ),
    );
  }

  Widget _buildStopCard(Map<String, dynamic> stop) {
    print(stop);
    return _buildInfoCard(
      title: stop["stopName"]?.toString() ?? '',
      onTap: () => _navigateToStopDetails(stop),
      onRemove: () =>
          _showConfirmDialog(context, stop["stopName"], "FavoritesStop"),
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
            AppLocalizations.of(context)!.text_31,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.build, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_32,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                : Center(
                    child: Text(AppLocalizations.of(context)!.text_33,
                        style: const TextStyle(color: Colors.grey))),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    // 如果是選取「站牌」搜尋，維持你原本的寫法（直接返回）
    if (_dropdownValueNotifier.value != SearchType.route) {
      return BusStopList(suggestions.value);
    }

    // ✅ 核心改動：外層包裹 ValueListenableBuilder，一邊輸入，這裡就會一邊即時重繪
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: busIdController, // 監聽輸入框的文字變化
      builder: (context, textEditingValue, child) {
        final query = textEditingValue.text;

        // 1. 防護機制：如果沒輸入任何字，直接返回空列表，省去撈資料庫的時間
        if (query.isEmpty) {
          _suggestionFuture = Future.value([]); // 清空 Future
          _lastQuery = '';
          return Buslist(
            suggestions: const [],
            city: correspondingIDNotifier.value == 'all'
                ? "Taipei,Taichung"
                : correspondingIDNotifier.value,
          );
        }

        // 2. 關鍵：如果關鍵字真的變了，才處理更新邏輯
        if (_lastQuery != query) {
          _lastQuery = query;

          // 🚀 實作 Debounce (防抖)：使用者停止輸入 300 毫秒後，才真正發送 SQL 請求
          _debounceTimer?.cancel(); // 取消上一次的計時

          // 建立一個新的暫存 Future，先讓 UI 知道 Future 變了
          final completer = Completer<List<dynamic>>();
          _suggestionFuture = completer.future;

          _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
            try {
              // 300ms 到了，真的去查資料庫
              final data = await _updateSuggestions('route');
              if (!completer.isCompleted) completer.complete(data);
            } catch (e) {
              if (!completer.isCompleted) completer.completeError(e);
            }
          });
        }

        // 3. 渲染與原本結構相同的 FutureBuilder
        return FutureBuilder<List<dynamic>>(
          future: _suggestionFuture,
          builder: (context, snapshot) {
            // 如果正在等待（且目前還沒有舊資料），顯示轉圈圈
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // 成功取得資料，或是有快取舊資料，直接顯示
            return Buslist(
              suggestions: snapshot.data ?? [],
              city: correspondingIDNotifier.value == 'all'
                  ? "Taipei,Taichung"
                  : correspondingIDNotifier.value,
            );
          },
        );
      },
    );
  }

  // 其他方法保持不變，但使用新的顏色變數
  void updatedCorrespondingID() {
    final city = cities.firstWhere(
      (city) => city.name == currentCityNotifier.value,
      orElse: () => const CityItem(
        name: '全部',
        id: 'all',
      ),
    );

    correspondingIDNotifier.value = city.id;
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _navigateToRouteDetails(BusRoute route) async {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final routeName = isEnglish
        ? (route.routeEn?.isNotEmpty == true ? route.routeEn! : route.routeZh)
        : route.routeZh;

    final departureName = isEnglish
        ? (route.departureStopNameEn?.isNotEmpty == true
            ? route.departureStopNameEn!
            : route.departureStopNameZh)
        : route.departureStopNameZh;

    final destinationName = isEnglish
        ? (route.destinationStopNameEn?.isNotEmpty == true
            ? route.destinationStopNameEn!
            : route.destinationStopNameZh)
        : route.destinationStopNameZh;

    final jsonField = isEnglish ? "En" : "Zh_tw";

    final baseData = await mysqlSelect("""
SELECT *
FROM Bus.bus_route
WHERE City = '${correspondingIDNotifier.value}'
AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.${jsonField}')) = '$routeName'
""");

    // 取得 RouteID
    String rawCity = correspondingIDNotifier.value;
    String rawRouteID = route.routeID.toString();

    const needsPaddingCities = [
      'Keelung',
      'Hsinchu',
      'HsinchuCounty',
      'Pingtung',
      'InterCity',
    ];

    final finalRouteID = needsPaddingCities.contains(rawCity)
        ? rawRouteID.padLeft(4, '0')
        : rawRouteID;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusTime(
          routeName: routeName,
          departureStopName: departureName,
          destinationStopName: destinationName,
          operators: "",
          routeMapImageUrl:
              baseData.isNotEmpty ? baseData[0]["RouteMapImageUrl"] : "",
          city: correspondingIDNotifier.value,
          routeID: finalRouteID,
          hasSubRoutes: route.hasSubRoute,
          data: route,
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

  void _showConfirmDialog(
      BuildContext context, String item, String SharedPreferencesList) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      text: AppLocalizations.of(context)!.text_34,
      confirmBtnText: AppLocalizations.of(context)!.text_35,
      cancelBtnText: AppLocalizations.of(context)!.text_36,
      confirmBtnColor: Colors.green,
      onCancelBtnTap: () => Navigator.pop(context),
      onConfirmBtnTap: () {
        _removeFavorite(context, item, SharedPreferencesList);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _removeFavorite(
      BuildContext context, String item, String SharedPreferencesList) async {
    favorite_feature db = favorite_feature();
    if (SharedPreferencesList == "FavoritesRoute") {
      await db.removeFavoriteRoute(
        item,
        correspondingIDNotifier.value,
      );
    } else if (SharedPreferencesList == "FavoritesStop") {
      await db.removeFavoriteStop(item, correspondingIDNotifier.value);
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
              child:
                  const Icon(Icons.place, size: 16, color: Color(0xFF1A73E8)),
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
