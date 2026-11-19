import 'dart:async';

import 'package:com.rsmn574.app/features/airport/state/airport_provider.dart';
import 'package:com.rsmn574.app/features/parking/state/parking_provider.dart';
import 'package:com.rsmn574.app/features/traffic/state/traffic_provider.dart';
import 'package:com.rsmn574.app/features/ev_charging/state/ev_station_provider.dart';
import 'package:com.rsmn574.app/features/weather/state/weather_provider.dart';
import 'package:com.rsmn574.app/features/railway/provider/railway_provider.dart';
import 'package:com.rsmn574.app/features/notification/state/notification_provider.dart';
import 'package:com.rsmn574.app/features/settings/state/settings_provider.dart';
import 'dart:ui';

import 'package:com.rsmn574.app/features/ev_charging/pages/ev_station_page.dart';
import 'package:com.rsmn574.app/features/tools/pages/speedometer_page.dart';
import 'package:com.rsmn574.app/features/parking/pages/parking_page.dart';
import 'package:com.rsmn574.app/features/traffic/pages/traffic_page.dart';
import 'package:com.rsmn574.app/secure_storage/secure_storage.dart';
import 'package:com.rsmn574.app/features/notification/services/arrival_reminder_task.dart';
import 'package:com.rsmn574.app/features/diagnostics/pages/metro_map_test_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/single_child_widget.dart';

import 'const/regular_class.dart';
import 'core/city/taiwan_city.dart';
import 'core/error/app_error_handler.dart';
import 'package:com.rsmn574.app/features/diagnostics/pages/diagnostics_page.dart';
import 'core/startup/startup_metrics.dart';
import 'firebase/analytics_service.dart';
import 'firebase/crashlytics_reporter.dart';
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
import 'database/sql/schedule.dart';
import 'database/get_data.dart';
import 'database/token_manager.dart';
import 'firebase/fcm.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'widget/geolocator.dart';
import 'package:com.rsmn574.app/features/profile/pages/info_pages.dart';
import 'features/home/pages/home.dart';
import 'features/bus/state/bus_provider.dart';
import 'package:logging/logging.dart';
import 'features/metro/state/metro_provider.dart';
import 'features/startup/pages/startup_gate.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('zh'));

class AppInitializer {
  static bool firebaseInitialized = false;
  static bool bootstrapReady = false;
  static bool _deferredStarted = false;
  static final Logger _log = Logger('AppInitializer');

  static void _setupLogging() {
    Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint(
        '${record.level.name}: ${record.time}: ${record.message}'
        '${record.error != null ? '\n  error: ${record.error}' : ''}'
        '${record.stackTrace != null ? '\n${record.stackTrace}' : ''}',
      );
    });
  }

  /// 啟動關鍵路徑：只做「首頁顯示前一定要完成」且不需要網路的工作。
  ///
  /// QA B03：先前在 runApp 前依序等待 FCM 權限對話框、FCM getToken、
  /// TDX Token 與 bootstrap（HTTP timeout 20s），弱網路時白畫面 20 秒以上。
  static Future<void> initializeCritical() async {
    _setupLogging();
    AppErrorHandler.installGlobalHandlers();
    _log.info('app start');

    try {
      // Android 的 google-services 外掛會在原生端先建立 [DEFAULT] app，
      // 重複呼叫 initializeApp 會丟 core/duplicate-app，導致登入不可用。
      if (Firebase.apps.isEmpty) {
        try {
          await StartupMetrics.measure(
            'firebase_init',
            () => Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
          );
        } on FirebaseException catch (e) {
          if (e.code != 'duplicate-app') rethrow;
        }
      }
      firebaseInitialized = true;
      AppErrorHandler.attachReporter(CrashlyticsErrorReporter());
      // 背景執行時 FCM 需要在啟動時註冊 handler（同步、不需網路）。
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e, stack) {
      _log.severe('Firebase 初始化失敗', e, stack);
    }
  }

  /// 首幀之後才執行的非必要初始化；各項彼此獨立，單一失敗不影響其他項目。
  static Future<void> initializeDeferred() async {
    if (_deferredStarted) return;
    _deferredStarted = true;

    if (firebaseInitialized) {
      unawaited(_runGuarded('crashlytics_config', () async {
        final info = await PackageInfo.fromPlatform();
        final reporter = AppErrorHandler.reporter;
        if (reporter is CrashlyticsErrorReporter) {
          await reporter.configure(
            appVersion: info.version,
            buildNumber: info.buildNumber,
          );
        }
      }));
      // 推播設定獨立處理：離線時 FCM getToken() 會丟例外，
      // 不可因此讓到站提醒與 TDX Token 自動更新一起被略過。
      unawaited(_runGuarded('fcm', () async {
        await requestPermission();
        await initializeNotifications();
        setupForegroundMessageHandler();
        await setupFirebaseMessaging();
      }));
    }

    unawaited(_runGuarded('secure_storage', SecureStorage.purgeLegacyApiKey));
    unawaited(
        _runGuarded('arrival_reminder', initializeArrivalReminderService));

    // TDX Token：背景預先取得即可，TdxApiClient 需要時會自行取得/更新。
    final tokenManager = TokenManager();
    tokenManager.startAutoRefresh();
    unawaited(_runGuarded('tdx_token_prefetch', () => tokenManager.getToken()));

    // 首次預載資料（bus list → SQLite）：失敗不影響 App，保留本地快取。
    unawaited(_runGuarded('bootstrap', () async {
      await StartupMetrics.measure(
        'bootstrap',
        BootstrapService.instance.ensureLoaded,
      );
      bootstrapReady = true;
    }));
  }

  static Future<void> _runGuarded(
    String name,
    Future<void> Function() action,
  ) async {
    try {
      AppErrorHandler.breadcrumb('init $name');
      await action();
    } catch (e, stack) {
      _log.warning('$name 初始化失敗', e, stack);
      unawaited(AppErrorHandler.recordNonFatal(e, stack,
          feature: 'startup', reason: name));
    }
  }
}

