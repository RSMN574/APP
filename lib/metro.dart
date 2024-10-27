import 'dart:convert';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'Const/regularClass.dart';
import 'Const/regularConst.dart';
import 'database/getData.dart';

class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro>with TickerProviderStateMixin {
  late TabController _tabController;

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

  String _selectedCity = "臺北市"; // 默认选项
  late MRTGreenLinePainter _mrtGreenLinePainter; // 用于保存画布绘制器

  @override
  void initState() {
    super.initState();
    _mrtGreenLinePainter = MRTGreenLinePainter(); // 实例化
    String currentCity = Provider.of<CityProvider>(context, listen: false).city;
     _tabController = TabController(length: 2, vsync: this ); // 现在有两个标签页
    // 检查 currentCity 是否在 _list 中
    if (_list.contains(currentCity)) {
      _selectedCity = currentCity; // 正确赋值
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("捷運")),
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
                _buildTabBar(),
                Expanded(child: _buildPageView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) => _buildTabItem(index),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              current = index;
            });
            pageController.animateToPage(
              current,
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(5),
            width: 100,
            height: 55,
            decoration: BoxDecoration(
              color: current == index ? Colors.white70 : Colors.white54,
              borderRadius: BorderRadius.circular(current == index ? 12 : 7),
              border: current == index ? Border.all(color: busBlue, width: 2.5) : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: current == index ? 23 : 20,
                    color: current == index ? Colors.black : Colors.grey.shade400,
                  ),
                  Text(items[index]),
                ],
              ),
            ),
          ),
        ),
        if (current == index)
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: busBlue,
              shape: BoxShape.circle,
            ),
          ),
      ],
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
                    child:GestureDetector(
                  onTapDown: (details) {
                    Offset localPosition = details.localPosition;
                    int stationIndex = _mrtGreenLinePainter.getStationIndexAtOffset(localPosition);

                    if (stationIndex != -1) {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(

                              width: MediaQuery.of(context).size.width, // 适应屏幕宽度

                              child:
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _mrtGreenLinePainter.stationInfos[stationIndex].name,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(_mrtGreenLinePainter.stationInfos[stationIndex].englishName),
                                SizedBox(height: 8),
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
                            SizedBox(
                              height: 300, // 固定高度
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildStationInfo(_mrtGreenLinePainter.stationInfos[stationIndex].name),  // 车站资讯内容
                                  _buildTransferInfo(), // 转乘资讯内容
                                ],
                              )),
                              ],
                            ),
                          )



                          );
                        }
                      );
                    }
                  },
                  child: CustomPaint(
                    size: Size(300, 1500),
                    painter: _mrtGreenLinePainter,
                  ),
                ));
              } else {
                return Text("車站");
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

  // 根据选中的城市返回不同的 Widget
  Widget _buildCityText(String city) {
    String imageUrl;
    switch (city) {
      case "臺北市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/TRTC_map.jpg?raw=true";
        break;
      case "桃園市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/TYMC_map.jpg?raw=true";
        break;
      case "臺中市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/TMRT_map.jpg?raw=true";
        break;
      case "高雄市":
        imageUrl = "https://github.com/RSMN574/assets/blob/main/KMRT_map.jpg?raw=true";
        break;
      default:
        return const Text("未知的城市");
    }

    return FutureBuilder<Image>(
      future: _loadImage(imageUrl),
      builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.stretchedDots(
              color: Colors.black,
              size: 40,
            ),
          ); // 加载时显示进度指示器
        } else if (snapshot.hasError) {
          return const Text("加载失败"); // 显示加载错误
        } else {
          return InteractiveViewer(
            child: snapshot.data!,
          ); // 显示加载的图像
        }
      },
    );
  }

  // 加载图像的 Future
  Future<Image> _loadImage(String url) async {
    final image = Image.network(url);
    await precacheImage(image.image, context); // 预加载图像
    return image;
  }
