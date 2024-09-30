import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/Const/regularConst.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/getData.dart';
import '../database/shared_perferences.dart';
import '../pages/bus_time.dart';

class Buslist extends StatefulWidget {
  final List suggestions;

  Buslist({
    required this.suggestions,
  });

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> {
  List<String> favoritesBusRoute = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // 加载收藏的公交线路
  Future<void> _loadFavorites() async {
    List<String>? loadedFavorites = await loadList("favoritesBusRoute");
    if (loadedFavorites != null) {
      setState(() {
        favoritesBusRoute = loadedFavorites;
      });
    }
  }

  String extractZhTw(jsonString) {
    print(jsonString);
    return json.decode(jsonString)["Zh_tw"];
  }

  @override
  Widget build(BuildContext context) {
    return widget.suggestions.isEmpty
        ? const Center(
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
          color: bgColorWhite,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: SvgPicture.asset(
              'assets/icons/bus-outline.svg',
              width: 20, // 設置寬度
              height: 20, // 設置高度
            ),
            title: Text(
              '${extractZhTw(route["RouteName"])}',
              style: const TextStyle(
                fontFamily: 'MiSans-Demibold',
                fontSize: 15,
                color: busBlue,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('起點: ${route["DepartureStopNameZh"]}'),
                Text('終點: ${route["DestinationStopNameZh"]}'),
              ],
            ),

            onTap: () async {
              await GetBusInfo(int.parse(route["RouteID"]), "Taichung");
              // 打印路由 ID
              print(route["RouteID"]);

              // 使用 Navigator.push 创建新的页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusTime(
                    routeName: extractZhTw(route["RouteName"]),
                    departureStopName: route["DepartureStopNameZh"],
                    destinationStopName: route["DestinationStopNameZh"],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
