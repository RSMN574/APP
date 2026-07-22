import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'Const/regularConst.dart';
import 'database/flight/getFlight.dart';
import 'l10n/app_localizations.dart';

final PageController pageController = PageController();

// 定義機場資料模型
class AirportData {
  final String name;
  final String iataCode;
  final double area; // 公頃
  final int terminals;
  final int annualPassengers; // 萬人次
  final String phone;
  final Color primaryColor;

  // 交通資訊
  final List<TransportInfo> transport;
  final List<TransportRoute>? transportRoute;

  // 服務設施
  final List<ServiceInfo> services;

  // 緊急資訊
  final Map<String, String> emergencyContacts;

  AirportData({
    required this.name,
    required this.iataCode,
    required this.area,
    required this.terminals,
    required this.annualPassengers,
    required this.phone,
    required this.primaryColor,
    required this.transport,
    required this.services,
    required this.emergencyContacts,
    this.transportRoute
  });
}
enum TransportType {
  bus,     // 公車
  train,   // 台鐵
  hsr,     // 高鐵
  mrt,     // 捷運
}

class TransportRoute {
  final TransportType type;   // 公車 / 火車 / 高鐵 / 捷運
  final String routeId;       // 路線 ID（TDX 用）
  final String name;          // 顯示名稱（300、機捷A1）
  final String? operator;      // 業者（TRTC、TYMC、THSR）
  final String? destination;  // 方向 / 終點
  final Color? color;         // 捷運路線顏色
  final String? remark;       // 備註（例：假日行駛）

  TransportRoute({
    required this.type,
    required this.routeId,
    required this.name,
     this.operator,
    this.destination,
    this.color,
    this.remark,
  });
}

class TransportInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  TransportInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class ServiceInfo {
  final String label;
  final IconData icon;

  ServiceInfo({
    required this.label,
    required this.icon,
  });
}