class ProviderSetup {
  static List<SingleChildWidget> getProviders(
    AppProvider appProvider, {
    CityProvider? cityProvider,
    required bool firebaseInitialized,
  }) {
    return [
      if (cityProvider != null)
        ChangeNotifierProvider.value(value: cityProvider)
      else
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
        update: (_, auth, sync) => (sync ?? CloudSyncProvider())..attachUser(auth.currentUser?.uid),
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
  static const String diagnostics = "/debug/diagnostics";
  static const String parking = "parking";
  static const String traffic = "traffic";
  static const String speedometer = "speedometer";
  static const String taxi = "taxi";
  static const String authLogin = "/auth/login";
  static const String authProfile = "/auth/profile";
}

Future<void> main() async {
  StartupMetrics.markMainStart();
  WidgetsFlutterBinding.ensureInitialized();
  // 偏好設定讀取與 Firebase 初始化並行，縮短首幀前的等待。
  final appProviderFuture = AppProvider.load();
  final cityProviderFuture = CityProvider.load();
  await AppInitializer.initializeCritical();
  StartupMetrics.attachPerformanceTrace();
  final appProvider = await appProviderFuture;
  final cityProvider = await cityProviderFuture;

  runApp(MultiProvider(
    providers: ProviderSetup.getProviders(
      appProvider,
      cityProvider: cityProvider,
      firebaseInitialized: AppInitializer.firebaseInitialized,
    ),
    child: const NavigationBarApp(),
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    StartupMetrics.markFirstFrame();
    unawaited(AppInitializer.initializeDeferred());
    unawaited(AppAnalytics.logAppOpen());
  });
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
    // QA B4：只監聽主題與語系，且不在 build 內輸出 log。
    final themeMode =
        context.select<AppProvider, ThemeMode>((p) => p.themeMode);
    final locale = context.select<AppProvider, Locale>((p) => p.locale);

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
                  child: Metro(),
                ),
            AppRoutes.bus: (BuildContext context) => (const Bus()),
            AppRoutes.notification: (BuildContext context) =>
                (NotificationPage()),
            AppRoutes.home: (BuildContext context) => (Home()),
            // AppRoutes.bike: (BuildContext context) => (Bike()),
            AppRoutes.HSR: (BuildContext context) => (HSR()),
            AppRoutes.EVStation: (BuildContext context) => (EVStation()),
            AppRoutes.IntercityBus: (BuildContext context) => (IntercityBus()),
            // QA B17：測試頁只在 Debug build 註冊。
            if (kDebugMode)
              AppRoutes.test: (BuildContext context) => (MetroMapScreen()),
            if (AppDiagnostics.enabled)
              AppRoutes.diagnostics: (BuildContext context) =>
                  const DiagnosticsPage(),
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
          themeMode: themeMode,
          // --- 重點：套用語言 ---
          locale: locale,

          // themeMode: ThemeMode.system,
          home: const StartupGate(home: TaiwanPass()),
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
  // QA C4：縣市清單由 TaiwanCity 產生（id 為中文名稱，與 CityProvider 一致）。
  List<CityItem> get regions {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return [
      for (final city in TaiwanCity.all)
        CityItem(name: isEnglish ? city.enName : city.zhName, id: city.zhName),
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

    // QA B04：TDX 回傳 `HsinchuCounty` 等代碼，統一由 TaiwanCity 解析。
    final detected = TaiwanCity.tryParse(districtInfo["city"]);
    if (detected == null) {
      if (!context.mounted) return null;
      return AppLocalizations.of(context)!.text_919;
    }

    if (!context.mounted) return null;
    // QA B06：GPS 只在使用者從未手動選擇城市時套用，不覆蓋上次選擇。
    final applied = Provider.of<CityProvider>(context, listen: false)
        .applyDetectedCity(detected.zhName);
    if (applied) {
      unawaited(AppAnalytics.logCityChanged(
          city: detected.tdxCode, source: 'gps'));
    }

    return detected.zhName;
  }

  @override
  void initState() {
    super.initState();
    _navIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final city = Provider.of<CityProvider>(context, listen: false).city;
    unawaited(AppErrorHandler.setContext(city: city, feature: 'home'));

    // 首頁先顯示，再背景取得定位（不阻塞首頁互動）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupMetrics.markHomeVisible();
      unawaited(fetchAndUpdateLocation(context)
          .catchError((Object e, StackTrace st) {
        unawaited(AppErrorHandler.recordNonFatal(e, st, feature: 'location'));
        return null;
      }).whenComplete(StartupMetrics.markHomeInteractive));
    });

    unawaited(Future<void>(ScheduleService.instance.initDatabase)
        .catchError((Object e, StackTrace st) => AppErrorHandler.recordNonFatal(
            e, st,
            feature: 'schedule_db')));
  }

