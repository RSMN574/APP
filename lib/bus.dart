import 'dart:convert';
import 'package:com.rsmn574.app/pages/busStopInfo.dart';
import 'package:flutter/material.dart';
import 'package:com.rsmn574.app/widget/BusList.dart';
import 'package:com.rsmn574.app/widget/tab.dart';
import 'Const/regularConst.dart';
import 'database/getData.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class Bus extends StatefulWidget {
  const Bus({Key? key}) : super(key: key);

  @override
  State<Bus> createState() => BusState();
}

class BusState extends State<Bus> {
  final List<String> _list = ['全部', '臺中市'];
  final ValueNotifier<String> _dropdownValueNotifier = ValueNotifier<String>('路線');
  final ValueNotifier<double> suggestionsHeightNotifier = ValueNotifier<double>(0);
  TextEditingController busIdController = TextEditingController();
  List suggestions = [];

  Future<void> _updateSuggestions(id) async {
    suggestions.clear();

    if (id == "route") {
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
    } else if (id == "stop") {
      var i = await mysqlSelect("SELECT StationName FROM Bus.Bus_Taichung_Stop WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw')) LIKE '%${busIdController.text}%'");
      for (var a in i) {
        if (busIdController.text == json.decode(a["StationName"])["Zh_tw"]) {
          suggestions.insert(0, json.decode(a["StationName"])["Zh_tw"]);
        } else {
          suggestions.add(json.decode(a["StationName"])["Zh_tw"]);
        }
      }
      suggestions = (suggestions.toSet().toList());
    }

    setState(() {
      double screenHeight = MediaQuery.of(context).size.height;
      double bottomInset = MediaQuery.of(context).viewInsets.bottom;
      double appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
      suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 14 - 70;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: busBlue,
        elevation: 0,
        title: const Text(
          "公車",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          hideKeyboard(context);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: CustomDropdown<String>(
                hintText: 'Select City',
                items: _list,
                initialItem: _list[0],
                onChanged: (value) {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                height: 70,
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      child: ValueListenableBuilder<String>(
                        valueListenable: _dropdownValueNotifier,
                        builder: (context, value, child) {
                          return DropdownButtonFormField<String>(
                            value: value,
                            onChanged: (String? newValue) {
                              _dropdownValueNotifier.value = newValue!;
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: <String>['路線', '站牌', '業者']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: (text) async {
                          if (text.isNotEmpty) {
                            if (_dropdownValueNotifier.value == "路線") {
                              await _updateSuggestions('route');
                            } else if (_dropdownValueNotifier.value == "站牌") {
                              await _updateSuggestions('stop');
                            }
                          } else {
                            suggestions.clear();
                            suggestionsHeightNotifier.value = 0;
                          }
                        },
                        controller: busIdController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[700], size: 24),
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
                              _dropdownValueNotifier.value = '路線';
                              suggestions.clear();
                              suggestionsHeightNotifier.value = 0;
                            },
                          ),
                        ),
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const tab(
                    id: ["route", "stop", "map", "routeplan"],
                    items: ["收藏路線", "收藏站牌", "地圖", "規劃"],
                    icons: [Icons.favorite, Icons.favorite, Icons.map, Icons.route],
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: suggestionsHeightNotifier,
                    builder: (context, height, child) {
                      return Container(
                        color: bgColor,
                        height: height,
                        child: suggestions.isNotEmpty
                            ? _dropdownValueNotifier.value == "路線"
                            ? Buslist(suggestions: suggestions)
                            : _dropdownValueNotifier.value == "站牌"
                            ? BusStopList(suggestions)
                            : const Center(child: Text("请选择一个有效的选项"))
                            : const Center(child: Text("没有找到匹配的结果", style: TextStyle(color: Colors.grey))),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}

Widget BusStopList(suggestions) {
  return ListView.builder(
    itemCount: suggestions.length,
    itemBuilder: (context, index) {
      return Card(
        margin:EdgeInsets.symmetric(vertical: 4.0,horizontal :12),

        child: ListTile(
          leading: Icon(Icons.directions_bus, color: Colors.blueAccent),
          title: Text(suggestions[index].toString()),
          trailing: Icon(Icons.arrow_forward, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BusStopInfo(suggestions[index].toString())),
            );
          },
        ),
      );
    },
  );
}
