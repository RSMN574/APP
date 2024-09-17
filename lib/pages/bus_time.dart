import'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../database/getBusTime.dart';

class busTime extends StatefulWidget {
  busTime({Key? key, }) : super(key: key);


  @override
  State<busTime> createState() => _busTimeState();
}

class _busTimeState extends State<busTime> {

  @override
  Widget build(BuildContext context) {

    var routeID=ModalRoute.of(context)!.settings.arguments as String;
    fetchBusTime(routeID);
    return Scaffold(
      appBar: AppBar(
      automaticallyImplyLeading: true,
      title:  Text(routeID),
    ),
      body: Text(routeID),
    );
  }
}
