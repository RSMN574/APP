import 'package:flutter/material.dart';

import 'dart:ui';

import 'get_metro.dart';

class CityInfo {
  final String id;
  final String name;

  CityInfo({required this.id, required this.name});

  factory CityInfo.fromJson(Map<String, dynamic> json) {
    return CityInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}
// ==========================================
// 1. MetroLine
// ==========================================
class MetroLine {
  final String id;
  final String name;
  final Color color;

  MetroLine({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value.toRadixString(16).padLeft(8, '0'), // 例如 "ffe50012"
  };

  factory MetroLine.fromJson(Map<String, dynamic> json) {
    return MetroLine(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(int.parse('0x${json['color']}')),
    );
  }
}

// ==========================================
// 2. Station
// ==========================================
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': position.dx,
    'y': position.dy,
    'lineIds': lineIds,
  };

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      lineIds: List<String>.from(json['lineIds']),
    );
  }
}

// ==========================================
// 3. Edge
// ==========================================
class Edge {
  final String stationA;
  final String stationB;
  final String lineId;

  Edge(this.stationA, this.stationB, this.lineId);

  Map<String, dynamic> toJson() => {
    'stationA': stationA,
    'stationB': stationB,
    'lineId': lineId,
  };

  factory Edge.fromJson(Map<String, dynamic> json) {
    return Edge(
      json['stationA'] as String,
      json['stationB'] as String,
      json['lineId'] as String,
    );
  }
}

