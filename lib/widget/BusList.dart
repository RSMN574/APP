import 'dart:convert';

import'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../database/getData.dart';

class Buslist extends StatefulWidget {
  final List suggestions;

  Buslist({
    required this.suggestions,
  });

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> {
  RegExp regExp = RegExp(r'"Zh_tw":"(.*?)"');

  String extractZhTw(String jsonString) {
    Match? match = regExp.firstMatch(jsonString);
    return match != null ? match.group(1)! : "No match";
  }

  @override
  Widget build(BuildContext context) {
    return widget.suggestions.isEmpty
        ? Center(
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '找不到此公車路線',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    )
        : ListView.builder(
      itemCount: widget.suggestions.length,
      itemBuilder: (context, index) {
        final route = widget.suggestions[index];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Icon(Icons.directions_bus),
            title: Text('路線：${extractZhTw(route["RouteName"])}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('起點: ${route["DepartureStopNameZh"]}'),
                Text('終點: ${route["DestinationStopNameZh"]}'),
              ],
            ),
            onTap: ()  async {
              await GetBusInfo(int.parse(route["RouteID"]));
              // Add navigation or functionality for each route here
              print(route["RouteID"]);

              Navigator.pushNamed(context, "busTime",    arguments:[json.decode(route["RouteName"])['Zh_tw'],route["DepartureStopNameZh"],route["DestinationStopNameZh"]]);

            },
          ),
        );
      },
    );
  }
}
