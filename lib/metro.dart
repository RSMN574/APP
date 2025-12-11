import 'dart:collection';
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
  late List<Map<String, dynamic>> data;

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
    "臺中市測試版",
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



Future<void> _loadTravelTimeData() async {
  final data = await mysqlSelect(
      "SELECT * FROM MRT.MRT_Taichung_S2STravelTime;");

  TravelTimeHelper.load(data);

}

// 返回每個隱藏的菜單項 - 美化版本
  PopupMenuItem<String> _buildPopupMenuItem(IconData icon, String text, String id, Color color) {
    return PopupMenuItem<String>(
      value: id,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
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
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "捷運資訊",
          style: TextStyle(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Color(0xFF1A73E8),
                ),
              ),
              onPressed: _showInfoMenu, // 改為調用底部彈出菜單
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 城市選擇下拉框
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    underline: const SizedBox(),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Color(0xFF1A73E8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _list.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCity = value;
                        });
                      }
                    },
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Color(0xFF1A73E8),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Column(
              children: [
                // 水平 TabBar

                Expanded(child: _buildPageView()),
              ],
            ),
          ),
        ],
      ),

    );
  }

  void _showInfoMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // 限制最大高度
        ),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView( // 添加滾動支持
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),





              // 選項列表
              _buildMenuOption(
                icon: Icons.info_outline_rounded,
                title: '捷運資訊',
                subtitle: '查看捷運路線與資訊',
                color: const Color(0xFF1A73E8),
                onTap: _navigateToMRTInfo,
              ),
              const SizedBox(height: 12),
              _buildMenuOption(
                icon: Icons.confirmation_number_rounded,
                title: '車票資訊',
                subtitle: '票價與購票說明',
                color: const Color(0xFF34C759),
                onTap: _navigateToTicketInfo,
              ),
              const SizedBox(height: 12),
              _buildMenuOption(
                icon: Icons.schedule_rounded,
                title: '發車時刻表',
                subtitle: '查看列車發車時間',
                color: const Color(0xFFFF9500),
                onTap: _navigateToSchedule,
              ),
              const SizedBox(height: 12),
              _buildMenuOption(
                icon: Icons.help_outline_rounded,
                title: '使用說明',
                subtitle: '應用程式操作指南',
                color: const Color(0xFFAF52DE),
                onTap: _navigateToHelp,
              ),

              const SizedBox(height: 20),

              // 安全區域底部填充（可選）
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // 關閉底部菜單
          onTap(); // 執行對應的操作
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 圖標
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // 文字資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 導航箭頭
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// 對應的導航方法
  void _navigateToMRTInfo() {
    // 導航到捷運資訊頁面
    print('導航到捷運資訊');
  }

  void _navigateToTicketInfo() {
    // 導航到車票資訊頁面
    print('導航到車票資訊');
  }

  void _navigateToSchedule() {
    // 導航到發車時刻表頁面
    print('導航到發車時刻表');
  }

  void _navigateToHelp() {
    // 導航到使用說明頁面
    print('導航到使用說明');
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
              }
          else if(_selectedCity == "臺中市測試版") {
                _loadTravelTimeData();
          return const MetroMap(key:Key('Taichung'),city: 'Taichung',);
            }
              else if(_selectedCity == "臺北市") {

                return const MetroMap(key:Key('Taipei'),city: 'Taipei',);
              }


          else {
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
                expand: false,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 頂部拖拽指示器
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),

                        // 標題區域
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // 車站圖標和名稱
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.train_rounded,
                                      size: 20,
                                      color: Color(0xFF1A73E8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        // 車站名稱
                                        Text(
                                          _mrtGreenLinePainter.stationInfos[stationIndex].name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A73E8),
                                            letterSpacing: -0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        // 英文名稱
                                        Text(
                                          _mrtGreenLinePainter.stationInfos[stationIndex].englishName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

// TabBar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1A73E8).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1A73E8),
                                  Color(0xFF1A73E8), // 或改成透明 / 淺色
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A73E8).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorWeight: 0,
                            indicatorPadding: const EdgeInsets.all(4),
                            labelColor: Colors.white,
                            unselectedLabelColor: const Color(0xFF1A73E8),
                            labelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: MaterialStateProperty.all(Colors.transparent),
                            tabs: const [
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text("車站資訊"),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.transfer_within_a_station_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text("轉乘資訊"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 內容區域
                        Expanded(
                          child: Container(
                            // margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // 車站資訊頁面
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(16),
                                    child: buildStationInfo(
                                      _mrtGreenLinePainter.stationInfos[stationIndex].name,
                                    ),
                                  ),
                                ),
                                // 轉乘資訊頁面
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(16),
                                    child: _buildTransferInfo(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
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
  // 加载并缓存图像的 Future
  Future<Image> _loadCachedImage(String url) async {
    final cacheManager = DefaultCacheManager();
    final file = await cacheManager.getSingleFile(url);
    final image = Image.file(file);
    await precacheImage(image.image, context); // Preload the image
    return image;
  }


}

Future<List> _getStationInfo(String station) async {
  // 取得 stationExit
  var stationExit = await mysqlSelect(
      "SELECT * FROM MRT.MRT_Taichung_StationExit WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw'))='$station'"
  );

  // 查詢 info
  var i = await mysqlSelect(
      "SELECT info FROM MRT.MRT_Taichung_station WHERE StationNameZh_tw LIKE '%$station%'"
  );

  if (i.isEmpty) {
    print("⚠ 資料表中未找到站名：$station");
    facilitiesNotifier.value = [];  // 給預設空陣列避免 UI 爆掉
    return stationExit;
  }

  try {
    facilitiesNotifier.value = json.decode(i[0]["info"]);
  } catch (e) {
    print("❌ JSON decode 失敗：$e");
    facilitiesNotifier.value = [];
  }

  return stationExit;
}

// 獲取設施顏色
Color getFacilityColor(String iconName) {
  switch (iconName) {
    case 'Inquiry Desk Icon':
      return const Color(0xFF1A73E8);
    case 'ATM Icon':
      return const Color(0xFF34C759);
    case 'Water Fountain Icon':
      return const Color(0xFF007AFF);
    case 'Restroom Icon':
      return const Color(0xFFFF9500);
    case 'AEDA Icon':
      return const Color(0xFFAF52DE);
    case 'Accessible Elevator Icon':
      return const Color(0xFF5856D6);
    default:
      return const Color(0xFF8E8E93);
  }
}
// 車站資訊頁面
Widget buildStationInfo(String station) {



  // 獲取設施顏色
  Color _getFacilityColor(String iconName) {
    switch (iconName) {
      case 'Inquiry Desk Icon':
        return const Color(0xFF1A73E8);
      case 'ATM Icon':
        return const Color(0xFF34C759);
      case 'Water Fountain Icon':
        return const Color(0xFF007AFF);
      case 'Restroom Icon':
        return const Color(0xFFFF9500);
      case 'AEDA Icon':
        return const Color(0xFFAF52DE);
      case 'Accessible Elevator Icon':
        return const Color(0xFF5856D6);
      default:
        return const Color(0xFF8E8E93);
    }
  }
  return FutureBuilder(
    future: _getStationInfo(station),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.stretchedDots(
                  color: const Color(0xFF1A73E8),
                  size: 40,
                ),
                const SizedBox(height: 16),
                const Text(
                  '載入車站資訊中...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (snapshot.hasError) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF3B30).withOpacity(0.1),
                        const Color(0xFFFF3B30).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Color(0xFFFF3B30),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '無法載入車站資訊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (snapshot.hasData) {
        List<dynamic>? stationI = snapshot.data;

        return SingleChildScrollView(
          // padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 出口資訊卡片
              if (stationI != null && stationI.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 標題
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_rounded,
                                size: 20,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '車站出口資訊',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 出口列表
                      ...stationI.asMap().entries.map((entry) {
                        final index = entry.key;
                        final station = entry.value;
                        final isLast = index == stationI.length - 1;

                        return Container(
                          margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                          child: _buildExitCard(station, index, context),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              // 車站設施卡片
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_activity_rounded,
                              size: 20,
                              color: Color(0xFF34C759),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '車站設施',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 設施列表
                    ValueListenableBuilder<List< dynamic>>(
                      valueListenable: facilitiesNotifier,
                      builder: (context, facilities, _) {
                        if (facilities.isEmpty) {
                          return const SizedBox(); // 或 loading
                        }
                        return Column(
                          children: facilities.map((facility) {
                            final color = _getFacilityColor(facility['icon']);
                            return _buildFacilityCard(facility, color);
                          }).toList(),
                        );
                      },
                    ),
      const SizedBox(height: 16),
                    _buildMultiImageButton(context,json.decode(stationI ![0]["ExitMapURLs"]))

      ],
                ),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A73E8).withOpacity(0.1),
                        const Color(0xFF1A73E8).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 40,
                    color: Color(0xFF1A73E8),
                  ),
                ),

                const Text(
                  '未找到車站資訊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    },
  );
}
Widget _buildMultiImageButton(BuildContext context, List<dynamic> mapList) {
  if (mapList == null || mapList.isEmpty) {
    return const SizedBox.shrink();
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        _showMultiImageDialog(context, mapList);
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
      highlightColor: const Color(0xFFEEF3FB).withOpacity(0.5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFEEF3FB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.map_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '車站地圖',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mapList.length} 張地圖可供查看',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showMultiImageDialog(BuildContext context, List<dynamic> mapList) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),

        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題欄
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.map_rounded,
                    color: Color(0xFF1A73E8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '車站地圖',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 地圖列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: mapList.length,
                itemBuilder: (context, index) {
                  final mapData = mapList[index];
                  final mapUrl = mapData["MapURL"] as String?;
                  final mapName = mapData["MapName"]["Zh_tw"] as String?;
                  final floorLevel = mapData["FloorLevel"] as String?;

                  return _buildMapListItem(context, mapUrl, mapName, floorLevel, index);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
void _showImageDialog(BuildContext context, String imageUrl, String? title) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // 背景遮罩
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // 圖片容器
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),

              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題欄
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          color: Color(0xFF1A73E8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title ?? '圖片預覽',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A73E8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // 圖片內容
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 3,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFF1A73E8),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 40,
                                    color: Color(0xFFFF3B30),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '無法載入圖片',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF3B30),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'URL: $imageUrl',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildMapListItem(BuildContext context, String? imageUrl, String? mapName, String? floorLevel, int index) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (imageUrl != null) {
            Navigator.pop(context); // 關閉列表對話框
            _showImageDialog(context, imageUrl, mapName);
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 序號
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 地圖資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mapName ?? '未命名地圖',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (floorLevel != null && floorLevel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          floorLevel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
// 構建出口卡片
Widget _buildExitCard(dynamic station, int index, BuildContext context) {
  final exitName = json.decode(station["ExitName"])["Zh_tw"];
  final locationDescription = station["LocationDescription"] as String?;

  // 判斷設施是否存在
  final hasStair = station["Stair"] == 1 || station["Stair"] == true;
  final hasElevator = station["Elevator"] == 1 || station["Elevator"] == true;
  final hasEscalator = station["Escalator"] == 1;
  final hasFacilities = hasStair || hasElevator || hasEscalator;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('點擊了 $exitName'),
            backgroundColor: const Color(0xFF1A73E8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: const Color(0xFF1A73E8).withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 出口圖標
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),

            // 出口資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 出口名稱
                  Text(
                    exitName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  // 位置描述（如果有的話）
                  if (locationDescription != null && locationDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        locationDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 設施圖標
                  if (hasFacilities)
                    Row(
                      children: [
                        if (hasStair)
                          _buildFacilityIcon(Icons.stairs_rounded, '樓梯', const Color(0xFF1A73E8)),
                        if (hasElevator)
                          _buildFacilityIcon(Icons.elevator_rounded, '電梯', const Color(0xFF34C759)),
                        if (hasEscalator)
                          _buildFacilityIcon(Icons.escalator_rounded, '手扶梯', const Color(0xFFFF9500)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// 獲取設施圖標
IconData getIcon(String iconName) {
  switch (iconName) {
    case 'Inquiry Desk Icon':
      return Icons.info_outline_rounded;
    case 'ATM Icon':
      return Icons.atm_rounded;
    case 'Water Fountain Icon':
      return Icons.water_drop_rounded;
    case 'Restroom Icon':
      return Icons.wc_rounded;
    case 'AEDA Icon':
      return Icons.accessible_rounded;
    case 'Accessible Elevator Icon':
      return Icons.elevator_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}
// 構建設施卡片
Widget _buildFacilityCard(Map<String, dynamic> facility, Color color) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 處理設施點擊
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 設施圖標
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getIcon(facility['icon']),
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              // 設施資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility['facility'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      facility['location'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// 構建設施圖標
Widget _buildFacilityIcon(IconData icon, String label, Color color) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
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
// ValueNotifier<List<dynamic>> facilitiesNotifier = ValueNotifier([]);
class Pair<T1, T2> {
  final T1 a;
  final T2 b;

  Pair(this.a, this.b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Pair &&
              ((a == other.a && b == other.b) || (a == other.b && b == other.a));

  @override
  int get hashCode => a.hashCode ^ b.hashCode;
}
class Connection {
  final MRTStation station;
  final Color color;

  Connection(this.station, this.color);
}
class MRTStation {
  final String  stationId;
  final String name;
  final Offset relativePosition;
  List<Connection> connections;
  final Color lineColor;
  int? displayTime;

  MRTStation(
      this.stationId,
      this.name,
      this.relativePosition, {
        List<Connection>? connections,
        this.lineColor = Colors.blue,
        this.displayTime,
      }) : connections = connections ?? [];
}



class MetroMap extends StatefulWidget {
  final String city;

  const MetroMap({
    Key? key,          // 將 Key 放在這裡
    required this.city,
  }) : super(key: key); // 傳給父類別的 key

  @override
  _MetroMapScreenState createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMap>with TickerProviderStateMixin {
  late TabController _tabController;
  final TransformationController _transformationController = TransformationController();
  final double _stationRadius = 6.0;
  MRTStation? _selectedStation;
  Map<MRTStation, int> _timeMap = {};
  List<MRTStation> _stations = [];
  int selectedIndex = -1; // 選中的站點索引
  @override
  void initState() {
    super.initState();
    _initializeStations();
    _initConnections();
    _tabController = TabController(length: 2, vsync: this); // 现在有两个标签页
  }

  void _initializeStations() {
    final cityStationsData = <String, List<Map<String, dynamic>>>{
      'Taichung': [
        // 綠線
        {'id': '103a', 'name': '北屯總站', 'pos': Offset(0.5, 0.05), 'color': Colors.green},
        {'id': '103', 'name': '舊社', 'pos': Offset(0.5, 0.10), 'color': Colors.green},
        {'id': '104', 'name': '松竹', 'pos': Offset(0.5, 0.15), 'color': Colors.green},
        {'id': '105', 'name': '四維國小', 'pos': Offset(0.5, 0.20), 'color': Colors.green},
        {'id': '106', 'name': '文心崇德', 'pos': Offset(0.5, 0.25), 'color': Colors.green},
        {'id': '107', 'name': '文心中清', 'pos': Offset(0.5, 0.30), 'color': Colors.green},
        {'id': '108', 'name': '文華高中', 'pos': Offset(0.5, 0.35), 'color': Colors.green},
        {'id': '109', 'name': '文心櫻花', 'pos': Offset(0.5, 0.40), 'color': Colors.green},
        {'id': '110', 'name': '市政府', 'pos': Offset(0.5, 0.45), 'color': Colors.green},
        {'id': '111', 'name': '水安宮', 'pos': Offset(0.5, 0.50), 'color': Colors.green},
        {'id': '112', 'name': '文心森林公園', 'pos': Offset(0.5, 0.55), 'color': Colors.green},
        {'id': '113', 'name': '南屯', 'pos': Offset(0.5, 0.60), 'color': Colors.green},
        {'id': '114', 'name': '豐樂公園', 'pos': Offset(0.5, 0.70), 'color': Colors.green},
        {'id': '115', 'name': '大慶', 'pos': Offset(0.501, 0.75), 'color': Colors.green},
        {'id': '116', 'name': '九張犁', 'pos': Offset(0.45, 0.81), 'color': Colors.green},
        {'id': '117', 'name': '九德', 'pos': Offset(0.33, 0.85), 'color': Colors.green},
        {'id': '118', 'name': '烏日', 'pos': Offset(0.24, 0.85), 'color': Colors.green},
        {'id': '119', 'name': '高鐵台中站', 'pos': Offset(0.18, 0.85), 'color': Colors.green},
      ],
      'Taipei': [
        // 紅線淡水信義線
        {'id': 'R28', 'name': '淡水', 'pos': Offset(0.10, 0.05), 'color': Colors.red},
        {'id': 'R23', 'name': '北投', 'pos': Offset(0.18, 0.20), 'color': Colors.red},
        {'id': 'R17', 'name': '劍潭', 'pos': Offset(0.20, 0.30), 'color': Colors.red},
        {'id': 'R10', 'name': '台北車站', 'pos': Offset(0.45, 0.50), 'color': Colors.red},
        {'id': 'R05', 'name': '大安', 'pos': Offset(0.55, 0.65), 'color': Colors.red},
        {'id': 'R02', 'name': '象山', 'pos': Offset(0.60, 0.75), 'color': Colors.red},
        // 綠線松山新店線
        {'id': 'G03', 'name': '松山', 'pos': Offset(0.55, 0.10), 'color': Colors.green},
        {'id': 'G06', 'name': '南京復興', 'pos': Offset(0.55, 0.20), 'color': Colors.green},
        {'id': 'G10', 'name': '古亭', 'pos': Offset(0.50, 0.45), 'color': Colors.green},
        {'id': 'G17', 'name': '公館', 'pos': Offset(0.46, 0.65), 'color': Colors.green},
        {'id': 'G19', 'name': '新店', 'pos': Offset(0.45, 0.80), 'color': Colors.green},
        // 藍線板南線
        {'id': 'BL23', 'name': '南港展覽館', 'pos': Offset(0.90, 0.55), 'color': Colors.blue},
        {'id': 'BL19', 'name': '市政府', 'pos': Offset(0.75, 0.55), 'color': Colors.blue},
        {'id': 'BL12', 'name': '台北車站', 'pos': Offset(0.45, 0.50), 'color': Colors.blue},
        {'id': 'BL07', 'name': '龍山寺', 'pos': Offset(0.30, 0.45), 'color': Colors.blue},
        {'id': 'BL03', 'name': '板橋', 'pos': Offset(0.10, 0.45), 'color': Colors.blue},
      ],
    };

    final cityData = cityStationsData[widget.city] ?? [];
    _stations.clear();
    for (var s in cityData) {
      _stations.add(MRTStation(s['id'], s['name'], s['pos'], lineColor: s['color']));
    }
  }

  void _initConnections() {
    void connectStations(List<MRTStation> stations, Color color) {
      for (int i = 0; i < stations.length - 1; i++) {
        stations[i].connections.add(Connection(stations[i + 1], color));
        stations[i + 1].connections.add(Connection(stations[i], color));
      }
    }

    // 將 stations 按 lineColor 分組
    final Map<Color, List<MRTStation>> byLine = {};
    for (var s in _stations) {
      byLine.putIfAbsent(s.lineColor, () => []);
      byLine[s.lineColor]!.add(s);
    }

    byLine.forEach((color, stations) {
      if (stations.length > 1) connectStations(stations, color);
    });
  }

  Map<MRTStation, int> _calculateTimes(MRTStation station) {
    return TravelTimeHelper.calculateTimes(station, _stations);
  }


  void _updateSelectedStation(MRTStation station) {
    setState(() {
      _selectedStation = station;
      _timeMap = _calculateTimes(station);

      _stations.forEach((s) {
        // 將秒數轉換為分鐘（小數）
        final seconds = _timeMap[s];
        if (seconds == -1) {
          s.displayTime = -1; // 保持 -1 表示無法到達
        } else {
          s.displayTime = (seconds!/60).round(); // 轉為分鐘
        }
      });
    });


    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedStation != null) {
        showBottomSheet(
          context: context,
          builder: (context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: [
                            Container(
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                            ),
                            Text(
                              _selectedStation!.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
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
                            SingleChildScrollView(
                              controller: scrollController,
                              child:
                              buildStationInfo(_selectedStation!.name),
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
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.6,
          maxScale: 3.0,
          child: Container(

            width: 600,
            height: 600,
            child: GestureDetector(
              onTapUp: (details) {
                _handleTap(details);
              } ,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return CustomPaint(
                    painter: _MetroMapPainter(
                      stations: _stations,
                      selectedStation: _selectedStation,
                      stationRadius: _stationRadius,
                      canvasSize: canvasSize,
                    ),
                    child: Stack(
                      children: _stations
                          .map((station) => _buildStationDot(station, canvasSize))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_selectedStation != null)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.white,
              child: Text('當前選擇: ${_selectedStation!.name}'),
            ),
          ),
      ],
    );
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
  Widget _buildStationDot(MRTStation station, Size canvasSize) {
    final actualOffset = Offset(
      station.relativePosition.dx * canvasSize.width,
      station.relativePosition.dy * canvasSize.height,
    );

    return Positioned(
      left: actualOffset.dx - _stationRadius,
      top: actualOffset.dy - _stationRadius,
      child: GestureDetector(
        onTap: () {
          _updateSelectedStation(station);

        },
        child: Container(
          width: _stationRadius * 2,

          height: _stationRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final tapPosition = details.localPosition;
    final untransformedPosition = MatrixUtils.transformPoint(inverseMatrix, tapPosition);

    for (final station in _stations) {
      final dx = station.relativePosition.dx - untransformedPosition.dx;
      final dy = station.relativePosition.dy - untransformedPosition.dy;
      final distance = dx * dx + dy * dy;

      if (distance < _stationRadius * _stationRadius) {
        _updateSelectedStation(station);
        return;
      }
    }


  }

  void _showStationInfo(MRTStation station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('所屬路線: ${_getLineColorName(station.lineColor)}'),
            if (station.displayTime != null) Text('距離當前站: ${station.displayTime} 分鐘'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('關閉'),
          ),
        ],
      ),
    );
  }

  String _getLineColorName(Color color) {
    if (color == Colors.red) return '紅線';
    if (color == Colors.green) return '綠線';
    return '其他路線';
  }
}

class _MetroMapPainter extends CustomPainter {
  final List<MRTStation> stations;
  final MRTStation? selectedStation;
  final double stationRadius;
  final Size canvasSize;

  _MetroMapPainter({
    required this.stations,
    this.selectedStation,
    required this.stationRadius,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawnConnections = <Pair<MRTStation, MRTStation>>{};

    // 繪製連接線
    for (final station in stations) {
      for (final connection in station.connections) {
        final pair = Pair(station, connection.station);
        if (!drawnConnections.contains(pair)) {
          final paint = Paint()
            ..color = connection.color
            ..strokeWidth = 4.5
            ..style = PaintingStyle.stroke;

          final startPosition = _getAbsolutePosition(station.relativePosition, size);
          final endPosition = _getAbsolutePosition(connection.station.relativePosition, size);

          canvas.drawLine(startPosition, endPosition, paint);
          drawnConnections.add(pair);
        }
      }
    }

    // 繪製車站
    for (final station in stations) {
      _drawStation(canvas, station, size);
    }
  }

  Offset _getAbsolutePosition(Offset relativePosition, Size size) {
    final x = relativePosition.dx * size.width;
    final y = relativePosition.dy * size.height;
    return Offset(x, y);
  }

  void _drawStation(Canvas canvas, MRTStation station, Size size) {
    final isSelected = station == selectedStation;
    final position = _getAbsolutePosition(station.relativePosition, size);

    // 外圓
    final outerPaint = Paint()
      ..color = station.lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, stationRadius * 0.9, outerPaint);

    // 內圓（圓環邊框）
    const ringWidth = 1.5;
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, stationRadius * 0.9 - ringWidth, innerPaint);

    // 如果是選中的車站，繪製選中效果
    if (isSelected) {
      final selectedPaint = Paint()
        ..color = const Color(0xFFFF3B30).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, stationRadius * 1.2, selectedPaint);
    }

    // 繪製時間文字（如果有）
    if (station.displayTime != null) {
      final text = station.displayTime.toString();
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: stationRadius * 0.8,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final offset = Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }

    // 繪製車站名稱（在下方）
    if (station.name.isNotEmpty) {
      final namePainter = TextPainter(
        text: TextSpan(
          text: station.name,
          style: TextStyle(
            fontSize: stationRadius * 0.9, // 稍微放大字體
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();

      // 修正位置：在車站正下方
      final offset = Offset(
        position.dx - namePainter.width / 2, // 居中對齊
        position.dy + stationRadius * 1.2,  // 在車站下方
      );
      namePainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TravelTime {
  final String fromStationId;
  final String toStationId;
  final String id;
  final int runtime;   // 行駛秒數
  final int stopTime;  // 停靠秒數

  TravelTime({
    required this.fromStationId,
    required this.toStationId,
    required this.id,
    required this.runtime,
    required this.stopTime,
  });

  factory TravelTime.fromJson(Map<String, dynamic> json) {
    return TravelTime(
      id: json['id'].toString(),
      fromStationId: json['traveltimes_fromstationid'].toString(),
      toStationId: json['traveltimes_tostationid'].toString(),
      runtime: (json['traveltimes_runtime'] as num).toInt(),
      stopTime: (json['traveltimes_stoptime'] as num).toInt(),
    );
  }
}
class TravelTimeHelper {
  /// sourceId → { targetId → runtimeSec }
  static final Map<String, Map<String, int>> travelMatrix = {};

  /// 除錯：顯示 travelMatrix 的內容
  static void debugPrintMatrix() {
    print("=== travelMatrix 除錯資訊 ===");
    print("總共有 ${travelMatrix.length} 個起點車站");

    int totalConnections = 0;
    travelMatrix.forEach((from, connections) {
      print("$from -> ${connections.length} 個連接: ${connections.keys.toList()}");
      totalConnections += connections.length;
    });
    print("總連接數: $totalConnections");

    // 顯示前幾個連接的詳細資訊
    int count = 0;
    travelMatrix.forEach((from, connections) {
      connections.forEach((to, time) {
        if (count < 5) {
          print("$from -> $to : $time 秒");
          count++;
        }
      });
    });
  }
  /// 初始化資料
  static void load(List<Map<String, dynamic>> data) {
    travelMatrix.clear();

    for (final row in data) {
      // 去除字串中的引號
      final from = _cleanId(row["traveltimes_fromstationid"].toString());
      final to = _cleanId(row["traveltimes_tostationid"].toString());
      final runtime = (num.parse(row["traveltimes_runtime"].toString())).toInt();

      travelMatrix.putIfAbsent(from, () => {});
      travelMatrix[from]![to] = runtime;

      // 如果需要雙向連接，也加上反向
      travelMatrix.putIfAbsent(to, () => {});
      travelMatrix[to]![from] = runtime;
    }

    print("✅ 已載入 travelMatrix，車站ID範例: ${travelMatrix.keys.take(3).toList()}");
  }

  /// 清理ID：去除多餘的引號和空白
  static String _cleanId(String id) {
    return id
        .replaceAll('"', '')  // 去除雙引號
        .replaceAll("'", '')   // 去除單引號
        .trim();               // 去除空白
  }
  /// 計算某站到所有站的最短行駛時間
  /// 計算某站到所有站的最短行駛時間（基本版 Dijkstra）
  static Map<MRTStation, int> calculateTimes(
      MRTStation start, List<MRTStation> stations) {

    print("\n======= 開始計算旅行時間 =======");
    print("起始站: ${start.name} (ID: ${start.stationId})");
    print("總車站數: ${stations.length}");
    print("travelMatrix 大小: ${travelMatrix.length}");

    // 先檢查起始站是否在 travelMatrix 中
    if (!travelMatrix.containsKey(start.stationId)) {
      print("❌ 錯誤: 起始站 ${start.stationId} 不在 travelMatrix 中!");
      print("travelMatrix 中的車站ID: ${travelMatrix.keys.toList()}");

      // 檢查是否有相似ID
      for (var key in travelMatrix.keys) {
        if (key.replaceAll('"', '').replaceAll("'", "") == start.stationId) {
          print("⚠️ 發現相似ID: '$key' 可能匹配 '${start.stationId}'");
        }
      }

      return {
        for (var s in stations)
          s: (s.stationId == start.stationId) ? 0 : -1,
      };
    }

    print("✅ 起始站 ${start.stationId} 在 travelMatrix 中");
    print("起始站的連接數: ${travelMatrix[start.stationId]!.length}");
    print("起始站連接: ${travelMatrix[start.stationId]!.entries.map((e) => '${e.key}:${e.value}秒').toList()}");

    final Map<String, int> dist = {};
    final Set<String> visited = {};

    // 初始化距離
    print("\n初始化距離:");
    for (var s in stations) {
      dist[s.stationId] = 999999;
      print("  ${s.stationId}: 999999");
    }
    dist[start.stationId] = 0;
    print("  ${start.stationId}: 0 (起始站)");

    // 重複直到所有節點都被訪問
    int iteration = 0;
    while (visited.length < stations.length) {
      iteration++;
      print("\n--- 迭代 $iteration ---");
      print("已訪問: ${visited.length}/${stations.length}");
      print("已訪問車站: ${visited.toList()}");

      // 找到未訪問的最小距離節點
      String? current;
      int minDist = 999999;

      for (var entry in dist.entries) {
        if (!visited.contains(entry.key) && entry.value < minDist) {
          minDist = entry.value;
          current = entry.key;
        }
      }

      if (current == null || minDist == 999999) {
        print("⚠️ 找不到更多可到達的節點，停止計算");
        break;
      }

      print("選擇當前節點: $current (距離: $minDist)");
      visited.add(current);

      // 如果當前節點沒有連接，跳過
      if (!travelMatrix.containsKey(current)) {
        print("❌ $current 在 travelMatrix 中沒有連接");
        continue;
      }

      // 更新所有鄰居的距離
      print("更新 $current 的鄰居:");
      travelMatrix[current]!.forEach((nextId, runtime) {
        if (visited.contains(nextId)) {
          print("  $nextId: 已訪問，跳過");
          return;
        }

        // 檢查 nextId 是否在 dist 中
        if (!dist.containsKey(nextId)) {
          print("  ❌ $nextId: 不在 dist 映射中！");
          return;
        }

        final newDist = dist[current]! + runtime;
        final oldDist = dist[nextId]!;

        if (newDist < oldDist) {
          dist[nextId] = newDist;
          print("  ✅ $nextId: $oldDist → $newDist 秒");
        } else {
          print("  $nextId: $oldDist (新距離 $newDist 不小於舊距離)");
        }
      });
    }

    print("\n======= 計算完成 =======");
    print("總迭代次數: $iteration");
    print("已訪問車站數: ${visited.length}");

    // 分析結果
    int reachableCount = 0;
    int unreachableCount = 0;

    dist.forEach((stationId, time) {
      if (time == 999999) {
        unreachableCount++;
      } else if (time > 0) {
        reachableCount++;
      }
    });

    print("可到達車站: $reachableCount 個");
    print("無法到達: $unreachableCount 個");
    print("起始站自己: 1 個");

    // 顯示前幾個車站的結果
    print("\n前10個車站結果:");
    int count = 0;
    for (var s in stations) {
      if (count >= 10) break;
      final time = dist[s.stationId]!;
      print("  ${s.stationId}: ${time == 999999 ? '無法到達' : '$time 秒'}");
      count++;
    }

    // 返回結果，將無法到達的標記為 -1
    return {
      for (var s in stations)
        s: dist[s.stationId] == 999999 ? -1 : dist[s.stationId]!,
    };
  }
}
