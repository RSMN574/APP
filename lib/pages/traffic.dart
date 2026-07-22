import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../database/traffic/getTraffic.dart';
import '../l10n/app_localizations.dart';

class Traffic extends StatefulWidget {
  const Traffic({super.key});

  @override
  State<Traffic> createState() => _TrafficState();
}

// 請確定檔案最上方有 import：


// 如果你已經在同一檔案有 FreeWayInfoPage、tdxService 等，請保持其他程式碼不變。

class _TrafficState extends State<Traffic> {
  // -----------------------------
  // 範例資料（未來可換成 TDX）
  // -----------------------------
  late String gps = AppLocalizations.of(context)!.text_621;
  String direction = "—";
  double vdSpeed = 0.0; // 顯示為 km/h
  late String nearestIC = AppLocalizations.of(context)!.text_622;
  double nearestICDistance = 1200; // 公尺
  late String cmsMessage = AppLocalizations.of(context)!.text_623;

  late List<Map<String, dynamic>> frontEvents = [
    {
      "type": AppLocalizations.of(context)!.text_624,
      "description": "國道1號 23.6k 道路施工",
      "distance": 1800 // 公尺
    }
  ];

  bool loading = false;
  double gpsAccuracy = 0.0; // GPS 精度 (公尺)

  Timer? autoTimer;

  // -------- GPS stream & smoothing ----------
  StreamSubscription<Position>? _positionStreamSub;
  Position? _lastPosition;
  final List<double> _speedBuffer = []; // 存放最近幾筆速度 (km/h) 做平滑
  final int _speedBufferSize = 5; // 移動平均的樣本數，可調整

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadMockData();

