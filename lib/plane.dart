import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database/flight/getFlight.dart';
class Plane extends StatefulWidget {
  const Plane({super.key});

  @override
  State<Plane> createState() => _PlaneState();
}

class _PlaneState extends State<Plane> {
// 假資料 - 航班列表
  final List<Map<String, String>> flights = [
    {
      'flightNo': 'MF8966',
      'origin': '尚義',
      'time': '21:20',
      'terminal': 'T1',
      'status': '到達',
    },
    {
      'flightNo': 'QN330',
      'origin': '南昌',
      'time': '21:20',
      'terminal': 'T1',
      'status': '到達',
    },
    {
      'flightNo': 'AQ334',
      'origin': '海口',
      'time': '21:28',
      'terminal': 'T2',
      'status': '到達',
    },
    {
      'flightNo': 'AQ334',
      'origin': '澳門',
      'time': '21:28',
      'terminal': 'T2',
      'status': '到達',
    },
  ];

  // 假資料 - 機場服務功能 (圖示 + 標題)
  final List<Map<String, dynamic>> services = [
    {'icon': Icons.local_taxi, 'label': '機場交通'},
    {'icon': Icons.local_dining, 'label': '特許商店'},
    {'icon': Icons.restaurant, 'label': '餐飲美食'},
    {'icon': Icons.airplane_ticket, 'label': '電子登機牌'},
    {'icon': Icons.security, 'label': '安檢安保'},
    {'icon': Icons.luggage, 'label': '行李服務'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('桃園國際機場 TPE'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 航班資訊區 (改成FutureBuilder)
            FutureBuilder<List<dynamic>>(
              future: getAirportFIDSArrival(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('航班資料載入失敗: ${snapshot.error}'));
                }
                final flights = snapshot.data ?? [];
                return FlightDashboard (flights: flights,);
              },
            ),

            // 2. 機場服務按鈕區 (網格狀)
            _buildServicesGrid(),

            // 3. 其他資訊區 (地圖 + 流量資訊)
            _buildMapSection(),

            // 4. 底部可能有其他資訊(示例)
            const SizedBox(height: 16),
            _buildBottomInfo(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 機場服務功能按鈕區 (網格)
  Widget _buildServicesGrid() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 一列顯示幾個
          childAspectRatio: 1, // 寬高比
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(service['icon'] as IconData, size: 28, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                service['label'] as String,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          );
        },
      ),
    );
  }

  // 地圖或其他資訊區
  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '流量正常',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // 這裡可以放置一張地圖圖片示例，或使用第三方地圖套件(如 google_maps_flutter)等
          Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Text('地圖位置 / 飛機動態 (示意)'),
            ),
          ),
          const SizedBox(height: 8),
          // 其他資訊 (例如 100%正常、1 架次、72...等)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('當前正常率: 100%'),
              Text('不正常航班: 0'),
            ],
          ),
        ],
      ),
    );
  }

  // 底部資訊(示例)
  Widget _buildBottomInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('可取消240元', style: TextStyle(color: Colors.red)),
          Icon(Icons.info, color: Colors.grey),
        ],
      ),
    );
  }
}
class FlightDashboard extends StatelessWidget {
  final List<dynamic> flights;

  const FlightDashboard({super.key, required this.flights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8), // 整體縮小內邊距
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // 圓角再縮小
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 6),
          ...flights.map((flight) => _buildFlightCard(flight)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '入境航班',
        style: TextStyle(
          fontSize: 16, // 標題縮小
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A73E8),
        ),
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final delayMinutes = _calculateDelayMinutes(flight);

    return Container(
      margin: const EdgeInsets.only(bottom: 6), // 縮小卡片間距
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8), // 縮小卡片內邊距
        child: Column(
          children: [
            _buildFlightHeader(flight),
            const SizedBox(height: 6),
            _buildFlightDetails(flight, delayMinutes),
            if (flight['ArrivalRemark'] != null) _buildRemark(flight),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightHeader(Map<String, dynamic> flight) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              flight['AirlineID'] + flight['FlightNumber'] ?? '--',
              style: const TextStyle(
                fontSize: 16, // 縮小航班號
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _getAircraftType(flight['AcType']),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        const Spacer(),
        _buildStatusIndicator(flight['ArrivalRemark']),
      ],
    );
  }

  Widget _buildFlightDetails(Map<String, dynamic> flight, int delayMinutes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeItem('計劃', flight['ScheduleArrivalTime']),
        _buildTimeItem('實際', flight['ActualArrivalTime'], isDelayed: delayMinutes > 0),
        _buildDelayItem(delayMinutes),
        _buildInfoItem('航廈', flight['Terminal'] ?? '--'),
        if (!(flight['IsCargo'] ?? false))
          _buildInfoItem('行李', flight['BaggageClaim'] ?? '--'),
        _buildInfoItem('登機門', flight['Gate'] ?? '--'),
      ],
    );
  }

  Widget _buildTimeItem(String label, String? time, {bool isDelayed = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 1),
        Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDelayed ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDelayItem(int minutes) {
    return Column(
      children: [
        const Text('延誤', style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 1),
        Text(
          '${minutes > 0 ? '+' : ''}$minutes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: minutes > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 1),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatusIndicator(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF52C41A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF52C41A).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.airplanemode_active, size: 12, color: Color(0xFF52C41A)),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52C41A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemark(Map<String, dynamic> flight) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[600], size: 14),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '${flight['ArrivalRemark']}',
              style: TextStyle(color: Colors.orange[600], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDelayMinutes(Map<String, dynamic> flight) {
    try {
      final scheduled = DateTime.parse(flight['ScheduleArrivalTime']);
      final actual = DateTime.parse(flight['ActualArrivalTime']);
      return actual.difference(scheduled).inMinutes;
    } catch (e) {
      return 0;
    }
  }

  String _getAircraftType(String? acType) {
    return acType != null ? '$acType 客機' : '--';
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '--:--';
    final dt = DateTime.tryParse(isoTime);
    return dt != null ? DateFormat.Hm().format(dt.toLocal()) : '--:--';
  }
}

enum FlightStatus { onTime, delayed, canceled, landed }