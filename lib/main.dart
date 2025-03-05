import 'dart:ui';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'Bike.dart';
import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'HSR.dart';
import 'commute.dart';
import 'database/SQL/schedule.dart';
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

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // 初始化 Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 请求通知权限
    await requestPermission();

    // 初始化通知和消息处理
    await initializeNotifications();
    setupForegroundMessageHandler();
    await setupFirebaseMessaging();

    // 设置后台消息处理
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase 初始化失败: $e');
  }
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // 记录日志或上报异常
  };

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => CityProvider()),
      ChangeNotifierProvider(create: (context) => LocationProvider()),
      ChangeNotifierProvider(create: (context) => MarkerProvider()),
    ],
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
late AnimationController _animationController;
class NavigationBarApp extends StatefulWidget {
  const NavigationBarApp({super.key});

  @override
  _NavigationBarAppState createState() => _NavigationBarAppState();
}

class _NavigationBarAppState extends State<NavigationBarApp>
    with SingleTickerProviderStateMixin { // 使用 SingleTickerProviderStateMixin
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 初始化 AnimationController
    _animationController = AnimationController(
      vsync: this, // 使用 this 作為 TickerProvider
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // 釋放資源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            routes: {
              "plane": (BuildContext context) => _buildAnimatedPage(Plane()),
              "train": (BuildContext context) => _buildAnimatedPage(Train()),
              "metro": (BuildContext context) => _buildAnimatedPage(Metro()),
              "bus": (BuildContext context) => _buildAnimatedPage(const Bus()),
              'notification': (BuildContext context) => _buildAnimatedPage(NotificationPage()),
              "home": (BuildContext context) => _buildAnimatedPage(Home()),
              "bike": (BuildContext context) => _buildAnimatedPage(Bike()),
              "HSR": (BuildContext context) => _buildAnimatedPage(HSR()),
            },
            theme: appTheme,
            themeMode: ThemeMode.system,
            home: const TaiwanPass(),
          );
        },
      ),
    );
  }
  Widget _buildAnimatedPage(Widget page, {bool isReverse = false}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.fastEaseInToSlowEaseOut,
      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 定義進出動畫方向
        final Offset enterOffset = isReverse
            ? const Offset(-0.1, 0)
            : const Offset(0.1, 0);
        final Offset exitOffset = isReverse
            ? const Offset(0.1, 0)
            : const Offset(-0.1, 0);

        // 進入動畫
        final Animation<Offset> enterAnimation = Tween<Offset>(
          begin: enterOffset,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        ));

        // 退出動畫
        final Animation<Offset> exitAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: exitOffset,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, 1.0, curve: Curves.easeInCubic),
        ));

        // 組合動畫
        return Stack(
          children: <Widget>[
            // 退出頁面動畫
            SlideTransition(
              position: exitAnimation,
              child: FadeTransition(
                opacity: ReverseAnimation(animation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                    CurvedAnimation(
                      parent: ReverseAnimation(animation),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
            // 進入頁面動畫
            SlideTransition(
              position: enterAnimation,
              child: FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey(page.runtimeType),
        child: page,
      ),
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

    getLocation(context);
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
    final schedule _schedule = schedule();
    _schedule.initDatabase();

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
    // 在应用启动时获取定位信息

    getLocation(context);
    final cityProvider = Provider.of<CityProvider>(context); // 获取 CityProvider 实例
    print(cityProvider.city);
    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣通'),
        actions: [
          // 下拉菜单
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: cityProvider.city,
              hint: const Text('選擇地區'),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              onChanged: (String? newValue) {
                if (newValue != null) {

                  cityProvider.setCity(newValue); // 更新所选城市
                }
              },
              items: regions.map<DropdownMenuItem<String>>((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "notification");
            },
            icon: SvgPicture.asset(
              SvgAssets.notifications,
              width: 20,
              height: 20,
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
  // Widget _buildNavigationBar() {
  //   return NavigationBarTheme(
  //     data: NavigationBarThemeData(
  //       indicatorColor: const Color(0xFFFFFFFF),
  //       labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
  //             (Set<WidgetState> states) {
  //           if (states.contains(WidgetState.selected)) {
  //             return const TextStyle(color: primary, fontWeight: FontWeight.bold);
  //           }
  //           return const TextStyle(fontSize: 12, color: Colors.grey);
  //         },
  //       ),
  //       backgroundColor: Colors.white,
  //     ),
  //     child: NavigationBar(
  //       selectedIndex: currentPageIndex,
  //       onDestinationSelected: (int index) {
  //         setState(() {
  //           currentPageIndex = index;
  //         });
  //       },
  //       destinations: _buildNavigationDestinations(),
  //     ),
  //   );
  // }



  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

}
