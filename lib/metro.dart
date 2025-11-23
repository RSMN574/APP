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

  fetchData() async {
    data = await mysqlSelect("SELECT * FROM MRT.MRT_taichung_S2STravelTime;");
    return;
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
          return MetroMap();
            }else {
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
      "SELECT * FROM MRT.MRT_taichung_stationExit WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw'))='$station'"
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
        var stationI = snapshot.data;
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
                    )


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
                const SizedBox(height: 16),
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

// 構建出口卡片
Widget _buildExitCard(dynamic station, int index,context) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('點擊了 ${json.decode(station["ExitName"])["Zh_tw"]}'),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8),Color(0xFF1A73E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.exit_to_app_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            // 出口資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    json.decode(station["ExitName"])["Zh_tw"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 設施圖標
                  Row(
                    children: [
                      if (int.parse(station["Stair"]) == 1)
                        _buildFacilityIcon(Icons.stairs_rounded, '樓梯', const Color(0xFF1A73E8)),
                      if (int.parse(station["Elevator"]) == 1)
                        _buildFacilityIcon(Icons.elevator_rounded, '電梯', const Color(0xFF34C759)),
                      if (int.parse(station["Escalator"]) == 1)
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
  final String name;
  final Offset relativePosition;
  List<Connection> connections;
  final Color lineColor;
  int? displayTime;

  MRTStation(
      this.name,
      this.relativePosition, {
        List<Connection>? connections,
        this.lineColor = Colors.blue,
        this.displayTime,
      }) : connections = connections ?? [];
}



class MetroMap extends StatefulWidget {
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
    // Create the shared transfer station
    final cityHallStation = MRTStation('市政府', Offset(0.5, 0.45), lineColor: Colors.green);

    // Green Line stations
    final greenLineStations = [
      MRTStation('北屯總站', Offset(0.5, 0.05), lineColor: Colors.green),
      MRTStation('舊社', Offset(0.5, 0.10), lineColor: Colors.green),
      MRTStation('松竹', Offset(0.5, 0.15), lineColor: Colors.green),
      MRTStation('四維國小', Offset(0.5, 0.20), lineColor: Colors.green),
      MRTStation('文心崇德', Offset(0.5, 0.25), lineColor: Colors.green),
      MRTStation('文心中清', Offset(0.5, 0.30), lineColor: Colors.green),
      MRTStation('文華高中', Offset(0.5, 0.35), lineColor: Colors.green),
      MRTStation('文心櫻花', Offset(0.5, 0.40), lineColor: Colors.green),
      cityHallStation, // Transfer MRTStation
      MRTStation('水安宮', Offset(0.5, 0.50), lineColor: Colors.green),
      MRTStation('文心森林公園', Offset(0.5, 0.55), lineColor: Colors.green),
      MRTStation('南屯', Offset(0.5, 0.60), lineColor: Colors.green),
      MRTStation('豐樂公園', Offset(0.5, 0.7), lineColor: Colors.green),
      MRTStation('大慶', Offset(0.501, 0.75), lineColor: Colors.green),
      MRTStation('九張犁', Offset(0.45, 0.81), lineColor: Colors.green),
      MRTStation('九德', Offset(0.33, 0.85), lineColor: Colors.green),
      MRTStation('烏日', Offset(0.24, 0.85), lineColor: Colors.green),
      MRTStation('高鐵台中站', Offset(0.18, 0.85), lineColor: Colors.green),
    ];


    // Blue Line stations (20 stations, horizontal along Taiwan Boulevard)
    // final blueLineStations = [
    //   MRTStation('台中港站 (B1)', Offset(0.10, 0.45), lineColor: Colors.blue),
    //   MRTStation('梧棲站 (B2)', Offset(0.14, 0.45), lineColor: Colors.blue),
    //   MRTStation('大庄站 (B3)', Offset(0.18, 0.45), lineColor: Colors.blue),
    //   MRTStation('沙鹿站 (B4)', Offset(0.22, 0.45), lineColor: Colors.blue),
    //   MRTStation('竹林站 (B5)', Offset(0.26, 0.45), lineColor: Colors.blue),
    //   MRTStation('靜宜大學站 (B6)', Offset(0.30, 0.45), lineColor: Colors.blue),
    //   MRTStation('弘光科大站 (B7)', Offset(0.34, 0.45), lineColor: Colors.blue),
    //   MRTStation('正英路站 (B8)', Offset(0.38, 0.45), lineColor: Colors.blue),
    //   // MRTStation('東海別墅站 (B9)', Offset(0.42, 0.45), lineColor: Colors.blue),
    //   // MRTStation('東海大學站 (B10)', Offset(0.46, 0.45), lineColor: Colors.blue),
    //   // MRTStation('澄清醫院站 (B11)', Offset(0.48, 0.45), lineColor: Colors.blue),
    //   // MRTStation('福安站 (B12)', Offset(0.49, 0.45), lineColor: Colors.blue),
    //   // MRTStation('朝馬站 (B13)', Offset(0.495, 0.45), lineColor: Colors.blue),
    //   cityHallStation, // Transfer MRTStation (B14)
    //   // MRTStation('漢口路站 (B15)', Offset(0.505, 0.45), lineColor: Colors.blue),
    //   // MRTStation('科博館站 (B16)', Offset(0.52, 0.45), lineColor: Colors.blue),
    //   MRTStation('茄苳腳站 (B17)', Offset(0.56, 0.45), lineColor: Colors.blue),
    //   MRTStation('第二市場站 (B18)', Offset(0.60, 0.45), lineColor: Colors.blue),
    //   MRTStation('台中車站 (B19)', Offset(0.64, 0.45), lineColor: Colors.blue),
    //   MRTStation('帝國製糖廠站 (B20)', Offset(0.68, 0.45), lineColor: Colors.blue),
    // ];
    // Add all stations, avoiding duplication of the transfer MRTStation
    _stations.addAll(greenLineStations);
    // _stations.addAll(blueLineStations.where((s) => s != cityHallStation));
  }

  void _initConnections() {
    // Green Line connections
    final greenLineStations = _stations.where((s) => s.lineColor == Colors.green || s.name == '市政府站').toList();
    for (int i = 0; i < greenLineStations.length - 1; i++) {
      greenLineStations[i].connections.add(Connection(greenLineStations[i + 1], Colors.green));
      greenLineStations[i + 1].connections.add(Connection(greenLineStations[i], Colors.green));
    }

    // blue Line connections
    final blueLineStations = _stations.where((s) => s.lineColor == Colors.blue || s.name == '市政府站').toList();
    for (int i = 0; i < blueLineStations.length - 1; i++) {
      blueLineStations[i].connections.add(Connection(blueLineStations[i + 1], Colors.blue));
      blueLineStations[i + 1].connections.add(Connection(blueLineStations[i], Colors.blue));
    }
  }

  Map<MRTStation, int> _calculateTimes(MRTStation start) {
    Map<MRTStation, int> distances = {};
    final queue = Queue<MRTStation>();
    distances[start] = 0;
    queue.add(start);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final connection in current.connections) {
        final neighborStation = connection.station;
        if (!distances.containsKey(neighborStation)) {
          distances[neighborStation] = distances[current]! + 1;
          queue.add(neighborStation);
        }
      }
    }

    return distances.map((station, distance) => MapEntry(station, distance * 2));
  }

  void _updateSelectedStation(MRTStation station) {
    setState(() {
      _selectedStation = station;
      _timeMap = _calculateTimes(station);
      _stations.forEach((s) => s.displayTime = _timeMap[s]);
    });
    print(_selectedStation?.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {if (_selectedStation != null) {
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
                            _selectedStation
                            !.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
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
                          // 将车站信息和转乘信息作为子项传入
                          SingleChildScrollView(
                            controller: scrollController,
                            child: buildStationInfo(
                                _selectedStation
                                !.name),
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
    }});
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

    // Draw connections
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

    // Draw stations
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
    canvas.drawCircle(position, stationRadius*0.9, outerPaint);

// 內圓（留一個漂亮的圓環邊）
    const ringWidth = 1.5; // 邊框寬度
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, stationRadius*0.9 - ringWidth, innerPaint);


    // Draw time text
    if (station.displayTime != null) {
      final text = station.displayTime.toString();
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: stationRadius * 0.8,
            color:   Colors.black ,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final offset = Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }

    // Draw station name
    final namePainter = TextPainter(
      text: TextSpan(
        text: station.name,
        style: TextStyle(
          fontSize: stationRadius * 0.8,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(
      canvas,
      Offset(position.dx + stationRadius, position.dy + stationRadius),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


