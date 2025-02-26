import 'package:flutter/material.dart';
class plane extends StatefulWidget {
  const plane({super.key});

  @override
  State<plane> createState() => _planeState();
}

class _planeState extends State<plane> {
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
        title: const Text('台中清泉崗 RMQ'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 航班資訊區
            _buildFlightInfoSection(),

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

  // 航班資訊清單
  Widget _buildFlightInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          const Text(
            '進港航班',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // 航班列表
          Column(
            children: flights.map((flight) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // 航班號
                    Expanded(
                      flex: 2,
                      child: Text(
                        flight['flightNo'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // 出發地
                    Expanded(
                      flex: 2,
                      child: Text(flight['origin'] ?? ''),
                    ),
                    // 時間
                    Expanded(
                      flex: 2,
                      child: Text(flight['time'] ?? ''),
                    ),
                    // 航廈
                    Expanded(
                      flex: 1,
                      child: Text(flight['terminal'] ?? ''),
                    ),
                    // 狀態
                    Expanded(
                      flex: 1,
                      child: Text(
                        flight['status'] ?? '',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
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
