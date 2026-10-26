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
import '../model/bus_station_model.dart';

ValueNotifier<List<String>> _stationIDs = ValueNotifier<List<String>>([]);
final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
ValueNotifier<int> remainingSecondsNotifier = ValueNotifier(40);
Timer? _timer;

enum SortType {
  nameAsc,
  nameDesc,
  timeAsc,
  timeDesc
}

class BusStopInfo extends StatefulWidget {
  final String stop;
  final String city;
  const BusStopInfo(this.stop, {super.key, required this.city});
  @override
  State<BusStopInfo> createState() => _BusStopInfoState();
}

class _BusStopInfoState extends State<BusStopInfo>
    with TickerProviderStateMixin {
  ValueNotifier<bool> isTimerOn = ValueNotifier(false);
  late TabController _tabController;
  final StreamController<List<Map<String, dynamic>>> _streamController =
  StreamController();
  List<Map<String, dynamic>> processedUp = [];
  List<Map<String, dynamic>> processedDown = [];
  final _sortNotifier = ValueNotifier<SortType>(SortType.timeAsc);
  List<Map<String, dynamic>> data = [];
  bool _hasLoadedOnce = false;

  void _startAutoReload() {
    _timer?.cancel();
    remainingSecondsNotifier.value = 40;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSecondsNotifier.value > 1) {
        remainingSecondsNotifier.value = remainingSecondsNotifier.value - 1;
      } else {
        remainingSecondsNotifier.value = 40;
        _loadData();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController =
        TabController(length: _stationIDs.value.length, vsync: this);
    _tabController.index = 0;
    _currentTabIndex.value = 0;
    _tabController.addListener(_handleTabChange);

    // 监听站点数量变化，重建 TabController
    _stationIDs.addListener(_syncTabControllerLength);
  }

  /// 当 _stationIDs 数量变化时，重建 TabController（length 是 final，不能改）
  /// 注意：先取 oldIndex → removeListener → dispose 旧 controller → 再 new 新 controller
  /// 使用 TickerProviderStateMixin 允许多个 ticker（重建 controller 必需）
  void _syncTabControllerLength() {
    final newLen = _stationIDs.value.length;
    if (!mounted || newLen == _tabController.length) return;

    final oldController = _tabController;
    final oldIndex = oldController.index; // dispose 前先取 index
    oldController.removeListener(_handleTabChange);
    oldController.dispose();

    _tabController = TabController(
      length: newLen,
      vsync: this,
      initialIndex: oldIndex.clamp(0, newLen == 0 ? 0 : newLen - 1),
    );
    _tabController.addListener(_handleTabChange);

    _currentTabIndex.value = _tabController.index;
    if (mounted) setState(() {});
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (!_tabController.indexIsChanging) {
      _currentTabIndex.value = _tabController.index;
    }
  }

  @override
  void dispose() {
    _stationIDs.removeListener(_syncTabControllerLength);
    _streamController.close();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    isTimerOn.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController.length > 0) {
      _tabController.index = 0;
    }
  }

  Future<void> _loadData() async {
    if (isTimerOn.value) _startAutoReload();
    final data = await fetchBusStopInfo();
    _streamController.add(data);
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
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.text_318,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73E8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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

  Future<Map<String, dynamic>> getTimeList(stopData) async {
    if (stopData["EstimateTime"] != null) {
      isTimerOn.value = true;
      int estimateTime = stopData["EstimateTime"];

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

    if (stopData["NextBusTime"] != null) {
      DateTime nextBusTime =
      DateTime.parse(stopData["NextBusTime"]).toLocal();
      Duration difference = nextBusTime.difference(DateTime.now());
      int totalMinutes = difference.inMinutes;

      if (totalMinutes < 0) {
        isTimerOn.value = false;
        return {
          "time": totalMinutes > -5
              ? AppLocalizations.of(context)!.text_340
              : AppLocalizations.of(context)!.text_317,
          "isRed": '',
          "PlateNumb": "",
          "color": AppLocalizations.of(context)!.text_317,
        };
      }

      if (totalMinutes < 60) {
        isTimerOn.value = true;

        if (totalMinutes < 1) {
          return {
            "time": AppLocalizations.of(context)!.text_316,
            "isRed": '0',
            "PlateNumb": stopData["PlateNumb"] ?? "",
            "color": '0',
          };
        }

        if (totalMinutes < 3) {
          return {
            "time": "$totalMinutes 分鐘",
            "isRed": '2',
            "PlateNumb": stopData["PlateNumb"] ?? "",
            "color": "2",
          };
        }

        return {
          "time": AppLocalizations.of(context)!
              .nearStopMinutes(totalMinutes.toString()),
          "isRed": '',
          "PlateNumb": "",
          "color": "min",
        };
      }

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

    isTimerOn.value = false;
    return {
      "time": AppLocalizations.of(context)!.text_317,
      "isRed": '',
      "PlateNumb": "",
      "color": AppLocalizations.of(context)!.text_317,
    };
  }

  bool _isEnglishLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }

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
      try {
        final parsed = json.decode(routeName);
        if (parsed is Map) {
          return _localizedBusText(parsed, isEnglish: isEnglish);
        }
      } catch (_) {}
      return routeName;
    }

    return routeName.toString();
  }

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

        return _buildTabContentUI(direction, sortedList);
      },
    );
  }

  Widget _buildTabContentUI(
      String direction, List<Map<String, dynamic>> finalList) {
    return RefreshIndicator(
      onRefresh: () async => await _loadData(),
      child: ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: ValueKey(_sortNotifier.value),
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
                      final int? tappedDirection = stop["Direction"] is int
                          ? stop["Direction"] as int
                          : int.tryParse("${stop["Direction"]}");
                      if (!mounted) return;
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
                                  : Mark(direction: tappedDirection)),
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

  String? _extractLocalizedName(
      dynamic value, {
        required BuildContext context,
        bool? isEnglish,
      }) {
    if (value == null) return null;
    final locale = Localizations.localeOf(context);
    final bool activeIsEnglish = locale.languageCode == 'en';

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
        final nestedName =
        _extractDestination(Map<String, dynamic>.from(obj), context);
        if (nestedName != null) return nestedName;
      }
    }

    return null;
  }

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
        final nestedName =
        _extractDeparture(Map<String, dynamic>.from(obj), context);
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
      final routeMap = <String, Map<String, dynamic>>{};

      for (final item in stopEstimatedTime) {
        if (item["StationID"] != stationID) continue;

        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        final direction = item["Direction"];
        if (routeName == null || routeName.isEmpty) continue;

        final routeKey = "${routeName}_$direction";
        final currentTime = _parseTimeToMinutes(item["time"]);

        final existing = routeMap[routeKey];
        if (existing == null ||
            (currentTime != -1 &&
                currentTime < _parseTimeToMinutes(existing["time"]))) {
          routeMap[routeKey] = item;
        }
      }

      final stationData = routeMap.values.toList();
      if (stationData.isEmpty) return [];

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

      final Map<String, Map<String, dynamic>> routeInfoCache = {};

      if (routeNames.isNotEmpty) {
        try {
          final nameList = routeNames.map((name) => "'$name'").join(',');
          final query = """
          SELECT *
          FROM Bus.bus_route
          WHERE City = 'Taichung'
            AND JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) IN ($nameList)
        """;

          final results = await mysqlSelect(query);

          for (final result in results) {
            final routeNameField = result["RouteName"];
            String? routeName;

            if (routeNameField is Map) {
              routeName = routeNameField["Zh_tw"] as String?;
            } else if (routeNameField is String) {
              try {
                final parsed =
                json.decode(routeNameField) as Map<String, dynamic>;
                routeName = parsed["Zh_tw"] as String?;
              } catch (_) {
                routeName = routeNameField;
              }
            }

            if (routeName != null && routeName.isNotEmpty) {
              routeInfoCache[routeName] = result;
            }
          }
        } catch (_) {
          for (final routeName in routeNames) {
            try {
              final query = """
              SELECT * FROM Bus.Bus_Taichung_Route 
              WHERE RouteName LIKE '%"Zh_tw": "$routeName"%'
              OR JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName'
            """;
              final results = await mysqlSelect(query);
              if (results.isNotEmpty) {
                routeInfoCache[routeName] = results.first;
              }
            } catch (_) {}
          }
        }
      }

      final List<Map<String, dynamic>> processedData = [];

      for (final item in stationData) {
        final routeNameObj = item["RouteName"];
        String? routeName;

        if (routeNameObj is Map<String, dynamic>) {
          routeName = routeNameObj["Zh_tw"] as String?;
        } else if (routeNameObj is String) {
          routeName = routeNameObj;
        }

        final direction = item["Direction"];
        if (routeName == null) continue;

        final resultItem = Map<String, dynamic>.from(item);
        final routeInfo = routeInfoCache[routeName];
        final hasValidInfo = routeInfo != null && routeInfo.isNotEmpty;

        if (!mounted) return [];
        final localizations = AppLocalizations.of(context)!;

        resultItem["RouteID"] = hasValidInfo
            ? (routeInfo["RouteID"]?.toString() ?? localizations.text_321)
            : localizations.text_321;

        String? departureName;
        String? destinationName;
        String? departureNameEn;
        String? destinationNameEn;

        if (hasValidInfo) {
          departureName = _safeStationName(routeInfo["DepartureStopNameZh"]) ??
              routeInfo["DepartureStopName"]?.toString();
          destinationName =
              _safeStationName(routeInfo["DestinationStopNameZh"]) ??
                  routeInfo["DestinationStopName"]?.toString();
          departureNameEn = routeInfo["DepartureStopNameEn"]?.toString();
          destinationNameEn = routeInfo["DestinationStopNameEn"]?.toString();
        }

        resultItem["DepartureStopName"] =
            departureName ?? localizations.text_325;
        resultItem["DestinationStopName"] =
            destinationName ?? localizations.text_326;

        final isDirection1 = direction == 1;
        resultItem["from"] = isDirection1
            ? (destinationName ?? localizations.text_428)
            : (departureName ?? localizations.text_429);
        resultItem["to"] = isDirection1
            ? (departureName ?? localizations.text_429)
            : (destinationName ?? localizations.text_428);
        final toEn = isDirection1 ? departureNameEn : destinationNameEn;
        resultItem["toEn"] =
        (toEn != null && toEn.trim().isNotEmpty) ? toEn : null;

        processedData.add(resultItem);
      }

      return processedData;
    } catch (e, st) {
      debugPrint('Error processing data: $e');
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  String? _safeStationName(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;
      if (s.startsWith('{')) {
        try {
          final decoded = json.decode(s);
          if (decoded is Map) {
            return (decoded["Zh_tw"] ?? decoded["En"] ?? decoded["zh_tw"])
                ?.toString();
          }
        } catch (_) {}
      }
      return s;
    }
    if (value is Map) {
      return (value["Zh_tw"] ?? value["En"] ?? value["zh_tw"])?.toString();
    }
    return value.toString();
  }

  int _parseTimeToMinutes(String? time) {
    if (time == null || time.isEmpty) return -1;

    if (time.contains(AppLocalizations.of(context)!.text_332)) {
      return int.tryParse(time.split(" ").first) ?? -1;
    }

    if (time.contains(":")) {
      final parts = time.split(":");
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;

        DateTime now = DateTime.now();
        DateTime parsedTime =
        DateTime(now.year, now.month, now.day, hour, minute);

        if (parsedTime.isBefore(now)) {
          parsedTime = parsedTime.add(const Duration(days: 1));
        }

        return parsedTime.difference(now).inMinutes;
      }
    }

    return -1;
  }

  Future<List<Map<String, dynamic>>> fetchBusStopInfo() async {
    List<dynamic> info =
    await GetBusStopInfo(stopName: widget.stop, city: widget.city);
    List<Map<String, dynamic>> tempData = [];

    _stationIDs.value = info
        .map((station) => station["StationID"] as String)
        .toList();

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

  SelectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: busBlue),
            Flexible(
                child:
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
          Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            Flexible(
                child: Text(
                  AppLocalizations.of(context)!.text_333,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadData();
    }

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return ErrorPage();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            print('snapshot.has not Data');
            return ErrorPage();
          } else {
            return Scaffold(
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
                        // —— leading：圆角外殼 + arrow_back_ios_rounded ——
                        leading: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness ==
                                Brightness.dark
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFEEF3FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                size: 20),
                            color: const Color(0xFF1A73E8),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        title: Text(
                          widget.stop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A73E8),
                            letterSpacing: -0.5,
                          ),
                        ),
                        centerTitle: true,
                        actions: [
                          // —— 刷新按鈕：圆角外殼 ——
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFEEF3FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              color: const Color(0xFF1A73E8),
                              onPressed: _loadData,
                            ),
                          ),
                          // —— 更多選單：圆角外殼 ——
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                  Brightness.dark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFEEF3FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded,
                                  size: 20),
                              iconColor: const Color(0xFF1A73E8),
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
                                  title: AppLocalizations.of(context)!.text_333,
                                  value: 'info',
                                  color: const Color(0xFF1A73E8),
                                ),
                                _buildPopupMenuItem(
                                  icon: Icons.favorite_border_rounded,
                                  title: AppLocalizations.of(context)!.text_334,
                                  value: 'favorite',
                                  color: const Color(0xFFFF3B30),
                                ),
                                _buildPopupMenuItem(
                                  icon: Icons.sort_rounded,
                                  title: AppLocalizations.of(context)!.text_335,
                                  value: 'sort',
                                  color: const Color(0xFF34C759),
                                ),
                              ],
                              onSelected: (String action) async {
                                if (action == 'favorite') {
                                  favorite_feature dbHelper = favorite_feature();
                                  final output = await dbHelper.addFavoriteStop(
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
                      controller: _tabController,
                      children:
                      List.generate(_stationIDs.value.length, (index) {
                        return FutureBuilder(
                          future: _buildTabContent(
                              _stationIDs.value[index], snapshot.data!),
                          builder: (context, contentSnapshot) {
                            if (contentSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const AppLoading();
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
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[700]!.withOpacity(0.7),
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
                                    Icons.pause_circle_filled_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                      child: Text(
                                        AppLocalizations.of(context)!.text_349,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
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
                                _loadData();
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 8, sigmaY: 8),
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
                                        color:
                                        Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
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
            );
          }
        },
      ),
    );
  }

  PreferredSize _buildTabBar(List<Map<String, dynamic>> station) {
    final ids = _stationIDs.value;
    final tabCount = ids.length;
    final isScrollable = tabCount > 3;

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      // TabController 是 ChangeNotifier，用 ListenableBuilder 监听 index 变化
      child: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          // 在 builder 内生成按钮，确保 isSelected 每次重新计算
          final List<Widget> buttons = List.generate(tabCount, (index) {
            final isSelected = _tabController.index == index;
            return _buildTabButton(
              icon: Icons.directions_bus,
              label: String.fromCharCode(65 + index),
              stationId: ids[index],
              isSelected: isSelected,
              onTap: () {
                if (index < _tabController.length) {
                  _tabController.animateTo(index);
                }
              },
            );
          });

          final List<Widget> spacedButtons = [];
          for (var i = 0; i < buttons.length; i++) {
            if (i > 0) spacedButtons.add(const SizedBox(width: 12));
            spacedButtons.add(buttons[i]);
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: isScrollable
                ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: spacedButtons),
            )
                : Row(
              children: List.generate(buttons.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == buttons.length - 1 ? 0 : 12,
                    ),
                    child: buttons[i],
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required String stationId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEEF3FB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1A73E8).withOpacity(0.3)
                  : Colors.grey[300]!,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color:
                  isSelected ? const Color(0xFF1A73E8) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 70,
                child: Text(
                  stationId,
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
      ),
    );
  }
}