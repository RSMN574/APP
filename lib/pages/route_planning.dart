import 'dart:convert';
import 'package:flutter/material.dart';
import '../const/regular_const.dart';
import '../database/get_data.dart';
import '../database/sql/schedule.dart';
import '../l10n/app_localizations.dart';

class RoutePlanner extends StatefulWidget {
  @override
  _RoutePlannerState createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner>  with SingleTickerProviderStateMixin{
  // 基础数据
  late List<String> transportModes = [AppLocalizations.of(context)!.text_585, AppLocalizations.of(context)!.text_586, AppLocalizations.of(context)!.text_587, AppLocalizations.of(context)!.text_588, AppLocalizations.of(context)!.text_589, AppLocalizations.of(context)!.text_590, 'Ubike'];
  late String selectedTransport = AppLocalizations.of(context)!.text_588;

  // 城市数据
  late List<String> cities = [ AppLocalizations.of(context)!.text_6,AppLocalizations.of(context)!.text_7];
  List<String> citiesID = [ 'Taichung', 'Taipei'];
  late ValueNotifier<String> selectedCityNotifier = ValueNotifier<String>(AppLocalizations.of(context)!.text_6);
  ValueNotifier<String> selectedCityIDNotifier = ValueNotifier<String>("Taichung");
  // 公车数据
  ValueNotifier<List<Map<String, dynamic>>> busRoutesNotifier = ValueNotifier([]);
  String? selectedRoute;
  // TabController 用來監聽當前的 Tab
  late TabController tabController;
  // 站点数据
  late Map<String, List<String>> busStopsByRoute = {
    '101路': [AppLocalizations.of(context)!.text_591, '101大樓', AppLocalizations.of(context)!.text_592],
    '202路': [AppLocalizations.of(context)!.text_175, AppLocalizations.of(context)!.text_593, AppLocalizations.of(context)!.text_594],
    '33路': [AppLocalizations.of(context)!.text_595, AppLocalizations.of(context)!.text_596, AppLocalizations.of(context)!.text_597],
  };

// 站点选择
  String? selectedDepartureStation; // 当前选择的出发站
  String? selectedArrivalStation; // 当前选择的到达站
int? selectDirection;
String? routeArrivalStation;
  String? routeDepartureStation;
// 出发站和到达站的数据（可能会根据选择的路线进行动态更新）
  List<String> departureStations = []; // 根据选择的路线更新的出发站
  List<String> arrivalStations = []; // 根据选择的路线更新的到达站
 int? RouteID;

  List<String> filteredStops = [];
  TextEditingController departureController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBusRoutes(); // 初始化加载公交路线数据
    tabController = TabController(length: 2, vsync: this);
  }

  Future<void> fetchBusRoutes() async {
    try {
      List result = await mysqlSelect("SELECT RouteName,RouteID FROM Bus.bus_route WHERE City = '${selectedCityIDNotifier.value}'");

      List<Map<String, dynamic>> routes=[];
      for(var a in result){
        // 新增一个元素到列表中
        routes.add({"route": json.decode(a["RouteName"])["Zh_tw"], "id": a["RouteID"]});

      }

      // 使用 map 提取 "route" 部分
      // List<String> routeNames = routes.map((item) => item['route'] as String).toList();

      busRoutesNotifier.value = routes;
    } catch (e) {
      print("Error fetching bus routes: $e");
    }
  }

  void updateBusStops() {
    if (selectedRoute == null || !busStopsByRoute.containsKey(selectedRoute)) {
      filteredStops = [];
    } else {
      filteredStops = busStopsByRoute[selectedRoute!]!;
      selectedCityNotifier.value;
    }
    departureController.clear();
    destinationController.clear();
  }

