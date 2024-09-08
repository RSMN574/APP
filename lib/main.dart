import 'package:flutter/material.dart';
import 'package:untitled/pages.dart';
import 'package:untitled/home.dart';
import 'package:untitled/plane.dart';
import 'package:untitled/metro.dart';
import 'package:untitled/train.dart';
import 'package:untitled/bus.dart';
import 'package:untitled/map.dart';
/// Flutter code sample for [NavigationBar].

void main() => runApp(const NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {

        "plane": (BuildContext context) => plane(),
        "train": (BuildContext context) => train(),
        "metro": (BuildContext context) => metro(),
        "bus": (BuildContext context) => bus(),
      },
      theme: ThemeData(useMaterial3: true),
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
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(Icons.home),
            label: '首頁',
          ),
          NavigationDestination(
            icon: Icon(Icons.commute),
            label: '交通',
          ), NavigationDestination(
            icon: Icon(Icons.commute),
            label: '地圖',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
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
        ),map(),
        pages()
      ][currentPageIndex],
    );
  }
}
