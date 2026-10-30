import 'dart:async';

import 'package:com.rsmn574.app/features/airport/state/airport_provider.dart';
import 'package:com.rsmn574.app/features/parking/state/parking_provider.dart';
import 'package:com.rsmn574.app/features/traffic/state/traffic_provider.dart';
import 'package:com.rsmn574.app/features/ev_charging/state/ev_station_provider.dart';
import 'package:com.rsmn574.app/features/weather/state/weather_provider.dart';
import 'package:com.rsmn574.app/features/railway/state/railway_provider.dart';
import 'package:com.rsmn574.app/features/notification/state/notification_provider.dart';
import 'package:com.rsmn574.app/features/settings/state/settings_provider.dart';
import 'dart:ui';

import 'package:com.rsmn574.app/features/ev_charging/pages/ev_station_page.dart';
import 'package:com.rsmn574.app/pages/other/speedometer.dart';
import 'package:com.rsmn574.app/features/parking/pages/parking_page.dart';
import 'package:com.rsmn574.app/features/traffic/pages/traffic_page.dart';
import 'package:com.rsmn574.app/secure_storage/secure_storage.dart';
import 'package:com.rsmn574.app/task/task.dart';
import 'package:com.rsmn574.app/test.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/single_child_widget.dart';

import 'const/regular_class.dart';
import 'const/regular_const.dart';
import 'database/bootstrap_service.dart';
import 'features/airport/pages/airport_page.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/unavailable_auth_repository.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/profile_page.dart';
import 'features/nearby_stations/pages/nearby_stations_page.dart';
import 'features/sync/state/cloud_sync_provider.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/bus/pages/bus_page.dart';
import 'features/bus/pages/intercity_bus_page.dart';
import 'features/metro/pages/metro_page.dart';
import 'features/notification/pages/notification_page.dart';
import 'features/railway/pages/commute_page.dart';
import 'features/railway/pages/hsr_page.dart';
import 'features/railway/pages/train_page.dart';
import 'features/taxi/pages/taxi_page.dart';
import 'features/taxi/state/taxi_provider.dart';
import 'features/youbike/pages/bike_page.dart';
import 'database/sql/schedule.dart';
import 'database/get_data.dart';
import 'database/token_manager.dart';
import 'firebase/fcm.dart';
import 'firebase/firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widget/geolocator.dart';
import 'pages.dart';
import 'features/home/pages/home.dart';
import 'features/bus/state/bus_provider.dart';
import 'package:logging/logging.dart';
import 'features/metro/state/metro_provider.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('zh'));

class AppInitializer {
  static bool firebaseInitialized = false;
  static bool bootstrapReady = false;

  static Future<void> initialize() async {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print(
        '${record.level.name}: ${record.time}: ${record.message}',
      );
    });

    final log = Logger('MyApp');
    log.info('app start');

    await SecureStorage.initializeApiKey();

    // ── 1. Firebase / 通知 / Token ──
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      firebaseInitialized = true;

      await requestPermission();
      await initializeNotifications();
      setupForegroundMessageHandler();
      await setupFirebaseMessaging();

      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      initializeArrivalReminderService();

      final tokenManager = TokenManager();
      await tokenManager.getToken();
      tokenManager.startAutoRefresh();

      log.info('Firebase 初始化完成');
    } catch (e, stack) {
      log.severe('Firebase 初始化失敗', e, stack);
    }

    // ── 2. 全域錯誤處理 ──
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      log.severe(
        'Flutter Error: ${details.exception}',
        details.exception,
        details.stack,
      );

      if (firebaseInitialized) {

        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(
            details,
          ),
        );
      }
    };

    // 處理未被其他機制捕捉的非同步錯誤
    PlatformDispatcher.instance.onError = (error, stack) {
      log.severe(
        'Uncaught asynchronous error',
        error,
        stack,
      );

      if (!firebaseInitialized) {
        // Firebase 尚未初始化，交由 Flutter 預設機制處理
        return false;
      }

      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          fatal: true,
        ),
      );

      return true;
    };

    // ── 3. 首次預載資料（bus list → SQLite）──
    // 失敗不影響 App 啟動，保留本地快取
    try {
      await BootstrapService.instance.ensureLoaded();

      bootstrapReady = true;
      log.info('bootstrap 完成');
    } catch (e, stack) {
      log.warning(
        'bootstrap 失敗，使用本地快取',
        e,
        stack,
      );
    }
  }
}

