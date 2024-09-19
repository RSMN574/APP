import 'dart:convert';
import 'package:flutter/material.dart';

import '../database/getBusTime.dart';
import '../database/getData.dart';

class BusTime extends StatefulWidget {
  const BusTime({Key? key}) : super(key: key);

  @override
  State<BusTime> createState() => _BusTimeState();
}

class _BusTimeState extends State<BusTime> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次依賴變化時重新加載數據
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final routeInfo = ModalRoute.of(context)!.settings.arguments as List;
    await fetchBusTime(routeInfo[0]);
    final stopNames1 = await fetchStopNames(0);
    final stopNames2 = await fetchStopNames(1);
    return {
      'routeInfo': routeInfo,
      'stopNames1': stopNames1,
      'stopNames2': stopNames2,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final data = snapshot.data!;
        final routeInfo = data['routeInfo'] as List;
        final stopNames1 = data['stopNames1'] as List<String>;
        final stopNames2 = data['stopNames2'] as List<String>;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: Text(
                routeInfo[1],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.blueAccent,
              bottom: _buildTabBar(routeInfo),
            ),
            body: TabBarView(
              children: [
                _buildTabContent(stopNames2),
                _buildTabContent(stopNames1),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSize _buildTabBar(List routeInfo) {
    return PreferredSize(
      preferredSize: Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        child: TabBar(
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 16),
          tabs: [
            Tab(icon: Icon(Icons.directions_bus), text: routeInfo[1]),
            Tab(icon: Icon(Icons.swap_horiz), text: routeInfo[2]),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(List<String> stopNames) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _dataFuture = _loadData();
        });
      },
      child: ListView.builder(
        itemCount: stopNames.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.directions_bus, color: Colors.blueAccent),
                title: Text(
                  stopNames[index],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<List<String>> fetchStopNames(int tabIndex) async {
    List stops = await getInfo("routeInfo");
    List<String> stopNames = [];

    if (tabIndex < stops.length) {
      var stopData = json.decode(stops[tabIndex]["Stops"]);
      for (var stop in stopData) {
        stopNames.add(stop["StopName"]["Zh_tw"]);
      }
    }

    return stopNames;
  }
}