// ==========================================
// 4. CityMetroData
// ==========================================
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lines': lines.map((e) => e.toJson()).toList(),
    'stations': stations.map((e) => e.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };

  factory CityMetroData.fromJson(Map<String, dynamic> json) {
    return CityMetroData(
      id: json['id'] as String,
      name: json['name'] as String,
      lines: (json['lines'] as List)
          .map((e) => MetroLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      stations: (json['stations'] as List)
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList(),
      edges: (json['edges'] as List)
          .map((e) => Edge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ==========================================
// 5. RouteResult
// ==========================================
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

  Map<String, dynamic> toJson() => {
    'path': path.map((e) => e.toJson()).toList(),
    'fare': fare,
    'durationMinutes': durationMinutes,
    'stationCount': stationCount,
    'transferCount': transferCount,
  };

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      path: (json['path'] as List)
          .map((e) => Station.fromJson(e as Map<String, dynamic>))
          .toList(),
      fare: json['fare'] as int,
      durationMinutes: json['durationMinutes'] as int,
      stationCount: json['stationCount'] as int,
      transferCount: json['transferCount'] as int,
    );
  }
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
      // ==========================================
      // 淡水信義線 (R) - 含新北投支線
      // ==========================================
      Station(id: 'R01', name: '廣慈/奉天宮', position: const Offset(780, 600), lineIds: ['R']),
      Station(id: 'R02', name: '象山', position: const Offset(730, 600), lineIds: ['R']),
      Station(id: 'R03', name: '台北101/世貿', position: const Offset(680, 600), lineIds: ['R']),
      Station(id: 'R04', name: '信義安和', position: const Offset(640, 600), lineIds: ['R']),
      Station(id: 'R05', name: '大安', position: const Offset(600, 600), lineIds: ['R', 'BR']),
      Station(id: 'R06', name: '大安森林公園', position: const Offset(550, 600), lineIds: ['R']),
      Station(id: 'R07', name: '東門', position: const Offset(500, 600), lineIds: ['R', 'O']),
      Station(id: 'R08', name: '中正紀念堂', position: const Offset(430, 600), lineIds: ['R', 'G']),
      Station(id: 'R09', name: '台大醫院', position: const Offset(430, 560), lineIds: ['R']),
      Station(id: 'R10', name: '台北車站', position: const Offset(430, 520), lineIds: ['R', 'BL']),
      Station(id: 'R11', name: '中山', position: const Offset(430, 470), lineIds: ['R', 'G']),
      Station(id: 'R12', name: '雙連', position: const Offset(430, 430), lineIds: ['R']),
      Station(id: 'R13', name: '民權西路', position: const Offset(430, 390), lineIds: ['R', 'O']),
      Station(id: 'R14', name: '圓山', position: const Offset(430, 350), lineIds: ['R']),
      Station(id: 'R15', name: '劍潭', position: const Offset(430, 310), lineIds: ['R']),
      Station(id: 'R16', name: '士林', position: const Offset(430, 270), lineIds: ['R']),
      Station(id: 'R17', name: '芝山', position: const Offset(430, 240), lineIds: ['R']),
      Station(id: 'R18', name: '明德', position: const Offset(430, 210), lineIds: ['R']),
      Station(id: 'R19', name: '石牌', position: const Offset(430, 180), lineIds: ['R']),
      Station(id: 'R20', name: '唭哩岸', position: const Offset(410, 155), lineIds: ['R']),
      Station(id: 'R21', name: '奇岩', position: const Offset(390, 135), lineIds: ['R']),
      Station(id: 'R22', name: '北投', position: const Offset(360, 115), lineIds: ['R']),
      Station(id: 'R22A', name: '新北投', position: const Offset(390, 85), lineIds: ['R']),
      Station(id: 'R23', name: '復興崗', position: const Offset(320, 115), lineIds: ['R']),
      Station(id: 'R24', name: '忠義', position: const Offset(280, 115), lineIds: ['R']),
      Station(id: 'R25', name: '關渡', position: const Offset(240, 115), lineIds: ['R']),
      Station(id: 'R26', name: '竹圍', position: const Offset(200, 100), lineIds: ['R']),
      Station(id: 'R27', name: '紅樹林', position: const Offset(180, 75), lineIds: ['R']),
      Station(id: 'R28', name: '淡水', position: const Offset(160, 50), lineIds: ['R']),

      // ==========================================
      // 板南線 (BL)
      // ==========================================
      Station(id: 'BL01', name: '頂埔', position: const Offset(180, 840), lineIds: ['BL']),
      Station(id: 'BL02', name: '永寧', position: const Offset(180, 800), lineIds: ['BL']),
      Station(id: 'BL03', name: '土城', position: const Offset(180, 760), lineIds: ['BL']),
      Station(id: 'BL04', name: '海山', position: const Offset(180, 720), lineIds: ['BL']),
      Station(id: 'BL05', name: '亞東醫院', position: const Offset(180, 680), lineIds: ['BL']),
      Station(id: 'BL06', name: '府中', position: const Offset(180, 640), lineIds: ['BL']),
      Station(id: 'BL07', name: '板橋', position: const Offset(210, 610), lineIds: ['BL']),
      Station(id: 'BL08', name: '新埔', position: const Offset(250, 580), lineIds: ['BL']),
      Station(id: 'BL09', name: '江子翠', position: const Offset(290, 550), lineIds: ['BL']),
      Station(id: 'BL10', name: '龍山寺', position: const Offset(335, 520), lineIds: ['BL']),
      Station(id: 'BL11', name: '西門', position: const Offset(380, 520), lineIds: ['BL', 'G']),
      Station(id: 'BL12', name: '台北車站', position: const Offset(430, 520), lineIds: ['BL', 'R']),
      Station(id: 'BL13', name: '善導寺', position: const Offset(480, 520), lineIds: ['BL']),
      Station(id: 'BL14', name: '忠孝新生', position: const Offset(530, 520), lineIds: ['BL', 'O']),
      Station(id: 'BL15', name: '忠孝復興', position: const Offset(600, 520), lineIds: ['BL', 'BR']),
      Station(id: 'BL16', name: '忠孝敦化', position: const Offset(650, 520), lineIds: ['BL']),
      Station(id: 'BL17', name: '國父紀念館', position: const Offset(700, 520), lineIds: ['BL']),
      Station(id: 'BL18', name: '市政府', position: const Offset(740, 520), lineIds: ['BL']),
      Station(id: 'BL19', name: '永春', position: const Offset(780, 520), lineIds: ['BL']),
      Station(id: 'BL20', name: '後山埤', position: const Offset(815, 520), lineIds: ['BL']),
      Station(id: 'BL21', name: '昆陽', position: const Offset(845, 520), lineIds: ['BL']),
      Station(id: 'BL22', name: '南港', position: const Offset(870, 520), lineIds: ['BL']),
      Station(id: 'BL23', name: '南港展覽館', position: const Offset(880, 520), lineIds: ['BL', 'BR']),

      // ==========================================
      // 松山新店線 (G) - 含小碧潭支線
      // ==========================================
      Station(id: 'G19', name: '松山', position: const Offset(760, 470), lineIds: ['G']),
      Station(id: 'G18', name: '南京三民', position: const Offset(700, 470), lineIds: ['G']),
      Station(id: 'G17', name: '台北小巨蛋', position: const Offset(650, 470), lineIds: ['G']),
      Station(id: 'G16', name: '南京復興', position: const Offset(600, 470), lineIds: ['G', 'BR']),
      Station(id: 'G15', name: '松江南京', position: const Offset(530, 470), lineIds: ['G', 'O']),
      Station(id: 'G14', name: '中山', position: const Offset(430, 470), lineIds: ['G', 'R']),
      Station(id: 'G13', name: '北門', position: const Offset(380, 470), lineIds: ['G']),
      Station(id: 'G12', name: '西門', position: const Offset(380, 520), lineIds: ['G', 'BL']),
      Station(id: 'G11', name: '小南門', position: const Offset(380, 570), lineIds: ['G']),
      Station(id: 'G10', name: '中正紀念堂', position: const Offset(430, 600), lineIds: ['G', 'R']),
      Station(id: 'G09', name: '古亭', position: const Offset(430, 660), lineIds: ['G', 'O']),
      Station(id: 'G08', name: '台電大樓', position: const Offset(470, 700), lineIds: ['G']),
      Station(id: 'G07', name: '公館', position: const Offset(500, 730), lineIds: ['G']),
      Station(id: 'G06', name: '萬隆', position: const Offset(520, 770), lineIds: ['G']),
      Station(id: 'G05', name: '景美', position: const Offset(520, 810), lineIds: ['G']),
      Station(id: 'G04', name: '大坪林', position: const Offset(520, 850), lineIds: ['G']),
      Station(id: 'G03', name: '七張', position: const Offset(520, 890), lineIds: ['G']),
      Station(id: 'G03A', name: '小碧潭', position: const Offset(470, 910), lineIds: ['G']),
      Station(id: 'G02', name: '新店區公所', position: const Offset(520, 930), lineIds: ['G']),
      Station(id: 'G01', name: '新店', position: const Offset(520, 960), lineIds: ['G']),

      // ==========================================
      // 中和新蘆線 (O)
      // ==========================================
      Station(id: 'O01', name: '南勢角', position: const Offset(430, 870), lineIds: ['O']),
      Station(id: 'O02', name: '景安', position: const Offset(430, 830), lineIds: ['O']),
      Station(id: 'O03', name: '永安市場', position: const Offset(430, 780), lineIds: ['O']),
      Station(id: 'O04', name: '頂溪', position: const Offset(430, 720), lineIds: ['O']),
      Station(id: 'O05', name: '古亭', position: const Offset(430, 660), lineIds: ['O', 'G']),
      Station(id: 'O06', name: '東門', position: const Offset(500, 600), lineIds: ['O', 'R']),
      Station(id: 'O07', name: '忠孝新生', position: const Offset(530, 520), lineIds: ['O', 'BL']),
      Station(id: 'O08', name: '松江南京', position: const Offset(530, 470), lineIds: ['O', 'G']),
      Station(id: 'O09', name: '行天宮', position: const Offset(530, 420), lineIds: ['O']),
      Station(id: 'O10', name: '中山國小', position: const Offset(480, 390), lineIds: ['O']),
      Station(id: 'O11', name: '民權西路', position: const Offset(430, 390), lineIds: ['O', 'R']),
      Station(id: 'O12', name: '大橋頭', position: const Offset(360, 390), lineIds: ['O']),
      // 迴龍支線
      Station(id: 'O13', name: '台北橋', position: const Offset(310, 420), lineIds: ['O']),
      Station(id: 'O14', name: '菜寮', position: const Offset(270, 450), lineIds: ['O']),
      Station(id: 'O15', name: '三重', position: const Offset(230, 480), lineIds: ['O']),
      Station(id: 'O16', name: '先嗇宮', position: const Offset(190, 510), lineIds: ['O']),
      Station(id: 'O17', name: '頭前庄', position: const Offset(150, 540), lineIds: ['O']),
      Station(id: 'O18', name: '新莊', position: const Offset(120, 570), lineIds: ['O']),
      Station(id: 'O19', name: '輔大', position: const Offset(90, 600), lineIds: ['O']),
      Station(id: 'O20', name: '丹鳳', position: const Offset(60, 630), lineIds: ['O']),
      Station(id: 'O21', name: '迴龍', position: const Offset(30, 660), lineIds: ['O']),
      // 蘆洲支線
      Station(id: 'O50', name: '三重國小', position: const Offset(320, 350), lineIds: ['O']),
      Station(id: 'O51', name: '三和國中', position: const Offset(280, 310), lineIds: ['O']),
      Station(id: 'O52', name: '徐匯中學', position: const Offset(240, 270), lineIds: ['O']),
      Station(id: 'O53', name: '三民高中', position: const Offset(200, 230), lineIds: ['O']),
      Station(id: 'O54', name: '蘆洲', position: const Offset(160, 190), lineIds: ['O']),

      // ==========================================
      // 文湖線 (BR)
      // ==========================================
      Station(id: 'BR01', name: '動物園', position: const Offset(800, 810), lineIds: ['BR']),
      Station(id: 'BR02', name: '木柵', position: const Offset(740, 810), lineIds: ['BR']),
      Station(id: 'BR03', name: '萬芳社區', position: const Offset(690, 810), lineIds: ['BR']),
      Station(id: 'BR04', name: '萬芳醫院', position: const Offset(640, 810), lineIds: ['BR']),
      Station(id: 'BR05', name: '辛亥', position: const Offset(600, 770), lineIds: ['BR']),
      Station(id: 'BR06', name: '麟光', position: const Offset(600, 730), lineIds: ['BR']),
      Station(id: 'BR07', name: '六張犁', position: const Offset(600, 690), lineIds: ['BR']),
      Station(id: 'BR08', name: '科技大樓', position: const Offset(600, 645), lineIds: ['BR']),
      Station(id: 'BR09', name: '大安', position: const Offset(600, 600), lineIds: ['BR', 'R']),
      Station(id: 'BR10', name: '忠孝復興', position: const Offset(600, 520), lineIds: ['BR', 'BL']),
      Station(id: 'BR11', name: '南京復興', position: const Offset(600, 470), lineIds: ['BR', 'G']),
      Station(id: 'BR12', name: '中山國中', position: const Offset(600, 420), lineIds: ['BR']),
      Station(id: 'BR13', name: '松山機場', position: const Offset(600, 370), lineIds: ['BR']),
      Station(id: 'BR14', name: '大直', position: const Offset(580, 310), lineIds: ['BR']),
      Station(id: 'BR15', name: '劍南路', position: const Offset(620, 270), lineIds: ['BR']),
      Station(id: 'BR16', name: '西湖', position: const Offset(660, 270), lineIds: ['BR']),
      Station(id: 'BR17', name: '港墘', position: const Offset(700, 270), lineIds: ['BR']),
      Station(id: 'BR18', name: '文德', position: const Offset(740, 270), lineIds: ['BR']),
      Station(id: 'BR19', name: '內湖', position: const Offset(780, 270), lineIds: ['BR']),
      Station(id: 'BR20', name: '大湖公園', position: const Offset(820, 290), lineIds: ['BR']),
      Station(id: 'BR21', name: '葫洲', position: const Offset(850, 330), lineIds: ['BR']),
      Station(id: 'BR22', name: '東湖', position: const Offset(880, 380), lineIds: ['BR']),
      Station(id: 'BR23', name: '南港軟體園區', position: const Offset(880, 440), lineIds: ['BR']),
      Station(id: 'BR24', name: '南港展覽館', position: const Offset(880, 520), lineIds: ['BR', 'BL']),
    ],
    edges: [
      // 淡水信義線 (R)
      Edge('R01', 'R02', 'R'),
      Edge('R02', 'R03', 'R'),
      Edge('R03', 'R04', 'R'),
      Edge('R04', 'R05', 'R'),
      Edge('R05', 'R06', 'R'),
      Edge('R06', 'R07', 'R'),
      Edge('R07', 'R08', 'R'),
      Edge('R08', 'R09', 'R'),
      Edge('R09', 'R10', 'R'),
      Edge('R10', 'R11', 'R'),
      Edge('R11', 'R12', 'R'),
      Edge('R12', 'R13', 'R'),
      Edge('R13', 'R14', 'R'),
      Edge('R14', 'R15', 'R'),
      Edge('R15', 'R16', 'R'),
      Edge('R16', 'R17', 'R'),
      Edge('R17', 'R18', 'R'),
      Edge('R18', 'R19', 'R'),
      Edge('R19', 'R20', 'R'),
      Edge('R20', 'R21', 'R'),
      Edge('R21', 'R22', 'R'),
      Edge('R22', 'R22A', 'R'),  // 新北投支線
      Edge('R22', 'R23', 'R'),
      Edge('R23', 'R24', 'R'),
      Edge('R24', 'R25', 'R'),
      Edge('R25', 'R26', 'R'),
      Edge('R26', 'R27', 'R'),
      Edge('R27', 'R28', 'R'),

      // 板南線 (BL)
      Edge('BL01', 'BL02', 'BL'),
      Edge('BL02', 'BL03', 'BL'),
      Edge('BL03', 'BL04', 'BL'),
      Edge('BL04', 'BL05', 'BL'),
      Edge('BL05', 'BL06', 'BL'),
      Edge('BL06', 'BL07', 'BL'),
      Edge('BL07', 'BL08', 'BL'),
      Edge('BL08', 'BL09', 'BL'),
      Edge('BL09', 'BL10', 'BL'),
      Edge('BL10', 'BL11', 'BL'),
      Edge('BL11', 'BL12', 'BL'),
      Edge('BL12', 'BL13', 'BL'),
      Edge('BL13', 'BL14', 'BL'),
      Edge('BL14', 'BL15', 'BL'),
      Edge('BL15', 'BL16', 'BL'),
      Edge('BL16', 'BL17', 'BL'),
      Edge('BL17', 'BL18', 'BL'),
      Edge('BL18', 'BL19', 'BL'),
      Edge('BL19', 'BL20', 'BL'),
      Edge('BL20', 'BL21', 'BL'),
      Edge('BL21', 'BL22', 'BL'),
      Edge('BL22', 'BL23', 'BL'),

      // 松山新店線 (G)
      Edge('G19', 'G18', 'G'),
      Edge('G18', 'G17', 'G'),
      Edge('G17', 'G16', 'G'),
      Edge('G16', 'G15', 'G'),
      Edge('G15', 'G14', 'G'),
      Edge('G14', 'G13', 'G'),
      Edge('G13', 'G12', 'G'),
      Edge('G12', 'G11', 'G'),
      Edge('G11', 'G10', 'G'),
      Edge('G10', 'G09', 'G'),
      Edge('G09', 'G08', 'G'),
      Edge('G08', 'G07', 'G'),
      Edge('G07', 'G06', 'G'),
      Edge('G06', 'G05', 'G'),
      Edge('G05', 'G04', 'G'),
      Edge('G04', 'G03', 'G'),
      Edge('G03', 'G03A', 'G'),  // 小碧潭支線
      Edge('G03', 'G02', 'G'),
      Edge('G02', 'G01', 'G'),

      // 中和新蘆線 (O)
      Edge('O01', 'O02', 'O'),
      Edge('O02', 'O03', 'O'),
      Edge('O03', 'O04', 'O'),
      Edge('O04', 'O05', 'O'),
      Edge('O05', 'O06', 'O'),
      Edge('O06', 'O07', 'O'),
      Edge('O07', 'O08', 'O'),
      Edge('O08', 'O09', 'O'),
      Edge('O09', 'O10', 'O'),
      Edge('O10', 'O11', 'O'),
      Edge('O11', 'O12', 'O'),
      // 迴龍線
      Edge('O12', 'O13', 'O'),
      Edge('O13', 'O14', 'O'),
      Edge('O14', 'O15', 'O'),
      Edge('O15', 'O16', 'O'),
      Edge('O16', 'O17', 'O'),
      Edge('O17', 'O18', 'O'),
      Edge('O18', 'O19', 'O'),
      Edge('O19', 'O20', 'O'),
      Edge('O20', 'O21', 'O'),
      // 蘆洲線
      Edge('O12', 'O50', 'O'),
      Edge('O50', 'O51', 'O'),
      Edge('O51', 'O52', 'O'),
      Edge('O52', 'O53', 'O'),
      Edge('O53', 'O54', 'O'),

      // 文湖線 (BR)
      Edge('BR01', 'BR02', 'BR'),
      Edge('BR02', 'BR03', 'BR'),
      Edge('BR03', 'BR04', 'BR'),
      Edge('BR04', 'BR05', 'BR'),
      Edge('BR05', 'BR06', 'BR'),
      Edge('BR06', 'BR07', 'BR'),
      Edge('BR07', 'BR08', 'BR'),
      Edge('BR08', 'BR09', 'BR'),
      Edge('BR09', 'BR10', 'BR'),
      Edge('BR10', 'BR11', 'BR'),
      Edge('BR11', 'BR12', 'BR'),
      Edge('BR12', 'BR13', 'BR'),
      Edge('BR13', 'BR14', 'BR'),
      Edge('BR14', 'BR15', 'BR'),
      Edge('BR15', 'BR16', 'BR'),
      Edge('BR16', 'BR17', 'BR'),
      Edge('BR17', 'BR18', 'BR'),
      Edge('BR18', 'BR19', 'BR'),
      Edge('BR19', 'BR20', 'BR'),
      Edge('BR20', 'BR21', 'BR'),
      Edge('BR21', 'BR22', 'BR'),
      Edge('BR22', 'BR23', 'BR'),
      Edge('BR23', 'BR24', 'BR'),
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
      Station(id: 'R24', name: '岡山', position: const Offset(320, 80), lineIds: ['R']),
      Station(id: 'R16', name: '左營', position: const Offset(320, 160), lineIds: ['R']),
      Station(id: 'R11', name: '高雄車站', position: const Offset(320, 240), lineIds: ['R']),
      Station(id: 'R10_O5', name: '美麗島', position: const Offset(320, 320), lineIds: ['R', 'O']),
      Station(id: 'R8', name: '三多商圈', position: const Offset(320, 400), lineIds: ['R']),
      Station(id: 'R4A', name: '草衙', position: const Offset(320, 480), lineIds: ['R']),
      Station(id: 'R3', name: '小港', position: const Offset(320, 560), lineIds: ['R']),
      Station(id: 'O1', name: '哈瑪星', position: const Offset(160, 320), lineIds: ['O']),
      Station(id: 'O2', name: '鹽埕埔', position: const Offset(240, 320), lineIds: ['O']),
      Station(id: 'O7', name: '文化中心', position: const Offset(420, 320), lineIds: ['O']),
      Station(id: 'O10', name: '衛武營', position: const Offset(500, 320), lineIds: ['O']),
      Station(id: 'O14', name: '大寮', position: const Offset(580, 320), lineIds: ['O']),
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
      Station(id: '103a', name: '北屯總站', position: const Offset(480, 100), lineIds: ['G']),
      Station(id: '103', name: '舊社', position: const Offset(440, 130), lineIds: ['G']),
      Station(id: '104', name: '松竹', position: const Offset(400, 160), lineIds: ['G']),
      Station(id: '105', name: '四維國小', position: const Offset(360, 190), lineIds: ['G']),
      Station(id: '106', name: '文心崇德', position: const Offset(320, 220), lineIds: ['G']),
      Station(id: '107', name: '文心中清', position: const Offset(300, 260), lineIds: ['G']),
      Station(id: '108', name: '文華高中', position: const Offset(280, 300), lineIds: ['G']),
      Station(id: '109', name: '文心櫻花', position: const Offset(260, 340), lineIds: ['G']),
      Station(id: '110', name: '市政府', position: const Offset(240, 380), lineIds: ['G']),
      Station(id: '111', name: '水安宮', position: const Offset(240, 420), lineIds: ['G']),
      Station(id: '112', name: '文心森林公園', position: const Offset(240, 460), lineIds: ['G']),
      Station(id: '113', name: '南屯', position: const Offset(240, 500), lineIds: ['G']),
      Station(id: '114', name: '豐樂公園', position: const Offset(240, 540), lineIds: ['G']),
      Station(id: '115', name: '大慶', position: const Offset(240, 580), lineIds: ['G']),
      Station(id: '116', name: '九張犁', position: const Offset(210, 610), lineIds: ['G']),
      Station(id: '117', name: '九德', position: const Offset(190, 640), lineIds: ['G']),
      Station(id: '118', name: '烏日', position: const Offset(170, 670), lineIds: ['G']),
      Station(id: '119', name: '高鐵台中站', position: const Offset(150, 700), lineIds: ['G']),
    ],
    edges: [
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

  // ==========================================
  // 動態快取（從 API 載入後覆蓋）
  // ==========================================
  static final Map<String, CityMetroData> _cache = {
    'taipei': taipei,
    'kaohsiung': kaohsiung,
    'taichung': taichung,
  };

  /// 從 API 載入所有城市資料，回傳合併後的清單
  static Future<List<CityMetroData>> loadFromApi({GetMetro? api}) async {
    final client = api ?? GetMetro();
    try {
      final cities = await client.getCities();

      // 逐一抓每個城市的完整資料
      final results = await Future.wait(
        cities.map((info) async {
          try {
            final data = await client.getMetro(info.id);
            _cache[info.id] = data;
            return data;
          } catch (e) {
            // 若 API 失敗，使用寫死的 fallback
            debugPrint('載入 ${info.id} 失敗：$e');
            return _cache[info.id] ?? taipei;
          }
        }),
      );

      return results;
    } finally {
      client.close();
    }
  }

  /// 從 API 載入單一城市並更新快取
  static Future<CityMetroData> loadCityFromApi(
      String cityId, {
        GetMetro? api,
      }) async {
    final client = api ?? GetMetro();
    try {
      final data = await client.getMetro(cityId);
      _cache[cityId] = data;
      return data;
    } finally {
      client.close();
    }
  }

  /// 取得快取中的城市（同步）
  static CityMetroData? cityById(String id) => _cache[id];

  /// 取得所有城市（同步，回傳目前快取）
  static List<CityMetroData> get allCities => _cache.values.toList();

  /// 取得所有城市 ID
  static List<String> get allCityIds => _cache.keys.toList();
}