  @override
  void dispose() {
    _navIconController.dispose();
    _pageController.dispose();
    super.dispose();
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
    // QA B4：城市變更只重建城市選擇器，不重建整個首頁殼（PageView 與地圖）。
    final cityProvider = Provider.of<CityProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final regionItems = regions;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.text_220,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // 豪華版地區選擇下拉選單
          Selector<CityProvider, String>(
            selector: (_, p) => p.city,
            builder: (context, currentCity, _) {
              final selectedCity =
                  regionItems.any((region) => region.id == currentCity)
                      ? currentCity
                      : null;
              return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
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
                        Icon(Icons.location_on_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.text_221,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    icon: Icon(Icons.arrow_drop_down_rounded,
                        size: 22, color: Theme.of(context).colorScheme.primary),
                    dropdownColor: colorScheme.surfaceContainer,
                    elevation: 8,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    menuMaxHeight: 300,
                    onChanged: (String? newValue) {
                      if (newValue == null) return;
                      unawaited(cityProvider.setCity(newValue));
                      final code = TaiwanCity.tryParse(newValue)?.tdxCode;
                      if (code != null) {
                        unawaited(AppAnalytics.logCityChanged(
                            city: code, source: 'home_selector'));
                        unawaited(AppErrorHandler.setContext(city: code));
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return regionItems.map<Widget>((CityItem region) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                region.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
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
                                ? colorScheme.primaryContainer
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
                                      ? Theme.of(context).colorScheme.primary
                                      : colorScheme.outline,
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
                                        ? Theme.of(context).colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: colorScheme.primary,
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
          );
            },
          ),
          // 通知按鈕
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
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
                    color: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
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
              animationDuration: reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 800),
              onDestinationSelected: (int index) {
                if (!reducedMotion) {
                  _navIconController
                      .forward()
                      .then((_) => _navIconController.reverse());
                }
                _pageController.animateToPage(
                  index,
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 500),
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
        duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        builder: (context, size, _) {
          return SvgPicture.asset(
            iconPath,
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
        },
      ),
      selectedIcon: TweenAnimationBuilder<double>(
        tween: Tween(begin: _inactiveIconSize, end: _activeIconSize),
        duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
            ? Duration.zero
            : const Duration(milliseconds: 300),
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