// 機場資料庫
final Map<String, AirportData> airports = {
  'TPE': AirportData(
      name: '桃園國際機場',
      iataCode: 'TPE',
      area: 1223,
      terminals: 3,
      annualPassengers: 4500,
      phone: '03-273-5081',
      primaryColor: const Color(0xFF1A73E8),
      transport: [
        TransportInfo(
          title: '機場捷運',
          subtitle: '直達台北車站，約35分鐘',
          icon: Icons.train_rounded,
        ),
        TransportInfo(
          title: '客運巴士',
          subtitle: '多條路線通往全台各地',
          icon: Icons.directions_bus_rounded,
        ),
        TransportInfo(
          title: '計程車',
          subtitle: '24小時排班服務',
          icon: Icons.local_taxi_rounded,
        ),
        TransportInfo(
          title: '租車服務',
          subtitle: '各大租車公司進駐',
          icon: Icons.directions_car_rounded,
        ),
      ],
      services: [
        ServiceInfo(label: '免稅商店', icon: Icons.shopping_bag_rounded),
        ServiceInfo(label: '貴賓室', icon: Icons.star_rounded),
        ServiceInfo(label: '餐飲服務', icon: Icons.restaurant_rounded),
        ServiceInfo(label: '免費WiFi', icon: Icons.wifi_rounded),
        ServiceInfo(label: '貨幣兌換', icon: Icons.currency_exchange_rounded),
        ServiceInfo(label: '行李寄存', icon: Icons.luggage_rounded),
        ServiceInfo(label: '祈禱室', icon: Icons.people_rounded),
        ServiceInfo(label: '育嬰室', icon: Icons.child_care_rounded),
      ],
      emergencyContacts: {
        '機場警察': '03-273-2946',
        '醫療中心': '03-273-2945',
        '遺失物協尋': '03-273-2947',
      },transportRoute:[
    TransportRoute(type:TransportType.bus, routeId: '706', name: '706',)
  ]
  ),
  'TSA': AirportData(
    name: '台北松山機場',
    iataCode: 'TSA',
    area: 182,
    terminals: 1,
    annualPassengers: 600,
    phone: '02-8770-3456',
    primaryColor: Colors.green,
    transport: [
      TransportInfo(
        title: '捷運文湖線',
        subtitle: '松山機場站，直達市區',
        icon: Icons.train_rounded,
      ),
      TransportInfo(
        title: '公車',
        subtitle: '多線公車可達',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '計程車',
        subtitle: '排班服務',
        icon: Icons.local_taxi_rounded,
      ),
      TransportInfo(
        title: 'YouBike',
        subtitle: '機場外有站點',
        icon: Icons.pedal_bike_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: '貴賓室', icon: Icons.star_rounded),
      ServiceInfo(label: '餐飲服務', icon: Icons.restaurant_rounded),
      ServiceInfo(label: '免費WiFi', icon: Icons.wifi_rounded),
      ServiceInfo(label: '便利商店', icon: Icons.store_rounded),
      ServiceInfo(label: '觀景台', icon: Icons.visibility_rounded),
    ],
    emergencyContacts: {
      '機場服務台': '02-8770-3456',
      '醫療協助': '02-8770-3460',
      '警察局': '02-8770-3461',
    },
  ),
  'RMQ': AirportData(
    name: '台中清泉崗機場',
    iataCode: 'RMQ',
    area: 564,
    terminals: 1,
    annualPassengers: 280,
    phone: '04-2615-5000',
    primaryColor: Colors.orange,
    transport: [
      TransportInfo(
        title: '公車',
        subtitle: '多線公車可達市區',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '計程車',
        subtitle: '排班服務',
        icon: Icons.local_taxi_rounded,
      ),
      TransportInfo(
        title: '租車服務',
        subtitle: '機場內提供',
        icon: Icons.directions_car_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: '餐飲服務', icon: Icons.restaurant_rounded),
      ServiceInfo(label: '免費WiFi', icon: Icons.wifi_rounded),
      ServiceInfo(label: '便利商店', icon: Icons.store_rounded),
      ServiceInfo(label: '哺乳室', icon: Icons.child_care_rounded),
    ],
    emergencyContacts: {
      '服務中心': '04-2615-5000',
      '醫療站': '04-2615-5100',
      '警察隊': '04-2615-5200',
    },
  ),
  'KHH': AirportData(
    name: '高雄國際機場',
    iataCode: 'KHH',
    area: 2645, // 約 264.5 ha
    terminals: 2, // 國內與國際航廈 :contentReference[oaicite:1]{index=1}
    annualPassengers:
    5865, // 2024 約 5,865,000 人次 :contentReference[oaicite:2]{index=2}
    phone: '07-805-7559', // From AIP data :contentReference[oaicite:3]{index=3}
    primaryColor: Colors.red,
    transport: [
      TransportInfo(
        title: '高雄捷運紅線',
        subtitle: '直達機場站（R4）',
        icon: Icons.train_rounded,
      ),
      TransportInfo(
        title: '客運/計程車',
        subtitle: '多線可達市區',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '租車服務',
        subtitle: '航站提供',
        icon: Icons.directions_car_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: '餐飲服務', icon: Icons.restaurant_rounded),
      ServiceInfo(label: 'Wi-Fi', icon: Icons.wifi_rounded),
      ServiceInfo(label: '便利商店', icon: Icons.store_rounded),
      ServiceInfo(label: '貴賓室', icon: Icons.star_rounded),
    ],
    emergencyContacts: {
      '服務中心': '07-805-7888',
    },
  ),

  'TNN': AirportData(
    name: '台南機場',
    iataCode: 'TNN',
    area: 435,
    terminals: 1,
    annualPassengers: 70, // 估算（約 70 萬） :contentReference[oaicite:4]{index=4}
    phone: '06-260-1016', // ⚠️ 建議補電話
    primaryColor: Colors.brown,
    transport: [
      TransportInfo(
        title: '公車',
        subtitle: '可達台南市區',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '計程車',
        subtitle: '機場外可搭乘',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: '免費WiFi', icon: Icons.wifi_rounded),
    ],
    emergencyContacts: {},
  ),
  'HUN': AirportData(
    name: '花蓮機場',
    iataCode: 'HUN',
    area:
    402, // 長度 ~2751m 寬度 ~45m的跑道（表格示意） :contentReference[oaicite:5]{index=5}
    terminals: 1,
    annualPassengers: 100, // 估算（約 100 萬） :contentReference[oaicite:6]{index=6}
    phone: '03-821-0768', // 旅遊資訊來源 :contentReference[oaicite:7]{index=7}
    primaryColor: Colors.teal,
    transport: [
      TransportInfo(
        title: '公車',
        subtitle: '可達花蓮市',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '計程車',
        subtitle: '機場外可搭乘',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: '免費WiFi', icon: Icons.wifi_rounded),
    ],
    emergencyContacts: {},
  ),
  'TTT': AirportData(
    name: '台東機場',
    iataCode: 'TTT',
    area: 461, // 跑道長度 ~2438m :contentReference[oaicite:8]{index=8}
    terminals: 1,
    annualPassengers: 50, // 估算（約 50 萬） :contentReference[oaicite:9]{index=9}
    phone: '089-361111', // 旅遊資訊來源 :contentReference[oaicite:10]{index=10}
    primaryColor: Colors.deepOrange,
    transport: [
      TransportInfo(
        title: '公車',
        subtitle: '可達台東市',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '計程車',
        subtitle: '機場外服務',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: 'WiFi', icon: Icons.wifi_rounded),
    ],
    emergencyContacts: {},
  ),
  'CYI': AirportData(
    name: '嘉義機場',
    iataCode: 'CYI',
    area:
    119, // 面積 km² （約 119 ha；跑道11,900㎡ 約 1.19e5㎡） :contentReference[oaicite:11]{index=11}
    terminals: 1,
    annualPassengers: 22, // 年容量約 22 萬 :contentReference[oaicite:12]{index=12}
    phone: '05-286-7886', // 官方機場資料 :contentReference[oaicite:13]{index=13}
    primaryColor: Colors.lightBlue,
    transport: [
      TransportInfo(
        title: '計程車',
        subtitle: '可達嘉義市區 / 火車站',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: '免費WiFi', icon: Icons.wifi_rounded),
    ],
    emergencyContacts: {},
  ),
  'KNH': AirportData(
    name: '金門機場',
    iataCode: 'KNH',
    area: 471, // 約 47100 平方公尺跑道區域 :contentReference[oaicite:14]{index=14}
    terminals: 1,
    annualPassengers: 120, // 約 120 萬估算 :contentReference[oaicite:15]{index=15}
    phone: '082-322381', // 旅遊資訊來源 :contentReference[oaicite:16]{index=16}
    primaryColor: Colors.amber,
    transport: [
      TransportInfo(
        title: '計程車',
        subtitle: '機場外服務',
        icon: Icons.local_taxi_rounded,
      ),
      TransportInfo(
        title: '公車',
        subtitle: '鄉內路線可達',
        icon: Icons.directions_bus_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: 'WiFi', icon: Icons.wifi_rounded),
    ],
    emergencyContacts: {},
  ),
  'MZG': AirportData(
    name: '澎湖馬公機場',
    iataCode: 'MZG',
    area: 440, // 約 44000 平方公尺跑道區域 :contentReference[oaicite:17]{index=17}
    terminals: 1,
    annualPassengers: 90, // 約 90 萬估算 :contentReference[oaicite:18]{index=18}
    phone: '06-922-8188', // 旅遊資訊來源 :contentReference[oaicite:19]{index=19}
    primaryColor: Colors.blueAccent,
    transport: [
      TransportInfo(
        title: '公車',
        subtitle: '連接澎湖本島各地',
        icon: Icons.directions_bus_rounded,
      ),
      TransportInfo(
        title: '計程車',
        subtitle: '機場外服務',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [
      ServiceInfo(label: 'WiFi', icon: Icons.wifi_rounded),
    ],
    emergencyContacts: {},
  ),
  'MFK': AirportData(
    name: '北竿機場',
    iataCode: 'MFK',
    area: 81, // 約 8095 平方公尺 apron :contentReference[oaicite:20]{index=20}
    terminals: 1,
    annualPassengers: 10, // 約 10 萬估算 :contentReference[oaicite:21]{index=21}
    phone: '0836-56606', // 旅遊資訊來源 :contentReference[oaicite:22]{index=22}
    primaryColor: Colors.greenAccent,
    transport: [
      TransportInfo(
        title: '計程車',
        subtitle: '機場外可搭',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [],
    emergencyContacts: {},
  ),
  'LZN': AirportData(
    name: '南竿機場',
    iataCode: 'LZN',
    area: 126, // 約 12600 平方公尺 apron :contentReference[oaicite:23]{index=23}
    terminals: 1,
    annualPassengers: 20, // 約 20 萬估算 :contentReference[oaicite:24]{index=24}
    phone: '0836-26505', // 旅遊資訊來源 :contentReference[oaicite:25]{index=25}
    primaryColor: Colors.purple,
    transport: [
      TransportInfo(
        title: '計程車',
        subtitle: '機場外可搭',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [],
    emergencyContacts: {},
  ),
  'KYD': AirportData(
    name: '蘭嶼機場',
    iataCode: 'KYD',
    area: 69, // 約 6880 平方公尺跑道 :contentReference[oaicite:26]{index=26}
    terminals: 1,
    annualPassengers: 46, // 約 46 千估算 :contentReference[oaicite:27]{index=27}
    phone: '089-732-221', // 旅遊資訊來源 :contentReference[oaicite:28]{index=28}
    primaryColor: Colors.lightGreen,
    transport: [
      TransportInfo(
        title: '計程車',
        subtitle: '機場外可搭',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [],
    emergencyContacts: {},
  ),
  'GNI': AirportData(
    name: '綠島機場',
    iataCode: 'GNI',
    area: 81, // 約 8103 平方公尺跑道 :contentReference[oaicite:29]{index=29}
    terminals: 1,
    annualPassengers: 28, // 約 28 千估算 :contentReference[oaicite:30]{index=30}
    phone: '089-671194', // 旅遊資訊來源 :contentReference[oaicite:31]{index=31}
    primaryColor: Colors.cyan,
    transport: [
      TransportInfo(
        title: '計程車',
        subtitle: '機場外可搭',
        icon: Icons.local_taxi_rounded,
      ),
    ],
    services: [],
    emergencyContacts: {},
  ),
};
class Plane extends StatefulWidget {
  const Plane({super.key});

  @override
  State<Plane> createState() => _PlaneState();
}

class _PlaneState extends State<Plane> {
  final TextEditingController _flightNumberController = TextEditingController();
  late final List<String> tabs = [AppLocalizations.of(context)!.text_747, AppLocalizations.of(context)!.text_748, AppLocalizations.of(context)!.text_749, AppLocalizations.of(context)!.text_750];
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  int _current = 0;
  // 假資料 - 機場服務功能 (圖示 + 標題)
  late final List<Map<String, dynamic>> services = [
    {'icon': Icons.local_taxi, 'label': AppLocalizations.of(context)!.text_751},
    {'icon': Icons.local_dining, 'label': AppLocalizations.of(context)!.text_752},
    {'icon': Icons.restaurant, 'label': AppLocalizations.of(context)!.text_753},
    {'icon': Icons.airplane_ticket, 'label': AppLocalizations.of(context)!.text_754},
    {'icon': Icons.security, 'label': AppLocalizations.of(context)!.text_755},
    {'icon': Icons.luggage, 'label': AppLocalizations.of(context)!.text_656},
  ];
  late final List<Map<String, String>> airportList = [
    {'code': 'TSA', 'name': AppLocalizations.of(context)!.text_596},
    {'code': 'KHH', 'name': AppLocalizations.of(context)!.text_756},
    {'code': 'TPE', 'name': AppLocalizations.of(context)!.text_757},
    {'code': 'MFK', 'name': AppLocalizations.of(context)!.text_742},
    {'code': 'LZN', 'name': AppLocalizations.of(context)!.text_744},
    {'code': 'KNH', 'name': AppLocalizations.of(context)!.text_738},
    {'code': 'MZG', 'name': AppLocalizations.of(context)!.text_758},
    {'code': 'RMQ', 'name': AppLocalizations.of(context)!.text_759},
    {'code': 'CYI', 'name': AppLocalizations.of(context)!.text_736},
    {'code': 'TNN', 'name': AppLocalizations.of(context)!.text_760},
    {'code': 'HUN', 'name': AppLocalizations.of(context)!.text_731},
    {'code': 'TTT', 'name': AppLocalizations.of(context)!.text_761},
    {'code': 'KYD', 'name': AppLocalizations.of(context)!.text_745},
    {'code': 'GNI', 'name': AppLocalizations.of(context)!.text_746},
  ];

  String selectedAirport = "TPE";

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            '${airportList.firstWhere((a) => a['code'] == selectedAirport)['name']}航班資訊',
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // 可以添加點擊效果
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF3FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1A73E8).withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: selectedAirport,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF1A73E8)),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF1A73E8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            items: airportList.map((airport) {
                              final isSelected = selectedAirport == airport;
                              return DropdownMenuItem<String>(
                                  value: airport['code'],
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEEF3FB)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.flight_takeoff_rounded,
                                          size: 16,
                                          color: const Color(0xFF1A73E8)
                                              .withOpacity(0.7),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(airport['name']!),
                                      ],
                                    ),
                                  ));
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedAirport = value;
                                });
                              }
                            },
                          ),
                        ))))
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100), // 只放 TabBar
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTabBar(), // 只返回 TabBar
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFD),
          ),
          child: Column(
            children: [
              Expanded(child: _buildPageView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (ctx, index) => _buildTabItem(index),
      ),
    );
  }

  Widget _buildTabItem(int index) {
    final bool isSelected = _current == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _current = index;
          });
          pageController.animateToPage(
            _current,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 100,
          height: 76,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      const Color(0xFF1A73E8),
                      const Color(0xFF1A73E8).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
            border: isSelected
                ? Border.all(
                    color: const Color(0xFF1A73E8).withOpacity(0.2), width: 1.5)
                : Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1A73E8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      itemCount: tabs.length,
      controller: pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        switch (tabs[index]) {
          case "機場資訊":
            return _buildAirportInfoTab();
          case "入境航班":
            return _buildArrivalTab();
          case "出境航班":
            return _buildDepartureTab();
          case "航班查詢":
            return _buildSearchTab();
        }
        return null;
      },
    );
  }


  Widget _buildArrivalTab() {
    return FutureBuilder<List<dynamic>>(
      future: getAirportFIDSArrival(selectedAirport),
      builder: (context, snapshot) {
        return _buildFlightList(snapshot, 'Arrival');
      },
    );
  }

  Widget _buildAirportInfoTab() {
    final airport = airports[selectedAirport] ?? airports['TPE']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 機場概況卡片
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: '${airport.name}概況',
            content: '''
• IATA代碼：${airport.iataCode}
• 總面積：${airport.area.toStringAsFixed(0)}公頃
• 航廈數：${airport.terminals}座
• 年旅客量：約${airport.annualPassengers}萬人次
• 24小時服務電話：${airport.phone}
          ''',
            color: airport.primaryColor,
          ),

          const SizedBox(height: 16),

          // 2. 交通資訊卡片
          _buildTransportationCard(airport),

          const SizedBox(height: 16),

          // 3. 服務設施卡片
          _buildServicesCard(airport),

          const SizedBox(height: 16),

          // 4. 緊急資訊卡片
          _buildEmergencyCard(airport),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
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
          // 標題區域
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 分隔線
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 內容區域
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportationCard(AirportData airport) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [airport.primaryColor, airport.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_transit_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.text_767,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  airport.primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...airport.transport.map((transport) => Column(
                      children: [
                        _buildTransportItem(
                          transport.title,
                          transport.subtitle,
                          transport.icon,
                          airport.primaryColor,
                        ),
                        if (transport != airport.transport.last)
                          const SizedBox(height: 12),
                      ],
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportItem(
      String title, String subtitle, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 處理交通項目點擊
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesCard(AirportData airport) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [airport.primaryColor, airport.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_activity_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                 Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.text_769,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  airport.primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: airport.services
                  .map((service) => _buildServiceChip(
                      service.label, service.icon, airport.primaryColor))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
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

  Widget _buildEmergencyCard(AirportData airport) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [airport.primaryColor, airport.primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                 Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.text_770,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  airport.primaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...airport.emergencyContacts.entries.map((entry) => Column(
                      children: [
                        _buildEmergencyItem(
                          entry.key,
                          entry.value,
                          Icons.phone_rounded,
                          airport.primaryColor,
                        ),
                        if (entry.key !=
                            airport.emergencyContacts.entries.last.key)
                          const SizedBox(height: 12),
                      ],
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: airport.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: airport.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '緊急情況請撥打：119\n機場服務台：${airport.phone}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyItem(
      String title, String phone, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 處理緊急電話撥打
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withOpacity(0.1),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.phone_rounded,
                size: 16,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartureTab() {
    return FutureBuilder<List<dynamic>>(
      future: getAirportFIDSDeparture(selectedAirport),
      builder: (context, snapshot) {
        return _buildFlightList(snapshot, 'Departure');
      },
    );
  }

  Widget _buildFlightList(AsyncSnapshot<List<dynamic>> snapshot, String type) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('資料載入失敗: ${snapshot.error}'));
    }
    final flights = snapshot.data ?? [];
    return FlightDashboard(flights: flights, type: type);
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 24),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
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
           Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: Color(0xFF1A73E8),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.text_771,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A73E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _flightNumberController,
                    decoration:  InputDecoration(
                      hintText: AppLocalizations.of(context)!.text_772,
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    onSubmitted: (value) => _searchFlight(value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF1A73E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _searchFlight(_flightNumberController.text),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child:  Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.text_773,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _searchFlight(String number) {
    if (number.isEmpty) {
      // 可以添加空輸入的提示
      return;
    }
    // 執行搜尋邏輯
    _searchQuery.value = number.trim();
  }

  Map<String, String> _parseFlightNumber(String input) {
    // 移除所有空格和特殊字符
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    // 分离字母和数字部分 (如CI62 -> {AirlineID: "CI", FlightNumber: "62"})
    final match = RegExp(r'^([A-Z]{1,3})(\d{1,4})$').firstMatch(cleaned);

    return {
      'AirlineID': match?.group(1) ?? '',
      'FlightNumber': match?.group(2) ?? cleaned // 如果无法分离，整个字符串作为航班号
    };
  }

  Widget _buildSearchResults() {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (context, input, _) {
        if (input.isEmpty) {
          return _buildEmptySearchState();
        }

        final flightInfo = _parseFlightNumber(input);
        final airlineId = flightInfo['AirlineID']!;
        final flightNumber = flightInfo['FlightNumber']!;
        final formattedFlightNumber =
            airlineId.isNotEmpty ? '$airlineId $flightNumber' : flightNumber;

        if (input != formattedFlightNumber.replaceAll(' ', '')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已自動格式化: $formattedFlightNumber'),
                backgroundColor: const Color(0xFF1A73E8),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          });
        }

        return FutureBuilder<List<dynamic>>(
          future: getFlight(airlineId, flightNumber),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }
            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyView();
            }

            final flights = snapshot.data!;
            print(snapshot.data!);
            return FlightInfoCard(flight: flights[0]);
          },
        );
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
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
              Icons.airplane_ticket_rounded,
              size: 50,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 24),
           Text(
            AppLocalizations.of(context)!.text_774,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.text_775,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '範例：CI123, BR196, JL809',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1A73E8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(40),
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
          Text(
            AppLocalizations.of(context)!.text_776,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A73E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
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
           Text(
            AppLocalizations.of(context)!.text_777,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
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
                  const Color(0xFFFF9500).withOpacity(0.1),
                  const Color(0xFFFF9500).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.airline_stops_rounded,
              size: 40,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 16),
           Text(
            AppLocalizations.of(context)!.text_778,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.text_779,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FlightDashboard extends StatefulWidget {
  final String type;
  final List<dynamic> flights;

  const FlightDashboard({
    super.key,
    required this.flights,
    required this.type,
  });

  @override
  State<FlightDashboard> createState() => _FlightDashboardState();
}

class _FlightDashboardState extends State<FlightDashboard> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.flights.length / 10).ceil();
    final pageFlights =
        widget.flights.skip(_currentPage * 10).take(10).toList();

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              const SizedBox(height: 6),
              ...pageFlights.map((flight) => _buildFlightCard(flight)),
              if (pageFlights.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      AppLocalizations.of(context)!.text_780,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 0 ? const Color(0xFF1A73E8) : Colors.grey,
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage--);
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '第 ${_currentPage + 1} 頁 / 共 $totalPages 頁',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < totalPages - 1
                ? const Color(0xFF1A73E8)
                : Colors.grey,
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() => _currentPage++);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            widget.type == "Departure"
                ? Icons.flight_takeoff
                : Icons.flight_land,
            color: const Color(0xFF1A73E8),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            widget.type == "Departure" ? AppLocalizations.of(context)!.text_749 : AppLocalizations.of(context)!.text_748,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A73E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final delayMinutes = _calculateDelayMinutes(flight);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlightHeader(flight),
            const Divider(height: 12, thickness: 0.8),
            _buildFlightDetails(flight, delayMinutes),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightHeader(Map<String, dynamic> flight) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            flight['IsCargo'] == 'true'
                ? Icons.airplanemode_active
                : Icons.airplanemode_active,
            color: const Color(0xFF1A73E8),
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flight['AirlineID'] + flight['FlightNumber'] ?? '--',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              (flight['IsCargo'] == 'true' ? AppLocalizations.of(context)!.text_781 : AppLocalizations.of(context)!.text_782),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        _buildStatusIndicator(widget.type == 'Departure'
            ? flight['DepartureRemark']
            : flight['ArrivalRemark']),
      ],
    );
  }

  Widget _buildFlightDetails(Map<String, dynamic> flight, int delayMinutes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimeItem(
              AppLocalizations.of(context)!.text_783,
              widget.type == 'Departure'
                  ? flight['ScheduleDepartureTime']
                  : flight['ScheduleArrivalTime']),
          _buildTimeItem(
              AppLocalizations.of(context)!.text_784,
              widget.type == 'Departure'
                  ? flight['ActualDepartureTime']
                  : flight['ActualArrivalTime'],
              isDelayed: delayMinutes > 0),
          _buildDelayItem(delayMinutes),
          _buildInfoItem(AppLocalizations.of(context)!.text_785, flight['Terminal'] ?? '--'),
          if (!(flight['IsCargo'] ?? false))
            _buildInfoItem(AppLocalizations.of(context)!.text_786, flight['BaggageClaim'] ?? '--'),
          _buildInfoItem(AppLocalizations.of(context)!.text_787, flight['Gate'] ?? '--'),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String? time, {bool isDelayed = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 3),
        Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDelayed ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDelayItem(int minutes) {
    final Color textColor = minutes > 0
        ? Colors.red
        : minutes < 0
            ? Colors.green
            : Colors.grey[700]!;

    return Column(
      children: [
         Text(AppLocalizations.of(context)!.text_788, style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${minutes > 0 ? '+' : ''}$minutes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String status) {
    final indicatorStyle = _getStatusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: indicatorStyle['backgroundColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorStyle['borderColor']),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorStyle['icon'],
              size: 10, color: indicatorStyle['textColor']),
          const SizedBox(width: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: indicatorStyle['textColor'],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status) {
      case '出發DEPARTED':
        return {
          'icon': Icons.flight_takeoff,
          'backgroundColor': Colors.blue.withOpacity(0.1),
          'borderColor': Colors.blue.withOpacity(0.3),
          'textColor': Colors.blue,
        };
      case '到達ARRIVED':
        return {
          'icon': Icons.flight_land,
          'backgroundColor': Colors.green.withOpacity(0.1),
          'borderColor': Colors.green.withOpacity(0.3),
          'textColor': Colors.green,
        };
      case '取消CANCELLED':
        return {
          'icon': Icons.cancel,
          'backgroundColor': Colors.red.withOpacity(0.1),
          'borderColor': Colors.red.withOpacity(0.3),
          'textColor': Colors.red,
        };
      case '延誤':
        return {
          'icon': Icons.access_time,
          'backgroundColor': Colors.orange.withOpacity(0.1),
          'borderColor': Colors.orange.withOpacity(0.3),
          'textColor': Colors.orange,
        };
      default:
        return {
          'icon': Icons.airplanemode_active,
          'backgroundColor': Colors.grey.withOpacity(0.1),
          'borderColor': Colors.grey.withOpacity(0.3),
          'textColor': Colors.black87,
        };
    }
  }

  int _calculateDelayMinutes(Map<String, dynamic> flight) {
    try {
      final scheduled = DateTime.parse(widget.type == 'Departure'
          ? flight['ScheduleDepartureTime']
          : flight['ScheduleArrivalTime']);
      final actual = DateTime.parse(widget.type == 'Departure'
          ? flight['ActualDepartureTime']
          : flight['ActualArrivalTime']);
      return actual.difference(scheduled).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '--:--';
    final dt = DateTime.tryParse(isoTime);
    return dt != null ? DateFormat.Hm().format(dt.toLocal()) : '--:--';
  }
}

enum FlightStatus { onTime, delayed, canceled, landed }

class FlightInfoCard extends StatefulWidget {
  final Map<String, dynamic> flight;

  const FlightInfoCard({super.key, required this.flight});

  @override
  State<FlightInfoCard> createState() => _FlightInfoCardState();
}

class _FlightInfoCardState extends State<FlightInfoCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween(begin: 0.0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(String isoTime) {
    try {
      final date = DateTime.parse(isoTime).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '--:--';
    }
  }

  Color _getStatusColor() {
    final remark = (isDeparture
            ? widget.flight['DepartureRemark']
            : widget.flight['ArrivalRemark']) ??
        '';

    if (remark.contains(AppLocalizations.of(context)!.text_788)) return Colors.orange;
    if (remark.contains(AppLocalizations.of(context)!.text_789)) return Colors.green;
    if (remark.contains(AppLocalizations.of(context)!.text_36)) return Colors.red;
    return Colors.blue.shade600;
  }

  // 用 ArrivalRemark/DepartureRemark 判斷出發與抵達（避免兩者皆有的狀況）
  bool get isArrival =>
      widget.flight['ArrivalRemark'] != null &&
      widget.flight['DepartureRemark'] == null;

  bool get isDeparture =>
      widget.flight['DepartureRemark'] != null &&
      widget.flight['ArrivalRemark'] == null;

  String get airportCode => isDeparture
      ? widget.flight['DepartureAirportID'] ?? '--'
      : widget.flight['ArrivalAirportID'] ?? '--';

  String get terminal => isDeparture
      ? widget.flight['DepartureTerminal'] ?? '--'
      : widget.flight['ArrivalTerminal'] ?? '--';

  String get gate => isDeparture
      ? widget.flight['DepartureGate'] ?? '--'
      : widget.flight['ArrivalGate'] ?? '--';

  Widget _buildAirlineBadge() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          widget.flight['AirlineID'] ?? '--',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800),
        ),
      ),
    );
  }

  Widget _buildTimeComparison() {
    final scheduledTime = isDeparture
        ? widget.flight['ScheduleDepartureTime']
        : widget.flight['ScheduleArrivalTime'];
    final actualTime = isDeparture
        ? widget.flight['ActualDepartureTime']
        : widget.flight['ActualArrivalTime'];
    final estimatedTime = isDeparture
        ? widget.flight['EstimatedDepartureTime']
        : widget.flight['EstimatedArrivalTime'];
    final remark = isDeparture
        ? widget.flight['DepartureRemark']
        : widget.flight['ArrivalRemark'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '預定時間：${_formatTime(scheduledTime)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        if (actualTime != null)
          Text(
            '實際時間：${_formatTime(actualTime)}',
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
            ),
          )
        else if (estimatedTime != null)
          Text(
            '預估時間：${_formatTime(estimatedTime)}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (remark != null && remark.toString().trim().isNotEmpty)
          Text(
            '備註：$remark',
            style: TextStyle(color: Colors.red.shade600),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 使用 AnimatedSize 自動調整 Card 高度，避免固定高度限制導致 overflow
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _expanded = !_expanded;
            _expanded ? _controller.forward() : _controller.reverse();
          });
        },
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header 區塊
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAirlineBadge(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 航空公司與航班號
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${widget.flight['AirlineID']} ${widget.flight['FlightNumber']}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isDeparture ? AppLocalizations.of(context)!.text_67 : AppLocalizations.of(context)!.text_68,
                                  style: TextStyle(
                                    color: _getStatusColor(),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 機場與航廈資訊
                          Text(
                            '$airportCode 第$terminal航廈',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 時間資訊區域
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: _buildTimeComparison()),
                    Icon(
                      isDeparture ? Icons.flight_takeoff : Icons.flight_land,
                      size: 32,
                      color: theme.primaryColor,
                    ),
                  ],
                ),
                // 展開詳細資訊區塊
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ConstrainedBox(
                      // 限制最大高度，超出部分可滑動
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 24),
                            _buildDetailRow(
                              Icons.departure_board,
                              AppLocalizations.of(context)!.text_787,
                              gate,
                            ),
                            if (isArrival)
                              _buildDetailRow(
                                Icons.luggage,
                                AppLocalizations.of(context)!.text_790,
                                widget.flight['BaggageClaim'] ?? '--',
                              ),
                            _buildDetailRow(
                              Icons.assignment_ind,
                              AppLocalizations.of(context)!.text_791,
                              widget.flight['CheckCounter'] ?? '--',
                            ),
                            _buildDetailRow(
                              Icons.update,
                              AppLocalizations.of(context)!.text_792,
                              _formatTime(widget.flight['UpdateTime']),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // 展開指示器
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _expanded
                      ? Icon(Icons.expand_less,
                          color: Colors.grey.shade500, key: const ValueKey(1))
                      : RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(Icons.expand_more,
                              color: Colors.grey.shade500,
                              key: const ValueKey(2)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      // 卡片的背景與陰影：現代化設計
      // (Card 本身內建 elevation，但這裡也可以根據需求額外調整)
    );
  }
}

// 加载指示器
Widget _buildLoadingIndicator(context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.text_793, style: TextStyle(color: Colors.grey.shade600)),
      ],
    ),
  );
}

// 空状态视图
Widget _buildEmptyView(context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.airplanemode_inactive,
            size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.text_794,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      ],
    ),
  );
}

// 错误视图
Widget _buildErrorView(context,String error) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          '查詢失敗：$error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.text_795),
            onPressed: () {}
            // onPressed: () => _flightNumberController.text.isNotEmpty
            //     ? getFlight(_flightNumberController.text)
            //     : null,
            ),
      ],
    ),
  );
}
