import 'dart:convert';
import 'dart:ui';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/database/sql/favorite_feature.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/features/bus/data/get_station_info.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_time_page.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/features/bus/widgets/bubble.dart';
import 'package:com.rsmn574.app/widget/error.dart';

import '../../../widget/AppLoading.dart';
import '../model/bus_station_model2.dart';

ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
ValueNotifier<int> remainingSecondsNotifier = ValueNotifier(40);
Timer? _timer;
// 在檔案頂部(其他import之後)宣告enum
enum SortType {
  nameAsc, // 站名正序 (A-Z)
  nameDesc, // 站名倒序 (Z-A)
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

class _BusStopInfoState extends State<BusStopInfo>
    with SingleTickerProviderStateMixin {
  ValueNotifier<bool> isTimerOn = ValueNotifier(false);
  late final TabController _tabController;
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController();
  List<Map<String, dynamic>> processedUp = [];
  List<Map<String, dynamic>> processedDown = [];
  void _startAutoReload() {
    // 如果已有定时器正在运行，先取消它
    _timer?.cancel();
    remainingSecondsNotifier.value = 40; // 初始40秒
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSecondsNotifier.value > 1) {
        remainingSecondsNotifier.value = remainingSecondsNotifier.value - 1;
      } else {
        remainingSecondsNotifier.value = 40; // 重置倒计时
        _loadData(); // 加载数据
      }
    });
  }
  final _sortNotifier = ValueNotifier<SortType>(SortType.timeAsc);
  List<Map<String, dynamic>> data = [];
  // 构建 TabBar
  @override
  void initState() {
    super.initState();

    // _loadData(); // 初次加载数据
    _tabController =
        TabController(length: _stationIDs.value.length, vsync: this); // 兩個 Tab
    // 每次頁面重新進入，重置 Tab
    _tabController.index = 0;
    _currentTabIndex.value = 0; // 添加監聽器，只更新 ValueNotifier
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (!_tabController.indexIsChanging) {
      _currentTabIndex.value = _tabController.index;
    }
  }

  @override
  void dispose() {
    _streamController.close(); // 关闭 StreamController
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose(); // 释放 TabController
    isTimerOn.dispose();
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
    if (isTimerOn.value) _startAutoReload();
    final data = await fetchBusStopInfo();

    _streamController.add(data); // 向数据流中添加新数据
  }

  int _timeAscComparator(a, b) {
    if (a["time"] == AppLocalizations.of(context)!.text_316) return -1;
    if (b["time"] == AppLocalizations.of(context)!.text_316) return 1;
    if (a["time"] == AppLocalizations.of(context)!.text_317) return 1;
    if (b["time"] == AppLocalizations.of(context)!.text_317) return -1;
    return _parseTimeToMinutes(a['time'])
        .compareTo(_parseTimeToMinutes(b['time']));
  }

  int _timeDescComparator(a, b) {
    if (a["time"] == AppLocalizations.of(context)!.text_316) return 1;
    if (b["time"] == AppLocalizations.of(context)!.text_316) return -1;
    if (a["time"] == AppLocalizations.of(context)!.text_317) return -1;
    if (b["time"] == AppLocalizations.of(context)!.text_317) return 1;
    return _parseTimeToMinutes(b['time'])
        .compareTo(_parseTimeToMinutes(a['time']));
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
                    Flexible(child: Text(
                      AppLocalizations.of(context)!.text_318,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A73E8),
                      ), maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ),
                const SizedBox(height: 20),

                // 排序選項
                _buildSortOption('站序 1→10', SortType.nameAsc,
                    Icons.numbers_rounded, const Color(0xFF1A73E8)),
                _buildSortOption('站序 10→1', SortType.nameDesc,
                    Icons.numbers_rounded, const Color(0xFF1A73E8)),
                _buildSortOption(
                    AppLocalizations.of(context)!.text_319,
                    SortType.timeAsc,
                    Icons.access_time_rounded,
                    const Color(0xFF34C759)),
                _buildSortOption(
                    AppLocalizations.of(context)!.text_320,
                    SortType.timeDesc,
                    Icons.access_time_rounded,
                    const Color(0xFFFF9500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
      String title, SortType type, IconData icon, Color color) {
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
              color: _sortNotifier.value == type
                  ? color.withOpacity(0.1)
                  : Colors.transparent,
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
                    color: _sortNotifier.value == type
                        ? color
                        : color.withOpacity(0.1),
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
                      color:
                          _sortNotifier.value == type ? color : Colors.black87,
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
    // ---------- 1. EstimateTime（預估到站時間） ----------
    if (stopData["EstimateTime"] != null) {
      isTimerOn.value = true;
      int estimateTime = stopData["EstimateTime"];

      // 進站中
      if (estimateTime == 0) {
        List PlateNumb = [];
        if (stopData['Estimates'] != null) {
          for (var estimate in stopData['Estimates']) {
            PlateNumb.add(estimate["PlateNumb"]);
          }
        }
        return {
          "color": '0',
          "time": AppLocalizations.of(context)!.text_316,
          "isRed": '0',
          "PlateNumb": PlateNumb.toString()
        };
      }

      // 一般倒數
      int result = (estimateTime / 60).floor();
      List PlateNumb = [];
      if (stopData['Estimates'] != null) {
        for (var estimate in stopData['Estimates']) {
          PlateNumb.add(estimate["PlateNumb"]);
        }
      }

      return {
        "color": result < 3 ? "2" : "min",
        "time": result < 1
            ? AppLocalizations.of(context)!.text_316
            : AppLocalizations.of(context)!
            .nearStopMinutes(result.toString()),
        "isRed": result < 3 ? "2" : "",
        "PlateNumb": result < 20 ? PlateNumb.toString() : ""
      };
    }

    // ---------- 2. NextBusTime（下一班車時間） ----------
    if (stopData["NextBusTime"] != null) {
      // 轉為在地時間，避免時區誤差
      DateTime nextBusTime =
      DateTime.parse(stopData["NextBusTime"]).toLocal();
      Duration difference = nextBusTime.difference(DateTime.now());
      int totalMinutes = difference.inMinutes;

      // 已過站
      if (totalMinutes < 0) {
        isTimerOn.value = false;
        return {
          "time": totalMinutes > -5
              ? AppLocalizations.of(context)!.text_340   // 已過站
              : AppLocalizations.of(context)!.text_317,  // 班次結束
          "isRed": '',
          "PlateNumb": "",
          "color": AppLocalizations.of(context)!.text_317,
        };
      }

      // 一小時內會到 → 倒數
      if (totalMinutes < 60) {
        isTimerOn.value = true;

        // 進站中
        if (totalMinutes < 1) {
          return {
            "time": AppLocalizations.of(context)!.text_316,
            "isRed": '0',
            "PlateNumb": stopData["PlateNumb"] ?? "",
            "color": '0',
          };
        }

        // 1-2 分鐘：即將進站
        if (totalMinutes < 3) {
          return {
            "time": "$totalMinutes 分鐘",
            "isRed": '2',
            "PlateNumb": stopData["PlateNumb"] ?? "",
            "color": "2",
          };
        }

        // 3-59 分鐘：一般倒數
        return {
          "time": AppLocalizations.of(context)!
              .nearStopMinutes(totalMinutes.toString()),
          "isRed": '',
          "PlateNumb": "",
          "color": "min",
        };
      }

      // 超過 60 分鐘 → 直接顯示發車時刻 HH:mm
      isTimerOn.value = false;
      String formattedTime =
          "${nextBusTime.hour.toString().padLeft(2, '0')}:${nextBusTime.minute.toString().padLeft(2, '0')}";
      return {
        "time": formattedTime,
        "isRed": '',
        "PlateNumb": "",
        "color": AppLocalizations.of(context)!.text_317,
      };
    }

    // ---------- 3. 無時間資料 ----------
    isTimerOn.value = false;
    return {
      "time": AppLocalizations.of(context)!.text_317,
      "isRed": '',
      "PlateNumb": "",
      "color": AppLocalizations.of(context)!.text_317,
    };
  }
  /// 判断当前是否为英文语言环境
  bool _isEnglishLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }/// 根据语言环境获取路线名称（支持 Map 或 String 类型）
  String _localizedBusText(dynamic routeName, {required bool isEnglish}) {
    if (routeName == null) return '';

    if (routeName is Map) {
      if (isEnglish) {
        return routeName['En']?.toString() ??
            routeName['Zh_tw']?.toString() ??
            '';
      } else {
        return routeName['Zh_tw']?.toString() ??
            routeName['En']?.toString() ??
            '';
      }
    }

    if (routeName is String) {
      // 尝试解析 JSON 字符串
      try {
        final parsed = json.decode(routeName);
        if (parsed is Map) {
          return _localizedBusText(parsed, isEnglish: isEnglish);
        }
      } catch (_) {
        // 不是 JSON，直接返回
      }
      return routeName;
    }

    return routeName.toString();
  }

  /// 获取本地化的出发站名称
  String _localizedDepartureName(dynamic route, {required bool isEnglish}) {
    if (route == null) return '';

    if (isEnglish) {
      return route.departureStopNameEn?.toString() ??
          route.departureStopNameZh?.toString() ??
          route.departureStopName?.toString() ??
          '';
    } else {
      return route.departureStopNameZh?.toString() ??
          route.departureStopNameEn?.toString() ??
          route.departureStopName?.toString() ??
          '';
    }
  }

  /// 获取本地化的终点站名称
  String _localizedDestinationName(dynamic route, {required bool isEnglish}) {
    if (route == null) return '';

    if (isEnglish) {
      return route.destinationStopNameEn?.toString() ??
          route.destinationStopNameZh?.toString() ??
          route.destinationStopName?.toString() ??
          '';
    } else {
      return route.destinationStopNameZh?.toString() ??
          route.destinationStopNameEn?.toString() ??
          route.destinationStopName?.toString() ??
          '';
    }
  }
  /// 获取 TDX 格式的路线名称
  String _tdxRouteName(dynamic route, dynamic fallbackName) {
    if (route == null) return fallbackName?.toString() ?? '';

    try {
      final routeName = route.routeName;
      if (routeName is Map) {
        return routeName['Zh_tw']?.toString() ??
            routeName['En']?.toString() ??
            fallbackName?.toString() ??
            '';
      }
      return routeName?.toString() ?? fallbackName?.toString() ?? '';
    } catch (_) {
      return fallbackName?.toString() ?? '';
    }
  }

  Future<Widget> _buildTabContent(
      String direction, List<Map<String, dynamic>> stopEstimatedTime) async {
    List<Map<String, dynamic>> finalList =
        await _processData(direction, stopEstimatedTime);

    return ValueListenableBuilder<SortType>(
      valueListenable: _sortNotifier,
      builder: (context, sortType, _) {
        final sortedList = [...finalList];

        final isEnglish = _isEnglishLocale(context);
        switch (sortType) {
          case SortType.nameAsc:
            sortedList.sort((a, b) => getChineseName(
                    _localizedBusText(a['RouteName'], isEnglish: isEnglish))
                .compareTo(getChineseName(
                    _localizedBusText(b['RouteName'], isEnglish: isEnglish))));
            break;
          case SortType.nameDesc:
            sortedList.sort((a, b) => getChineseName(
                    _localizedBusText(b['RouteName'], isEnglish: isEnglish))
                .compareTo(getChineseName(
                    _localizedBusText(a['RouteName'], isEnglish: isEnglish))));
            break;
          case SortType.timeAsc:
            sortedList.sort(_timeAscComparator);
            break;
          case SortType.timeDesc:
            sortedList.sort(_timeDescComparator);
            break;
        }

        return _buildTabContentUI(
            direction, sortedList); // 改這裡：傳給 UI builder 而不是 Future
      },
    );
  }

  Widget _buildTabContentUI(
      String direction, List<Map<String, dynamic>> finalList) {
    return RefreshIndicator(
      onRefresh: () async => await _loadData(),
      child: ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: ValueKey(_sortNotifier.value), // 每次排序不同 key
        items: finalList,
        areItemsTheSame: (a, b) => a["RouteID"] == b["RouteID"],
        itemBuilder: (context, animation, stop, index) {
          final PlateNumb = stop["PlateNumb"];

          final color = stop["color"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["color"] == '2'
                  ? const Color.fromRGBO(225, 85, 104, 0.1)
                  : (stop["color"] == AppLocalizations.of(context)!.text_317
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
                      final isEnglish = _isEnglishLocale(context);
                      final city = widget.city.isNotEmpty
                          ? widget.city
                          : busCurrentCity;
                      BusRoute route = BusRoute.fromJson(
                          await getBusRouteWithId(
                              city: city, routeId: stop["RouteID"]));
                      // 在 await 之前取值，避免列表重建後讀到別的班次
                      final int? tappedDirection = stop["Direction"] is int
                          ? stop["Direction"] as int
                          : int.tryParse("${stop["Direction"]}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusTime(
                              routeName: _tdxRouteName(route, stop["RouteName"]),
                              departureStopName: _localizedDepartureName(
                                  route,
                                  isEnglish: isEnglish),
                              destinationStopName: _localizedDestinationName(
                                  route,
                                  isEnglish: isEnglish),
                              operators: route.operatorName,
                              routeMapImageUrl: route.routeMapUrl,
                              city: route.routeCity.isNotEmpty
                                  ? route.routeCity
                                  : city,
                              routeID: route.routeId,
                              hasSubRoutes: route.hasSubRoute,
                              data: route,
                            mark: tappedDirection == null
                                ? null
                                : Mark(direction: tappedDirection),),
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
                        stop["time"] ?? AppLocalizations.of(context)!.text_321,
                        style: TextStyle(
                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? Colors.white
                              : (stop["color"] == '2'
                                  ? const Color.fromRGBO(255, 85, 104, 1)
                                  : (stop["color"] ==
                                          AppLocalizations.of(context)!.text_317
                                      ? const Color.fromRGBO(149, 149, 149, 1.0)
                                      : (stop["color"] == "min"
                                          ? const Color.fromRGBO(
                                              13, 168, 255, 1)
                                          : const Color.fromRGBO(
                                              68, 68, 68, 1)))),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          _localizedBusText(
                                stop["RouteName"],
                                isEnglish: _isEnglishLocale(context),
                              ).isNotEmpty
                              ? _localizedBusText(
                                  stop["RouteName"],
                                  isEnglish: _isEnglishLocale(context),
                                )
                              : AppLocalizations.of(context)!.text_322,
                          style: TextStyle(
                            fontFamily: stop["color"] == "0"
                                ? 'MiSans-Semibold'
                                : 'MiSans-normal',
                            fontSize: 17,
                            color: stop["color"] ==
                                    AppLocalizations.of(context)!.text_317
                                ? const Color.fromRGBO(136, 136, 136, 1)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "往 ${stop["to"] ?? AppLocalizations.of(context)!.text_323}",
                          style: const TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: Color.fromRGBO(136, 136, 136, 1),
                          ),
                        ),
                      ],
                    ),
                    trailing:
                        PlateNumb != null ? bubble(plateNum: PlateNumb) : null,
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

  /// 安全解析多語系名稱 (自動依 Context/系統語系切換優先順序，並過濾無效字串)
  String? _extractLocalizedName(
      dynamic value, {
        required BuildContext context,
        bool? isEnglish,
      }) {
    if (value == null) return null;
    final locale = Localizations.localeOf(context);
    // 自動判斷目前語系模式
    final bool activeIsEnglish =  locale.languageCode == 'en';

    if (value is Map) {
      final keys = activeIsEnglish
          ? ["En", "en", "Zh_tw", "zh_tw", "Zh", "zh"]
          : ["Zh_tw", "zh_tw", "Zh", "zh", "En", "en"];

      for (final key in keys) {
        final val = value[key];
        if (val != null) {
          final str = val.toString().trim();
          if (str.isNotEmpty && str != "null") {
            return str;
          }
        }
      }
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == "null") return null;
      try {
        final decoded = json.decode(trimmed);
        if (decoded is Map) {
          return _extractLocalizedName(
            decoded,
            context: context,
            isEnglish: activeIsEnglish,
          );
        }
      } catch (_) {}
      return trimmed;
    }

    final str = value.toString().trim();
    if (str.isEmpty || str == "null") return null;
    return str;
  }

  /// 深層掃描提取目的地名稱 (支援多語系)
  String? _extractDestination(Map<String, dynamic> item, BuildContext context) {
    final directCandidates = [
      item["DestinationStopNameEn"],
      item["DestinationStopNameZh"],
      item["DestinationStopName"],
      item["DestinationStop"],
      item["DestinationNameEn"],
      item["DestinationNameZh"],
      item["DestinationName"],
      item["Destination"],
      item["DestStopName"],
      item["EndStopNameEn"],
      item["EndStopNameZh"],
      item["EndStopName"],
      item["Headsign"],
      item["TripHeadsign"],
      item["destinationStopNameEn"],
      item["destinationStopNameZh"],
      item["destinationStopName"],
      item["destination_stop_name"],
    ];

    for (final cand in directCandidates) {
      final name = _extractLocalizedName(cand, context: context);
      if (name != null) return name;
    }

    final nestedObjs = [
      item["Route"],
      item["SubRoute"],
      item["BusRoute"],
      item["route"],
    ];

    for (final obj in nestedObjs) {
      if (obj is Map<String, dynamic>) {
        final nestedName = _extractDestination(obj, context);
        if (nestedName != null) return nestedName;
      } else if (obj is Map) {
        final nestedName = _extractDestination(Map<String, dynamic>.from(obj), context);
        if (nestedName != null) return nestedName;
      }
    }

    return null;
  }

  /// 深層掃描提取起點站名稱 (支援多語系)
  String? _extractDeparture(Map<String, dynamic> item, BuildContext context) {
    final directCandidates = [
      item["DepartureStopNameEn"],
      item["DepartureStopNameZh"],
      item["DepartureStopName"],
      item["DepartureStop"],
      item["DepartureNameEn"],
      item["DepartureNameZh"],
      item["DepartureName"],
      item["Departure"],
      item["StartStopNameEn"],
      item["StartStopNameZh"],
      item["StartStopName"],
      item["departureStopNameEn"],
      item["departureStopNameZh"],
      item["departureStopName"],
      item["departure_stop_name"],
    ];

    for (final cand in directCandidates) {
      final name = _extractLocalizedName(cand, context: context);
      if (name != null) return name;
    }

    final nestedObjs = [
      item["Route"],
      item["SubRoute"],
      item["BusRoute"],
      item["route"],
    ];

    for (final obj in nestedObjs) {
      if (obj is Map<String, dynamic>) {
        final nestedName = _extractDeparture(obj, context);
        if (nestedName != null) return nestedName;
      } else if (obj is Map) {
        final nestedName = _extractDeparture(Map<String, dynamic>.from(obj), context);
        if (nestedName != null) return nestedName;
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _processData(
      String stationID,
      List<Map<String, dynamic>> stopEstimatedTime,
      ) async {
    try {
      /// -----------------------------
      /// 1. 過濾 StationID、依 RouteName + Direction 去重並保留最快班次
      /// -----------------------------
      final filteredRouteMap = <String, Map<String, dynamic>>{};
      final missingInfoRouteIds = <String>{};
      final missingInfoRouteNames = <String>{};

      for (final item in stopEstimatedTime) {
        final itemStationID = item["StationID"]?.toString();
        if (itemStationID != stationID) continue;

        final routeName = _extractLocalizedName(item["RouteName"], context: context);
        if (routeName == null || routeName.isEmpty) continue;

        final rawDir = item["Direction"];
        final directionVal = (rawDir is int)
            ? rawDir
            : int.tryParse(rawDir?.toString() ?? '') ?? 0;

        final routeKey = "${routeName}_$directionVal";
        final currentTime = _parseTimeToMinutes(item["time"]?.toString());

        final existing = filteredRouteMap[routeKey];
        if (existing == null ||
            (currentTime != -1 && currentTime < (existing["_parsedTime"] as int))) {
          final processedItem = Map<String, dynamic>.from(item);
          processedItem["_parsedRouteName"] = routeName;
          processedItem["_parsedDirection"] = directionVal;
          processedItem["_parsedTime"] = currentTime;

          filteredRouteMap[routeKey] = processedItem;

          final rId = item["RouteID"]?.toString();
          if (rId != null && rId.isNotEmpty) {
            missingInfoRouteIds.add(rId);
          }
          missingInfoRouteNames.add(routeName);
        }
      }

      if (filteredRouteMap.isEmpty) return [];

      /// -----------------------------
      /// 2. 1 次查詢 Bus.bus_station 並建立 BusStationInfo Lookup
      /// -----------------------------
      final city = widget.city.isNotEmpty ? widget.city : busCurrentCity;
      final cityCode = convertCityCode(city);

      final stationQuery = """
      SELECT *
      FROM Bus.bus_station
      WHERE LocationCityCode = '$cityCode'
    """;

      final stationResults = await mysqlSelect(stationQuery);

      final stationMap = <String, BusStationInfo>{};
      for (final row in stationResults) {
        final station = BusStationInfo.fromMap(row);
        if (station.stationID.isNotEmpty) {
          stationMap[station.stationID] = station;
        }
        if (station.stationUID.isNotEmpty) {
          stationMap[station.stationUID] = station;
        }
      }

      /// -----------------------------
      /// 3. 若即時資料缺乏起訖站，進行 1 次批次 SQL 補充
      /// -----------------------------
      final routeDbCache = <String, Map<String, dynamic>>{};
      bool needsRouteDbQuery = false;

      for (final item in filteredRouteMap.values) {
        final dep = _extractDeparture(item, context);
        final dest = _extractDestination(item, context);
        if (dep == null || dest == null) {
          needsRouteDbQuery = true;
          break;
        }
      }

      if (needsRouteDbQuery) {
        try {
          String whereClause = "";
          if (missingInfoRouteIds.isNotEmpty) {
            final idList = missingInfoRouteIds
                .map((id) => "'${id.replaceAll("'", "''")}'")
                .join(',');
            whereClause = "RouteID IN ($idList)";
          } else if (missingInfoRouteNames.isNotEmpty) {
            final nameList = missingInfoRouteNames
                .map((n) => "'${n.replaceAll("'", "''")}'")
                .join(',');
            whereClause =
            "JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) IN ($nameList)";
          }

          if (whereClause.isNotEmpty) {
            final routeQuery = """
            SELECT *
            FROM Bus.bus_route
            WHERE City = '$city' AND $whereClause
          """;
            final routeResults = await mysqlSelect(routeQuery);
            for (final row in routeResults) {
              final rId = row["RouteID"]?.toString();
              if (rId != null && rId.isNotEmpty) {
                routeDbCache[rId] = row;
              }
              final rName = _extractLocalizedName(row["RouteName"], context: context);
              if (rName != null && rName.isNotEmpty) {
                routeDbCache[rName] = row;
              }
            }
          }
        } catch (e) {
          debugPrint("批次補充 bus_route 資訊失敗: $e");
        }
      }

      /// -----------------------------
      /// 4. 合併資料並計算去的方向 (to)
      /// -----------------------------
      final stationInfo = stationMap[stationID];
      final List<Map<String, dynamic>> processedData = [];

      for (final item in filteredRouteMap.values) {
        final routeName = item["_parsedRouteName"] as String;
        final directionVal = item["_parsedDirection"] as int;

        // 1. 解析 RouteID
        String? routeID = item["RouteID"]?.toString();
        if ((routeID == null || routeID.isEmpty) && stationInfo != null) {
          for (final stop in stationInfo.stops) {
            final stopRouteName = _extractLocalizedName(stop.routeName, context: context);
            if (stopRouteName == routeName && stop.routeID.isNotEmpty) {
              routeID = stop.routeID;
              break;
            }
          }
        }
        routeID ??= AppLocalizations.of(context)!.text_321;

        // 2. 提取起點站與終點站
        final dbInfo = routeDbCache[routeID] ?? routeDbCache[routeName];

        final departureName = _extractDeparture(item, context) ??
            _extractLocalizedName(dbInfo?["DepartureStopNameZh"], context: context) ??
            _extractLocalizedName(dbInfo?["DepartureStopNameEn"], context: context);

        final destinationName = _extractDestination(item, context) ??
            _extractLocalizedName(dbInfo?["DestinationStopNameZh"], context: context) ??
            _extractLocalizedName(dbInfo?["DestinationStopNameEn"], context: context);

        final finalDeparture =
            departureName ?? AppLocalizations.of(context)!.text_325;
        final finalDestination =
            destinationName ?? AppLocalizations.of(context)!.text_326;

        item["RouteID"] = routeID;
        item["DepartureStopName"] = finalDeparture;
        item["DestinationStopName"] = finalDestination;

        // 3. 車頭牌 Headsign 安全解析與多語系處理 (自動清除中英文前綴)
        String? headsign;
        final rawHeadsign = _extractLocalizedName(item["Headsign"], context: context);
        if (rawHeadsign != null && rawHeadsign.isNotEmpty) {
          final RegExp prefixRegex = RegExp(r'^(往\s*|to:\s*|to\s+|for:\s*|for\s+)', caseSensitive: false);
          final cleanedHeadsign = rawHeadsign.replaceFirst(prefixRegex, '').trim();
          if (cleanedHeadsign.isNotEmpty) {
            headsign = AppLocalizations.of(context)!.nearStopTo(cleanedHeadsign);
          }
        }

        // 4. 方向比對
        final isDirection1 = directionVal == 1;

        item["from"] = isDirection1 ? finalDestination : finalDeparture;

        if (headsign != null && headsign.isNotEmpty) {
          item["to"] = headsign;
        } else {
          item["to"] = isDirection1 ? finalDeparture : finalDestination;
        }

        // 清理暫存 key
        item.remove("_parsedRouteName");
        item.remove("_parsedDirection");
        item.remove("_parsedTime");

        processedData.add(item);
      }

      return processedData;
    } catch (e) {
      debugPrint('處理 bus_station 資料發生錯誤: $e');
      return [];
    }
  }
  int _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return -1;

    // 处理 "X 分鐘" 格式
    if (time.contains(AppLocalizations.of(context)!.text_332)) {
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
        DateTime parsedTime =
            DateTime(now.year, now.month, now.day, hour, minute);

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
    List<dynamic> info =
        await GetBusStopInfo(stopName: widget.stop, city: widget.city);
    List<Map<String, dynamic>> tempData = [];

    _stationIDs.value = info
        .map((station) => station["StationID"] as String)
        .toList(); // 提取 StationID

    for (var i in info) {
      List<Map<String, dynamic>> stationInfo =
          await fetchStationInfo(_stationIDs.value, widget.city);
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
            Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ));
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
          Flexible(child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ), maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
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
            Flexible(child: Text(
              AppLocalizations.of(context)!.text_333,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A73E8),
              ), maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
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
              '所在城市：${localizedCityName(
                widget.city.isNotEmpty ? widget.city : busCurrentCity,
                isEnglish: _isEnglishLocale(context),
              )}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.text_44,
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
            return // 直接替換原本的 Center(child: LoadingAnimationWidget...)
              const AppLoading();
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
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
                          iconTheme:
                              const IconThemeData(color: Color(0xFF1A73E8)),
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
                                  child: const Icon(Icons.refresh_rounded,
                                      size: 20),
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
                                  child: const Icon(Icons.more_vert_rounded,
                                      size: 20),
                                ),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  _buildPopupMenuItem(
                                    icon: Icons.info_outline_rounded,
                                    title:
                                        AppLocalizations.of(context)!.text_333,
                                    value: 'info',
                                    color: const Color(0xFF1A73E8),
                                  ),
                                  _buildPopupMenuItem(
                                    icon: Icons.favorite_border_rounded,
                                    title:
                                        AppLocalizations.of(context)!.text_334,
                                    value: 'favorite',
                                    color: const Color(0xFFFF3B30),
                                  ),
                                  _buildPopupMenuItem(
                                    icon: Icons.sort_rounded,
                                    title:
                                        AppLocalizations.of(context)!.text_335,
                                    value: 'sort',
                                    color: const Color(0xFF34C759),
                                  ),
                                ],
                                onSelected: (String action) async {
                                  if (action == 'favorite') {
                                    favorite_feature dbHelper =
                                        favorite_feature();
                                    final output =
                                        await dbHelper.addFavoriteStop(
                                      stopName: widget.stop,
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
                                        text: AppLocalizations.of(context)!
                                            .text_336,
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
                body: Stack(
                  children: [
                    Container(
                      color: bgColorWhite,
                      child: TabBarView(
                        children: List.generate(_stationIDs.value.length, (index) {
                          String label = String.fromCharCode(65 + index);
                          return FutureBuilder(
                            future: _buildTabContent(
                                _stationIDs.value[index], snapshot.data!),
                            builder: (context, contentSnapshot) {
                              if (contentSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return  const AppLoading();
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
                    if (isTimerOn.value == false)
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 16,
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[700]!
                                      .withOpacity(0.7),
                                  borderRadius:
                                  BorderRadius.circular(
                                      12),
                                  border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                                  mainAxisSize:
                                  MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons
                                          .pause_circle_filled_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Flexible(
                                        child: Text(
                                          AppLocalizations.of(
                                              context)!
                                              .text_349,
                                          maxLines: 1,
                                          overflow: TextOverflow
                                              .ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (isTimerOn.value == true)
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: ValueListenableBuilder<int>(
                            valueListenable: remainingSecondsNotifier,
                            builder: (context, remainingTime, child) {
                              final isWarning = remainingTime <= 10;

                              return GestureDetector(
                                onTap: () {
                                  // 點擊時重新載入資料
                                  _loadData();
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: (isWarning
                                            ? const Color(0xFFFF9500)
                                            : const Color(0xFF1A73E8))
                                            .withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isWarning
                                                ? Icons.warning_amber_rounded
                                                : Icons.autorenew_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "$remainingTime 秒",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                  ],
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
