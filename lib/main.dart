import 'package:com.rsmn574.app/widget/geolocator.dart';
import 'package:com.rsmn574.app/widget/googlemap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/Const/regularConst.dart';
import 'package:com.rsmn574.app/pages.dart';
import 'package:com.rsmn574.app/home.dart';
import 'package:com.rsmn574.app/pages/bus_time.dart';
import 'package:com.rsmn574.app/pages/nearStop.dart';
import 'package:com.rsmn574.app/pages/notification.dart';
import 'package:com.rsmn574.app/plane.dart';
import 'package:com.rsmn574.app/metro.dart';
import 'package:com.rsmn574.app/train.dart';
import 'package:com.rsmn574.app/bus.dart';
import 'package:com.rsmn574.app/map.dart';
import 'package:provider/provider.dart';
import 'Const/regularClass.dart';
import 'database/getData.dart';
import 'database/getWeather.dart';
import 'firebase/FCM.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Flutter 範例 [NavigationBar]。
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // 初始化 Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 获取 API 数据
    await GetApi();

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
    // 可以在这里使用一个简单的弹窗或 Snackbar 来提示用户
  }
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => CityProvider()),
      ChangeNotifierProvider(create: (context) => LocationProvider()),
    ],
    child: const NavigationBarApp(),
  ));
  // runApp(const NavigationBarApp());
}

// 定義 SVG 資源路徑的常量類別
class SvgAssets {
  static const String notifications = 'assets/icons/notifications-outline.svg';
  static const String homeOutline = 'assets/icons/home-outline.svg';
  static const String home = 'assets/icons/home.svg';
  static const String busStop = 'assets/icons/bus-stop.svg';
  static const String navigateOutline = 'assets/icons/navigate-outline.svg';
  static const String navigate = 'assets/icons/navigate.svg';
  static const String personOutline = 'assets/icons/person-outline.svg';
  static const String person = 'assets/icons/person.svg';
}

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      routes: {
        "plane": (BuildContext context) => plane(),
        "train": (BuildContext context) => train(),
        "metro": (BuildContext context) => Metro(),
        "bus": (BuildContext context) => Bus(),
        "busTime": (BuildContext context) => BusTime(),
        'notification':(BuildContext context) => notification(),
      },
      theme: appTheme,
      themeMode: ThemeMode.system,

      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  final List<Widget> _pages = [
    Home(),
    const Center(child: Text('commute page')),
    near_stop(),
    MapWidget(),
    pages(),
  ];
  @override
  void initState() {
    super.initState();
    // 在应用启动时获取定位信息
    getLocation(context);
    //天氣
    getWeatherInfo(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣通 交通聯合'),
        actions: [
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
      body:GestureDetector(
        onTap: () {
          hideKeyboard(context);
        },
        child: _pages[currentPageIndex],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: const Color(0xFFFFFFFF),
        // 使用 WidgetStateProperty 來取代 MaterialStateProperty
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(

                  color: primary, fontWeight: FontWeight.bold);
            }
            return const TextStyle(
                fontSize: 12,
                color: Colors.grey);
          },
        ),
        backgroundColor: Colors.white,
      ),
      child: NavigationBar(

        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: _buildNavigationDestinations(),
      ),
    );
  }

  List<NavigationDestination> _buildNavigationDestinations() {
    return [
      NavigationDestination(

        icon: SvgPicture.asset(

          SvgAssets.homeOutline,

          width: 20,
          height: 20,
        ),
        selectedIcon: SvgPicture.asset(
          SvgAssets.home,
          colorFilter: const ColorFilter.mode(primary, BlendMode.srcIn),
          width: 20,
          height: 20,
        ),
        label: '首頁',

      ),
      const NavigationDestination(
        icon: Icon(Icons.commute_outlined),

        label: '我的出行',
      ),
      NavigationDestination(
        icon: SvgPicture.asset(
          SvgAssets.busStop,
          width: 20,
          height: 20,
        ),selectedIcon: SvgPicture.asset(
        SvgAssets.busStop,
        colorFilter: const ColorFilter.mode(primary, BlendMode.srcIn),
        width: 20,
        height: 20,
      ),
        label: '最近站牌',
      ),
      NavigationDestination(
        icon: SvgPicture.asset(
          SvgAssets.navigateOutline,
          width: 20,
          height: 20,
        ),
        selectedIcon: SvgPicture.asset(
          SvgAssets.navigate,
          colorFilter: const ColorFilter.mode(primary, BlendMode.srcIn),
          width: 20,
          height: 20,
        ),
        label: '地圖',
      ),
      NavigationDestination(
        icon: SvgPicture.asset(
          SvgAssets.personOutline,
          width: 20,
          height: 20,
        ),
        selectedIcon: SvgPicture.asset(
          SvgAssets.person,
          colorFilter: const ColorFilter.mode(primary, BlendMode.srcIn),
          width: 20,
          height: 20,
        ),
        label: '我的資料',
      ),
    ];
  }
  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
