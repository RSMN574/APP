import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:untitled/pages.dart';
import 'package:untitled/home.dart';
import 'package:untitled/pages/bus_time.dart';
import 'package:untitled/pages/nearStop.dart';
import 'package:untitled/plane.dart';
import 'package:untitled/metro.dart';
import 'package:untitled/train.dart';
import 'package:untitled/bus.dart';
import 'package:untitled/map.dart';
import 'database/getData.dart';
/// Flutter code sample for [NavigationBar].

void main() {
  runApp(const NavigationBarApp());
  GetApi();
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
      },
      theme: ThemeData(useMaterial3: true ,fontFamily: 'MiSans-Normal'),
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
  NavigationDestinationLabelBehavior labelBehavior =
      NavigationDestinationLabelBehavior.alwaysShow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣通BETA'),
       actions: [IconButton(onPressed:(){ print("notifications");}, icon: SvgPicture.asset(
         'assets/icons/notifications-outline.svg',
         width: 20,  // 設置寬度
         height: 20, // 設置高度
       ) ) ],
      ),
      bottomNavigationBar: NavigationBar(
        labelBehavior: labelBehavior,
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0xFFFFFFFF),
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: <Widget>[
          NavigationDestination(
            icon:  SvgPicture.asset(
              'assets/icons/home-outline.svg',
              width: 20,  // 設置寬度
              height: 20, // 設置高度
            ),
            selectedIcon: SvgPicture.asset(
              'assets/icons/home-outline.svg',
              width: 20,  // 設置寬度
              height: 20, // 設置高度
            ),
            label: '首頁',
          ),
          const NavigationDestination(
            icon: Icon(Icons.commute),
            label: '我的出行',
          ),
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/icons/bus-stop.svg',
              width: 20,  // 設置寬度
              height: 20, // 設置高度
            ),
            label: '最近站牌',
          ),  NavigationDestination(
            icon: SvgPicture.asset(
              'assets/icons/map-pin.svg',
              width: 20,  // 設置寬度
              height: 20, // 設置高度
            ),
            label: '地圖',
          ),
           NavigationDestination(

            icon: SvgPicture.asset(
              'assets/icons/person-outline.svg',
              width: 20,  // 設置寬度
              height: 20, // 設置高度
            ),
            label: '我的資料',
          ),
        ],
      ),
      body: <Widget>[
        /// Home page
       home(),
        const Card(
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'commute page',
              ),
            ),
          ),
        ),near_stop(),map(),
        pages()
      ][currentPageIndex],
    );
  }
}
