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
  final List<String> _list = [
    '全部',
    '臺中市',
  ];
  // 定义一个 ValueNotifier 来管理 Dropdown 的值
  final ValueNotifier<String> _dropdownValueNotifier = ValueNotifier<String>('路線');
  // 使用 ValueNotifier 来管理 suggestions 的高度
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

 for(var a in i){

print(json.decode(a["StationName"])["Zh_tw"]);
if (busIdController.text == json.decode(a["StationName"])["Zh_tw"]) {
  suggestions.insert(0, json.decode(a["StationName"])["Zh_tw"]);
} else {
  suggestions.add(json.decode(a["StationName"])["Zh_tw"]);
}
 }
      suggestions=(suggestions.toSet().toList());
    }

    // 更新 suggestions 的高度
    setState(() {
      double screenHeight = MediaQuery.of(context).size.height;
      double bottomInset = MediaQuery.of(context).viewInsets.bottom;
      double appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

      // 计算新的高度
      suggestionsHeightNotifier.value = screenHeight - bottomInset - appBarHeight - 14 - 70; // 更新为 70
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
      body: GestureDetector(
        onTap: () {
          hideKeyboard(context);
        },
        child: Column(
          children: [
            CustomDropdown<String>(
              hintText: 'Select job role',
              items: _list,
              initialItem: _list[0],
              onChanged: (value) {},
            ),
            Container(
              margin: const EdgeInsets.all(10),
              height: 70,
              child: Row(
                children: [
                  // 下拉式選單
                  Container(
                    width: 90, // 可以根据需要调整宽度
                    margin: const EdgeInsets.only(right: 10),
                    child: ValueListenableBuilder<String>(
                      valueListenable: _dropdownValueNotifier,
                      builder: (context, value, child) {
                        return DropdownButtonFormField<String>(
                          value: value, // 绑定 ValueNotifier 的值
                          onChanged: (String? newValue) {
                            _dropdownValueNotifier.value = newValue!; // 更新 ValueNotifier 的值
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

                  // 搜索框
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
                          suggestions.clear(); // 如果输入为空，清空建议
                          suggestionsHeightNotifier.value = 0; // 重置高度
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
                            _dropdownValueNotifier.value = '路線'; // 或者清除建议
                            suggestions.clear(); // 清空建议列表
                            suggestionsHeightNotifier.value = 0; // 重置高度
                          },
                        ),
                      ),
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  tab(
                    id: const ["route", "stop", "map", "routeplan"],
                    items: const ["收藏路線", "收藏站牌", "地圖", "規劃"],
                    icons: const [Icons.favorite, Icons.favorite, Icons.map, Icons.route],
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: suggestionsHeightNotifier,
                    builder: (context, height, child) {
                      return Container(
                        color: bgColor,
                        height: height,
                        child:
                        suggestions.isNotEmpty
                            ? _dropdownValueNotifier.value == "路線"
                            ? Buslist(suggestions: suggestions) // 显示 Buslist
                            : _dropdownValueNotifier.value == "站牌"
                            ? BusStopList(suggestions) // 显示 BusStopList
                            : const Center(child: Text("请选择一个有效的选项")) // 其他情况
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

Widget BusStopList(suggestions){
  return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index].toString()),
onTap: (){

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => BusStopInfo(suggestions[index].toString())),
  );
},


        );

      }
  );
}