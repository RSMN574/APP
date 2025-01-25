import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../database/getData.dart';

class StationDialog {
  // 高鐵主題色
  static const Color primaryColor = Color(0xFFDC5321);     // 高鐵橘
  static const Color surfaceColor = Color(0xFFF8F9FA);     // 背景色
  static const Color textPrimary = Color(0xFF2D3748);      // 主要文字
  static const Color textSecondary = Color(0xFF718096);    // 次要文字

  static Future<Map<String, dynamic>?> showStationDialog(context) async {
    // 獲取高鐵車站數據
    List stationData = await mysqlSelect("SELECT StationID, StationName, StationPosition FROM HSR.HSR_Station;");

    // 轉換數據格式
    List<Map<String, dynamic>> stationDataMap = stationData.map((item) {
      final stationName = json.decode(item["StationName"]);
      return {
        'StationName': {
          'Zh_tw': stationName['Zh_tw'],
          'En': stationName['En'],
        },
        'StationID': item['StationID'],
        'StationPosition': item['StationPosition'],
      };
    }).toList();

    String? _selectedStation;
    Map<String, dynamic>? selectedStationData;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.9, // 動態調整寬度
                      maxHeight: constraints.maxHeight * 0.8, // 動態調整高度
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 頂部標題欄
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Text('選擇高鐵車站',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 車站列表
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: stationDataMap.length,
                              itemBuilder: (context, index) {
                                final station = stationDataMap[index];
                                final stationName = station['StationName']['Zh_tw'];

                                return Material(
                                  color: _selectedStation == stationName
                                      ? primaryColor.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      _selectedStation = stationName;
                                      selectedStationData = station;
                                    }),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: _selectedStation == stationName
                                                ? primaryColor
                                                : Colors.transparent,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        stationName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // 按鈕區
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: BorderSide(color: textSecondary.withOpacity(0.3)),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('取消',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (selectedStationData != null) {
                                      Navigator.pop(context, selectedStationData);
                                    }
                                  },
                                  child: const Text('確認選擇',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}