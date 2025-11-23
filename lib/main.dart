import 'dart:ui';

import 'package:com.rsmn574.app/pages/EV_station.dart';
import 'package:com.rsmn574.app/pages/parking.dart';
import 'package:com.rsmn574.app/secure_storage/secure_storage.dart';
import 'package:com.rsmn574.app/task/task.dart';
import 'package:com.rsmn574.app/test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/single_child_widget.dart';

import 'Bike.dart';
import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'HSR.dart';
import 'IntercityBus.dart';
import 'commute.dart';
import 'database/SQL/schedule.dart';
import 'database/SQL/sqlite.dart';
import 'database/getData.dart';
import 'database/token_manager.dart';
import 'firebase/FCM.dart';
import 'firebase/firebase_options.dart';
import 'widget/geolocator.dart';
import 'pages.dart';
import 'home.dart';
import 'pages/nearStop.dart';
import 'pages/notification.dart';
import 'plane.dart';
import 'metro.dart';
import 'train.dart';
import 'bus.dart';
import 'package:logging/logging.dart';
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
class AppInitializer {
  static Future<void> initialize() async {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    final log = Logger('MyApp');
    log.info('應用程式啟動');

    await SecureStorage.initializeApiKey();

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await requestPermission();
      await initializeNotifications();
      setupForegroundMessageHandler();
      await setupFirebaseMessaging();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final tokenManager = TokenManager();
      await tokenManager.getToken();  // 啟動時先確保有 token
      tokenManager.startAutoRefresh(); // 啟動定時更新
    } catch (e, stack) {
      log.severe('Firebase 初始化失敗', e, stack);
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      log.severe('Flutter Error: ${details.exception}', details.stack);
    };
  }
}
class ProviderSetup {
  static List<SingleChildWidget> getProviders() {
    return [
      ChangeNotifierProvider(create: (_) => CityProvider()),
      ChangeNotifierProvider(create: (_) => LocationProvider()),
      ChangeNotifierProvider(create: (_) => MarkerProvider()),
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();


  runApp(MultiProvider(
    providers: ProviderSetup.getProviders(),
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
    with SingleTickerProviderStateMixin { // 使用 SingleTickerProviderStateMixin


  @override
  void initState() {
    super.initState();


    // 在应用启动时获取定位信息

    getLocation(context);
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



    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child:  MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          AppRoutes.plane: (BuildContext context) => (Plane()),
          AppRoutes.train: (BuildContext context) => (Train()),
          AppRoutes.metro: (BuildContext context) => (Metro()),
          AppRoutes.bus: (BuildContext context) => (const Bus()),
          AppRoutes.notification: (BuildContext context) => (NotificationPage()),
          AppRoutes.home: (BuildContext context) => (Home()),
          AppRoutes.bike: (BuildContext context) => (Bike()),
          AppRoutes.HSR: (BuildContext context) => (HSR()),
          AppRoutes.EVStation: (BuildContext context) => (EVStation()),
          AppRoutes.IntercityBus: (BuildContext context) => (IntercityBus()),
          AppRoutes.test: (BuildContext context) => (MetroMapScreen()),
          AppRoutes.parking: (BuildContext context) => (Parking()),
        },

        theme: appTheme,
        themeMode: ThemeMode.system,
        home: const TaiwanPass(),
      )
    );
  }

}
class TaiwanPass extends StatefulWidget {
  const TaiwanPass({super.key});

  @override
  State<TaiwanPass> createState() => _TaiwanPassState();
}

class _TaiwanPassState extends State<TaiwanPass> with SingleTickerProviderStateMixin{
  int currentPageIndex = 0;
  String? selectedRegion;
  // 在 State 類別新增動畫控制器
  late AnimationController _navIconController;
  final double _activeIconSize = 24;
  final double _inactiveIconSize = 22;
  final PageController _pageController = PageController(); // 控制 PageView
  final List<String> regions = [
    '宜蘭縣', '花蓮縣', '臺東縣', '澎湖縣', '金門縣', '連江縣', '臺北市',
    '新北市', '桃園市', '臺中市', '臺南市', '高雄市', '基隆市', '新竹縣',
    '新竹市', '苗栗縣', '彰化縣', '南投縣', '雲林縣', '嘉義縣', '嘉義市', '屏東縣',
  ];

  // 初始化页面列表
  final List<Widget> _pages = [];

  @override
  void initState() {
    // 在应用启动时获取定位信息

    // 延迟获取定位信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getLocation(context); // 异步获取定位信息
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

    final cityProvider = Provider.of<CityProvider>(context); // 获取 CityProvider 实例

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '台灣通',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A73E8),
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
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // 可以添加點擊效果
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: cityProvider.city,
                      hint: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF1A73E8)),
                          const SizedBox(width: 8),
                          Text(
                            '選擇地區',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 22, color: Color(0xFF1A73E8)),
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
                        return regions.map<Widget>((String region) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF1A73E8)),
                                const SizedBox(width: 6),
                                Text(
                                  region,
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
                      items: regions.map<DropdownMenuItem<String>>((String region) {
                        final isSelected = cityProvider.city == region;
                        return DropdownMenuItem<String>(
                          value: region,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEEF3FB) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1A73E8) : Colors.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    region,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? const Color(0xFF1A73E8) : Colors.black87,
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
            data: NavigationBarThemeData(
              height: 64,
              indicatorColor: Colors.white.withOpacity(0.5),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                    (Set<WidgetState> states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: isSelected ? 12 : 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.blueAccent : Colors.grey[600],
                    letterSpacing: 0.2,
                  );
                },
              ),
            ),
            child: NavigationBar(
              selectedIndex: currentPageIndex,
              animationDuration: const Duration(milliseconds: 800),
              onDestinationSelected: (int index) {
                _navIconController.forward().then((_) => _navIconController.reverse());
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
                  label: '首頁',
                ),
                _buildAnimatedDestination(
                  iconPath: SvgAssets.commuteOutlined,
                  activeIconPath: SvgAssets.commuteOutlined,
                  label: '出行',
                ),
                _buildAnimatedDestination(
                  iconPath: SvgAssets.busStop,
                  activeIconPath: SvgAssets.busStop,
                  label: '站牌',
                ),
                _buildAnimatedDestination(
                  iconPath: SvgAssets.personOutline,
                  activeIconPath: SvgAssets.person,
                  label: '我的',
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
