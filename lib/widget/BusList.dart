import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:com.rsmn574.app/Const/regularConst.dart';

import '../database/getData.dart';
import '../database/shared_perferences.dart';
import '../pages/bus_time.dart';

class Buslist extends StatefulWidget {
  final List suggestions;
  final String city;

  const Buslist({required this.suggestions, required this.city});

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
                color: Colors.white,
                // 保持白色背景
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.4), // 輕微圓角
                ),
                elevation: 0,
                // 去除陰影，符合扁平化設計
                child: Padding(
                  padding: const EdgeInsets.all(10.0), // 內邊距適中
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6), // 增加內邊距
                      decoration: BoxDecoration(
                        color: busBlue.withOpacity(0.15), // 扁平化設計中的單一背景色
                        shape: BoxShape.circle, // 圓形圖標背景
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/bus-outline.svg',
                        width: 24, // 調整圖標大小
                        height: 24,
                        color: busBlue, // 使用單一色調
                      ),
                    ),
                    title: Text(
                      extractZhTw(route["RouteName"]),
                      style: const TextStyle(
                        fontFamily: 'MiSans-Demibold',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: busBlue, // 使用扁平化設計中常見的明亮色調
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5), // 增加間距
                        Text(
                          '起點: ${route["DepartureStopNameZh"]}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700], // 使用扁平化設計中的灰色來弱化次要文本
                          ),
                        ),
                        Text(
                          '終點: ${route["DestinationStopNameZh"]}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                    // 保持簡潔的右側箭頭
                    onTap: () async {
                      await GetBusInfo(
                          routeid: int.parse(route["RouteID"]), city: route["City"]);

                      // 使用 Navigator.push 创建新的页面
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusTime(
                            routeName: extractZhTw(route["RouteName"]),
                            departureStopName: route["DepartureStopNameZh"],
                            destinationStopName: route["DestinationStopNameZh"],
                            operators: route["Operators"],
                            routeMapImageUrl: route["RouteMapImageUrl"],
                            city: route["City"],
                            routeID: int.parse(route["RouteID"]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
  }
}
