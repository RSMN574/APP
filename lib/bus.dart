import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:untitled/widget/BusList.dart';
import 'package:untitled/widget/tab.dart';
import 'Const/regularConst.dart';
import 'database/getData.dart';

class Bus extends StatefulWidget {
  const Bus({Key? key}) : super(key: key);

  @override
  State<Bus> createState() => BusState();
}

class BusState extends State<Bus> {
  double suggestionsIsHidden = 0;
  TextEditingController busIdController = TextEditingController();
  List suggestions = [];

  void _updateSuggestions() {
    suggestions.clear();
    for (var route in busName) {
      String routeName = json.decode(route["RouteName"])["Zh_tw"];
      if (routeName.contains(busIdController.text)) {
        if (busIdController.text == routeName) {
          suggestions.insert(0, route);
        } else {
          suggestions.add(route);
        }
      }
    }

    setState(() {
      double screenHeight = MediaQuery.of(context).size.height;
      double bottomInset = MediaQuery.of(context).viewInsets.bottom;
      double appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

      // 更新建议列表的高度
      suggestionsIsHidden = screenHeight - bottomInset - appBarHeight - 14 - 70; // 更新为 70
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: busBlue,
        elevation: 0,
        title: Text(
          "公車",
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            height: 70,
            child: TextField(
              onChanged: (text) async {
                if (text.isNotEmpty) {
                  _updateSuggestions();
                } else {
                  setState(() {
                    suggestionsIsHidden = 0;
                  });
                }
              },
              controller: busIdController,
              decoration: InputDecoration(
                hintText: 'Search for a bus route...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Icon(Icons.search, color: Colors.grey[700], size: 24),
                contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: busBlue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 2.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  color: Colors.grey[700],
                  onPressed: () {
                    busIdController.clear();
                    setState(() {
                      suggestionsIsHidden = 0;
                    });
                  },
                ),
              ),
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
          ),
          Expanded( // 使用 Expanded 来填充剩余空间
            child: Stack(
              children: [
                tab(
                  id: ["route","stop","home","map","city",],
                  items: ["收藏路線", "收藏站牌","路線", "地圖", "城市",],
                  icons: [Icons.favorite,Icons.favorite,Icons.home, Icons.map, Icons.location_city, ],
                ),
                // 这里我们保持建议列表的高度不被挡住
                Container(
                  color: bgColor,
                  height: suggestionsIsHidden,
                  child: suggestions.isNotEmpty
                      ? Buslist(suggestions: suggestions)
                      : Center(child: Text("没有找到匹配的结果", style: TextStyle(color: Colors.grey))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