  void showBusStopPicker(TextEditingController controller) {
    if (selectedRoute == null || !(busStopsByRoute.containsKey(selectedRoute))) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.text_598, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.text_599,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filteredStops = (busStopsByRoute[selectedRoute!] ?? [])
                            .where((stop) => stop.contains(searchQuery))
                            .toList();
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: filteredStops.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filteredStops[index]),
                      onTap: () {
                        controller.text = filteredStops[index];
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:  Text(AppLocalizations.of(context)!.text_44),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: busRoutesNotifier,
        builder: (context, busRoutes, child) {
          if (busRoutes.isEmpty) {
            return  Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.text_600, style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return SingleChildScrollView( // 加入滾動確保小螢幕不溢出
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 讓按鈕填滿寬度
              children: [
                _buildSectionHeader(Icons.location_city, AppLocalizations.of(context)!.text_28),
                const SizedBox(height: 10),
                _buildDropdownField(),

                const SizedBox(height: 24),
                _buildSectionHeader(Icons.directions_bus, AppLocalizations.of(context)!.text_601),
                const SizedBox(height: 10),
                _buildPickerButton(
                  label: selectedRoute ?? AppLocalizations.of(context)!.text_602,
                  onPressed: () => showRoutePicker(),
                  isPlaceholder: selectedRoute == null,
                ),

                if (selectedRoute != null) ...[
                  const SizedBox(height: 24),
                  // 使用 Stack 或 Row 營造「站點連接」的視覺感
                  _buildStationTimeline(),
                ],

                const SizedBox(height: 40),
                // 确认按钮
                if (selectedDepartureStation != null && selectedArrivalStation != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: () => confirmRouteSelection(
                          selectedCityNotifier.value, selectedRoute!, selectedDepartureStation!, selectedArrivalStation!),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.blue.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child:  Text(AppLocalizations.of(context)!.text_603, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

// --- 輔助組件，保持邏輯不變，僅美化外觀 ---

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: DropdownButtonFormField<String>(
        value:  selectedCityNotifier.value,
        onChanged: (String? newCity) {
          if (newCity != null) {
            // 1. 找到新城市在列表中的索引
            int index = cities.indexOf(newCity);

            // 2. 同步更新兩個 ValueNotifier
            // 注意：ValueNotifier 不需要放在 setState 裡面，它會自動通知監聽者


  selectedCityNotifier.value = newCity;
  selectedCityIDNotifier.value = citiesID[index];
            fetchBusRoutes();
          }
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
      ),
    );
  }

  Widget _buildPickerButton({required String label, required VoidCallback onPressed, required bool isPlaceholder}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPlaceholder ? Colors.grey.shade300 : Colors.blue.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 16, color: isPlaceholder ? Colors.grey : Colors.black87, fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500)),
              Icon(Icons.unfold_more, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.trip_origin, AppLocalizations.of(context)!.text_604),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.all(10), // 為左側連接線留空間
          child: Column(
            children: [
              _buildTimelineStep(
                title: AppLocalizations.of(context)!.text_63,
                content: selectedDepartureStation ?? AppLocalizations.of(context)!.text_161,
                onTap: () => showStationPicker("departure"),
                isLast: false,
                isActive: true,
              ),
              if (selectedDepartureStation != null)
                _buildTimelineStep(
                  title: AppLocalizations.of(context)!.text_162,
                  content: selectedArrivalStation ?? AppLocalizations.of(context)!.text_163,
                  onTap: () => showStationPicker2(),
                  isLast: true,
                  isActive: selectedArrivalStation != null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String content,
    required VoidCallback onTap,
    required bool isLast,
    required bool isActive,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                _buildPickerButton(label: content, onPressed: onTap, isPlaceholder: content.contains(AppLocalizations.of(context)!.text_605)),
                if (!isLast) const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // 构建 TabBar
  PreferredSize _buildTabBar(List routeInfo) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: tabController, // 绑定 TabController
          // controller:  _tabController ,
          indicatorColor: busBlue,
          labelColor: busBlue,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3.0,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: [
            Tab(icon: const Icon(Icons.directions_bus), text: routeInfo[0]),
            Tab(icon: const Icon(Icons.swap_horiz), text: routeInfo[1]),
          ],
        ),
      ),
    );
  }

  // 獲取路線基本資訊與所有停靠站
  Future<Map<String, dynamic>> _fetchBusRouteData(String routeName) async {
    var routeQuery = await mysqlSelect(
      "SELECT * FROM Bus.bus_route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName' AND City = 'Taichung';",
    );
    var stopsQuery = await mysqlSelect(
      "SELECT Stops FROM Bus.stopOfRoute WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$routeName' AND City = 'Taichung' ;",
    );
    return {'route': routeQuery[0], 'stops': stopsQuery};
  }
  void showStationPicker(String type) async {
    final data = await _fetchBusRouteData(selectedRoute!);
    final route = data['route'];
    final stops = data['stops'];

    // 解析兩側方向的站點
    List<dynamic> dir0Stops = json.decode(stops[0]["Stops"]);
    List<dynamic> dir1Stops = (stops.length > 1) ? json.decode(stops[1]["Stops"]) : dir0Stops;

    // 使用剛才封裝的 StationPickerDialog (需微調支援 Tab 或分兩次)
    // 這裡我們直接呼叫 Dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StationPickerDialog(
        // 如果你要支援兩邊方向，建議傳入目前 Tab 對應的列表
        stations: tabController.index == 0 ? dir0Stops : dir1Stops,
        title: '選擇出發站 (${tabController.index == 0 ? route["DepartureStopNameZh"] : route["DestinationStopNameZh"]} 方向)',
      ),
    );

    if (result != null) {
      setState(() {
        selectedDepartureStation = result["StopName"]["Zh_tw"];

        // 根據 Tab 紀錄方向邏輯
        if (tabController.index == 0) {
          routeDepartureStation = route["DepartureStopNameZh"];
          routeArrivalStation = route["DestinationStopNameZh"];
          selectDirection = 0; // 假設 0 是去程
        } else {
          routeDepartureStation = route["DestinationStopNameZh"];
          routeArrivalStation = route["DepartureStopNameZh"];
          selectDirection = 1; // 假設 1 是回程
        }
      });
    }
  }
  void showStationPicker2() async {
    final data = await _fetchBusRouteData(selectedRoute!);
    final route = data['route'];
    final stops = data['stops'];

    List<dynamic> targetStops = [];

    // 根據當前選擇的出發站 terminal 決定使用哪一組 Stops 資料
    if (routeDepartureStation == route["DepartureStopNameZh"]) {
      // 如果出發總站是去程起點
      targetStops = json.decode(stops[0]["Stops"]);
    } else {
      // 否則使用回程資料 (index 1)
      targetStops = (stops.length > 1) ? json.decode(stops[1]["Stops"]) : json.decode(stops[0]["Stops"]);
    }

    // 呼叫封裝好的 Dialog
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => StationPickerDialog(
        stations: targetStops,
        title: AppLocalizations.of(context)!.text_606,
      ),
    );

    if (result != null) {
      setState(() {
        selectedArrivalStation = result["StopName"]["Zh_tw"];

        // 自動計算 API 需要的 Direction
        // 邏輯：比對選中的 List 是否與 stops[1] 內容一致
        if (stops.length > 1 && json.encode(targetStops) == stops[1]["Stops"]) {
          selectDirection = 1;
        } else {
          selectDirection = 0;
        }
      });
    }
  }

// 構建搜索框
  Widget _buildSearchBox({required Function(String) onSearch}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        decoration:  InputDecoration(
          hintText: AppLocalizations.of(context)!.text_607,
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: onSearch,
      ),
    );
  }
  // 構建站點列表
  Widget _buildStationList({
    required List<dynamic> stops,
    required Function(String) onStationSelected,
  }) {
    return ListView.builder(
      itemCount: stops.length,
      itemBuilder: (context, index) {
        String stationName = stops[index]["StopName"]["Zh_tw"];
        return ListTile(
          title: Text(stationName),
          onTap: () {
            onStationSelected(stationName);
          },
        );
      },
    );
  }

