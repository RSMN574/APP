import 'dart:convert';
import 'package:flutter/material.dart';

import '../../database/getData.dart';

class StationDialog {
  static const Color modernOrange = Color(0xFFFFA726); // 橘色
  static const Color modernBlue = Color(0xFF42A5F5); // 蓝色

  static   Future<Map<String, dynamic>?> showStationDialog(context) async {
    // 定义现代化橘色和蓝色
    const Color modernOrange = Color(0xFFFFA726); // 橘色
    const Color modernBlue = Color(0xFF42A5F5); // 蓝色
    List stationData = await mysqlSelect("SELECT StationID,StationClass,StationName,StationPosition,LocationCity FROM Train.Train_Station;");

    // 转换 stationData 到 stationDataMap
    List<Map<String, dynamic>> stationDataMap = stationData.map((item) {
      final stationName = json.decode(item["StationName"]);
      return {
        'StationName': {
          'Zh_tw': stationName['Zh_tw'],
          'En': stationName['En'],
        },
        'LocationCity': item['LocationCity'],
        'StationClass': item['StationClass'],
        'StationID': item['StationID'],
        'StationPosition': item['StationPosition'],
      };
    }).toList();

// 构建 stationsList
    final Map<String, List<String>> stationsList = {};
    for (var entry in stationDataMap) {
      String city = entry['LocationCity'];
      String stationName = entry['StationName']['Zh_tw'];

      // 使用 putIfAbsent 简化逻辑
      stationsList.putIfAbsent(city, () => []).add(stationName);
    }

    print(stationsList);
    String _selectedCity = '臺中市';
    String? _selectedStation;
    Map<String, dynamic>? selectedStationData;

    Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.16),
                                    blurRadius: 1,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: ListView(
                                children: stationsList.keys.map((city) {
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCity = city;
                                        _selectedStation = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedCity == city ? Colors.grey[800] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        city,
                                        style: TextStyle(
                                          color: _selectedCity == city ? Colors.white : Colors.grey[800],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.16),
                                    blurRadius: 1,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child:  ListView(
                                children: stationsList[_selectedCity]!.map((station) {
                                  var stationEntry = stationDataMap.firstWhere(
                                        (entry) => entry['StationName']['Zh_tw'] == station,

                                  );

                                  Color? textColor;

// 根据 StationClass 的值设置文字颜色
                                  switch (stationEntry['StationClass'].toString()) {
                                    case "0":
                                      textColor = modernOrange;
                                      break;
                                    case "1":
                                      textColor = modernBlue;
                                      break;
                                    default:
                                      textColor = Colors.grey[800]; // 默认颜色
                                      break;
                                  }


                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedStation = station;
                                        selectedStationData = stationEntry;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _selectedStation == station ? Colors.grey[300] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        station,
                                        style: TextStyle(
                                          color: textColor, // 根据 StationClass 设置文字颜色
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭对话框，不返回任何值
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('關閉', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedStationData != null) {
                                Navigator.of(context).pop(selectedStationData); // 返回選中的車站資料
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('請選擇一個車站')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('確認', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result; // 返回選中的站點資料，或 null（用户未選擇）
  }
}