class ProviderSetup {
  static List<SingleChildWidget> getProviders(
    AppProvider appProvider, {
    required bool firebaseInitialized,
  }) {
    return [
      ChangeNotifierProvider(create: (_) => CityProvider()),
      ChangeNotifierProvider(create: (_) => LocationProvider()),
      ChangeNotifierProvider(create: (_) => MarkerProvider()),
      ChangeNotifierProvider(create: (_) => PolylineProvider()),
      ChangeNotifierProvider.value(value: appProvider),
      ChangeNotifierProvider(create: (_) => BusProvider()),
      ChangeNotifierProvider(create: (_) => AirportProvider()..loadAirports()),
      ChangeNotifierProvider(create: (_) => ParkingProvider()),
      ChangeNotifierProvider(create: (_) => TrafficProvider()),
      ChangeNotifierProvider(create: (_) => EvStationProvider()),
      ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ChangeNotifierProvider(create: (_) => RailwayProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider<AuthProvider>(
        lazy: false,
        create: (_) => AuthProvider(
          repository: firebaseInitialized
              ? FirebaseAuthRepository()
              : const UnavailableAuthRepository(),
        ),
      ),
      ChangeNotifierProxyProvider<AuthProvider, CloudSyncProvider>(
        create: (_) => CloudSyncProvider(),
        update: (_, auth, sync) => (sync ?? CloudSyncProvider())..attach(auth),
      ),
    ];
  }
}

class AppRoutes {
  static const String plane = "plane";
  static const String train = "train";
  static const String metro = "metro";
  static const String bus = "bus";
  static const String notification = "notification";
  static const String home = "home";
  static const String bike = "bike";
  static const String HSR = "HSR";
  static const String EVStation = "EVStation";
  static const String IntercityBus = "IntercityBus";
  static const String test = "test";
  static const String parking = "parking";
  static const String traffic = "traffic";
  static const String speedometer = "speedometer";
  static const String taxi = "taxi";
  static const String authLogin = "/auth/login";
  static const String authProfile = "/auth/profile";
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appProvider = await AppProvider.load();
  await AppInitializer.initialize();

  runApp(MultiProvider(
    providers: ProviderSetup.getProviders(
      appProvider,
      firebaseInitialized: AppInitializer.firebaseInitialized,
    ),
    child: const NavigationBarApp(),
  ));
}

// 定义 SVG 资源路径的常量类
class SvgAssets {
  static const String notifications = 'assets/icons/notifications-outline.svg';
  static const String homeOutline = 'assets/icons/home-outline.svg';
  static const String home = 'assets/icons/home.svg';
  static const String busStop = 'assets/icons/bus-stop.svg';
  static const String navigateOutline = 'assets/icons/navigate-outline.svg';
  static const String navigate = 'assets/icons/navigate.svg';
  static const String personOutline = 'assets/icons/person-outline.svg';
  static const String person = 'assets/icons/person.svg';
  static const String commuteOutlined = 'assets/icons/commute-outlined.svg';
}

class NavigationBarApp extends StatefulWidget {
  const NavigationBarApp({super.key});