  void showRoutePicker() async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String searchQuery = '';
        // 提取 route 部分


        List<Map<String,dynamic>> filtered= busRoutesNotifier.value ;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(AppLocalizations.of(context)!.text_601, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.text_608,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        filtered =   busRoutesNotifier.value.where((item) => item["route"].toString().contains(value)).toList();


                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(filtered[index]["route"]),
                      onTap: () {
                        Navigator.of(context).pop(filtered[index]["route"]); // 返回选择的路线

                        RouteID=int.parse(filtered[index]["id"]);

                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭弹窗
                  },
                  child:  Text(AppLocalizations.of(context)!.text_44),
                ),
              ],
            );
          },
        );
      },
    );

    // 弹窗关闭后处理选中的值
    if (selected != null) {
      setState(() {
        selectedRoute = selected; // 更新选中的路线
        updateBusStops(); // 更新站点
      });
    }
  }
  void confirmRouteSelection(String selectedCity, String selectedRoute, String selectedDepartureStation, String selectedArrivalStation,){

    _showAddToCategoryDialog(selectedCity,selectedRoute,selectedDepartureStation,selectedArrivalStation,);
  }

  void _showAddToCategoryDialog(String city, String route,String Departure,String DestinationS,) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.text_609),
          content: Text(AppLocalizations.of(context)!.text_610),
          actions: [
            TextButton(
              onPressed: () async {
                // 添加到通勤逻辑
                Navigator.pop(context); // 关闭对话框
                final schedule = ScheduleModel(
                    city: city,
                    userStartingStopName: Departure,
                    userDestinationStopName: DestinationS,
                    startingStopName:routeDepartureStation!,
                    finalStopName:routeArrivalStation!,
                    route: route, type: 'bus',
                    routeID:RouteID,
                    category:"trip",
                    other:{"routeID":RouteID.toString(),"category":"trip","direction":selectDirection.toString()}
                );

                final result = await ScheduleService.instance.addSchedule(schedule);



// 根据 addSchedule 方法返回的结果进行处理
                if (result == -1) {
                  // 如果已经存在相同的记录，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(AppLocalizations.of(context)!.text_611))
                  );
                } else if (result == 100) {
                  // 成功添加行程，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(AppLocalizations.of(context)!.text_612))
                  );
                } else {
                  // 添加行程失败，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.text_613))
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.text_614),
            ),
            TextButton(
              onPressed: () async {
                // 添加到通勤逻辑
                Navigator.pop(context); // 关闭对话框

                final schedule = ScheduleModel(
                    city: city,
                    userStartingStopName: Departure,
                    userDestinationStopName: DestinationS,
                    startingStopName:routeDepartureStation!,
                    finalStopName:routeArrivalStation!,
                    route: route, type: 'bus',
                    routeID:RouteID,
                    category:"commute",
                    other:{"routeID":RouteID,"category":"commute","direction":selectDirection.toString()}
                );

                final result = await ScheduleService.instance.addSchedule(schedule);



// 根据 addSchedule 方法返回的结果进行处理
                if (result == -1) {
                  // 如果已经存在相同的记录，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(AppLocalizations.of(context)!.text_611))
                  );
                } else if (result == 100) {
                  // 成功添加行程，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(AppLocalizations.of(context)!.text_612))
                  );
                } else {
                  // 添加行程失败，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.text_613))
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.text_615),
            ),
          ],
        );
      },
    );
  }
}