    // 如果還要保留自動 mock 更新 (示範目的)，可以保留此 timer。
    autoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMockData();
    });
  }

  @override
  void dispose() {
    autoTimer?.cancel();
    _positionStreamSub?.cancel();
    super.dispose();
  }

  // -----------------------------
  // 初始化定位權限並開始監聽位置
  // -----------------------------
  Future<void> _initLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _startPositionStream();
    } else {
      setState(() {
        gps = AppLocalizations.of(context)!.text_625;
      });
    }
  }

  void _startPositionStream() {
    // 你可以根據需求調整 accuracy / distanceFilter / intervalDuration
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1, // 當移動超過 1 公尺才更新（減少頻率）
      // Android/iOS 可使用時間間隔設定 (較新 geolocator 版本支援)
      // timeLimit: Duration(seconds:1) // 若使用舊版可用 getPositionStream(...).listen(...)
    );

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position pos) {
        if (pos == null) return;
        _onNewPosition(pos);
      },
      onError: (e) {
        // 錯誤處理（可擴充）
        debugPrint('position stream error: $e');
      },
    );
  }

  // -----------------------------
  // 當收到新位置時處理
  // -----------------------------
  void _onNewPosition(Position pos) {
    // 更新 GPS 字串
    final latStr = pos.latitude.toStringAsFixed(6);
    final lonStr = pos.longitude.toStringAsFixed(6);
    gps = "$latStr, $lonStr";

    // GPS 精度
    gpsAccuracy = pos.accuracy; // 公尺

    // 取得方向：優先使用 pos.heading，否則用前一位置算 bearing
    double bearing = 0.0;
    if (pos.heading != null && pos.heading.isFinite && pos.heading >= 0) {
      bearing = pos.heading;
    } else if (_lastPosition != null) {
      bearing = _calcBearing(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude
      );
    }
    direction = _bearingToDirection(bearing);

    // 取得速度
    double speedKmh = 0.0;
    if (pos.speed != null && pos.speed.isFinite && pos.speed >= 0) {
      speedKmh = pos.speed * 3.6; // m/s -> km/h
    } else if (_lastPosition != null && pos.timestamp != null && _lastPosition!.timestamp != null) {
      final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude
      ); // 公尺
      final dt = pos.timestamp!.difference(_lastPosition!.timestamp!).inMilliseconds / 1000.0;
      if (dt > 0) {
        speedKmh = (distance / dt) * 3.6;
      }
    }

    // 僅保留精度 < 10 公尺的速度 (可調整)
    if (gpsAccuracy <= 10) {
      _speedBuffer.add(speedKmh);
    }

    // 平滑速度 (移動平均)
    if (_speedBuffer.length > _speedBufferSize) _speedBuffer.removeAt(0);
    vdSpeed = _speedBuffer.isNotEmpty ? (_speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length) : 0.0;

    // 儲存為 last position
    _lastPosition = pos;

    // 更新 UI
    setState(() {});
  }


  // -----------------------------
  // 模擬資料更新（不接 API）
  // -----------------------------
  Future<void> _loadMockData() async {
    setState(() => loading = true);

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      // 若實際有 GPS 則 vdSpeed 會被上面的 stream 覆蓋，這裡只在沒有 stream 時模擬：
      if (_positionStreamSub == null) {
        vdSpeed = 70 + (DateTime.now().second % 20);
      }

      // 模擬事件是否出現（示範）
      if (vdSpeed < 75) {
        frontEvents = [
          {
            "type": AppLocalizations.of(context)!.text_626,
            "description": AppLocalizations.of(context)!.text_627,
            "distance": 2300
          }
        ];
      } else {
        frontEvents = []; // 沒事件
      }

      loading = false;
    });

    // 若有事件 → 自動警示
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
  // Bearing / Direction 工具
  // -----------------------------
  double _calcBearing(double lat1, double lon1, double lat2, double lon2) {
    final toRad = (double d) => d * pi / 180.0;
    final dLon = toRad(lon2 - lon1);
    final y = sin(dLon) * cos(toRad(lat2));
    final x = cos(toRad(lat1)) * sin(toRad(lat2)) - sin(toRad(lat1)) * cos(toRad(lat2)) * cos(dLon);
    final brng = atan2(y, x);
    return (brng * 180 / pi + 360) % 360;
  }

  String _bearingToDirection(double bearing) {
    if (bearing < 22.5 || bearing >= 337.5) return AppLocalizations.of(context)!.text_628;
    if (bearing < 67.5) return AppLocalizations.of(context)!.text_629;
    if (bearing < 112.5) return AppLocalizations.of(context)!.text_630;
    if (bearing < 157.5) return AppLocalizations.of(context)!.text_631;
    if (bearing < 202.5) return AppLocalizations.of(context)!.text_632;
    if (bearing < 247.5) return AppLocalizations.of(context)!.text_633;
    if (bearing < 292.5) return AppLocalizations.of(context)!.text_634;
    return AppLocalizations.of(context)!.text_635;
  }

  // -----------------------------
  // UI 主體（保持你原本 UI）
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.text_636,
          style: const TextStyle(
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
                AppLocalizations.of(context)!.text_637,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GPS：$gps", style: const TextStyle(fontSize: 16)),
                    Text("精度：約 ${gpsAccuracy.toStringAsFixed(1)} 公尺", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("行車方向：$direction", style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildCard(
                AppLocalizations.of(context)!.text_638,
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
                AppLocalizations.of(context)!.text_639,
                Text(
                  cmsMessage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                "即時速度（km/h）",
                Text(
                  vdSpeed.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              _buildCard(
                AppLocalizations.of(context)!.text_640,
                frontEvents.isEmpty
                    ?  Text(
                  AppLocalizations.of(context)!.text_641,
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
                    :  Text(AppLocalizations.of(context)!.text_642),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // 以下保持你原本的 menu 與 card 函式（請放回原本實作或保留）
  // -----------------------------
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
              const SizedBox(height: 16),

              _buildMenuOption(
                icon: Icons.info_outline_rounded,
                title: AppLocalizations.of(context)!.text_643,
                subtitle: AppLocalizations.of(context)!.text_644,
                color: const Color(0xFF1A73E8),
                onTap: _navigateToFreeWayInfo,
              ),

              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
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
        title:  Text(AppLocalizations.of(context)!.text_643),
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
            return  Center(child: Text(AppLocalizations.of(context)!.text_645));
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
                        event['EventTitle'] ?? AppLocalizations.of(context)!.text_646,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(location.isNotEmpty
                          ? '${location['Road'] ?? ''} ${location['Direction'] ?? ''} ${location['StartKM'] ?? ''}～${location['EndKM'] ?? ''} (${location['SectionStart'] ?? ''} → ${location['SectionEnd'] ?? ''})'
                          : AppLocalizations.of(context)!.text_647),
                      const SizedBox(height: 4),
                      Text('影響：${impact['Description'] ?? AppLocalizations.of(context)!.text_648}'),
                      Text('阻斷車道：${impact['BlockedLanes'] ?? AppLocalizations.of(context)!.text_648}'),
                      const SizedBox(height: 4),
                      Text('來源：${event['Source'] ?? AppLocalizations.of(context)!.text_321}'),
                      Text(
                          '發布時間：${event['PublishTime'] ?? AppLocalizations.of(context)!.text_321} 更新：${event['LastUpdateTime'] ?? AppLocalizations.of(context)!.text_321}'),
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