  @override
  _NavigationBarAppState createState() => _NavigationBarAppState();
}

class _NavigationBarAppState extends State<NavigationBarApp>
    with SingleTickerProviderStateMixin {
  // 使用 SingleTickerProviderStateMixin

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 監聽應用的生命周期變化
  void didChangeLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      connMysql();
    }
  }

  @override
  Widget build(BuildContext context) {
// 監聽 Provider 中的狀態
    final appProvider = Provider.of<AppProvider>(context);
    print("目前語言: ${appProvider.locale}");

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          supportedLocales: AppLocalizations.supportedLocales,

          debugShowCheckedModeBanner: false,
          routes: {
            AppRoutes.plane: (BuildContext context) => (Plane()),
            AppRoutes.train: (BuildContext context) => (Train()),
            AppRoutes.metro: (BuildContext context) => ChangeNotifierProvider(
                  create: (_) => MetroProvider(),
                  child:  Metro(),
                ),
            AppRoutes.bus: (BuildContext context) => (const Bus()),
            AppRoutes.notification: (BuildContext context) =>
                (NotificationPage()),
            AppRoutes.home: (BuildContext context) => (Home()),
            // AppRoutes.bike: (BuildContext context) => (Bike()),
            AppRoutes.HSR: (BuildContext context) => (HSR()),
            AppRoutes.EVStation: (BuildContext context) => (EVStation()),
            AppRoutes.IntercityBus: (BuildContext context) => (IntercityBus()),
            AppRoutes.test: (BuildContext context) => (MetroMapScreen()),
            AppRoutes.parking: (BuildContext context) => (Parking()),
            AppRoutes.traffic: (BuildContext context) => (Traffic()),
            AppRoutes.speedometer: (BuildContext context) => (Speedometer()),
            AppRoutes.taxi: (BuildContext context) => ChangeNotifierProvider(
                  create: (_) => TaxiProvider(),
                  child: const TaxiPage(),
                ),
            AppRoutes.authLogin: (BuildContext context) => const LoginPage(),
            AppRoutes.authProfile: (BuildContext context) =>
                const ProfilePage(),
          },
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: appProvider.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          // --- 重點：套用語言 ---
          locale: appProvider.locale,

          // themeMode: ThemeMode.system,
          home: const TaiwanPass(),
        ));
  }
}

class TaiwanPass extends StatefulWidget {
  const TaiwanPass({super.key});

  @override
  State<TaiwanPass> createState() => _TaiwanPassState();
}

