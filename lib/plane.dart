import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Const/regularConst.dart';
import 'database/flight/getFlight.dart';
final PageController pageController = PageController();
class Plane extends StatefulWidget {
  const Plane({super.key});

  @override
  State<Plane> createState() => _PlaneState();
}

class _PlaneState extends State<Plane>   {
  final TextEditingController _flightNumberController = TextEditingController();
  final List<String> tabs = ['機場資訊','入境航班', '出境航班', '航班查詢'];
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  int _current = 0;
  // 假資料 - 機場服務功能 (圖示 + 標題)
  final List<Map<String, dynamic>> services = [
    {'icon': Icons.local_taxi, 'label': '機場交通'},
    {'icon': Icons.local_dining, 'label': '特許商店'},
    {'icon': Icons.restaurant, 'label': '餐飲美食'},
    {'icon': Icons.airplane_ticket, 'label': '電子登機牌'},
    {'icon': Icons.security, 'label': '安檢安保'},
    {'icon': Icons.luggage, 'label': '行李服務'},
  ];
  final List<Map<String, String>> airportList = [
    {'code': 'TSA', 'name': '松山機場'},
    {'code': 'KHH', 'name': '高雄機場'},
    {'code': 'TPE', 'name': '桃園機場'},
    {'code': 'MFK', 'name': '北竿機場'},
    {'code': 'LZN', 'name': '南竿機場'},
    {'code': 'KNH', 'name': '金門機場'},
    {'code': 'MZG', 'name': '澎湖機場'},
    {'code': 'RMQ', 'name': '臺中機場'},
    {'code': 'CYI', 'name': '嘉義機場'},
    {'code': 'TNN', 'name': '臺南機場'},
    {'code': 'HUN', 'name': '花蓮機場'},
    {'code': 'TTT', 'name': '臺東機場'},
    {'code': 'KYD', 'name': '蘭嶼機場'},
    {'code': 'GNI', 'name': '綠島機場'},
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
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A73E8)),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Color(0xFF1A73E8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: airportList.map((airport) {
                  return DropdownMenuItem<String>(
                    value: airport['code'],
                    child: Row(
                      children: [
                        Icon(
                          Icons.flight_takeoff_rounded,
                          size: 16,
                          color: const Color(0xFF1A73E8).withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(airport['name']!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedAirport = value;
                    });
                  }
                },
              ),
            ),
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
              Expanded(
                child:_buildPageView()
              ),
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
                ? Border.all(color: const Color(0xFF1A73E8).withOpacity(0.2), width: 1.5)
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
            return _buildSearchField();

        }
        return null;
      },
    );
  }
