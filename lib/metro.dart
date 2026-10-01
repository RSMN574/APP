import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'const/regular_const.dart';

// ==========================================
// 2. 資料模型 (Data Models)
// ==========================================

class MetroLine {
  final String id;
  final String name;
  final Color color;

  MetroLine({required this.id, required this.name, required this.color});
}

class Station {
  final String id;
  final String name;
  final Offset position;
  final List<String> lineIds;

  Station({
    required this.id,
    required this.name,
    required this.position,
    required this.lineIds,
  });

  bool get isTransfer => lineIds.length > 1;
}

class Edge {
  final String stationA;
  final String stationB;
  final String lineId;

  Edge(this.stationA, this.stationB, this.lineId);
}

class CityMetroData {
  final String id;
  final String name;
  final List<MetroLine> lines;
  final List<Station> stations;
  final List<Edge> edges;

  CityMetroData({
    required this.id,
    required this.name,
    required this.lines,
    required this.stations,
    required this.edges,
  });
}

class RouteResult {
  final List<Station> path;
  final int fare;
  final int durationMinutes;
  final int stationCount;
  final int transferCount;

  RouteResult({
    required this.path,
    required this.fare,
    required this.durationMinutes,
    required this.stationCount,
    required this.transferCount,
  });
}

// ==========================================
// 3. 完整縣市捷運資料庫 (Complete Metro Datasets)
// ==========================================