class _TaiwanPassState extends State<TaiwanPass>
    with SingleTickerProviderStateMixin {
  int currentPageIndex = 0;
  String? selectedRegion;
  // 在 State 類別新增動畫控制器
  late AnimationController _navIconController;
  final double _activeIconSize = 24;
  final double _inactiveIconSize = 22;
  final PageController _pageController = PageController(); // 控制 PageView
  List<CityItem> get regions {
    final l10n = AppLocalizations.of(context)!;
    return [
      CityItem(name: l10n.text_74, id: '宜蘭縣'),
      CityItem(name: l10n.text_76, id: '花蓮縣'),
      CityItem(name: l10n.text_78, id: '臺東縣'),
      CityItem(name: l10n.text_80, id: '澎湖縣'),
      CityItem(name: l10n.text_82, id: '金門縣'),
      CityItem(name: l10n.text_84, id: '連江縣'),
      CityItem(name: l10n.text_7, id: '臺北市'),
      CityItem(name: l10n.text_8, id: '新北市'),
      CityItem(name: l10n.text_9, id: '桃園市'),
      CityItem(name: l10n.text_6, id: '臺中市'),
      CityItem(name: l10n.text_10, id: '臺南市'),
      CityItem(name: l10n.text_11, id: '高雄市'),
      CityItem(name: l10n.text_12, id: '基隆市'),
      CityItem(name: l10n.text_92, id: '新竹縣'),
      CityItem(name: l10n.text_13, id: '新竹市'),
      CityItem(name: l10n.text_94, id: '苗栗縣'),
      CityItem(name: l10n.text_96, id: '彰化縣'),
      CityItem(name: l10n.text_98, id: '南投縣'),
      CityItem(name: l10n.text_100, id: '雲林縣'),
      CityItem(name: l10n.text_101, id: '嘉義縣'),
      CityItem(name: l10n.text_102, id: '嘉義市'),
      CityItem(name: l10n.text_104, id: '屏東縣'),
    ];
  }

  Future<String?> fetchAndUpdateLocation(BuildContext context) async {
    // 1. 取得定位
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      if (!context.mounted) return null;
      return AppLocalizations.of(context)!.text_916; // 權限或定位服務未開啟
    }

    if (!context.mounted) return null;
    Provider.of<LocationProvider>(context, listen: false)
        .setLocation(pos.latitude, pos.longitude);

    // 2. 查詢行政區
    final districtInfo = await LocationService.getDistrictFromTDX(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    if (districtInfo == null) {
      if (!context.mounted) return null;
      return AppLocalizations.of(context)!.text_919;
    }

    String city = cityNameConverter(districtInfo["city"] ?? "");

    if (!context.mounted) return null;
    Provider.of<CityProvider>(context, listen: false).setCity(city);

    return city;
  }

  // 初始化页面列表
  final List<Widget> _pages = [];

  @override
  void initState() {
    // 在应用启动时获取定位信息

    // 延迟获取定位信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchAndUpdateLocation(context);
    });
    _navIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    super.initState();
    _pages.addAll([
      Home(),
      Commute(),
      NearbyStationsPage(),
      InfoPages(),
    ]);

    ScheduleService.instance.initDatabase();

    // 获取天气信息
    // getWeatherInfo(context);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return Home();
      case 1:
        return Commute();
      case 2:
        return const NearbyStationsPage();
      case 3:
        return InfoPages();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityProvider =
        Provider.of<CityProvider>(context); // 获取 CityProvider 实例
    final regionItems = regions;
    final selectedCity =
        regionItems.any((region) => region.id == cityProvider.city)
            ? cityProvider.city
            : null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.text_220,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // 豪華版地區選擇下拉選單
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCity,
                    hint: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 18, color: Color(0xFF1A73E8)),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.text_221,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        size: 22, color: Color(0xFF1A73E8)),
                    dropdownColor: Colors.white,
                    elevation: 8,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    menuMaxHeight: 300,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        cityProvider.setCity(newValue);
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return regionItems.map<Widget>((CityItem region) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 16, color: Color(0xFF1A73E8)),
                              const SizedBox(width: 6),
                              Text(
                                region.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A73E8),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    items: regionItems
                        .map<DropdownMenuItem<String>>((CityItem region) {
                      final isSelected = cityProvider.city == region.id;
                      return DropdownMenuItem<String>(
                        value: region.id,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEEF3FB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1A73E8)
                                      : Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  region.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF1A73E8)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Color(0xFF1A73E8),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          // 通知按鈕
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamed(context, "notification");
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    SvgAssets.notifications,
                    width: 20,
                    height: 20,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PageView.builder(
          physics: const NeverScrollableScrollPhysics(), // 禁用 PageView 的滑动手势
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          itemCount: 4,
          itemBuilder: (context, index) => _buildPage(index),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: NavigationBarTheme(
            data: AppThemes.getNavigationBarTheme(context),
            child: NavigationBar(
              selectedIndex: currentPageIndex,
              animationDuration: const Duration(milliseconds: 800),
              onDestinationSelected: (int index) {
                _navIconController
                    .forward()
                    .then((_) => _navIconController.reverse());
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                );
              },
              destinations: [
                _buildAnimatedDestination(
                  iconPath: SvgAssets.homeOutline,
                  activeIconPath: SvgAssets.home,
                  label: AppLocalizations.of(context)!.text_222,
                ),
                _buildAnimatedDestination(
                  iconPath: SvgAssets.commuteOutlined,
                  activeIconPath: SvgAssets.commuteOutlined,
                  label: AppLocalizations.of(context)!.text_223,
                ),
                _buildAnimatedDestination(
                  iconPath: SvgAssets.busStop,
                  activeIconPath: SvgAssets.busStop,
                  label: AppLocalizations.of(context)!.text_29,
                ),
                _buildAnimatedDestination(
                  iconPath: SvgAssets.personOutline,
                  activeIconPath: SvgAssets.person,
                  label: AppLocalizations.of(context)!.text_224,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDestination({
    required String iconPath,
    required String activeIconPath,
    required String label,
  }) {
    return NavigationDestination(
      label: label,
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: _inactiveIconSize, end: _inactiveIconSize),
        duration: const Duration(milliseconds: 300),
        builder: (context, size, _) {
          return SvgPicture.asset(
            iconPath,
            width: size,
            height: size,
            color: Colors.grey[600],
          );
        },
      ),
      selectedIcon: TweenAnimationBuilder<double>(
        tween: Tween(begin: _inactiveIconSize, end: _activeIconSize),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, size, _) {
          return ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
                stops: [0.3, 1.0],
              ).createShader(bounds);
            },
            child: SvgPicture.asset(
              activeIconPath,
              width: size,
              height: size,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
