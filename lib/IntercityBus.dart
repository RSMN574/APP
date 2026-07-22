import 'dart:async';
import 'dart:convert';
import 'package:com.rsmn574.app/pages/bus/busStopInfo.dart';
import 'package:com.rsmn574.app/pages/bus/bus_time.dart';
import 'package:com.rsmn574.app/pages/routePlanning.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/bus/BusList.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'database/SQL/favorite_feature.dart';
import 'database/getData.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

import 'l10n/app_localizations.dart';


class IntercityBus extends StatefulWidget {
  const IntercityBus({Key? key}) : super(key: key);

  @override
  State<IntercityBus> createState() => IntercityBusState();
}



class IntercityBusState extends State<IntercityBus> {
  final List<IconData> icons = [Icons.favorite, Icons.favorite, Icons.route, Icons.airport_shuttle];
  late final List<String> items = [AppLocalizations.of(context)!.text_1, AppLocalizations.of(context)!.text_2, AppLocalizations.of(context)!.text_3, AppLocalizations.of(context)!.text_4];
  final List<String> id = ["route", "stop", "routeplan", "shuttleBus"];
  int _current = 0;
  final PageController pageController = PageController();
  ValueNotifier<List<Map<String, dynamic>>> favoriteStops = ValueNotifier([]);
  ValueNotifier<List<Map<String, dynamic>>> favoriteRoutes = ValueNotifier([]);
  List busData = [];

  late ValueNotifier<String> currentCityNotifier = ValueNotifier<String>(AppLocalizations.of(context)!.text_5);
  ValueNotifier<String> correspondingIDNotifier = ValueNotifier<String>("");
  late final ValueNotifier<String> _dropdownValueNotifier = ValueNotifier<String>(AppLocalizations.of(context)!.text_15);
  final ValueNotifier<double> suggestionsHeightNotifier = ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  final ValueNotifier<List> suggestions = ValueNotifier<List>([]);

  // 顏色定義 - 使用航班主題
  final Color _primaryColor = const Color(0xFF1A73E8);
  final Color _secondaryColor = const Color(0xFFEEF3FB);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _greyColor = Colors.grey;

  // Future<int> updateCurrent() async {
  //   favoriteRoutes.value = await _loadFavorites("FavoritesRoute", city: correspondingIDNotifier.value);
  //   favoriteStops.value = await _loadFavorites("FavoritesStop", city: correspondingIDNotifier.value);
  //   return 200;
  // }

