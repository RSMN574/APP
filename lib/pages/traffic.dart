import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
