class MetroRepository {
  static final CityMetroData taipei = CityMetroData(
    id: 'taipei',
    name: '台北捷運 (Taipei MRT)',
    lines: [
      MetroLine(id: 'R', name: '淡水信義線', color: const Color(0xFFE50012)),
      MetroLine(id: 'BL', name: '板南線', color: const Color(0xFF0070BD)),
      MetroLine(id: 'G', name: '松山新店線', color: const Color(0xFF008659)),
      MetroLine(id: 'O', name: '中和新蘆線', color: const Color(0xFFF8B61C)),
      MetroLine(id: 'BR', name: '文湖線', color: const Color(0xFFC48C31)),
    ],
    stations: [
      // 紅線 (R)
      Station(
          id: 'R28',
          name: '淡水',
          position: const Offset(300, 60),
          lineIds: ['R']),
      Station(
          id: 'R22',
          name: '北投',
          position: const Offset(300, 120),
          lineIds: ['R']),
      Station(
          id: 'R16',
          name: '士林',
          position: const Offset(300, 180),
          lineIds: ['R']),
      Station(
          id: 'R13_O11',
          name: '民權西路',
          position: const Offset(300, 240),
          lineIds: ['R', 'O']),
      Station(
          id: 'R11_G14',
          name: '中山',
          position: const Offset(300, 300),
          lineIds: ['R', 'G']),
      Station(
          id: 'R10_BL12',
          name: '台北車站',
          position: const Offset(300, 360),
          lineIds: ['R', 'BL']),
      Station(
          id: 'R08_G10',
          name: '中正紀念堂',
          position: const Offset(300, 440),
          lineIds: ['R', 'G']),
      Station(
          id: 'R05_BR09',
          name: '大安',
          position: const Offset(420, 440),
          lineIds: ['R', 'BR']),
      Station(
          id: 'R02',
          name: '象山',
          position: const Offset(520, 440),
          lineIds: ['R']),

      // 板南線 (BL)
      Station(
          id: 'BL07',
          name: '板橋',
          position: const Offset(120, 360),
          lineIds: ['BL']),
      Station(
          id: 'BL11_G12',
          name: '西門',
          position: const Offset(210, 360),
          lineIds: ['BL', 'G']),
      Station(
          id: 'BL14_O07',
          name: '忠孝新生',
          position: const Offset(380, 360),
          lineIds: ['BL', 'O']),
      Station(
          id: 'BL15_BR10',
          name: '忠孝復興',
          position: const Offset(460, 360),
          lineIds: ['BL', 'BR']),
      Station(
          id: 'BL22',
          name: '南港',
          position: const Offset(560, 360),
          lineIds: ['BL']),

      // 綠線 (G)
      Station(
          id: 'G19',
          name: '松山',
          position: const Offset(560, 240),
          lineIds: ['G']),
      Station(
          id: 'G16_BR11',
          name: '南京復興',
          position: const Offset(460, 240),
          lineIds: ['G', 'BR']),
      Station(
          id: 'G09_O05',
          name: '古亭',
          position: const Offset(300, 500),
          lineIds: ['G', 'O']),
      Station(
          id: 'G05',
          name: '公館',
          position: const Offset(300, 560),
          lineIds: ['G']),
      Station(
          id: 'G01',
          name: '新店',
          position: const Offset(300, 620),
          lineIds: ['G']),

      // 橘線 (O)
      Station(
          id: 'O01',
          name: '迴龍',
          position: const Offset(120, 240),
          lineIds: ['O']),
      Station(
          id: 'O06_R07',
          name: '東門',
          position: const Offset(380, 440),
          lineIds: ['O', 'R']),

      // 文湖線 (BR)
      Station(
          id: 'BR13',
          name: '松山機場',
          position: const Offset(460, 160),
          lineIds: ['BR']),
      Station(
          id: 'BR01',
          name: '動物園',
          position: const Offset(460, 560),
          lineIds: ['BR']),
    ],
    edges: [
      // 淡水信義線
      Edge('R28', 'R22', 'R'),
      Edge('R22', 'R16', 'R'),
      Edge('R16', 'R13_O11', 'R'),
      Edge('R13_O11', 'R11_G14', 'R'),
      Edge('R11_G14', 'R10_BL12', 'R'),
      Edge('R10_BL12', 'R08_G10', 'R'),
      Edge('R08_G10', 'O06_R07', 'R'),
      Edge('O06_R07', 'R05_BR09', 'R'),
      Edge('R05_BR09', 'R02', 'R'),

      // 板南線
      Edge('BL07', 'BL11_G12', 'BL'),
      Edge('BL11_G12', 'R10_BL12', 'BL'),
      Edge('R10_BL12', 'BL14_O07', 'BL'),
      Edge('BL14_O07', 'BL15_BR10', 'BL'),
      Edge('BL15_BR10', 'BL22', 'BL'),

      // 松山新店線
      Edge('G19', 'G16_BR11', 'G'),
      Edge('G16_BR11', 'R11_G14', 'G'),
      Edge('R11_G14', 'BL11_G12', 'G'),
      Edge('BL11_G12', 'R08_G10', 'G'),
      Edge('R08_G10', 'G09_O05', 'G'),
      Edge('G09_O05', 'G05', 'G'),
      Edge('G05', 'G01', 'G'),

      // 中和新蘆線
      Edge('O01', 'R13_O11', 'O'),
      Edge('R13_O11', 'BL14_O07', 'O'),
      Edge('BL14_O07', 'O06_R07', 'O'),
      Edge('O06_R07', 'G09_O05', 'O'),

      // 文湖線
      Edge('BR13', 'G16_BR11', 'BR'),
      Edge('G16_BR11', 'BL15_BR10', 'BR'),
      Edge('BL15_BR10', 'R05_BR09', 'BR'),
      Edge('R05_BR09', 'BR01', 'BR'),
    ],
  );

