import 'dart:convert';

import'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../database/getBusTime.dart';
import '../database/getData.dart';
import '../widget/tab.dart';

class busTime extends StatefulWidget {
  busTime({Key? key, }) : super(key: key);


  @override
  State<busTime> createState() => _busTimeState();
}

class _busTimeState extends State<busTime> {

  List tabItems=[];
  @override
  Widget build(BuildContext context) {
    tabItems.clear();
    List BusInfo = getInfo('routeInfo');
    // Future <List> r() async {
    //   List BusInfo = await getInfo('routeInfo');
    //
    //   print(json
    //       .decode(BusInfo[0]["Stops"])[json
    //       .decode(BusInfo[0]["Stops"])
    //       .length-1]["StopName"]["Zh_tw"]);
    //   tabItems.add((json
    //       .decode(BusInfo[0]["Stops"])[json
    //       .decode(BusInfo[0]["Stops"])
    //       .length-1]["StopName"]["Zh_tw"]) );
    //   tabItems.add((json
    //       .decode(BusInfo[1]["Stops"])[json
    //       .decode(BusInfo[1]["Stops"])
    //       .length-1]["StopName"]["Zh_tw"]) );
    //
    //   return tabItems;
    // }
    var route = ModalRoute
        .of(context)!
        .settings
        .arguments as List;
    print(route);
    fetchBusTime(route[0]);
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(route[1]),
          bottom: TabBar(
            indicatorColor: Colors.white, // Customize the indicator color
            labelColor: Colors.white, // Color of selected tab text
            unselectedLabelColor: Colors.white70, // Color of unselected tab text
            indicatorWeight: 3.0, // Customize indicator height
            tabs: [
              Tab(icon: Icon(Icons.home), text:route[1] ),
              Tab(icon: Icon(Icons.search), text: route[2]),
            ],
          ),
          backgroundColor: Colors.blueAccent, // Customize AppBar color
        ),
        body: TabBarView(
          children: [
            Text(route[1]), // First tab page content
            Text(route[2]), // Second tab page content
          ],
        ),
      ),
    );

  }
}
