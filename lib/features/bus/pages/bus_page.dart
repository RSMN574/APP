import 'dart:async';
import 'dart:convert';

import 'package:com.rsmn574.app/features/bus/pages/bus_stop_info_page.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_time_page.dart';
import 'package:com.rsmn574.app/features/bus/pages/route_planning_page.dart';
import 'package:com.rsmn574.app/features/bus/widgets/bus_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/database/sql/favorite_feature.dart';
import 'package:com.rsmn574.app/database/get_data.dart';

import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';
import 'package:com.rsmn574.app/features/bus/state/bus_provider.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_search_service.dart';

import '../../../const/surface_decoration.dart';
import '../../../database/bootstrap_service.dart';
import '../../../database/sql/app_database.dart';
import '../../../firebase/analytics_service.dart';

class Bus extends StatefulWidget {
  const Bus({Key? key}) : super(key: key);

  @override
  State<Bus> createState() => BusState();
}

enum SearchType { route, stop }

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

// 城市資料：`name` 為資料值（用於比對 / 顯示），不屬於 UI 靜態字串。
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
  MenuItemData(id: 'route', title: 'text_1', icon: Icons.favorite),
  MenuItemData(id: 'stop', title: 'text_2', icon: Icons.favorite),
  MenuItemData(id: 'shuttleBus', title: 'text_4', icon: Icons.airport_shuttle),
];

class BusState extends State<Bus> {
  int _current = 0;
  final PageController pageController = PageController();

  ValueNotifier<List<Map<String, dynamic>>> favoriteStops = ValueNotifier([]);
  ValueNotifier<List<BusRoute>> favoriteRoutes = ValueNotifier([]);
  List<BusRoute> busData = [];

  ValueNotifier<String> currentCityNotifier = ValueNotifier<String>('全部');
  ValueNotifier<String> correspondingIDNotifier = ValueNotifier<String>('');

  final ValueNotifier<double> suggestionsHeightNotifier =
  ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  final ValueNotifier<List> suggestions = ValueNotifier<List>([]);

  // 搜尋防抖 / 競態控制
  Timer? _debounceTimer;
  int _searchSeq = 0;

  // 收藏載入去重
  Future<void>? _favoritesInFlight;

  // ✅ P2：改為由主題取得，避免硬編碼品牌色。
  Color get _primaryColor => Theme.of(context).colorScheme.primary;
  Color get _secondaryColor => context.appColors.mutedBackground;

  // ---------------------------------------------------------------------------
  // 生命週期
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final currentCity =
        Provider.of<CityProvider>(context, listen: false).city;

    // 只在此處記錄一次「公車頁面開啟」，避免 build 重複上報。
    unawaited(AppAnalytics.logFeatureOpened('bus_page'));

    BootstrapService.instance.dbVersion.addListener(_onDbUpdated);