  static final CityMetroData kaohsiung = CityMetroData(
    id: 'kaohsiung',
    name: '高雄捷運 (Kaohsiung MRT)',
    lines: [
      MetroLine(id: 'R', name: '紅線', color: const Color(0xFFE2001A)),
      MetroLine(id: 'O', name: '橘線', color: const Color(0xFFF39800)),
    ],
    stations: [
      Station(
          id: 'R24',
          name: '岡山',
          position: const Offset(320, 80),
          lineIds: ['R']),
      Station(
          id: 'R16',
          name: '左營',
          position: const Offset(320, 160),
          lineIds: ['R']),
      Station(
          id: 'R11',
          name: '高雄車站',
          position: const Offset(320, 240),
          lineIds: ['R']),
      Station(
          id: 'R10_O5',
          name: '美麗島',
          position: const Offset(320, 320),
          lineIds: ['R', 'O']),
      Station(
          id: 'R8',
          name: '三多商圈',
          position: const Offset(320, 400),
          lineIds: ['R']),
      Station(
          id: 'R4A',
          name: '草衙',
          position: const Offset(320, 480),
          lineIds: ['R']),
      Station(
          id: 'R3',
          name: '小港',
          position: const Offset(320, 560),
          lineIds: ['R']),
      Station(
          id: 'O1',
          name: '哈瑪星',
          position: const Offset(160, 320),
          lineIds: ['O']),
      Station(
          id: 'O2',
          name: '鹽埕埔',
          position: const Offset(240, 320),
          lineIds: ['O']),
      Station(
          id: 'O7',
          name: '文化中心',
          position: const Offset(420, 320),
          lineIds: ['O']),
      Station(
          id: 'O10',
          name: '衛武營',
          position: const Offset(500, 320),
          lineIds: ['O']),
      Station(
          id: 'O14',
          name: '大寮',
          position: const Offset(580, 320),
          lineIds: ['O']),
    ],
    edges: [
      Edge('R24', 'R16', 'R'),
      Edge('R16', 'R11', 'R'),
      Edge('R11', 'R10_O5', 'R'),
      Edge('R10_O5', 'R8', 'R'),
      Edge('R8', 'R4A', 'R'),
      Edge('R4A', 'R3', 'R'),
      Edge('O1', 'O2', 'O'),
      Edge('O2', 'R10_O5', 'O'),
      Edge('R10_O5', 'O7', 'O'),
      Edge('O7', 'O10', 'O'),
      Edge('O10', 'O14', 'O'),
    ],
  );

  static final CityMetroData taichung = CityMetroData(
    id: 'taichung',
    name: '台中捷運 (Taichung MRT)',
    lines: [
      MetroLine(id: 'G', name: '綠線', color: const Color(0xFF46B131)),
    ],
    stations: [
      // 北屯總站方向（由北到南）
      Station(
          id: '103a',
          name: '北屯總站',
          position: const Offset(480, 100),
          lineIds: ['G']),
      Station(
          id: '103',
          name: '舊社',
          position: const Offset(440, 130),
          lineIds: ['G']),
      Station(
          id: '104',
          name: '松竹',
          position: const Offset(400, 160),
          lineIds: ['G']),
      Station(
          id: '105',
          name: '四維國小',
          position: const Offset(360, 190),
          lineIds: ['G']),
      Station(
          id: '106',
          name: '文心崇德',
          position: const Offset(320, 220),
          lineIds: ['G']),
      Station(
          id: '107',
          name: '文心中清',
          position: const Offset(300, 260),
          lineIds: ['G']),
      Station(
          id: '108',
          name: '文華高中',
          position: const Offset(280, 300),
          lineIds: ['G']),
      Station(
          id: '109',
          name: '文心櫻花',
          position: const Offset(260, 340),
          lineIds: ['G']),
      Station(
          id: '110',
          name: '市政府',
          position: const Offset(240, 380),
          lineIds: ['G']),
      Station(
          id: '111',
          name: '水安宮',
          position: const Offset(240, 420),
          lineIds: ['G']),
      Station(
          id: '112',
          name: '文心森林公園',
          position: const Offset(240, 460),
          lineIds: ['G']),
      Station(
          id: '113',
          name: '南屯',
          position: const Offset(240, 500),
          lineIds: ['G']),
      Station(
          id: '114',
          name: '豐樂公園',
          position: const Offset(240, 540),
          lineIds: ['G']),
      Station(
          id: '115',
          name: '大慶',
          position: const Offset(240, 580),
          lineIds: ['G']),
      Station(
          id: '116',
          name: '九張犁',
          position: const Offset(210, 610),
          lineIds: ['G']),
      Station(
          id: '117',
          name: '九德',
          position: const Offset(190, 640),
          lineIds: ['G']),
      Station(
          id: '118',
          name: '烏日',
          position: const Offset(170, 670),
          lineIds: ['G']),
      Station(
          id: '119',
          name: '高鐵台中站',
          position: const Offset(150, 700),
          lineIds: ['G']),
    ],
    edges: [
      // 完整順序（由北到南）
      Edge('103a', '103', 'G'),
      Edge('103', '104', 'G'),
      Edge('104', '105', 'G'),
      Edge('105', '106', 'G'),
      Edge('106', '107', 'G'),
      Edge('107', '108', 'G'),
      Edge('108', '109', 'G'),
      Edge('109', '110', 'G'),
      Edge('110', '111', 'G'),
      Edge('111', '112', 'G'),
      Edge('112', '113', 'G'),
      Edge('113', '114', 'G'),
      Edge('114', '115', 'G'),
      Edge('115', '116', 'G'),
      Edge('116', '117', 'G'),
      Edge('117', '118', 'G'),
      Edge('118', '119', 'G'),
    ],
  );

