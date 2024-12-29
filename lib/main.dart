import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'Bike.dart';
import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'commute.dart';
import 'database/schedule.dart';
import 'firebase/FCM.dart';
import 'firebase_options.dart';
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
}

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});


  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      routes: {
        "plane": (BuildContext context) => plane(),
        "train": (BuildContext context) => Train(),
        "metro": (BuildContext context) => Metro(),
        "bus": (BuildContext context) => const Bus(),
        // "busTime": (BuildContext context) => BusTime(city: '',),
        'notification': (BuildContext context) => NotificationPage(),
        "home": (BuildContext context) => Home(),
        "bike": (BuildContext context) => Bike(),

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
  String? selectedRegion;
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
    super.initState();
    _pages.addAll([
      Home(),
      Commute(),
      NearbyStationsPage(),

      InfoPages(),

    ]);
    final schedule _schedule = schedule();
    _schedule.initDatabase();
    // 在应用启动时获取定位信息
    getLocation(context);

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
        return NearbyStationsPage();
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
        title: const Text('台灣通 交通聯合'),
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
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: Colors.white,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold);
            }
            return const TextStyle(fontSize: 12, color: Colors.grey);
          },
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          _pageController.jumpToPage(index);
        },
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(SvgAssets.homeOutline, width: 20, height: 20),
            selectedIcon: SvgPicture.asset(SvgAssets.home, color: Colors.blue, width: 20, height: 20),
            label: '首頁',
          ),
          const NavigationDestination(
            icon: Icon(Icons.commute_outlined),
            selectedIcon:Icon(Icons.commute, color: Colors.blue, ),
            label: '我的出行',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(SvgAssets.busStop, width: 20, height: 20),
            selectedIcon: SvgPicture.asset(SvgAssets.busStop, color: Colors.blue, width: 20, height: 20),
            label: '最近站牌',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(SvgAssets.personOutline, width: 20, height: 20),
            selectedIcon: SvgPicture.asset(SvgAssets.person, color: Colors.blue, width: 20, height: 20),
            label: '我的資料',
          ),
        ],
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