class StationPickerDialog extends StatefulWidget {
  final List<dynamic> stations; // 原始站點列表
  final String title;
  final dynamic initialSelection; // 初始選中的站點

  const StationPickerDialog({
    super.key,
    required this.stations,
    // this.title = AppLocalizations.of(context)!.text_616,
    this.title = "選擇站點",
    this.initialSelection,
  });

  @override
  State<StationPickerDialog> createState() => _StationPickerDialogState();
}

class _StationPickerDialogState extends State<StationPickerDialog> {
  late List<dynamic> _filteredStops;
  dynamic _tempSelected;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredStops = widget.stations;
    _tempSelected = widget.initialSelection;
  }

  void _runFilter(String query) {
    setState(() {
      _filteredStops = widget.stations
          .where((stop) => stop["StopName"]["Zh_tw"]
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.zero,
      title: _buildHeader(),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 12),
            _buildStationList(),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: _buildActions(),
    );
  }

  // 1. 美化標題區
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // 2. 美化搜尋框
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _runFilter,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.text_617,
        prefixIcon: const Icon(Icons.search, color: Colors.blue),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () {
            _searchController.clear();
            _runFilter('');
          },
        )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 3. 美化列表
  Widget _buildStationList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: _filteredStops.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredStops.length,
        itemBuilder: (context, index) {
          final station = _filteredStops[index];
          final String name = station["StopName"]["Zh_tw"];
          final bool isSelected = _tempSelected == station;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              onTap: () => setState(() => _tempSelected = station),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isSelected ? Colors.blue.shade50 : Colors.transparent,
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade800 : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(AppLocalizations.of(context)!.text_618, style: const TextStyle(color: Colors.grey)),
    );
  }

  // 4. 操作按鈕
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context)!.text_36, style: TextStyle(color: Colors.grey.shade600)),
      ),
      ElevatedButton(
        onPressed: _tempSelected == null
            ? null
            : () => Navigator.pop(context, _tempSelected),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(AppLocalizations.of(context)!.text_619),
      ),
    ];
  }
}