  static List<CityMetroData> get allCities => [taipei, kaohsiung, taichung];
}

// ==========================================
// 4. 主元件 (Main StatefulWidget)
// ==========================================

class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro> with SingleTickerProviderStateMixin {
  late CityMetroData _currentCity;
  Station? _startStation;
  Station? _endStation;
  RouteResult? _routeResult;

  final TransformationController _transformationController =
  TransformationController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _glowAnimationController;

  List<Station> _filteredStations = [];

  Rect get _stationBounds {
    if (_currentCity.stations.isEmpty) {
      return Rect.zero;
    }
    final positions = _currentCity.stations.map((station) => station.position);
    final minX = positions.map((position) => position.dx).reduce(min);
    final maxX = positions.map((position) => position.dx).reduce(max);
    final minY = positions.map((position) => position.dy).reduce(min);
    final maxY = positions.map((position) => position.dy).reduce(max);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Offset get _mapOrigin => Offset(
    _stationBounds.left - 56,
    _stationBounds.top - 56,
  );

  Offset _mapPosition(Offset position) => position - _mapOrigin;

  Size _mapSize(Size viewportSize) {
    const mapPadding = 112.0;
    final bounds = _stationBounds;
    return Size(
      max(viewportSize.width, bounds.width + mapPadding),
      max(viewportSize.height, bounds.height + mapPadding),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentCity = MetroRepository.taipei;
    _filteredStations = _currentCity.stations;

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _changeCity(CityMetroData city) {
    setState(() {
      _currentCity = city;
      _filteredStations = city.stations;
      _searchController.clear();
      _startStation = null;
      _endStation = null;
      _routeResult = null;
      _resetZoom();
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _filterStations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStations = _currentCity.stations;
      } else {
        _filteredStations =
            _currentCity.stations.where((s) => s.name.contains(query)).toList();
      }
    });
  }

  void _onStationTapped(Station station) {
    setState(() {
      if (_startStation == null ||
          (_startStation != null && _endStation != null)) {
        _startStation = station;
        _endStation = null;
        _routeResult = null;
      } else if (_startStation == station) {
        _startStation = null;
      } else {
        _endStation = station;
        _calculateRoute();
      }
    });
    _showStationDialog(station);
  }

  void _calculateRoute() {
    if (_startStation == null || _endStation == null) return;

    final String startId = _startStation!.id;
    final String targetId = _endStation!.id;

    Map<String, List<Edge>> graph = {};
    for (var edge in _currentCity.edges) {
      graph.putIfAbsent(edge.stationA, () => []).add(edge);
      graph
          .putIfAbsent(edge.stationB, () => [])
          .add(Edge(edge.stationB, edge.stationA, edge.lineId));
    }

    List<String>? bestPathIds;
    Queue<List<String>> queue = Queue();
    Set<String> visited = {startId};

    queue.add([startId]);

    while (queue.isNotEmpty) {
      List<String> path = queue.removeFirst();
      String current = path.last;

      if (current == targetId) {
        bestPathIds = path;
        break;
      }

      for (var neighborEdge in graph[current] ?? []) {
        if (!visited.contains(neighborEdge.stationB)) {
          visited.add(neighborEdge.stationB);
          queue.add([...path, neighborEdge.stationB]);
        }
      }
    }

    if (bestPathIds != null) {
      List<Station> pathStations = bestPathIds
          .map((id) => _currentCity.stations.firstWhere((s) => s.id == id))
          .toList();

      int stationCount = pathStations.length - 1;
      int transfers = 0;
      String? currentLine;

      for (int i = 0; i < pathStations.length - 1; i++) {
        String a = pathStations[i].id;
        String b = pathStations[i + 1].id;
        var edge = _currentCity.edges.firstWhere(
              (e) =>
          (e.stationA == a && e.stationB == b) ||
              (e.stationA == b && e.stationB == a),
        );

        if (currentLine != null && currentLine != edge.lineId) {
          transfers++;
        }
        currentLine = edge.lineId;
      }

      int fare = 20 + ((stationCount / 3).floor() * 5);
      int duration = (stationCount * 2) + (transfers * 4) + 3;

      setState(() {
        _routeResult = RouteResult(
          path: pathStations,
          fare: fare,
          durationMinutes: duration,
          stationCount: stationCount,
          transferCount: transfers,
        );
      });
    }
  }

  // 規範需求：對話框選擇與卡片 modal
  void _showStationDialog(Station station) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 圖標容器 (寬高 48px，漸變背景，圓角 14px，白色圖標)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, blue],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.subway_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '車站代碼: ${station.id}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (station.isTransfer)
                      _buildTag('轉乘站', colorScheme.tertiary),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: station.lineIds.map((lId) {
                    final line =
                    _currentCity.lines.firstWhere((l) => l.id == lId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTag(line.name, line.color),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildGradientButton(
                        label: '設為起點',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          setState(() {
                            _startStation = station;
                            if (_endStation == station) _endStation = null;
                            _calculateRoute();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOutlineButton(
                        label: '設為終點',
                        icon: Icons.flag_rounded,
                        onPressed: () {
                          setState(() {
                            _endStation = station;
                            if (_startStation == station) _startStation = null;
                            _calculateRoute();
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 規範需求：標籤 (圓角 20px，背景色 10% 透明度，邊框 30% 透明度)
  Widget _buildTag(String text, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: baseColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 規範需求：主要按鈕樣式 (漸變 #1A73E8 到 #1A73E8(80%)，圓角 12px，陰影 #1A73E8 30% 透明度，模糊 12px)
  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, blue],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 18),
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) const Icon(Icons.subway, color: primary, size: 18),
          if (icon != null) const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final citySelector = DropdownButtonHideUnderline(
      child: DropdownButton<CityMetroData>(
        isExpanded: true,
        value: _currentCity,
        icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
        style: Theme.of(context).textTheme.titleMedium,
        items: MetroRepository.allCities.map((city) {
          return DropdownMenuItem(
            value: city,
            child:
            Text(city.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (city) => city != null ? _changeCity(city) : null,
      ),
    );
    final searchField = Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStations,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: '搜尋車站...',
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: colorScheme.onSurfaceVariant,
              size: 18,
            ),
            onPressed: () {
              _searchController.clear();
              _filterStations('');
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // 規範需求：AppBar 白色背景，無陰影，標題 20px 字重 700 主色，居中
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '捷運路線與票價查詢',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.center_focus_strong, color: colorScheme.primary),
            tooltip: '重置視角',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 規範需求：搜尋輸入框與城市選擇卡片
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surface,
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              child: citySelector,
                            ),
                            const SizedBox(height: 8),
                            searchField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(width: 220, child: citySelector),
                          const SizedBox(width: 12),
                          Expanded(child: searchField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // 主畫布區域 (Canvas Map & Floating Card Overlays)
            Expanded(
              child: Stack(
                children: [
                  // 向量縮放地圖 (Pan & Zoom Canvas)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final mapSize = _mapSize(viewportSize);
                      final visibleStationIds = _filteredStations
                          .map((station) => station.id)
                          .toSet();

                      return InteractiveViewer(
                        transformationController: _transformationController,
                        constrained: false,
                        minScale: 0.5,
                        maxScale: 3.5,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: SizedBox(
                          key: const ValueKey('metro-route-canvas'),
                          width: mapSize.width,
                          height: mapSize.height,
                          child: AnimatedBuilder(
                            animation: _glowAnimationController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: mapSize,
                                painter: MetroMapPainter(
                                  cityData: _currentCity,
                                  startStation: _startStation,
                                  endStation: _endStation,
                                  routeResult: _routeResult,
                                  animationValue:
                                  _glowAnimationController.value,
                                  mapOrigin: _mapOrigin,
                                  visibleStationIds: visibleStationIds,
                                  backgroundColor: colorScheme.surface,
                                  gridColor: colorScheme.outlineVariant,
                                  stationLabelColor: colorScheme.onSurface,
                                ),
                                child: Stack(
                                  children: _filteredStations.map((station) {
                                    final isStart =
                                        _startStation?.id == station.id;
                                    final isEnd = _endStation?.id == station.id;
                                    final isInRoute = _routeResult?.path.any(
                                            (item) => item.id == station.id) ??
                                        false;
                                    final stationPosition =
                                    _mapPosition(station.position);

                                    return Positioned(
                                      key: ValueKey(station.id),
                                      left: stationPosition.dx - 18,
                                      top: stationPosition.dy - 18,
                                      child: Semantics(
                                        button: true,
                                        label: '${station.name}，${station.id}',
                                        child: Tooltip(
                                          message:
                                          '${station.name} (${station.id})',
                                          child: GestureDetector(
                                            onTap: () =>
                                                _onStationTapped(station),
                                            child: SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: Center(
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                  width: (isStart || isEnd)
                                                      ? 22
                                                      : 14,
                                                  height: (isStart || isEnd)
                                                      ? 22
                                                      : 14,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isStart
                                                        ? startColor
                                                        : isEnd
                                                        ? endColor
                                                        : isInRoute
                                                        ? primary
                                                        : colorScheme
                                                        .surface,
                                                    border: Border.all(
                                                      color: (isStart ||
                                                          isEnd ||
                                                          isInRoute)
                                                          ? primary
                                                          : colorScheme
                                                          .onSurfaceVariant,
                                                      width: station.isTransfer
                                                          ? 3
                                                          : 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  // 起終點即時提示小卡 (通知中心風格卡片)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const CircleAvatar(
                                    radius: 5, backgroundColor: startColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startStation?.name ?? '選擇起點',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: (_startStation != null
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        : Theme.of(context)
                                        .textTheme
                                        .bodyMedium)
                                        ?.copyWith(
                                      color: _startStation != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.east_rounded,
                              color: colorScheme.onSurfaceVariant, size: 18),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    _endStation?.name ?? '選擇終點',
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: (_endStation != null
                                        ? Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        : Theme.of(context)
                                        .textTheme
                                        .bodyMedium)
                                        ?.copyWith(
                                      color: _endStation != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                    radius: 5, backgroundColor: endColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 規範需求：通知中心風格的列表查詢結果卡片
                  if (_routeResult != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.08),
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
                                // 圖標容器 (48px, 漸變, 白色圖標)
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [colorScheme.primary, blue],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                      Icons.directions_subway_rounded,
                                      color: Colors.white,
                                      size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '規劃路線資訊',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '經過 ${_routeResult!.stationCount} 站 · 轉乘 ${_routeResult!.transferCount} 次',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                _buildTag(
                                    'NT\$ ${_routeResult!.fare}', startColor),
                              ],
                            ),
                            Divider(
                              height: 24,
                              color: colorScheme.outlineVariant,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '預估時間: ~${_routeResult!.durationMinutes} 分鐘',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '單程票價: NT\$ ${_routeResult!.fare}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 行經路徑水平捲動標籤
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _routeResult!.path
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int idx = entry.key;
                                  Station s = entry.value;
                                  bool isLast =
                                      idx == _routeResult!.path.length - 1;
                                  return Row(
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          color: (idx == 0)
                                              ? startColor
                                              : isLast
                                              ? endColor
                                              : colorScheme.onSurface,
                                          fontWeight: (idx == 0 || isLast)
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (!isLast)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: colorScheme.onSurfaceVariant,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. 向量路網與動態發光繪製器 (Custom Painter)
// ==========================================

class MetroMapPainter extends CustomPainter {
  final CityMetroData cityData;
  final Station? startStation;
  final Station? endStation;
  final RouteResult? routeResult;
  final double animationValue;
  final Offset mapOrigin;
  final Set<String> visibleStationIds;
  final Color backgroundColor;
  final Color gridColor;
  final Color stationLabelColor;

  MetroMapPainter({
    required this.cityData,
    this.startStation,
    this.endStation,
    this.routeResult,
    required this.animationValue,
    required this.mapOrigin,
    required this.visibleStationIds,
    required this.backgroundColor,
    required this.gridColor,
    required this.stationLabelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(backgroundColor, BlendMode.src);

    // 微弱背景網格
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 1. 繪製預設捷運路線軌跡
    for (var edge in cityData.edges) {
      final stationA =
      cityData.stations.firstWhere((s) => s.id == edge.stationA);
      final stationB =
      cityData.stations.firstWhere((s) => s.id == edge.stationB);
      final line = cityData.lines.firstWhere((l) => l.id == edge.lineId);

      final linePaint = Paint()
        ..color =
        line.color.withValues(alpha: routeResult != null ? 0.25 : 0.85)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        stationA.position - mapOrigin,
        stationB.position - mapOrigin,
        linePaint,
      );
    }

    // 2. 繪製計算後的高亮動態發光路線 (Route Highlighting)
    if (routeResult != null && routeResult!.path.length > 1) {
      Path routePath = Path();
      final firstPosition = routeResult!.path.first.position - mapOrigin;
      routePath.moveTo(firstPosition.dx, firstPosition.dy);

      for (int i = 1; i < routeResult!.path.length; i++) {
        final position = routeResult!.path[i].position - mapOrigin;
        routePath.lineTo(position.dx, position.dy);
      }

      // 脈衝發光底影
      final glowPaint = Paint()
        ..color = primary.withValues(
          alpha: 0.3 + 0.2 * sin(animationValue * pi * 2),
        )
        ..strokeWidth = 12.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // 主路徑線條
      final corePathPaint = Paint()
        ..color = primary
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(routePath, glowPaint);
      canvas.drawPath(routePath, corePathPaint);
    }

    // 3. 繪製站名文字標籤
    for (var station in cityData.stations) {
      if (!visibleStationIds.contains(station.id)) continue;
      final textPainter = TextPainter(
        text: TextSpan(
          text: station.name,
          style: TextStyle(
            color: stationLabelColor,
            fontSize: 12,
            fontWeight: station.isTransfer ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          station.position.dx - mapOrigin.dx - textPainter.width / 2,
          station.position.dy - mapOrigin.dy + 14,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MetroMapPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.routeResult != routeResult ||
        oldDelegate.startStation != startStation ||
        oldDelegate.endStation != endStation ||
        oldDelegate.cityData != cityData ||
        oldDelegate.mapOrigin != mapOrigin ||
        oldDelegate.visibleStationIds.length != visibleStationIds.length ||
        !oldDelegate.visibleStationIds.containsAll(visibleStationIds) ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.stationLabelColor != stationLabelColor;
  }
}
