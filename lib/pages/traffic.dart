import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../database/traffic/getTraffic.dart';

class Traffic extends StatefulWidget {
  const Traffic({super.key});

  @override
  State<Traffic> createState() => _TrafficState();
}

class _TrafficState extends State<Traffic> {
  // -----------------------------
  // 範例資料（未來可換成 TDX）
  // -----------------------------
  String gps = "25.0335, 121.5651"; // 台北101附近
  String direction = "北上"; // 示範
  double vdSpeed = 85.0; // VD 模擬車速
  String nearestIC = "圓山交流道";
  double nearestICDistance = 1200; // 公尺
  String cmsMessage = "前方道路施工 請減速慢行";

  List<Map<String, dynamic>> frontEvents = [
    {
      "type": "施工",
      "description": "國道1號 23.6k 道路施工",
      "distance": 1800 // 公尺
    }
  ];

  bool loading = false;

  Timer? autoTimer;

  @override
  void initState() {
    super.initState();
    _loadMockData();

    // -----------------------------
    // 自動每 5 秒更新
    // -----------------------------
    autoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMockData();
    });
  }

  @override
  void dispose() {
    autoTimer?.cancel();
    super.dispose();
  }

  // -----------------------------
  // 模擬資料更新（不接 API）
  // -----------------------------
  Future<void> _loadMockData() async {
    setState(() => loading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      // 模擬車速變動
      vdSpeed = 70 + (DateTime.now().second % 20);

      // 模擬事件是否出現
      if (vdSpeed < 75) {
        frontEvents = [
          {
            "type": "事故",
            "description": "國道1號 25.2k 小客車追撞",
            "distance": 2300
          }
        ];
      } else {
        frontEvents = []; // 沒事件
      }

      loading = false;
    });

    // -----------------------------
    // 若有事件 → 自動警示
    // -----------------------------
    if (frontEvents.isNotEmpty) {
      _showWarning(frontEvents.first);
    }
  }

  // -----------------------------
  // 警報 UI（SnackBar）
  // -----------------------------
  void _showWarning(Map<String, dynamic> event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "⚠️ 前方 ${event["type"]}：${event["description"]}",
            style: const TextStyle(fontSize: 16),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
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
  void _navigateToFreeWayInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FreeWayInfoPage(),
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
                title: '高速公路道路事件資訊',
                subtitle: '查看高速公路道路事件資訊',
                color: const Color(0xFF1A73E8),
                onTap: _navigateToFreeWayInfo,
              ),
              // const SizedBox(height: 12),
              // _buildMenuOption(
              //   icon: Icons.confirmation_number_rounded,
              //   title: '車票資訊',
              //   subtitle: '票價與購票說明',
              //   color: const Color(0xFF34C759),
              //   onTap: _navigateToTicketInfo,
              // ),
              // const SizedBox(height: 12),
              // _buildMenuOption(
              //   icon: Icons.schedule_rounded,
              //   title: '發車班距',
              //   subtitle: '查看列車發車班距頻率',
              //   color: const Color(0xFFFF9500),
              //   onTap: () => _navigateToSchedule(context),
              // ),
              //
              // const SizedBox(height: 12),
              // _buildMenuOption(
              //   icon: Icons.schedule_rounded,
              //   title: '發車時刻表',
              //   subtitle: '查看列車發車時間',
              //   color: const Color(0xFFFF9500),
              //   onTap: () => _navigateToSchedule(context),
              // ),

              const SizedBox(height: 20),

              // 安全區域底部填充（可選）
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // UI 主體
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: const Text(
          "高速公路行車助理系統 (範例)",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      body: RefreshIndicator(
        onRefresh: _loadMockData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildCard(
                "目前位置",
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GPS：$gps",
                        style: const TextStyle(fontSize: 16)),
                    Text("行車方向：$direction",
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                "最近交流道",
                Text(
                  "$nearestIC（${(nearestICDistance / 1000).toStringAsFixed(2)} km）",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                "可變標誌 CMS",
                Text(
                  cmsMessage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                "VD 即時車速（km/h）",
                Text(
                  vdSpeed.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                "前方 3 公里內事件",
                frontEvents.isEmpty
                    ? const Text(
                  "無事故 / 無施工",
                  style: TextStyle(fontSize: 18),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: frontEvents.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "• ${event["type"]}：${event["description"]}（距離 ${(event["distance"] / 1000).toStringAsFixed(2)} km）",
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),

              CupertinoButton.filled(
                onPressed: loading ? null : _loadMockData,
                child: loading
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Text("重新整理（示範）"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // 統一的卡片 UI
  // -----------------------------
  Widget _buildCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
            const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}














class FreeWayInfoPage extends StatelessWidget {
  const FreeWayInfoPage({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高速公路道路事件資訊'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchFreewayRoadEvent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('錯誤: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('沒有事件資料'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final location = event['Location']?['FreeExpressHighway'] ?? {};
              final impact = event['Impact'] ?? {};

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['EventTitle'] ?? '事件',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(location.isNotEmpty
                          ? '${location['Road'] ?? ''} ${location['Direction'] ?? ''} ${location['StartKM'] ?? ''}～${location['EndKM'] ?? ''} (${location['SectionStart'] ?? ''} → ${location['SectionEnd'] ?? ''})'
                          : '未知位置'),
                      const SizedBox(height: 4),
                      Text('影響：${impact['Description'] ?? '無'}'),
                      Text('阻斷車道：${impact['BlockedLanes'] ?? '無'}'),
                      const SizedBox(height: 4),
                      Text('來源：${event['Source'] ?? '未知'}'),
                      Text(
                          '發布時間：${event['PublishTime'] ?? '未知'} 更新：${event['LastUpdateTime'] ?? '未知'}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}