    if (cities.any((city) => city.name == currentCity)) {
      currentCityNotifier.value = currentCity;
    }
    _initializeFavorites();
    updatedCorrespondingID();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadForCurrentCity());
      unawaited(_reloadFavorites(force: true));
    });
  }

  void _onDbUpdated() {
    if (!mounted) return;
    unawaited(_loadForCurrentCity());
    unawaited(_reloadFavorites(force: true));
  }

  @override
  void dispose() {
    BootstrapService.instance.dbVersion.removeListener(_onDbUpdated);
    _debounceTimer?.cancel();
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
      final dbHelper = favorite_feature();
      await dbHelper.initDatabase();
    } catch (e, st) {
      debugPrint('init favorites db failed: $e\n$st');
    }
  }

  // ---------------------------------------------------------------------------
  // 路線資料
  // ---------------------------------------------------------------------------

  Future<void> _loadForCurrentCity() async {
    final city = correspondingIDNotifier.value;
    busCurrentCity = city;
    final data = await _fetchRoutes(city);
    if (!mounted || correspondingIDNotifier.value != city) return;
    setState(() => busData = data);
  }

  Future<List<BusRoute>> _fetchRoutes(String city) async {
    try {
      final db = await AppDatabase.instance.database;
      if (kDebugMode) {
        final stats = await db.rawQuery(
          'SELECT city, COUNT(*) AS n FROM bus_route GROUP BY city',
        );
        debugPrint('[db] city stats: $stats');
      }

      List<BusRoute> local;
      if (city == 'all') {
        const allCities = [
          'Taichung', 'Taipei', 'NewTaipei', 'Taoyuan',
          'Tainan', 'Kaohsiung', 'Keelung', 'Hsinchu', 'InterCity',
        ];
        final results = await Future.wait(
          allCities.map((c) => BusRouteDb.instance.getByCity(c)),
        );
        final seen = <String>{};
        local = results
            .expand((e) => e)
            .where((r) => seen.add('${r.city}|${r.routeID}'))
            .toList();
      } else {
        local = await BusRouteDb.instance.getByCity(city);
      }

      if (local.isNotEmpty) return local;

      if (!mounted) return local;
      return await context.read<BusProvider>().loadRoutes(city);
    } catch (error, st) {
      debugPrint('load routes failed for $city: $error\n$st');
      return busData;
    }
  }

  // ---------------------------------------------------------------------------
  // 收藏資料
  // ---------------------------------------------------------------------------

  Future<void> _reloadFavorites({bool force = false}) {
    if (!force && _favoritesInFlight != null) return _favoritesInFlight!;
    final future = _doReloadFavorites();
    _favoritesInFlight = future;
    future.whenComplete(() {
      if (identical(_favoritesInFlight, future)) _favoritesInFlight = null;
    });
    return future;
  }

  Future<void> _doReloadFavorites() async {
    final city = correspondingIDNotifier.value;
    final db = FavoriteService();
    try {
      final routes = await db.getFavoriteRoutes(city: city);
      final stops = await db.getFavoriteStops(city: city);
      if (!mounted || correspondingIDNotifier.value != city) return;

      favoriteRoutes.value =
          routes.map(_toBusRouteFromFavorite).whereType<BusRoute>().toList();
      favoriteStops.value = stops;
    } catch (e, st) {
      debugPrint('reload favorites failed: $e\n$st');
    }
  }

  BusRoute? _toBusRouteFromFavorite(Map<String, dynamic> e) {
    try {
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
        'DestinationStopNameZh':
        e['destinationStopNameZh']?.toString() ?? '',
        'DestinationStopNameEn':
        e['destinationStopNameEn']?.toString() ?? '',
        'TicketPriceDescriptionZh': e['ticketPriceDescriptionZh'],
        'TicketPriceDescriptionEn': e['ticketPriceDescriptionEn'],
        'RouteMapImageUrl': e['routeMapImageUrl'],
        'City': e['city']?.toString() ?? '',
        'CityCode': e['cityCode']?.toString() ?? '',
        'UpdateTime': DateTime.now().toIso8601String(),
        'VersionID': '0',
      });
    } catch (err, st) {
      debugPrint('skip invalid favorite route: $err\n$st');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 搜尋（防抖 + 競態保護）
  // ---------------------------------------------------------------------------

  void _cancelPendingSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _searchSeq++;
  }

  void _onSearchChanged(String text) {
    _cancelPendingSearch();

    if (text.trim().isEmpty) {
      suggestions.value = const [];
      suggestionsHeightNotifier.value = 0;
      return;
    }

    final type = _dropdownValueNotifier.value;
    final mq = MediaQuery.of(context);
    suggestionsHeightNotifier.value =
        mq.size.height - mq.viewInsets.bottom - kToolbarHeight - 200;

    final seq = _searchSeq;
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final result = await _updateSuggestions(
        type == SearchType.route ? 'route' : 'stop',
      );
      if (!mounted || seq != _searchSeq) return;
      suggestions.value = result;
    });
  }

  Future<List<dynamic>> _updateSuggestions(String id) async {
    final input = busIdController.text.trim();
    if (input.isEmpty) return const [];

    final languageCode = Localizations.localeOf(context).languageCode;
    final city = correspondingIDNotifier.value;

    if (id == 'route') {
      return BusSearchService.searchRoutes(
        city: city,
        keyword: input,
        languageCode: languageCode,
        memoryRoutes: busData,
      );
    }
    return BusSearchService.searchStops(
      cityId: city,
      keyword: input,
      languageCode: languageCode,
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar / info menu
  // ---------------------------------------------------------------------------

  AppBar _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final surface = AppThemes.getSurface(context);
    return AppBar(
      backgroundColor: surface,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: _primaryColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.directions_bus, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.text_16,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppThemes.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 24),
            color: _primaryColor,
            onPressed: _showInfoMenu,
          ),
        ),
      ],
    );
  }

  void _showInfoMenu() {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getSurface(context),
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
                  color: colorScheme.outlineVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemes.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
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
                      _primaryColor,
                      _primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: colorScheme.onPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
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
              color: AppThemes.getSurface(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppLocalizations.of(context)!.text_21,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoText(AppLocalizations.of(context)!.text_22),
                    const SizedBox(height: 12),
                    _buildInfoText(AppLocalizations.of(context)!.text_23),
                    const SizedBox(height: 12),
                    _buildInfoText(AppLocalizations.of(context)!.text_24),
                    const SizedBox(height: 12),
                    // TODO(P2-i18n): 需新增 ARB key（電子票證說明）。
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
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _navigateToAlertInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
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
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data is! List ||
                      (snapshot.data as List).isEmpty) {
                    return _buildNoDataWidget();
                  }
                  return _buildAlertList(snapshot.data as List);
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
              itemBuilder: (context, index) => _buildAlertCard(data[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
            color: AppThemes.getCardColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning, color: _primaryColor, size: 20),
        ),
        title: Text(
          alert['Title'] ?? AppLocalizations.of(context)!.text_25,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          alert['Description'] ?? AppLocalizations.of(context)!.text_26,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_27,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 城市下拉
  // ---------------------------------------------------------------------------

  Widget _buildCityDropdown([bool includeAll = true]) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredList = includeAll
        ? cities
        : cities
        .where((city) => city.name != AppLocalizations.of(context)!.text_5)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
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
            child: Icon(
              Icons.location_on_rounded,
              size: 20,
              color: _primaryColor,
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
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppThemes.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                isExpanded: true,
                value: currentCityNotifier.value ==
                    AppLocalizations.of(context)!.text_5 &&
                    !includeAll
                    ? null
                    : currentCityNotifier.value,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return filteredList.map<Widget>((CityItem city) {
                    return Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: colorScheme.primary,
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
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
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
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.3),
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
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null || value == currentCityNotifier.value) {
                    return;
                  }
                  _cancelPendingSearch();
                  suggestions.value = const [];
                  suggestionsHeightNotifier.value = 0;
                  busIdController.clear();

                  currentCityNotifier.value = value;
                  updatedCorrespondingID();
                  setState(() => busData = []);

                  unawaited(_loadForCurrentCity());
                  unawaited(_reloadFavorites(force: true));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => hideKeyboard(context),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCityDropdown(),
            ),
            _buildSearchSection(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppThemes.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 搜尋類型下拉
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
                  String labelOf(SearchType t) => t == SearchType.route
                      ? l10n.text_15
                      : l10n.text_29;

                  return DropdownButtonHideUnderline(
                    child: DropdownButton<SearchType>(
                      value: _dropdownValueNotifier.value,
                      isExpanded: true,
                      dropdownColor: AppThemes.getCardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: colorScheme.primary,
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
                                        ? colorScheme.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  labelOf(type),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (SearchType? newValue) {
                        if (newValue == null ||
                            newValue == _dropdownValueNotifier.value) {
                          return;
                        }
                        _cancelPendingSearch();
                        suggestions.value = const [];
                        suggestionsHeightNotifier.value = 0;
                        _dropdownValueNotifier.value = newValue;
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
                                horizontal: 4, vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : AppThemes.getCardColor(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    labelOf(type),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: colorScheme.onPrimary,
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
            Container(
              width: 1,
              height: 32,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4, right: 4),
                decoration: BoxDecoration(
                  color: AppThemes.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: busIdController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.text_30,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.search_rounded,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: busIdController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppThemes.getSurface(context),
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              _cancelPendingSearch();
                              busIdController.clear();
                              suggestions.value = const [];
                              suggestionsHeightNotifier.value = 0;
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final bool isSelected = _current == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() => _current = index);
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
          decoration: isSelected
              ? SurfaceDecoration.selected(context, radius: 16)
              : SurfaceDecoration.outlined(context, radius: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.info.withOpacity(0.12)
                      : colors.mutedBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  menuItems[index].icon,
                  size: 18,
                  color: colors.info,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _menuTitle(menuItems[index].id),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.info,
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
    return _buildFavoriteList<Map<String, dynamic>>(
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
    return ValueListenableBuilder<List<T>>(
      valueListenable: notifier,
      builder: (context, list, _) {
        if (list.isEmpty) return _buildEmptyState(emptyMessage);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => Divider(
            height: 16,
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          ),
          itemBuilder: (context, index) => itemBuilder(list[index]),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppThemes.getSurface(context),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        )
            : null,
        trailing: onRemove != null
            ? IconButton(
          icon: Icon(
            Icons.favorite,
            color: context.appColors.danger,
          ),
          onPressed: onRemove,
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          // TODO(P2-i18n): 需新增 ARB key（"暫無 {target}"）。
          Text(
            '暫無$message',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.text_31,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.text_32,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
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
              color: AppThemes.getSurface(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ValueListenableBuilder<List>(
              valueListenable: suggestions,
              builder: (context, list, _) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.text_33,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }
                if (_dropdownValueNotifier.value != SearchType.route) {
                  return BusStopList(list);
                }
                return Buslist(
                  suggestions: list,
                  city: correspondingIDNotifier.value == 'all'
                      ? "Taipei,Taichung"
                      : correspondingIDNotifier.value,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 其他輔助
  // ---------------------------------------------------------------------------

  void updatedCorrespondingID() {
    final city = cities.firstWhere(
          (c) => c.name == currentCityNotifier.value,
      orElse: () => const CityItem(name: '全部', id: 'all'),
    );
    correspondingIDNotifier.value = city.id;
  }

  void hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
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
    final cityId = correspondingIDNotifier.value;

    if (!BusSearchService.allowedCityIds.contains(cityId)) return;

    unawaited(AppAnalytics.logFeatureOpened('bus_time_page'));

    final detail = await BusSearchService.fetchRouteDetail(
      cityId: cityId,
      routeName: routeName,
      jsonField: jsonField,
    );

    if (!mounted) return;

    final rawRouteID = route.routeID.toString();
    const needsPaddingCities = [
      'Keelung',
      'Hsinchu',
      'HsinchuCounty',
      'Pingtung',
      'InterCity',
    ];
    final finalRouteID = needsPaddingCities.contains(cityId)
        ? rawRouteID.padLeft(4, '0')
        : rawRouteID;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusTime(
          routeName: route.routeZh,
          departureStopName: departureName,
          destinationStopName: destinationName,
          operators: "",
          routeMapImageUrl:
          detail?["RouteMapImageUrl"]?.toString() ?? "",
          city: cityId,
          routeID: finalRouteID,
          hasSubRoutes: route.hasSubRoute,
          data: route,
        ),
      ),
    );
  }

  void _navigateToStopDetails(Map<String, dynamic> stop) {
    unawaited(AppAnalytics.logFeatureOpened('bus_stop_info_page'));
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
      confirmBtnColor: context.appColors.success,
      onCancelBtnTap: () => Navigator.pop(context),
      onConfirmBtnTap: () async {
        await _removeFavorite(context, item, SharedPreferencesList);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }

  Future<void> _removeFavorite(
      BuildContext context, String item, String SharedPreferencesList) async {
    final db = favorite_feature();
    try {
      if (SharedPreferencesList == "FavoritesRoute") {
        await db.removeFavoriteRoute(item, correspondingIDNotifier.value);
      } else if (SharedPreferencesList == "FavoritesStop") {
        await db.removeFavoriteStop(item, correspondingIDNotifier.value);
      }
      unawaited(AppAnalytics.logFeatureOpened(
        SharedPreferencesList == "FavoritesRoute"
            ? 'bus_unfavorite_route'
            : 'bus_unfavorite_stop',
      ));
      await _reloadFavorites(force: true);
    } catch (e, st) {
      debugPrint('remove favorite failed: $e\n$st');
    }
  }

  Widget BusStopList(List suggestions) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightColor = colorScheme.primary.withOpacity(0.12);

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: index == 0
                ? highlightColor
                : AppThemes.getSurface(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.place, size: 16, color: colorScheme.primary),
            ),
            title: Text(
              suggestions[index].toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () {
              unawaited(AppAnalytics.logFeatureOpened('bus_stop_info_page'));
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