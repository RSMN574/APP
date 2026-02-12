import 'dart:convert';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../Const/regularConst.dart';
import '../database/SQL/favorite_feature.dart';
import '../database/getData.dart';
import '../database/bus/getStationInfo.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../pages/bus_time.dart';
import '../utils/convert.dart';
import '../widget/bubble.dart';
import '../widget/error.dart';
ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
// 在檔案頂部(其他import之後)宣告enum
enum SortType {
  nameAsc,     // 站名正序 (A-Z)
  nameDesc,    // 站名倒序 (Z-A)
  timeAsc, // 站序正序 (1-10)
  timeDesc // 站序倒序 (10-1)
}
class BusStopInfo extends StatefulWidget {

  final String stop;
  final String city;
  const BusStopInfo(this.stop, {super.key, required this.city});
  @override
  State<BusStopInfo> createState() => _BusStopInfoState();
}

class _BusStopInfoState extends State<BusStopInfo>with SingleTickerProviderStateMixin {
  late final  TabController _tabController;
  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController();
  List<Map<String, dynamic>> processedUp = [];
  List<Map<String, dynamic>> processedDown = [];


  final _sortNotifier = ValueNotifier<SortType>(SortType.timeAsc);
  List<Map<String, dynamic>> data = [];
  late List<Map<String, dynamic>> _sortedData;   // 排序后数据
  // 构建 TabBar
  @override
  void initState() {
    super.initState();

    // _loadData(); // 初次加载数据
    _tabController = TabController(length:  _stationIDs.value.length, vsync: this); // 兩個 Tab
    // 每次頁面重新進入，重置 Tab
    _tabController.index = 0;
    _currentTabIndex.value = 0; // 添加監聽器，只更新 ValueNotifier
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _currentTabIndex.value = _tabController.index;
      }
    });

  }
  @override
  void dispose() {
    _streamController.close(); // 关闭 StreamController
    _tabController.dispose(); // 释放 TabController

    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');

  _tabController.index = 0;



  }

  Future<void> _loadData() async {
    // 原本取得資料的 code...

    final data = await fetchBusStopInfo();

    _streamController.add(data); // 向数据流中添加新数据





  }

  int _timeAscComparator(a, b) {
    if (a["time"] == "即將到站") return -1;
    if (b["time"] == "即將到站") return 1;
    if (a["time"] == "班次結束") return 1;
    if (b["time"] == "班次結束") return -1;
    return _parseTimeToMinutes(a['time']).compareTo(_parseTimeToMinutes(b['time']));
  }

  int _timeDescComparator(a, b) {
    if (a["time"] == "即將到站") return 1;
    if (b["time"] == "即將到站") return -1;
    if (a["time"] == "班次結束") return -1;
    if (b["time"] == "班次結束") return 1;
    return _parseTimeToMinutes(b['time']).compareTo(_parseTimeToMinutes(a['time']));
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sort_rounded,
                        size: 24,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "選擇排序方式",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 排序選項
                _buildSortOption('站序 1→10', SortType.nameAsc, Icons.numbers_rounded, const Color(0xFF1A73E8)),
                _buildSortOption('站序 10→1', SortType.nameDesc, Icons.numbers_rounded, const Color(0xFF1A73E8)),
                _buildSortOption('時間 早→晚', SortType.timeAsc, Icons.access_time_rounded, const Color(0xFF34C759)),
                _buildSortOption('時間 晚→早', SortType.timeDesc, Icons.access_time_rounded, const Color(0xFFFF9500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, SortType type, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _sortNotifier.value = type;
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _sortNotifier.value == type ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: _sortNotifier.value == type
                  ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                  : Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                // 圖標
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _sortNotifier.value == type ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: _sortNotifier.value == type ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),

                // 標題
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _sortNotifier.value == type ? color : Colors.black87,
                    ),
                  ),
                ),

                // 選取指示器
                if (_sortNotifier.value == type)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 获取到站时间列表的异步方法
  Future<Map<String, dynamic>> getTimeList(stopData) async {
    if (stopData["EstimateTime"] != null) {
      if (stopData["EstimateTime"] == 0) {
        List PlateNumb = [];
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }
        return {"color": '0',"time": "即將到站", "isRed": '0', "PlateNumb": PlateNumb.toString()};
      } else {
        int result = (stopData["EstimateTime"] / 60).floor();
        List PlateNumb = [];
        if (stopData['Estimates'] != null) {
          for (var estimate in stopData['Estimates']) {
            PlateNumb.add(estimate["PlateNumb"]);
          }
        }

        return {
          "color": result < 3 ? "2" : "min",
          "time": result < 1 ? "即將到站" : "$result 分鐘",
          "isRed": result < 3 ? "2" : "",
          "PlateNumb": result < 20 ? PlateNumb.toString() : ""
        };
      }
    } else if (stopData["NextBusTime"] != null) {
      Duration difference = DateTime.parse(stopData["NextBusTime"]).difference(DateTime.now());
      if (difference.inHours == 0) {
        return {
          "time": difference.inMinutes.remainder(60) <= 0 ? "班次結束" : "${difference.inMinutes.remainder(60)} 分鐘",
          "isRed": '',
          "PlateNumb": "",
          "color":  difference.inMinutes.remainder(60) <= 0 ? "班次結束" :"min",
        };
      } else {
        DateTime NextBusTime = DateTime.now().add(Duration(hours: difference.inHours, minutes: difference.inMinutes.remainder(60)));
        return {
          'time': "${NextBusTime.hour.toString().padLeft(2, '0')}:${NextBusTime.minute.toString().padLeft(2, '0')}",
          "isRed": '',
          "PlateNumb": "",
          "color": "班次結束"
        };
      }
    } else {
      return {"time": "班次結束", "isRed": '', "PlateNumb": "","color": "班次結束"};
    }
  }

  Future<Widget> _buildTabContent(String direction,List<Map<String, dynamic>> stopEstimatedTime) async {
     List<Map<String, dynamic>> finalList=await _processData(direction,stopEstimatedTime);




    return ValueListenableBuilder<SortType>(
      valueListenable: _sortNotifier,
      builder: (context, sortType, _) {
        final sortedList = [...finalList];

        switch(sortType) {
          case SortType.nameAsc:
            sortedList.sort((a, b) => getChineseName(a['RouteName']["Zh_tw"]).compareTo(getChineseName(b['RouteName']["Zh_tw"])));
            break;
          case SortType.nameDesc:
            sortedList.sort((a, b) => getChineseName(b['RouteName']["Zh_tw"]).compareTo(getChineseName(a['RouteName']["Zh_tw"])));
            break;
          case SortType.timeAsc:
            sortedList.sort(_timeAscComparator);
            break;
          case SortType.timeDesc:
            sortedList.sort(_timeDescComparator);
            break;
        }

        return _buildTabContentUI(direction, sortedList); // 改這裡：傳給 UI builder 而不是 Future
      },
    );


  }
  Widget _buildTabContentUI(String direction, List<Map<String, dynamic>> finalList) {
    return RefreshIndicator(
      onRefresh: () async => await _loadData(),
      child:   ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: ValueKey(_sortNotifier.value), // 每次排序不同 key
        items: finalList,
        areItemsTheSame: (a, b) => a["RouteID"] == b["RouteID"],
        itemBuilder: (context, animation, stop, index) {
          final PlateNumb = stop["PlateNumb"];

          final color = stop["color"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["color"] == '2'
              ? const Color.fromRGBO(225, 85, 104, 0.1)
              : (stop["color"] == "班次結束"
              ? const Color.fromRGBO(69, 69, 69, 0.1)
              : (stop["color"] == "min"
              ? const Color.fromRGBO(13, 168, 255, 0.1)
              : const Color.fromRGBO(68, 68, 68, 0.1))));

          return SizeFadeTransition(
            animation: animation,
            curve: Curves.easeInOut,
            sizeFraction: 0.9,
            child: Column(
              children: [
                Container(
                  height: 53.0,
                  child: ListTile(
                    onTap: () async {
                      await GetBusInfo(
                          routeId: int.parse(stop["RouteID"]),
                          city: widget.city);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusTime(
                            routeName: stop["RouteName"]["Zh_tw"],
                            departureStopName: stop["DepartureStopName"],
                            destinationStopName: stop["DestinationStopName"],
                            operators: "",
                            routeMapImageUrl: "",
                            city: widget.city,
                            routeID: int.parse(stop["RouteID"]),
                            mark: Mark.fromMap({
                              "highlight": [widget.stop],
                              "direction": stop['Direction'] == 0 ? 1 : 0,
                            }),
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        stop["time"] ?? "未知",
                        style: TextStyle(

                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? Colors.white
                              : (stop["color"] == '2'
                              ? const Color.fromRGBO(255, 85, 104, 1)
                              : (stop["color"] == "班次結束"
                              ? const Color.fromRGBO(149, 149, 149, 1.0)
                              : (stop["color"] == "min"
                              ? const Color.fromRGBO(13, 168, 255, 1)
                              : const Color.fromRGBO(
                              68, 68, 68, 1)))),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          stop["RouteName"]["Zh_tw"] ?? "未知站名",
                          style: TextStyle(
                            fontFamily: stop["color"] == "0"
                                ? 'MiSans-Semibold'
                                : 'MiSans-normal',
                            fontSize: 17,
                            color: stop["color"] == "班次結束"
                                ? const Color.fromRGBO(136, 136, 136, 1)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "往 ${stop["to"] ?? "未知方向"}",
                          style: const TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: Color.fromRGBO(136, 136, 136, 1),
                          ),
                        ),
                      ],
                    ),
                    trailing: PlateNumb != null
                        ? bubble(plateNum: PlateNumb)
                        : null,
                  ),
                ),
                const Divider(
                  color: Color.fromRGBO(231, 231, 231, 1),
                  height: 9,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
              ],
            ),
          );
        },
      ),

    );
  }

  Future<List<Map<String, dynamic>>> _processData(String stationID, List<Map<String, dynamic>> stopEstimatedTime,) async {
    try {
      // print('=== 開始處理資料，stationID: $stationID ===');
      // print('原始數據數量: ${stopEstimatedTime.length}');

      /// -----------------------------
      /// 1. 過濾並去重
      /// -----------------------------
      final routeMap = <String, Map<String, dynamic>>{};

      for (final item in stopEstimatedTime) {
        // 只處理符合 StationID 的項目
        if (item["StationID"] != stationID) {
          continue;
        }

        // print('處理項目: ${item["RouteName"]}, StationID: ${item["StationID"]}');

        final routeNameObj = item["RouteName"];
        String? routeName;

        // 處理 RouteName 可能是 Map 或 String 的情況
        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
          // print('RouteName 是 Map: $routeNameObj, 提取: $routeName');
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        //  print('RouteName 是 String: $routeName');
        }

        final direction = item["Direction"];

        if (routeName == null || routeName.isEmpty) {
        //  print('跳過：routeName 為空');
          continue;
        }

        final routeKey = "${routeName}_$direction";
        final currentTime = _parseTimeToMinutes(item["time"]);

       // print('routeKey: $routeKey, currentTime: $currentTime');

        // 只保留每條路線最近的一班車
        final existing = routeMap[routeKey];
        if (existing == null ||
            (currentTime != -1 && currentTime < _parseTimeToMinutes(existing["time"]))) {
          routeMap[routeKey] = item;
      //    print('加入/更新: $routeKey');
        }
      }

      final stationData = routeMap.values.toList();
     // print('過濾後數據數量: ${stationData.length}');

      if (stationData.isEmpty) {
     //   print('無數據，返回空列表');
        return [];
      }

      /// -----------------------------
      /// 2. 批次獲取路線資訊 - 修正查詢方式
      /// -----------------------------
      final routeNames = <String>{};

      for (final item in stationData) {
        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        if (routeName != null && routeName.isNotEmpty) {
          routeNames.add(routeName);
        }
      }

     // print('需要查詢的路線名稱: $routeNames');

      final Map<String, Map<String, dynamic>> routeInfoCache = {};

      if (routeNames.isNotEmpty) {
        try {
          // 方法1：使用 JSON_UNQUOTE 和 JSON_EXTRACT（最標準）
          final nameList = routeNames.map((name) => "'$name'").join(',');

        //  print('執行 SQL 查詢，條件: $nameList');

          final query = """
        SELECT *
FROM Bus.bus_route
WHERE City = '${widget.city}'
  AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw'))
      IN ($nameList)
""";

        //  print('SQL 查詢: $query');

          final results = await mysqlSelect(query);
         // print('查詢結果數量: ${results.length}');

          // 建立路線名稱到數據的映射
          for (final result in results) {
          //  print('處理查詢結果: ${result}');

            final routeNameField = result["RouteName"];
            String? routeName;

            // 解析 RouteName 欄位
            if (routeNameField is Map) {
              routeName = routeNameField["Zh_tw"] as String?;
           //   print('RouteName 是 Map: $routeNameField, 提取: $routeName');
            } else if (routeNameField is String) {
              try {
                // 嘗試解析 JSON 字串
                final parsed = json.decode(routeNameField) as Map<String, dynamic>;
                routeName = parsed["Zh_tw"] as String?;
               // print('RouteName 是 JSON String: $routeNameField, 解析後: $parsed, 提取: $routeName');
              } catch (e) {
                routeName = routeNameField;
              //  print('解析 JSON 失敗，使用原始字串: $routeNameField');
              }
            }

            if (routeName != null && routeName.isNotEmpty) {
              routeInfoCache[routeName] = result;
             // print('快取路線: $routeName -> ${result["RouteID"]}');

              // 打印詳細資訊以便調試
            //  print('出發站名: ${result["DepartureStopNameZh"]}');
            //  print('目的站名: ${result["DestinationStopNameZh"]}');
            }
          }

          //print('快取大小: ${routeInfoCache.length}');
         // print('快取內容: ${routeInfoCache.keys.toList()}');

        } catch (e) {
          print('批次查詢失敗: $e');

          // 降級方案：逐個查詢
          print('開始逐個查詢...');
          for (final routeName in routeNames) {
            try {
              print('查詢路線: $routeName');

              // 方法2：使用 LIKE 查詢 JSON
              final query = """
              SELECT * FROM Bus.Bus_${widget.city}_Route 
              WHERE RouteName LIKE '%"Zh_tw": "$routeName"%'
              OR JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName'
            """;

              final results = await mysqlSelect(query);

              if (results.isNotEmpty) {
                routeInfoCache[routeName] = results.first;
                print('找到路線 $routeName: ${results.first["RouteID"]}');
              } else {
                print('未找到路線 $routeName');
              }
            } catch (e2) {
              print('查詢單一路線失敗 $routeName: $e2');
            }
          }
        }
      }

      /// -----------------------------
      /// 3. 合併路線資訊
      /// -----------------------------
      final List<Map<String, dynamic>> processedData = [];

      print('開始合併路線資訊...');

      for (final item in stationData) {
        print('處理項目: ${item["RouteName"]}');

        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        final direction = item["Direction"];

        if (routeName == null) {
          print('跳過：routeName 為空');
          continue;
        }

        final resultItem = Map<String, dynamic>.from(item);
        final routeInfo = routeInfoCache[routeName];
        final hasValidInfo = routeInfo != null && routeInfo.isNotEmpty;

        print('路線 $routeName 找到資訊: $hasValidInfo');

        // 設置路線 ID
        if (hasValidInfo) {
          resultItem["RouteID"] = routeInfo!["RouteID"]?.toString() ?? "未知";
          print('設置 RouteID: ${resultItem["RouteID"]}');
        } else {
          resultItem["RouteID"] = "未知";
          print('未找到路線資訊，設置為未知');
        }

        // 設置站名資訊
        String? departureName;
        String? destinationName;

        if (hasValidInfo) {
          departureName = routeInfo!["DepartureStopNameZh"]?.toString();
          destinationName = routeInfo!["DestinationStopNameZh"]?.toString();

          print('出發站名從 DB: $departureName');
          print('目的站名從 DB: $destinationName');

          // 如果沒有從資料庫獲取到，嘗試其他欄位名稱
          if (departureName == null) {
            departureName = routeInfo["DepartureStopName"]?.toString();
            print('從 DepartureStopName 獲取: $departureName');
          }

          if (destinationName == null) {
            destinationName = routeInfo["DestinationStopName"]?.toString();
            print('從 DestinationStopName 獲取: $destinationName');
          }
        }

        resultItem["DepartureStopName"] = departureName ?? "未知出發站";
        resultItem["DestinationStopName"] = destinationName ?? "未知目的站";

        print('設置 DepartureStopName: ${resultItem["DepartureStopName"]}');
        print('設置 DestinationStopName: ${resultItem["DestinationStopName"]}');

        // 根據方向設置 "from" 和 "to"
        final isDirection1 = direction == 1;
        resultItem["from"] = isDirection1
            ? destinationName ?? "未知目的地"
            : departureName ?? "未知出發地";
        resultItem["to"] = isDirection1
            ? departureName ?? "未知出發地"
            : destinationName ?? "未知目的地";

        print('設置 from: ${resultItem["from"]}');
        print('設置 to: ${resultItem["to"]}');

        processedData.add(resultItem);
        print('--- 完成處理 ---');
      }

      print('=== 處理完成，返回 ${processedData.length} 筆資料 ===');
      return processedData;
    } catch (e) {
      print('處理資料失敗: $e');
      print(e);
      return [];
    }
  }

  /// 添加調試用的輔助方法
  void _debugPrintRouteInfo(Map<String, dynamic> routeInfo) {
    print('=== 路線資訊調試 ===');
    for (final entry in routeInfo.entries) {
      print('${entry.key}: ${entry.value} (類型: ${entry.value.runtimeType})');
    }
    print('===================');
  }

  /// 添加一個測試函數來驗證資料庫查詢
  Future<void> _testDatabaseQuery() async {
    try {
      // 測試一個已知的路線名稱
      const testRouteName = '11'; // 替換為實際的路線名稱

      print('測試資料庫查詢...');

      // 測試不同查詢方式
      final queries = [
        "SELECT * FROM Bus.Bus_${widget.city}_Route WHERE RouteName LIKE '%\"$testRouteName\"%'",
        "SELECT * FROM Bus.Bus_${widget.city}_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$testRouteName'",
        "SELECT * FROM Bus.Bus_${widget.city}_Route WHERE RouteName->>'\$.Zh_tw' = '$testRouteName'",
      ];

      for (var i = 0; i < queries.length; i++) {
        print('\n嘗試查詢方式 ${i + 1}:');
        print('SQL: ${queries[i]}');
        try {
          final results = await mysqlSelect(queries[i]);
          print('結果數量: ${results.length}');
          if (results.isNotEmpty) {
            print('第一筆結果:');
            _debugPrintRouteInfo(results.first);
            break;
          }
        } catch (e) {
          print('查詢失敗: $e');
        }
      }
    } catch (e) {
      print('測試失敗: $e');
    }
  }
  // 解析时间格式，转换成相对于当前时间的分钟数
  int _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return -1;

    // 处理 "X 分鐘" 格式
    if (time.contains("分鐘")) {
      return int.tryParse(time.split(" ").first) ?? -1;
    }

    // 处理 "XX:XX" 格式
    if (time.contains(":")) {
      final parts = time.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;

        // 获取当前时间
        DateTime now = DateTime.now();
        DateTime parsedTime = DateTime(now.year, now.month, now.day, hour, minute);

        // 如果时间已经过去了，则认为是第二天的时间
        if (parsedTime.isBefore(now)) {
          parsedTime = parsedTime.add(const Duration(days: 1));
        }

        return parsedTime.difference(now).inMinutes;
      }
    }

    return -1;
  }

  // 获取公交站信息的异步方法
  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {

    List<dynamic> info = await GetBusStopInfo(widget.stop, widget.city);
    List<Map<String, dynamic>> tempData = [];

    _stationIDs.value= info.map((station) => station["StationID"] as String).toList();// 提取 StationID

    for (var i in info) {
      List<Map<String, dynamic>> stationInfo = await fetchStationInfo(_stationIDs.value, widget.city);
      for (var stop in stationInfo) {
        Map<String, dynamic> timeData = await getTimeList(stop);
        stop["time"] = timeData["time"];
        stop["isRed"] = timeData["isRed"];
        stop["color"] = timeData["color"];
      }
      tempData.addAll(stationInfo);
    }


    return tempData;
  }