// 獲取標籤對應的圖標
  IconData _getTabIcon(String text) {
    switch (text) {
      case '機場資訊':
        return Icons.info_outline_rounded;
      case '抵達航班':
        return Icons.flight_land_rounded;
      case '出發航班':
        return Icons.flight_takeoff_rounded;
      case '搜尋航班':
        return Icons.search_rounded;
      case '航班狀態':
        return Icons.airplane_ticket_rounded;
      case '設施服務':
        return Icons.local_activity_rounded;
      case '交通資訊':
        return Icons.directions_transit_rounded;
      case '購物餐飲':
        return Icons.local_dining_rounded;
      default:
        return Icons.flight_rounded;
    }
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 機場概況卡片
          _buildInfoCard(
            icon: Icons.info_outline,
            title: '桃園國際機場概況',
            content: '''
• IATA代碼：TPE
• 總面積：1,223公頃
• 航廈數：2座主航廈 + 1座廉航航廈
• 年旅客量：約4,500萬人次
• 24小時服務電話：03-273-5081
          ''',
          ),

          const SizedBox(height: 16),

          // 2. 交通資訊卡片
          _buildTransportationCard(),

          const SizedBox(height: 16),

          // 3. 服務設施卡片
          _buildServicesCard(),

          const SizedBox(height: 16),

          // 4. 緊急資訊卡片
          _buildEmergencyCard(),
        ],
      ),
    );
  }
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTransportationCard() {
    return _buildInfoCard(
      icon: Icons.directions_transit,
      title: '交通方式',
      content: '''
🚈 機場捷運：
   • 直達車：35分鐘到台北車站
   • 普通車：50分鐘到台北車站
   • 首班車：06:00 | 末班車：23:00

🚍 客運巴士：
   • 國光客運：1819路往台北車站
   • 大有巴士：1960路往松山機場
   • 統聯客運：705路往中壢

🚕 計程車：
   • 至台北市區約NT\$1,200-1,500
   • 24小時服務

🚗 自行開車：
   • 高速公路：國道2號機場支線
   • 停車費：NT\$30/小時（第一航廈）
    ''',
    );
  }
  Widget _buildServicesCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.room_service, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '服務設施',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildServiceChip(Icons.shopping_cart, '免稅店', 'B1/2F/3F'),
                _buildServiceChip(Icons.restaurant, '餐廳', '1F-4F'),
                _buildServiceChip(Icons.wifi, '免費WiFi', '全航廈'),
                _buildServiceChip(Icons.local_atm, '換匯', '1F/3F'),
                _buildServiceChip(Icons.baby_changing_station, '育嬰室', '各層洗手間旁'),
                _buildServiceChip(Icons.medical_services, '醫療站', '1F航廈中央'),
                _buildServiceChip(Icons.luggage, '行李寄存', '1F入境大廳'),
                _buildServiceChip(Icons.smoke_free, '吸菸區', '1F/3F室外'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(IconData icon, String label, String location) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label ($location)'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  Widget _buildEmergencyCard() {
    return _buildInfoCard(
      icon: Icons.warning_amber,
      title: '緊急資訊',
      content: '''
🆘 緊急求助：
   • 航警局：03-398-2261
   • 醫療中心：03-398-2583

🛂 海關申報：
   • 免稅額度：NT\$20,000
   • 禁止物品查詢：03-398-2308

⚠️ 遺失物查詢：
   • 第一航廈：03-273-5081
   • 第二航廈：03-273-5082
    ''',
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
      padding: const EdgeInsets.all(16),
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _flightNumberController,
            decoration: const InputDecoration(
              labelText: '輸入航班號碼',
              hintText: '例如：CI123',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) => _searchFlight(value),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _searchFlight(_flightNumberController.text),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
          ),
          child: const Text('立即查詢'),
        ),
      ],
    );
  }

  void _searchFlight(String number) {
    if (number.isEmpty) return;
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
        if (input.isEmpty) return const SizedBox.shrink();

        final flightInfo = _parseFlightNumber(input);
        final airlineId = flightInfo['AirlineID']!;
        final flightNumber = flightInfo['FlightNumber']!;
        final formattedFlightNumber = airlineId.isNotEmpty
            ? '$airlineId $flightNumber'
            : flightNumber;

        if (input != formattedFlightNumber.replaceAll(' ', '')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已自動格式化: $formattedFlightNumber'),
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




}

class FlightDashboard extends StatefulWidget {
  final String type;
  final List<dynamic> flights;

  const FlightDashboard({super.key, required this.flights, required this.type, });

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
                      '暫無航班資訊',
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
            widget.type == "Departure" ? "出境航班" : "入境航班",
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
              (flight['IsCargo'] == 'true' ? "貨機" : "客機"),
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
              '計劃',
              widget.type == 'Departure'
                  ? flight['ScheduleDepartureTime']
                  : flight['ScheduleArrivalTime']),
          _buildTimeItem(
              '實際',
              widget.type == 'Departure'
                  ? flight['ActualDepartureTime']
                  : flight['ActualArrivalTime'],
              isDelayed: delayMinutes > 0),
          _buildDelayItem(delayMinutes),
          _buildInfoItem('航廈', flight['Terminal'] ?? '--'),
          if (!(flight['IsCargo'] ?? false))
            _buildInfoItem('行李', flight['BaggageClaim'] ?? '--'),
          _buildInfoItem('登機門', flight['Gate'] ?? '--'),
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
        const Text('延誤', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
        : widget.flight['ArrivalRemark']) ?? '';

    if (remark.contains('延誤')) return Colors.orange;
    if (remark.contains('準時')) return Colors.green;
    if (remark.contains('取消')) return Colors.red;
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
                  style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                                  isDeparture ? '出發' : '抵達',
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
                              '登機門',
                              gate,
                            ),
                            if (isArrival)
                              _buildDetailRow(
                                Icons.luggage,
                                '行李轉盤',
                                widget.flight['BaggageClaim'] ?? '--',
                              ),
                            _buildDetailRow(
                              Icons.assignment_ind,
                              '報到櫃台',
                              widget.flight['CheckCounter'] ?? '--',
                            ),
                            _buildDetailRow(
                              Icons.update,
                              '最後更新',
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
Widget _buildLoadingIndicator() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
            '正在查询航班信息...',
            style: TextStyle(color: Colors.grey.shade600)),
      ],
    ),
  );
}

// 空状态视图
Widget _buildEmptyView() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.airplanemode_inactive, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
            '未找到相关航班信息',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600)),
      ],
    ),
  );
}

// 错误视图
Widget _buildErrorView(String error) {
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
          label: const Text('重試查詢'),
            onPressed: (){

            }
          // onPressed: () => _flightNumberController.text.isNotEmpty
          //     ? getFlight(_flightNumberController.text)
          //     : null,
        ),
      ],
    ),
  );
}