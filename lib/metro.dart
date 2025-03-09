import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'Const/regularClass.dart';
import 'database/getData.dart';

ValueNotifier<List<dynamic>> facilitiesNotifier = ValueNotifier([]);

class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro> with TickerProviderStateMixin {
  late TabController _tabController;
  var data;

  final List<String> items = [
    "車站",
    "路線圖",
  ];
  final List<String> id = [
    "station",
    "map",
  ];
  final List<IconData> icons = [
    Icons.subway,
    Icons.map,
  ];
  int current = 0;
  final PageController pageController = PageController();
  final List<String> _list = [
    "臺北市",
    "桃園市",
    "臺中市",
    "高雄市",
  ];
  int selectedIndex = -1; // 選中的站點索引
  String _selectedCity = "臺北市"; // 默认选项
  late MRTGreenLinePainter _mrtGreenLinePainter; // 用于保存画布绘制器

  @override
  void initState() {
    super.initState();
    _mrtGreenLinePainter = MRTGreenLinePainter(); // 实例化
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;
    _tabController = TabController(length: 2, vsync: this); // 现在有两个标签页
    // 检查 currentCity 是否在 _list 中
    if (_list.contains(currentCity)) {
      _selectedCity = currentCity; // 正确赋值
    }
  }

  fetchData() async {
    data = await mysqlSelect("SELECT * FROM MRT.MRT_taichung_S2STravelTime;");
    return;
  }

// 返回每个隐藏的菜单项
  SelectView(IconData icon, String text, String id) {
    return PopupMenuItem<String>(
        value: id,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon),
            Text(text),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("捷運"),
        actions: [
          PopupMenuButton<String>(
              iconColor: Colors.black,
              itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    SelectView(Icons.info, '捷運資訊', 'A'),
                    SelectView(Icons.airplane_ticket, '車票', 'B'),
                    SelectView(Icons.schedule, '發車時刻表', 'C'),
                  ],
              onSelected: (String action) async {})
        ],
      ),
      body: Column(
        children: [
          CustomDropdown<String>(
            hintText: '選擇城市',
            items: _list,
            initialItem: _selectedCity,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCity = value; // 更新选中的城市
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                // _buildTabBar(),
                Expanded(child: _buildPageView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      width: double.infinity,
      child: PageView.builder(
        itemCount: items.length,
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          switch (id[index]) {
            case "station":
              if (_selectedCity == "臺中市") {
                return SingleChildScrollView(
                    child: Container(
                  margin: EdgeInsets.only(bottom: 500),
                  child: GestureDetector(
                    onTapDown: (details) {
                      Offset localPosition = details.localPosition;
                      int stationIndex = _mrtGreenLinePainter
                          .getStationIndexAtOffset(localPosition);

                      if (stationIndex != -1) {
                        showBottomSheet(
                          context: context,
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.4, // 初始高度比例
                              minChildSize: 0.3, // 最小高度比例
                              maxChildSize: 0.8, // 最大高度比例
                              expand: false, // 防止内容展开
                              builder: (BuildContext context,
                                  ScrollController scrollController) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // 拖动提示线
                                      SingleChildScrollView(
                                        controller:
                                            scrollController, // 使用 ScrollController 使内容可以滚动
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 4, // 提示线高度
                                              width: 40, // 提示线宽度
                                              decoration: BoxDecoration(
                                                color: Colors.grey, // 提示线颜色
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        2), // 圆角
                                              ),
                                              margin: const EdgeInsets.only(
                                                  bottom: 8), // 提示线与内容之间的间距
                                            ),
                                            Text(
                                              _mrtGreenLinePainter
                                                  .stationInfos[stationIndex]
                                                  .name,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(_mrtGreenLinePainter
                                                .stationInfos[stationIndex]
                                                .englishName),
                                            const SizedBox(height: 8),
                                            TabBar(
                                              controller: _tabController,
                                              labelColor: Colors.black,
                                              unselectedLabelColor: Colors.grey,
                                              indicatorColor: Colors.blue,
                                              tabs: const [
                                                Tab(text: "車站資訊"),
                                                Tab(text: "轉乘資訊"),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                            // 将车站信息和转乘信息作为子项传入
                                            SingleChildScrollView(
                                              controller: scrollController,
                                              child: buildStationInfo(
                                                  _mrtGreenLinePainter
                                                      .stationInfos[
                                                          stationIndex]
                                                      .name),
                                            ),
                                            SingleChildScrollView(
                                              controller: scrollController,
                                              child: _buildTransferInfo(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                    child: CustomPaint(
                      size: Size(300, 1500),
                      painter: _mrtGreenLinePainter,
                    ),
                  ),
                ));
              } else {
                return _buildCityText(_selectedCity);
              }
            case "map":
              return _buildCityText(_selectedCity);
            default:
              return const Center(child: Text("Unknown"));
          }
        },
      ),
    );
  }

  Widget taichungMRT() {
    return SingleChildScrollView(
        child: GestureDetector(
      onTapDown: (details) {
        late int stationIndex;
        setState(() {
          // 判斷點擊到哪個站點
          selectedIndex = MRTGreenLinePainter()
              .getStationIndexAtOffset(details.localPosition);
          Offset localPosition = details.localPosition;
          stationIndex =
              _mrtGreenLinePainter.getStationIndexAtOffset(localPosition);
        });

        if (stationIndex != -1) {
          showBottomSheet(
            context: context,
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.4, // 初始高度比例
                minChildSize: 0.3, // 最小高度比例
                maxChildSize: 0.8, // 最大高度比例
                expand: false, // 防止内容展开
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 拖动提示线
                        SingleChildScrollView(
                          controller:
                              scrollController, // 使用 ScrollController 使内容可以滚动
                          child: Column(
                            children: [
                              Container(
                                height: 4, // 提示线高度
                                width: 40, // 提示线宽度
                                decoration: BoxDecoration(
                                  color: Colors.grey, // 提示线颜色
                                  borderRadius: BorderRadius.circular(2), // 圆角
                                ),
                                margin: const EdgeInsets.only(
                                    bottom: 8), // 提示线与内容之间的间距
                              ),
                              Text(
                                _mrtGreenLinePainter
                                    .stationInfos[stationIndex].name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(_mrtGreenLinePainter
                                  .stationInfos[stationIndex].englishName),
                              const SizedBox(height: 8),
                              TabBar(
                                controller: _tabController,
                                labelColor: Colors.black,
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Colors.blue,
                                tabs: const [
                                  Tab(text: "車站資訊"),
                                  Tab(text: "轉乘資訊"),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // 将车站信息和转乘信息作为子项传入
                              SingleChildScrollView(
                                controller: scrollController,
                                child: buildStationInfo(_mrtGreenLinePainter
                                    .stationInfos[stationIndex].name),
                              ),
                              SingleChildScrollView(
                                controller: scrollController,
                                child: _buildTransferInfo(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        }
      },
      child: CustomPaint(
        size: const Size(300, 2000), // 自定义画布大小
        painter: MRTGreenLinePainter(),
      ),
    ));
  }

  // 根据选中的城市返回不同的 Widget
  Widget _buildCityText(String city) {
    String imageUrl;
    switch (city) {
      case "臺北市":
        imageUrl =
            "https://github.com/RSMN574/assets/blob/main/TRTC_map.jpg?raw=true";
        break;
      case "桃園市":
        imageUrl =
            "https://github.com/RSMN574/assets/blob/main/TYMC_map.jpg?raw=true";
        break;
      case "臺中市":
        imageUrl =
            "https://github.com/RSMN574/assets/blob/main/TMRT_map.jpg?raw=true";
        break;
      case "高雄市":
        imageUrl =
            "https://github.com/RSMN574/assets/blob/main/KMRT_map.jpg?raw=true";
        break;
      default:
        return const Text("未知的城市");
    }

    return FutureBuilder<Image>(
      future: _loadCachedImage(imageUrl),
      builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),
          ); // 加载时显示进度指示器
        } else if (snapshot.hasError) {
          return const Text("載入失敗"); // 显示加载错误
        } else {
          return InteractiveViewer(
            child: snapshot.data!,
          ); // 显示加载的图像
        }
      },
    );
  }

  // 加载并缓存图像的 Future
  Future<Image> _loadCachedImage(String url) async {
    final cacheManager = DefaultCacheManager();
    final file = await cacheManager.getSingleFile(url);
    final image = Image.file(file);
    await precacheImage(image.image, context); // Preload the image
    return image;
  }

  // 轉乘資訊頁面
  Widget _buildTransferInfo() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        "這裡顯示車站的轉乘資訊，包括可以轉乘的其他交通工具或路線。",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// 异步获取车站信息
Future<List> _getStationInfo(String station) async {
  // 这里需要添加数据库查询的实际代码
  var stationExit = await mysqlSelect(
      "SELECT * FROM MRT.MRT_taichung_stationExit WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw'))='$station'");

  var i = (await mysqlSelect(
      "SELECT info FROM MRT.MRT_Taichung_station WHERE StationNameZh_tw ='$station'"));
  print(json.decode(i[0]["info"]) is List);
  try {
    facilitiesNotifier.value = json.decode(i[0]["info"]);
  } catch (e) {
    print(e);
  }

  // 假设你想展示 stationname_zh_tw 和一些其他信息

  return stationExit;
}

// 車站資訊頁面
Widget buildStationInfo(String station) {
  IconData getIcon(String iconName) {
    switch (iconName) {
      case 'Inquiry Desk Icon':
        return Icons.info;
      case 'ATM Icon':
        return Icons.atm;
      case 'Water Fountain Icon':
        return Icons.water;
      case 'Restroom Icon':
        return Icons.wc;
      case 'AEDA Icon':
        return Icons.favorite; // 可替换为更适合的图标
      case 'Accessible Elevator Icon':
        return Icons.elevator;
      default:
        return Icons.help; // 默认图标
    }
  }

  return FutureBuilder(
    future: _getStationInfo(station), // 异步获取车站信息
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: LoadingAnimationWidget.stretchedDots(
            color: Colors.black,
            size: 40,
          ),
        ); // 显示加载进度条
      } else if (snapshot.hasError) {
        return const Text("無法載入車站資訊"); // 显示错误信息
      } else if (snapshot.hasData) {
        var stationI = snapshot.data;
        return SingleChildScrollView(
          child: Column(
            children: [
              // 使用 Expanded 包裹 ListView 以便滚动
              ListView.builder(
                itemCount: stationI?.length, // 列表项数量
                physics:
                    const NeverScrollableScrollPhysics(), // 禁用 ListView 的滚动
                shrinkWrap: true, // 让 ListView 根据内容的高度收缩
                itemBuilder: (context, index) {
                  final station = stationI?[index]; // 获取当前车站的信息
                  return ListTile(
                    title: Text(
                      json.decode(station["ExitName"])["Zh_tw"], // 显示车站名称
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min, // 确保图标不会占用过多空间
                      children: [
                        if (int.parse(station["Stair"]) == 1)
                          const Icon(Icons.stairs, color: Colors.blue), // 楼梯图标
                        if (int.parse(station["Elevator"]) == 1)
                          const Icon(Icons.elevator,
                              color: Colors.green), // 电梯图标
                        if (int.parse(station["Escalator"]) == 1)
                          const Icon(Icons.escalator,
                              color: Colors.orange), // 手扶梯图标
                      ],
                    ),
                    onTap: () {
                      // 点击车站时执行的操作
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '点击了 ${json.decode(station["ExitName"])["Zh_tw"]}'),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20), // 增加间距使布局更清晰

              // 车站设施表格
              const Text(
                "車站設施",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10), // 表格标题与表格之间的间距

              DataTable(
                columnSpacing: 30,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                dataRowHeight: 60,
                columns: const [
                  DataColumn(label: Text('Icon')),
                  DataColumn(label: Text('Facility')),
                  DataColumn(label: Text('Location')),
                ],
                rows: facilitiesNotifier.value.map((facility) {
                  return DataRow(cells: [
                    DataCell(Icon(
                      getIcon(facility['icon']),
                      color: Colors.black54,
                      size: 24,
                    )),
                    DataCell(Text(facility['facility'])),
                    DataCell(Text(facility['location'])),
                  ]);
                }).toList(),
              ),
            ],
          ),
        );
      } else {
        return const Text("未找到任何車站資訊");
      }
    },
  );
}

class MRTGreenLinePainter extends CustomPainter {
  final List<StationInfo> stationInfos = [
    StationInfo('北屯總站', 'Beitun Main Station'),
    StationInfo('舊社', 'Jiushe'),
    StationInfo('松竹', 'Songzhu'),
    StationInfo('四維國小', 'Sihwei Elementary School\n(Erfenpu)'),
    StationInfo('文心崇德', 'Wenxin Chongde'),
    StationInfo('文心中清', 'Wenxin Zhongqing\n(Tianjin Shopping District)'),
    StationInfo('文華高中', 'Wenhua Senior High School'),
    StationInfo('文心櫻花', 'Wenxin Yinghua'),
    StationInfo('市政府', 'Taichung City Hall'),
    StationInfo('水安宮', 'Shui-an Temple'),
    StationInfo('文心森林公園', 'Wenxin Forest Park'),
    StationInfo('南屯', 'Nantun (Wenxin Wuquan W.)'),
    StationInfo('豐樂公園', 'Feng-le Park'),
    StationInfo('大慶', 'Daqing\n(Chungshan Medical University)'),
    StationInfo('九張犁', 'Jiuzhangli'),
    StationInfo('九德', 'Jiude'),
    StationInfo('烏日', 'Wuri'),
    StationInfo('高鐵臺中站', 'HSR Taichung Station'),
  ];

  final List<Offset> stationOffsets = [];
  final int selectedStationIndex;

  MRTGreenLinePainter({this.selectedStationIndex = -1}) {
    double startY = 50; // 起始Y轴位置
    double stationGap = 100; // 每个站点之间的间距

    for (int i = 0; i < stationInfos.length; i++) {
      stationOffsets.add(Offset(150, startY + i * stationGap));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint stationBorderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Paint stationInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint selectedStationPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // 绘制捷运的绿线
    for (int i = 0; i < stationOffsets.length - 1; i++) {
      canvas.drawLine(stationOffsets[i], stationOffsets[i + 1], linePaint);
    }

    // 绘制站点圆形
    for (int i = 0; i < stationOffsets.length; i++) {
      Offset station = stationOffsets[i];

      // 外圆边框
      canvas.drawCircle(station, 12, stationBorderPaint);

      // 内圆填充（选中 or 未选中）
      if (i == selectedStationIndex) {
        // 点选时填满绿色
        canvas.drawCircle(station, 10, selectedStationPaint);
      } else {
        // 未选中填充白色
        canvas.drawCircle(station, 10, stationInnerPaint);
      }

      // 绘制站点名称
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: stationInfos[i].name,
          style: TextStyle(
              color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(station.dx + 30, station.dy - 10));

      // 绘制站点英文名称
      TextPainter englishTextPainter = TextPainter(
        text: TextSpan(
          text: stationInfos[i].englishName,
          style: TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      englishTextPainter.layout();
      englishTextPainter.paint(canvas, Offset(station.dx + 30, station.dy + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  // 根据触摸坐标判断是否点击在车站上
  int getStationIndexAtOffset(Offset offset) {
    for (int i = 0; i < stationOffsets.length; i++) {
      if ((offset - stationOffsets[i]).distance <= 12) {
        // 判断是否点击在圆形内
        return i;
      }
    }
    return -1; // 未点击到任何车站
  }
}

class StationInfo {
  final String name; // 车站中文名称
  final String englishName; // 车站英文名称

  StationInfo(this.name, this.englishName);
}