// 返回每个隐藏的菜单项
  SelectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: busBlue),
            Text(text),
          ],
        )
    );
  }
  PopupMenuItem<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  void _showStopInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_rounded,
                color: Color(0xFF1A73E8),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '站牌資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '站牌名稱：${widget.stop}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '所在城市：${widget.city}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '關閉',
              style: TextStyle(
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    _loadData();

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.stretchedDots(
                color: Colors.black,
                size: 40,
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return ErrorPage();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('snapshot.has not Data');
            return ErrorPage();
          } else {
            return DefaultTabController(
              length: _stationIDs.value.length,
              child: Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(150),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          title: Text(
                            widget.stop,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A73E8),
                              letterSpacing: -0.5,
                            ),
                          ),
                          centerTitle: true,
                          iconTheme: const IconThemeData(color: Color(0xFF1A73E8)),
                          actions: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF3FB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.refresh_rounded, size: 20),
                                ),
                                onPressed: _loadData,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: PopupMenuButton<String>(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF3FB),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.more_vert_rounded, size: 20),
                                ),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  _buildPopupMenuItem(
                                    icon: Icons.info_outline_rounded,
                                    title: '站牌資訊',
                                    value: 'info',
                                    color: const Color(0xFF1A73E8),
                                  ),
                                  _buildPopupMenuItem(
                                    icon: Icons.favorite_border_rounded,
                                    title: '加入收藏',
                                    value: 'favorite',
                                    color: const Color(0xFFFF3B30),
                                  ),
                                  _buildPopupMenuItem(
                                    icon: Icons.sort_rounded,
                                    title: '排序方式',
                                    value: 'sort',
                                    color: const Color(0xFF34C759),
                                  ),
                                ],
                                onSelected: (String action) async {
                                  if (action == 'favorite') {
                                    favorite_feature dbHelper = favorite_feature();
                                    final output = await dbHelper.addFavorite(
                                      StopName: widget.stop,
                                      table: "FavoritesStop",
                                      city: widget.city,
                                    );

                                    if (output == 100) {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.success,
                                        text: '${widget.stop}已儲存項目',
                                      );
                                    } else if (output == -1) {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.warning,
                                        text: '${widget.stop}已存在於列表中，不會重複添加',
                                      );
                                    } else if (output == 200) {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.error,
                                        title: 'Oops...',
                                        text: '儲存項目時發生錯誤',
                                      );
                                    }
                                  } else if (action == 'sort') {
                                    _showSortDialog(context);
                                  } else if (action == 'info') {
                                    _showStopInfo(context);
                                  }
                                },
                              ),
                            ),
                          ],
                          bottom: _buildTabBar(snapshot.data!),
                        ),
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                body: TabBarView(
                  children: List.generate(_stationIDs.value.length, (index) {
                    String label = String.fromCharCode(65 + index);
                    return FutureBuilder(
                      future: _buildTabContent(_stationIDs.value[index], snapshot.data!),
                      builder: (context, contentSnapshot) {
                        if (contentSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: LoadingAnimationWidget.stretchedDots(
                              color: Colors.black,
                              size: 40,
                            ),
                          );
                        }

                        if (contentSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${contentSnapshot.error}'),
                          );
                        }

                        if (contentSnapshot.data == null) {
                          return Center(
                            child: Text("No content available"),
                          );
                        }
                        return contentSnapshot.data is Widget
                            ? contentSnapshot.data as Widget
                            : Center(child: Text("Invalid content"));
                      },
                    );
                  }),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  PreferredSize _buildTabBar(List<Map<String, dynamic>> station) {
    final tabCount = _stationIDs.value.length;
    final isScrollable = tabCount > 3; // 超過3個tab時可滾動

    return PreferredSize(
      preferredSize: const Size.fromHeight(90), // 增加高度以容納更多內容
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 可以添加一些頂部間距
            const SizedBox(height: 8),
            // TabBar 容器
            SizedBox(
              height: 80, // 固定TabBar高度
              child: TabBar(
                isScrollable: isScrollable, // 動態決定是否可滾動
                controller: null, // 讓 DefaultTabController 自動管理
                padding: const EdgeInsets.symmetric(horizontal: 12),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                onTap: (index) {
                  // 選項點擊由 TabBar 自動處理
                },
                tabs: List.generate(tabCount, (index) {
                  String label = String.fromCharCode(65 + index);
                  return Tab(
                    height: 62, // 固定每個tab的高度
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 80, // 最小寬度
                        maxWidth: 120, // 最大寬度，避免太寬
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 圖標容器
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_bus,
                              size: 18,
                              color: const Color(0xFF1A73E8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // 站牌字母標籤
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // 站牌編號（限制寬度並省略超出部分）
                          SizedBox(
                            width: 70, // 固定寬度
                            child: Text(
                              _stationIDs.value[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF1A73E8),
                    width: 1.5,
                  ),
                ),
                labelColor: const Color(0xFF1A73E8),
                unselectedLabelColor: Colors.grey[600],
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