// 車站資訊頁面
  Widget _buildStationInfo(String station) {
    return FutureBuilder(
      future: _getStationInfo(station), // 异步获取车站信息
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // 显示加载进度条
        } else if (snapshot.hasError) {
          return const Text("出错了，无法加载车站信息"); // 显示错误信息
        } else if (snapshot.hasData) {
          var stationInfo = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: stationInfo?.length, // 列表项数量
              itemBuilder: (context, index) {
                final station = stationInfo?[index]; // 获取当前车站的信息
                return ListTile(
                  title: Text(json.decode(station["ExitName"])["Zh_tw"]), // 显示车站名称
                  leading: Row(
                    mainAxisSize: MainAxisSize.min, // 确保图标不会占用过多空间
                    children: [
                      if (int.parse(station["Stair"]) == 1)
                        const Icon(Icons.stairs, color: Colors.blue), // 楼梯图标
                      if (int.parse(station["Elevator"]) == 1)
                        const Icon(Icons.elevator, color: Colors.green), // 电梯图标
                      if (int.parse(station["Escalator"]) == 1)
                        const Icon(Icons.escalator, color: Colors.orange), // 手扶梯图标
                    ],
                  ),

                  onTap: () {
                    // 点击车站时执行的操作
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('点击了 ${station.exitNameZh}')),
                    );
                  },
                );
              },
            ),
          );

        } else {
          return const Text("未找到任何车站信息");
        }
      },
    );
  }

// 异步获取车站信息
  Future<List> _getStationInfo(String station) async {
    // 这里需要添加数据库查询的实际代码
    var result = await mysqlSelect(
        "SELECT * FROM MRT.MRT_taichung_stationExit WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw'))='$station'"
    );
print(result is List);
 
      // 假设你想展示 stationname_zh_tw 和一些其他信息

      return result;

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
    StationInfo('高鐵台中站', 'HSR Taichung Station'),
  ];

  final List<Offset> stationOffsets = [];

  MRTGreenLinePainter() {
    double startY = 50; // 起始Y轴位置
    double stationGap = 100; // 每个站点之间的间距

    // 根据站点数量计算垂直分布
    for (int i = 0; i < stationInfos.length; i++) {
      stationOffsets.add(Offset(150, startY + i * stationGap)); // 固定 X 轴位置
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
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint stationInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 绘制捷运的绿线
    for (int i = 0; i < stationOffsets.length - 1; i++) {
      canvas.drawLine(stationOffsets[i], stationOffsets[i + 1], linePaint);
    }

    // 绘制站点圆角矩形
    for (int i = 0; i < stationOffsets.length; i++) {
      Offset station = stationOffsets[i];
      // 绘制外层圆角矩形
      RRect outerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: station, width: 60, height: 30),
        Radius.circular(8),
      );
      canvas.drawRRect(outerRect, stationBorderPaint);

      // 绘制内层圆角矩形
      RRect innerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: station, width: 56, height: 26),
        Radius.circular(6),
      );
      canvas.drawRRect(innerRect, stationInnerPaint);

      // 绘制站点名称
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: stationInfos[i].name,
          style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(station.dx + 40, station.dy - 10));

      // 绘制站点英文名称
      TextPainter englishTextPainter = TextPainter(
        text: TextSpan(
          text: stationInfos[i].englishName,
          style: TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      englishTextPainter.layout();
      englishTextPainter.paint(canvas, Offset(station.dx + 40, station.dy + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  // 根据触摸坐标判断是否点击在车站上
  int getStationIndexAtOffset(Offset offset) {
    for (int i = 0; i < stationOffsets.length; i++) {
      if ((offset.dx >= stationOffsets[i].dx - 30) &&
          (offset.dx <= stationOffsets[i].dx + 30) &&
          (offset.dy >= stationOffsets[i].dy - 15) &&
          (offset.dy <= stationOffsets[i].dy + 15)) {
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
