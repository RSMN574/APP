import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';
import 'package:com.rsmn574.app/database/sql/favorite_feature.dart';
import 'package:com.rsmn574.app/features/bus/services/bus_stop_info_service.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/bus/model/bus_route_model.dart';
import 'package:com.rsmn574.app/features/bus/pages/bus_time_page.dart';
import 'package:com.rsmn574.app/utils/convert.dart';
import 'package:com.rsmn574.app/features/bus/widgets/bubble.dart';
import 'package:com.rsmn574.app/widget/error.dart';

import '../../../database/get_data.dart';
import '../../../widget/AppLoading.dart';

enum SortType { nameAsc, nameDesc, timeAsc, timeDesc }

class BusStopInfo extends StatefulWidget {
  final String stop;
  final String city;
  const BusStopInfo(this.stop, {super.key, required this.city});
  @override
  State<BusStopInfo> createState() => _BusStopInfoState();
}

class _BusStopInfoState extends State<BusStopInfo>
    with TickerProviderStateMixin {
  // ── 狀態 ──────────────────────────────────────────────────────────────
  final ValueNotifier<List<String>> _stationIDs =
  ValueNotifier<List<String>>([]);
  final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier(40);
  Timer? _timer;

  late TabController _tabController;
  final StreamController<List<Map<String, dynamic>>> _streamController =
  StreamController();
  final _sortNotifier = ValueNotifier<SortType>(SortType.timeAsc);

  ValueNotifier<bool> isTimerOn = ValueNotifier(false);

  // P0：改由 BusStopInfoService 負責資料取得與 enrichment。
  final BusStopInfoService _stopInfoService = const BusStopInfoService();

  // P0：保留原 _processData 的去重語義（同 RouteName+Direction 保留最近時間）。
  final Map<String, List<Map<String, dynamic>>> _dedupedByStation = {};

  // 防競態：每次 _loadData 遞增；舊請求完成後若 requestId 不一致則丟棄
  int _requestId = 0;

  void _startAutoReload() {
    _timer?.cancel();
    _remainingSecondsNotifier.value = 40;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSecondsNotifier.value > 1) {
        _remainingSecondsNotifier.value =
            _remainingSecondsNotifier.value - 1;
      } else {
        _remainingSecondsNotifier.value = 40;
        _loadData();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 1, vsync: this);
    _tabController.index = 0;
    _currentTabIndex.value = 0;
    _tabController.addListener(_handleTabChange);

    _stationIDs.addListener(_syncTabControllerLength);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  void _syncTabControllerLength() {
    final newLen = _stationIDs.value.length;
    if (!mounted || newLen == 0) return;
    if (newLen == _tabController.length) return;

    final oldController = _tabController;
    final oldIndex = oldController.index;
    oldController.removeListener(_handleTabChange);
    oldController.dispose();

    _tabController = TabController(
      length: newLen,
      vsync: this,
      initialIndex: oldIndex.clamp(0, newLen - 1),
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
    _timer?.cancel();
    _requestId++;
    _stationIDs.removeListener(_syncTabControllerLength);
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _stationIDs.dispose();
    _currentTabIndex.dispose();
    _remainingSecondsNotifier.dispose();
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
    final reqId = ++_requestId;

    try {
      final result = await _stopInfoService.load(
        stopName: widget.stop,
        city: widget.city,
        l10n: AppLocalizations.of(context)!,
      );
      if (!mounted || reqId != _requestId) return;

      _stationIDs.value = result.stationIds;
      isTimerOn.value = result.hasLiveData;
      if (result.hasLiveData) _startAutoReload();

      _dedupedByStation.clear();
      for (final entry in result.stopsByStation.entries) {
        final routeMap = <String, Map<String, dynamic>>{};
        for (final item in entry.value) {
          final routeName = _routeNameOf(item);
          if (routeName == null || routeName.isEmpty) continue;
          final key = '${routeName}_${item["Direction"]}';
          final cur = _parseTimeToMinutes(item["time"]);
          final existing = routeMap[key];
          if (existing == null ||
              (cur != -1 && cur < _parseTimeToMinutes(existing["time"]))) {
            routeMap[key] = item;
          }
        }
        _dedupedByStation[entry.key] = routeMap.values.toList();
      }

      if (!_streamController.isClosed) {
        _streamController.add(
          result.stopsByStation.values.expand((e) => e).toList(),
        );
      }
    } catch (e, st) {
      if (!mounted || reqId != _requestId) return;
      debugPrint('BusStopInfo _loadData failed: $e\n$st');
      if (!_streamController.isClosed) {
        _streamController.addError(e, st);
      }
    }
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
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
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
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sort_rounded,
                        size: 24,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context)!.text_318,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSortOption('站序 1→10', SortType.nameAsc,
                    Icons.numbers_rounded, colorScheme.primary),
                _buildSortOption('站序 10→1', SortType.nameDesc,
                    Icons.numbers_rounded, colorScheme.primary),
                _buildSortOption(
                    AppLocalizations.of(context)!.text_319,
                    SortType.timeAsc,
                    Icons.access_time_rounded,
                    context.appColors.success),
                _buildSortOption(
                    AppLocalizations.of(context)!.text_320,
                    SortType.timeDesc,
                    Icons.access_time_rounded,
                    context.appColors.warning),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
      String title, SortType type, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  : Border.all(color: colorScheme.outlineVariant, width: 1),
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
                    color: _sortNotifier.value == type
                        ? colorScheme.onPrimary
                        : color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _sortNotifier.value == type
                          ? color
                          : colorScheme.onSurface,
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
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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

  String _localizedDestinationName(dynamic route,
      {required bool isEnglish}) {
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

  Widget _buildTabContent(String stationID) {
    final finalList = _dedupedByStation[stationID] ??
        const <Map<String, dynamic>>[];

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

        return _buildTabContentUI(sortedList);
      },
    );
  }

  Widget _buildTabContentUI(List<Map<String, dynamic>> finalList) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async => await _loadData(),
      child: ImplicitlyAnimatedList<Map<String, dynamic>>(
        key: ValueKey(_sortNotifier.value),
        items: finalList,
        areItemsTheSame: (a, b) => a["RouteID"] == b["RouteID"],
        itemBuilder: (context, animation, stop, index) {
          final PlateNumb = stop["PlateNumb"];

          // 站牌語義色：保留原設計（'0' / '2' / 'min' / text_317 各自對應業務語義）
          final Color color = stop["color"] == '0'
              ? const Color.fromRGBO(235, 15, 41, 0.85)
              : (stop["color"] == '2'
              ? const Color.fromRGBO(225, 85, 104, 0.1)
              : (stop["color"] == l10n.text_317
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
                              routeName:  route.routeZh,
                              departureStopName: _localizedDepartureName(route,
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
                        stop["time"] ?? l10n.text_321,
                        style: TextStyle(
                          fontSize: 17,
                          color: stop["color"] == '0'
                              ? colorScheme.onPrimary
                              : (stop["color"] == '2'
                              ? const Color.fromRGBO(255, 85, 104, 1)
                              : (stop["color"] == l10n.text_317
                              ? const Color.fromRGBO(
                              149, 149, 149, 1.0)
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
                              : l10n.text_322,
                          style: TextStyle(
                            fontFamily: stop["color"] == "0"
                                ? 'MiSans-Semibold'
                                : 'MiSans-normal',
                            fontSize: 17,
                            color: stop["color"] == l10n.text_317
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "往 ${stop["to"] ?? l10n.text_323}",
                          style: TextStyle(
                            fontFamily: 'MiSans-normal',
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                    PlateNumb != null ? bubble(plateNum: PlateNumb) : null,
                  ),
                ),
                Divider(
                  color: colorScheme.outlineVariant,
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

  // P0：去重時需要從 Map 取 RouteName。
  String? _routeNameOf(Map<String, dynamic> item) {
    final raw = item["RouteName"];
    if (raw is Map) return raw["Zh_tw"]?.toString();
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('{')) {
        try {
          final decoded = json.decode(trimmed);
          if (decoded is Map) return decoded["Zh_tw"]?.toString();
        } catch (_) {}
      }
      return raw;
    }
    return null;
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

  PopupMenuItem<String> _buildPopupMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showStopInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_rounded,
                color: colorScheme.primary,
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
                  color: colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO(P2-i18n): 需新增 ARB key，暫以原字串顯示。
            Text(
              '站牌名稱：${widget.stop}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // TODO(P2-i18n): 需新增 ARB key，暫以原字串顯示。
            Text(
              '所在城市：${localizedCityName(
                widget.city.isNotEmpty ? widget.city : busCurrentCity,
                isEnglish: _isEnglishLocale(context),
              )}',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.text_44,
              style: TextStyle(
                color: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          } else if (snapshot.hasError) {
            debugPrint('${snapshot.error}');
            return ErrorPage();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ErrorPage();
          } else {
            return Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(150),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AppBar(
                        backgroundColor: colorScheme.surface,
                        elevation: 0,
                        leading: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded,
                                size: 20),
                            color: colorScheme.primary,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        title: Text(
                          widget.stop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        centerTitle: true,
                        actions: [
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 20),
                              color: colorScheme.primary,
                              onPressed: _loadData,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded,
                                  size: 20),
                              iconColor: colorScheme.primary,
                              color: colorScheme.surfaceContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: colorScheme.outlineVariant,
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
                                  color: colorScheme.primary,
                                ),
                                _buildPopupMenuItem(
                                  icon: Icons.favorite_border_rounded,
                                  title:
                                  AppLocalizations.of(context)!.text_334,
                                  value: 'favorite',
                                  color: context.appColors.danger,
                                ),
                                _buildPopupMenuItem(
                                  icon: Icons.sort_rounded,
                                  title:
                                  AppLocalizations.of(context)!.text_335,
                                  value: 'sort',
                                  color: context.appColors.success,
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

                                  if (!mounted) return;

                                  if (output == 100) {
                                    QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.success,
                                      // TODO(P2-i18n): 需新增 ARB key。
                                      text: '${widget.stop}已儲存項目',
                                    );
                                  } else if (output == -1) {
                                    QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.warning,
                                      // TODO(P2-i18n): 需新增 ARB key。
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
                              color: colorScheme.onSurfaceVariant
                                  .withOpacity(0.5),
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
                    color: colorScheme.surface,
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(
                        _stationIDs.value.length,
                            (index) =>
                            _buildTabContent(_stationIDs.value[index]),
                      ),
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
                                // 深色 toast 樣式，與主題無關，保留原色。
                                color: Colors.grey[700]!.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.surface.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pause_circle_filled_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .text_349,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
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
                          valueListenable: _remainingSecondsNotifier,
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
                                          ? context.appColors.warning
                                          : colorScheme.primary)
                                          .withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                        colorScheme.surface.withOpacity(0.1),
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
                                          color: colorScheme.onPrimary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "$remainingTime 秒",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
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
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.outlineVariant,
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
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
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