  @override
  void initState() {
    super.initState();
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;

    _initializeFavorites();

    _getData();
    // updateCurrent();
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

  // Future<List<Map<String, dynamic>>> _loadFavorites(String key, {required String city}) async {
  //   favorite_feature db = favorite_feature();
  //   final favorites = await db.getFavorites(key, correspondingIDNotifier.value, city);
  //   return favorites;
  // }

  Future<List> _getData() async {
    busCurrentCity = correspondingIDNotifier.value;
    busData = await getBusRoute(city:"TaiwanTrip");
    return [];
  }

  Future<List<dynamic>> _updateSuggestions(String id) async {
    suggestions.value.clear();

    if (id == "route") {
      final String input = busIdController.text;
      final List<dynamic> suggestionsForRoute = [];

      for (Map route in busData) {


        final routeName = (route["RouteName"])["Zh_tw"];
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
          "SELECT StationName FROM Bus.Bus_TaiwanTrip_Stop "
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
              color: _secondaryColor,
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
            AppLocalizations.of(context)!.text_218,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
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

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppLocalizations.of(context)!.text_21,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
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
        color: Colors.white,
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


  @override
  Widget build(BuildContext context) {
    // updateCurrent();
    return Scaffold(
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => hideKeyboard(context),
        child: Column(
          children: [


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
            child: ValueListenableBuilder<String>(
              valueListenable: _dropdownValueNotifier,
              builder: (context, value, child) {



                return    SizedBox(
                  width: 120, // 或者根據需要調整寬度
                  child: CustomDropdown<String>(
                    items: [AppLocalizations.of(context)!.text_15, AppLocalizations.of(context)!.text_29],
                    initialItem:AppLocalizations.of(context)!.text_15 ,

                    onChanged: (value) {
                      _dropdownValueNotifier.value = value!;
                    },
                  ),
                );
              },
            ),
          ),

          // 搜尋輸入框
          Expanded(
            child: Container(
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
              child: TextField(
                onChanged: (text) async {
                  if (text.isNotEmpty) {
                    double screenHeight = MediaQuery.of(context).size.height;
                    double bottomInset = MediaQuery.of(context).viewInsets.bottom;
                    double appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

                    if (_dropdownValueNotifier.value == AppLocalizations.of(context)!.text_15) {
                      await _updateSuggestions('route');
                      setState(() {
                        suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 200;
                      });
                    } else if (_dropdownValueNotifier.value == AppLocalizations.of(context)!.text_29) {
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
                  hintText: AppLocalizations.of(context)!.text_30,
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[700], size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    color: Colors.grey[700],
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
                style: const TextStyle(color: Colors.black87, fontSize: 14),
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
        color: Colors.white,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            // updateCurrent();
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
          // case "route":
          //   return _buildFavoriteRoutes();
          // case "stop":
          //   return _buildFavoriteStops();
          // case "routeplan":
          //   return RoutePlanner();
          default:
            return _buildComingSoon();
        }
      },
    );
  }

  // Widget _buildFavoriteRoutes() {
  //   return _buildFavoriteList(
  //     favoriteRoutes,
  //     _buildRouteCard,
  //     AppLocalizations.of(context)!.text_1,
  //   );
  // }
  //
  // Widget _buildFavoriteStops() {
  //   return _buildFavoriteList(
  //     favoriteStops,
  //     _buildStopCard,
  //     AppLocalizations.of(context)!.text_2,
  //   );
  // }

  // Widget _buildFavoriteList(
  //     ValueNotifier<List<Map<String, dynamic>>> notifier,
  //     Widget Function(Map<String, dynamic>) itemBuilder,
  //     String emptyMessage,
  //     ) {
  //   return FutureBuilder<int>(
  //     future: updateCurrent(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       } else if (snapshot.hasError) {
  //         return Center(child: Text('載入失敗: ${snapshot.error}'));
  //       } else if (!snapshot.hasData || notifier.value.isEmpty) {
  //         return _buildEmptyState(emptyMessage);
  //       }
  //
  //       return ListView.separated(
  //         padding: const EdgeInsets.all(16),
  //         itemCount: notifier.value.length,
  //         separatorBuilder: (context, index) => const Divider(height: 16),
  //         itemBuilder: (context, index) => itemBuilder(notifier.value[index]),
  //       );
  //     },
  //   );
  // }

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
                : Center(child: Text(AppLocalizations.of(context)!.text_33, style: const TextStyle(color: Colors.grey))),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    if (_dropdownValueNotifier.value == AppLocalizations.of(context)!.text_15) {
      return FutureBuilder(
        future: _updateSuggestions('route'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Buslist(
            suggestions: snapshot.data ?? [],
            city: correspondingIDNotifier.value == 'all' ? "Taipei,Taichung" : correspondingIDNotifier.value,
          );
        },
      );
    } else {
      return BusStopList(suggestions.value);
    }
  }



  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _navigateToRouteDetails(Map<String, dynamic> route) async {

    List baseData = await mysqlSelect("SELECT * FROM Bus.Bus_TaiwanTrip_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))='${route["routeName"]}'");
    //
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BusTime(
    //       routeName: route["routeName"],
    //       departureStopName: route["DepartureStopNameZh"],
    //       destinationStopName: route["DestinationStopNameZh"],
    //       operators: "",
    //       routeMapImageUrl: baseData[0]["RouteMapImageUrl"],
    //       city: correspondingIDNotifier.value,
    //       routeID: route["routeID"],
    //         hasSubRoutes:route["HasSubRoutes"]
    //     ),
    //   ),
    // );
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

  Future<void> _removeFavorite(BuildContext context, String item, String SharedPreferencesList) async {
    favorite_feature db = favorite_feature();
    // if (SharedPreferencesList == "FavoritesRoute") {
    //   await db.removeFavorite(routeName: item, city: correspondingIDNotifier.value, table: SharedPreferencesList);
    // } else if (SharedPreferencesList == "FavoritesStop") {
    //   await db.removeFavorite(stopName: item, city: correspondingIDNotifier.value, table: SharedPreferencesList);
    // }
    // setState(() {});
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

