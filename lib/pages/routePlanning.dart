import 'dart:convert';
import 'package:flutter/material.dart';
import '../Const/regularConst.dart';
import '../database/getData.dart';
import '../database/schedule.dart';

class RoutePlanner extends StatefulWidget {
  @override
  _RoutePlannerState createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner>  with SingleTickerProviderStateMixin{
  // 基础数据
  List<String> transportModes = ['火車', '高鐵', '捷運', '公車', '飛機', '客運', 'Ubike'];
  String selectedTransport = '公車';

  // 城市数据
  List<String> cities = ['台北市', '新北市', '臺中市'];
  String selectedCity = '臺中市';

  // 公车数据
  ValueNotifier<List<Map<String, dynamic>>> busRoutesNotifier = ValueNotifier([]);
  String? selectedRoute;
  // TabController 用來監聽當前的 Tab
  late TabController tabController;
  // 站点数据
  Map<String, List<String>> busStopsByRoute = {
    '101路': ['市政府站', '101大樓', '信義安和'],
    '202路': ['台北車站', '士林夜市', '劍潭站'],
    '33路': ['中山國中', '松山機場', '圓山飯店'],
  };

// 站点选择
  String? selectedDepartureStation; // 当前选择的出发站
  String? selectedArrivalStation; // 当前选择的到达站
String? selectDirection;
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
      List result = await mysqlSelect("SELECT RouteName,RouteID FROM Bus.Bus_Taichung_Route;");

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
      selectedCity;
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
                  const Text('選擇站牌', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '搜尋站牌',
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
                  child: const Text('關閉'),
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
      padding: const EdgeInsets.all(16.0),
      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: busRoutesNotifier,
        builder: (context, busRoutes, child) {
          if (busRoutes.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 城市选择
              const Text('選擇城市', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCity,
                onChanged: (String? newCity) {
                  setState(() {
                    selectedCity = newCity!;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 路线选择
              const Text('選擇路線', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  showRoutePicker();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedRoute ?? '請選擇路線',
                      style: const TextStyle(color: Colors.black),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 出發站选择
              if (selectedRoute != null) ...[
                const Text('選擇出發站', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    showStationPicker("departure");
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDepartureStation ?? '請選擇出發站',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 到达站选择
              if (selectedDepartureStation != null) ...[
                const Text('選擇到達站', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    showStationPicker2();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedArrivalStation ?? '請選擇到達站',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 确认按钮
              if (selectedDepartureStation != null && selectedArrivalStation != null) ...[
                ElevatedButton(
                  onPressed: () {
                    // 确认按钮逻辑，执行所需的操作
                   confirmRouteSelection(selectedCity,selectedRoute!,selectedDepartureStation!,selectedArrivalStation!);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('確認'),
                ),
              ],
            ],
          );







        },
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

  void showStationPicker2( ) async {
    // 查詢路線和站點信息
    var routeQuery = await mysqlSelect(
      "SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$selectedRoute';",
    );
    var stopsQuery = await mysqlSelect(
      "SELECT Stops FROM Bus.Bus_Taichung WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$selectedRoute';",
    );
    if(selectDirection=="arrival"){

    }else if(selectDirection=='departure'){

    }
    // 路線方向信息
   late  List<dynamic> departureStops;
    if(routeDepartureStation== routeQuery[0]["DepartureStopNameZh"]){
      try {
        // 尝试解析 stopsQuery[1]["Stops"]
        departureStops = json.decode(stopsQuery[1]["Stops"]);
      } catch (e) {
        // 如果解析 stopsQuery[1]["Stops"] 失败，则使用 stopsQuery[0]["Stops"]
        print("解析 stopsQuery[1][\"Stops\"] 失败: $e");
        departureStops = json.decode(stopsQuery[0]["Stops"]);
      }
    }else   if(routeDepartureStation== routeQuery[0]["DestinationStopNameZh"]){
      departureStops = json.decode(stopsQuery[0]["Stops"]);
    }
    List<String> routeInfo = [
      routeQuery[0]["DepartureStopNameZh"],
      routeQuery[0]["DestinationStopNameZh"],
    ];

    // 初始站點列表



    // 搜尋結果
    ValueNotifier<List<dynamic>> filteredDepartureStops = ValueNotifier(departureStops);


    // 選擇的站點
    String? selected;




    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '選擇站點',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 10),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child:
                        // 第一個 Tab (出發站)
                        Column(
                          children: [
                            _buildSearchBox(
                              onSearch: (query) {
                                filteredDepartureStops.value = departureStops
                                    .where((stop) => stop["StopName"]["Zh_tw"]
                                    .toString()
                                    .contains(query))
                                    .toList();
                              },
                            ),
                            Expanded(
                              child: ValueListenableBuilder<List<dynamic>>(
                                valueListenable: filteredDepartureStops,
                                builder: (context, stops, _) {
                                  return _buildStationList(
                                    stops: stops,
                                    onStationSelected: (station) {
                                      selected = station;
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        // 第二個 Tab (到達站)


                  ),
                ],
              ),

          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('確認', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );




      setState(() {
        if (selected != null) selectedArrivalStation = selected!;
        // routeDepartureStation=  routeQuery[0]["DestinationStopNameZh"];
        // routeArrivalStation=  routeQuery[0]["DepartureStopNameZh"];
        //
        // selectDirection='arrival';
      });

  }
  void showStationPicker(String type) async {
    // 查詢路線和站點信息
    var routeQuery = await mysqlSelect(
      "SELECT * FROM Bus.Bus_Taichung_Route WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$selectedRoute';",
    );
    var stopsQuery = await mysqlSelect(
      "SELECT Stops FROM Bus.Bus_Taichung WHERE JSON_UNQUOTE(JSON_EXTRACT(RouteName, '\$.Zh_tw')) = '$selectedRoute';",
    );

    // 路線方向信息
    List<String> routeInfo = [
      routeQuery[0]["DepartureStopNameZh"],
      routeQuery[0]["DestinationStopNameZh"],
    ];

    // 初始站點列表
    List<dynamic> departureStops = [];
    List<dynamic> arrivalStops = json.decode(stopsQuery[0]["Stops"]);
    try {
      // 尝试解析 stopsQuery[1]["Stops"]
      departureStops = json.decode(stopsQuery[1]["Stops"]);
    } catch (e) {
      // 如果发生错误，尝试解析 stopsQuery[0]["Stops"]
      departureStops = json.decode(stopsQuery[0]["Stops"]);
    }
    // 搜尋結果
    ValueNotifier<List<dynamic>> filteredDepartureStops = ValueNotifier(departureStops);
    ValueNotifier<List<dynamic>> filteredArrivalStops = ValueNotifier(arrivalStops);

    // 選擇的站點
    String? selected;
    String? selectedArrival;



    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '選擇站點',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: DefaultTabController(
              length: 2,
              initialIndex: tabController.index,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabBar(routeInfo),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: TabBarView(
                      controller: tabController, // 關聯 TabController
                      children: [
                        // 第一個 Tab (出發站)
                        Column(
                          children: [
                            _buildSearchBox(
                              onSearch: (query) {
                                filteredDepartureStops.value = departureStops
                                    .where((stop) => stop["StopName"]["Zh_tw"]
                                    .toString()
                                    .contains(query))
                                    .toList();
                              },
                            ),
                            Expanded(
                              child: ValueListenableBuilder<List<dynamic>>(
                                valueListenable: filteredDepartureStops,
                                builder: (context, stops, _) {
                                  return _buildStationList(
                                    stops: stops,
                                    onStationSelected: (station) {
                                      selected = station;
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        // 第二個 Tab (到達站)
                        Column(
                          children: [
                            _buildSearchBox(
                              onSearch: (query) {
                                filteredArrivalStops.value = arrivalStops
                                    .where((stop) => stop["StopName"]["Zh_tw"]
                                    .toString()
                                    .contains(query))
                                    .toList();
                              },
                            ),
                            Expanded(
                              child: ValueListenableBuilder<List<dynamic>>(
                                valueListenable: filteredArrivalStops,
                                builder: (context, stops, _) {
                                  return _buildStationList(
                                    stops: stops,
                                    onStationSelected: (station) {
                                      selected = station;
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('確認', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    // 根據選擇的 Tab 和類型設置對應的站點
    String selectedTab = tabController.index == 0 ? 'A' : 'B';

    if (selectedTab == "A") {
      setState(() {
        if (selected != null) {
          selectedDepartureStation = selected!;
          routeDepartureStation=  routeQuery[0]["DepartureStopNameZh"];
          routeArrivalStation=  routeQuery[0]["DestinationStopNameZh"];


        }
      });
    } else if (selectedTab == "B") {
      setState(() {
        if (selected != null) selectedDepartureStation = selected!;
        routeDepartureStation=  routeQuery[0]["DestinationStopNameZh"];
        routeArrivalStation=  routeQuery[0]["DepartureStopNameZh"];

      });
    }
  }


// 構建搜索框
  Widget _buildSearchBox({required Function(String) onSearch}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: '搜尋站點',
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
                  const Text('選擇路線', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: '搜尋路線',
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
                  child: const Text('關閉'),
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
          title: Text('選擇類別'),
          content: Text('將路線 $route 添加到以下類別:'),
          actions: [
            TextButton(
              onPressed: () {
                // 添加到旅行逻辑
                Navigator.pop(context); // 关闭对话框
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('路線 $route 已添加到旅行')),
                );
              },
              child: Text('添加到旅行'),
            ),
            TextButton(
              onPressed: () async {
                // 添加到通勤逻辑
                Navigator.pop(context); // 关闭对话框

                final schedule _schedule = schedule();
                final result = await _schedule.addSchedule(
                    city: city,
                    UserStartingStopName: Departure,
                    UserDestinationStopName: DestinationS,
                    StartingStopName:routeDepartureStation,
                    FinalStopName:routeArrivalStation,
                    route: route, type: 'bus',
                     other:RouteID
                );

// 根据 addSchedule 方法返回的结果进行处理
                if (result == -1) {
                  // 如果已经存在相同的记录，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('該行程已經存在。'))
                  );
                } else if (result == 100) {
                  // 成功添加行程，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('行程添加成功！'))
                  );
                } else {
                  // 添加行程失败，提示用户
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('添加行程失敗。'))
                  );
                }
              },
              child: Text('添加到上班通勤'),
            ),
          ],
        );
      },
    );
  }
}
