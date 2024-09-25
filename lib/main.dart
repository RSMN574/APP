import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:untitled/Const/regularConst.dart';
import 'package:untitled/pages.dart';
import 'package:untitled/home.dart';
import 'package:untitled/pages/bus_time.dart';
import 'package:untitled/pages/nearStop.dart';
import 'package:untitled/pages/notification.dart';
import 'package:untitled/plane.dart';
import 'package:untitled/metro.dart';
import 'package:untitled/train.dart';
import 'package:untitled/bus.dart';
import 'package:untitled/map.dart';
import 'database/getData.dart';

/// Flutter 範例 [NavigationBar]。

void main() {
  runApp(const NavigationBarApp());
  GetApi();
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
        "metro": (BuildContext context) => metro(),
        "bus": (BuildContext context) => Bus(),
        "busTime": (BuildContext context) => BusTime(),
        'notification':(BuildContext context) => notification(),
      },
      theme: ThemeData(useMaterial3: true, fontFamily: 'MiSans-Normal'),
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
    home(),
    const Center(child: Text('commute page')),
    near_stop(),
    map(),
    pages(),
  ];

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
      body: _pages[currentPageIndex],
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
            return const TextStyle(color: Colors.grey);
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
        selectedIcon:Icon(Icons.commute),
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
}
