import 'dart:convert';
import 'package:flutter/material.dart';
import '../../database/getData.dart';

class StationDialog {
  // 現代化配色方案 (僅新增顏色常數)
  static const Color _backgroundWhite = Color(0xFFFDFDFD);
  static const Color _surfaceColor = Color(0xFFF3F5F7);
  static const Color _primaryColor = Color(0xFF2A5CAA);
  static const Color _accentColor = Color(0xFFFF9F1C);
  static const Color _textPrimary = Color(0xFF2D3748);
  static const Color _textSecondary = Color(0xFF718096);

  static Future<Map<String, dynamic>?> showStationDialog(context) async {
    // 原有數據獲取與處理邏輯保持不變...
    List stationData = await mysqlSelect("SELECT StationID,StationClass,StationName,StationPosition,LocationCity FROM Train.Train_Station;");

    // 原有數據轉換邏輯保持不變...
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

    // 構建 stationsList
    final Map<String, List<String>> stationsList = {};
    for (var entry in stationDataMap) {
      String city = entry['LocationCity'];
      String stationName = entry['StationName']['Zh_tw'];
      stationsList.putIfAbsent(city, () => []).add(stationName);
    }

    String _selectedCity = '臺中市';
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
                      color: _backgroundWhite,
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
                            color: _primaryColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.train, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text('選擇車站',
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

                        // 主內容區
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView( // 添加滾動支持
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 城市列表
                                  Container(
                                    width: constraints.maxWidth * 0.3, // 動態調整寬度
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: _surfaceColor,
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(), // 禁用滾動
                                      itemCount: stationsList.keys.length,
                                      itemBuilder: (context, index) {
                                        final city = stationsList.keys.elementAt(index);
                                        return Material(
                                          color: _selectedCity == city
                                              ? _primaryColor.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          child: InkWell(
                                            onTap: () => setState(() {
                                              _selectedCity = city;
                                              _selectedStation = null;
                                            }),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(
                                                    color: _selectedCity == city
                                                        ? _primaryColor
                                                        : Colors.transparent,
                                                    width: 4,
                                                  ),
                                                ),
                                              ),
                                              child: Text(city,
                                                style: TextStyle(
                                                  color: _selectedCity == city
                                                      ? _primaryColor
                                                      : _textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // 車站列表
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: _surfaceColor,
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(), // 禁用滾動
                                        itemCount: stationsList[_selectedCity]?.length ?? 0,
                                        itemBuilder: (context, index) {
                                          final station = stationsList[_selectedCity]![index];
                                          final stationEntry = stationDataMap.firstWhere(
                                                (entry) => entry['StationName']['Zh_tw'] == station,
                                          );

                                          return Material(
                                            color: _selectedStation == station
                                                ? _accentColor.withOpacity(0.1)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () => setState(() {
                                                _selectedStation = station;
                                                selectedStationData = stationEntry;
                                              }),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: _getStationColor(stationEntry['StationClass']),
                                                      width: 4,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _getStationIcon(stationEntry['StationClass']),
                                                      color: _getStationColor(stationEntry['StationClass']),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(station,
                                                      style: TextStyle(
                                                        color: _textPrimary,
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                    side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('取消',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primaryColor,
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

  // 以下為新增的樣式輔助方法 (不影響原有邏輯)
  static Color _getStationColor(String stationClass) {
    switch (stationClass) {
      case "0":
        return _accentColor;
      case "1":
        return _primaryColor;
      default:
        return _textSecondary;
    }
  }

  static IconData _getStationIcon(String stationClass) {
    switch (stationClass) {
      case "0":
        return Icons.directions_railway_filled;
      case "1":
        return Icons.train_sharp;
      default:
        return Icons.location_city;
    }
  }
}