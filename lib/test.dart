import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'database/getData.dart';
import 'l10n/app_localizations.dart';
ValueNotifier<List<dynamic>> facilitiesNotifier = ValueNotifier([]);
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
  final Station station;
  final Color color;

  Connection(this.station, this.color);
}
class Station {
  final String name;
  final Offset relativePosition;
  List<Connection> connections;
  final Color lineColor;
  int? displayTime;

  Station(
      this.name,
      this.relativePosition, {
        List<Connection>? connections,
        this.lineColor = Colors.blue,
        this.displayTime,
      }) : connections = connections ?? [];
}



class MetroMapScreen extends StatefulWidget {
  @override
  _MetroMapScreenState createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> {
  final TransformationController _transformationController = TransformationController();
  final double _stationRadius = 7.0;
  Station? _selectedStation;
  Map<Station, int> _timeMap = {};
  List<Station> _stations = [];

  @override
  void initState() {
    super.initState();
    _initializeStations();
    _initConnections();
  }

  void _initializeStations() {
    // Create the shared transfer station
    final cityHallStation = Station(AppLocalizations.of(context)!.text_591, Offset(0.5, 0.45), lineColor: Colors.black);

    // Green Line stations
    final greenLineStations = [
      Station(AppLocalizations.of(context)!.text_257, Offset(0.5, 0.05), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_804, Offset(0.5, 0.10), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_805, Offset(0.5, 0.15), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_806, Offset(0.5, 0.20), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_807, Offset(0.5, 0.25), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_808, Offset(0.5, 0.30), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_809, Offset(0.5, 0.35), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_810, Offset(0.5, 0.40), lineColor: Colors.green),
      cityHallStation, // Transfer station
      Station(AppLocalizations.of(context)!.text_811, Offset(0.5, 0.50), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_812, Offset(0.5, 0.55), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_813, Offset(0.5, 0.60), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_814, Offset(0.65, 0.7), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_815, Offset(0.7, 0.75), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_816, Offset(0.75, 0.8), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_817, Offset(0.8, 0.85), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_818, Offset(0.85, 0.9), lineColor: Colors.green),
      Station(AppLocalizations.of(context)!.text_819, Offset(0.9, 0.95), lineColor: Colors.green),
    ];


    // Blue Line stations (20 stations, horizontal along Taiwan Boulevard)
    final blueLineStations = [
      Station('台中港站 (B1)', Offset(0.10, 0.45), lineColor: Colors.blue),
      Station('梧棲站 (B2)', Offset(0.14, 0.45), lineColor: Colors.blue),
      Station('大庄站 (B3)', Offset(0.18, 0.45), lineColor: Colors.blue),
      Station('沙鹿站 (B4)', Offset(0.22, 0.45), lineColor: Colors.blue),
      Station('竹林站 (B5)', Offset(0.26, 0.45), lineColor: Colors.blue),
      Station(AppLocalizations.of(context)!.text_820, Offset(0.30, 0.45), lineColor: Colors.blue),
      Station(AppLocalizations.of(context)!.text_821, Offset(0.34, 0.45), lineColor: Colors.blue),
      Station('正英路站 (B8)', Offset(0.38, 0.45), lineColor: Colors.blue),
      // Station('東海別墅站 (B9)', Offset(0.42, 0.45), lineColor: Colors.blue),
      // Station('東海大學站 (B10)', Offset(0.46, 0.45), lineColor: Colors.blue),
      // Station('澄清醫院站 (B11)', Offset(0.48, 0.45), lineColor: Colors.blue),
      // Station('福安站 (B12)', Offset(0.49, 0.45), lineColor: Colors.blue),
      // Station('朝馬站 (B13)', Offset(0.495, 0.45), lineColor: Colors.blue),
      cityHallStation, // Transfer station (B14)
      // Station('漢口路站 (B15)', Offset(0.505, 0.45), lineColor: Colors.blue),
      // Station('科博館站 (B16)', Offset(0.52, 0.45), lineColor: Colors.blue),
      Station('茄苳腳站 (B17)', Offset(0.56, 0.45), lineColor: Colors.blue),
      Station('第二市場站 (B18)', Offset(0.60, 0.45), lineColor: Colors.blue),
      Station('台中車站 (B19)', Offset(0.64, 0.45), lineColor: Colors.blue),
      Station(AppLocalizations.of(context)!.text_823, Offset(0.68, 0.45), lineColor: Colors.blue),
    ];
    // Add all stations, avoiding duplication of the transfer station
    _stations.addAll(greenLineStations);
    _stations.addAll(blueLineStations.where((s) => s != cityHallStation));
  }

  void _initConnections() {
    // Green Line connections
    final greenLineStations = _stations.where((s) => s.lineColor == Colors.green || s.name == AppLocalizations.of(context)!.text_591).toList();
    for (int i = 0; i < greenLineStations.length - 1; i++) {
      greenLineStations[i].connections.add(Connection(greenLineStations[i + 1], Colors.green));
      greenLineStations[i + 1].connections.add(Connection(greenLineStations[i], Colors.green));
    }

    // blue Line connections
    final blueLineStations = _stations.where((s) => s.lineColor == Colors.blue || s.name == AppLocalizations.of(context)!.text_591).toList();
    for (int i = 0; i < blueLineStations.length - 1; i++) {
      blueLineStations[i].connections.add(Connection(blueLineStations[i + 1], Colors.blue));
      blueLineStations[i + 1].connections.add(Connection(blueLineStations[i], Colors.blue));
    }
  }

  Map<Station, int> _calculateTimes(Station start) {
    Map<Station, int> distances = {};
    final queue = Queue<Station>();
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

  void _updateSelectedStation(Station station) {
    setState(() {
      _selectedStation = station;
      _timeMap = _calculateTimes(station);
      _stations.forEach((s) => s.displayTime = _timeMap[s]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.text_824)),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.6,
            maxScale: 3.0,
            child: Container(
              color: Colors.grey,
              width: 600,
              height: 600,
              child: GestureDetector(
                onTapUp: (details) => _handleTap(details),
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
      ),
    );
  }

  Widget _buildStationDot(Station station, Size canvasSize) {
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
          buildStationInfo(context, "");
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

  void _showStationInfo(Station station) {
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
            child: Text(AppLocalizations.of(context)!.text_44),
          ),
        ],
      ),
    );
  }

  String _getLineColorName(Color color) {
    if (color == Colors.red) return AppLocalizations.of(context)!.text_288;
    if (color == Colors.green) return AppLocalizations.of(context)!.text_289;
    return AppLocalizations.of(context)!.text_290;
  }
}

class _MetroMapPainter extends CustomPainter {
  final List<Station> stations;
  final Station? selectedStation;
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
    final drawnConnections = <Pair<Station, Station>>{};

    // Draw connections
    for (final station in stations) {
      for (final connection in station.connections) {
        final pair = Pair(station, connection.station);
        if (!drawnConnections.contains(pair)) {
          final paint = Paint()
            ..color = connection.color
            ..strokeWidth = 4
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

  void _drawStation(Canvas canvas, Station station, Size size) {
    final isSelected = station == selectedStation;
    final position = _getAbsolutePosition(station.relativePosition, size);

    // Draw outer circle
    final outerPaint = Paint()
      ..color = station.lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, stationRadius, outerPaint);

    // Draw inner circle if selected
    if (isSelected) {
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, stationRadius * 0.6, innerPaint);
    }

    // Draw time text
    if (station.displayTime != null) {
      final text = station.displayTime.toString();
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: stationRadius * 0.8,
            color: isSelected ? Colors.black : Colors.white,
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
// 异步获取车站信息
Future<List> _getStationInfo(String station) async {
  // 这里需要添加数据库查询的实际代码
  var stationExit = await mysqlSelect(
      "SELECT * FROM MRT.MRT_taichung_stationExit WHERE JSON_UNQUOTE(JSON_EXTRACT(StationName, '\$.Zh_tw'))='$station'");

  var i = (await mysqlSelect(
      "SELECT info FROM MRT.MRT_Taichung_station WHERE StationNameZh_tw ='$station'"));

  try {
    facilitiesNotifier.value = json.decode(i[0]["info"]);
  } catch (e) {
    print(e);
  }

  // 假设你想展示 stationname_zh_tw 和一些其他信息

  return stationExit;
}

// 車站資訊頁面
void buildStationInfo(BuildContext context, String station) {
  IconData getIcon(String iconName) {
    switch (iconName) {
      case 'Inquiry Desk Icon':
        return Icons.info;
      case 'ATM Icon':
        return Icons.atm;
      case 'Water Fountain Icon':
        return Icons.water;
      case 'Restroom Icon':
        return Icons.wc;
      case 'AEDA Icon':
        return Icons.favorite; // 可替换为更适合的图标
      case 'Accessible Elevator Icon':
        return Icons.elevator;
      default:
        return Icons.help; // 默认图标
    }
  }

  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return FutureBuilder(
        future: _getStationInfo(station), // 异步获取车站信息
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(), // 显示加载进度条
            );
          } else if (snapshot.hasError) {
            return Text(AppLocalizations.of(context)!.text_246); // 显示错误信息
          } else if (snapshot.hasData) {
            var stationI = snapshot.data;
            return SingleChildScrollView(
              child: Column(
                children: [
                  // 使用 Expanded 包裹 ListView 以便滚动
                  ListView.builder(
                    itemCount: stationI?.length, // 列表项数量
                    physics:
                    const NeverScrollableScrollPhysics(), // 禁用 ListView 的滚动
                    shrinkWrap: true, // 让 ListView 根据内容的高度收缩
                    itemBuilder: (context, index) {
                      final station = stationI?[index]; // 获取当前车站的信息
                      return ListTile(
                        title: Text(
                          json.decode(station["ExitName"])["Zh_tw"], // 显示车站名称
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min, // 确保图标不会占用过多空间
                          children: [
                            if (int.parse(station["Stair"]) == 1)
                              const Icon(Icons.stairs, color: Colors.blue), // 楼梯图标
                            if (int.parse(station["Elevator"]) == 1)
                              const Icon(Icons.elevator,
                                  color: Colors.green), // 电梯图标
                            if (int.parse(station["Escalator"]) == 1)
                              const Icon(Icons.escalator,
                                  color: Colors.orange), // 手扶梯图标
                          ],
                        ),
                        onTap: () {
                          // 点击车站时执行的操作
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '点击了 ${json.decode(station["ExitName"])["Zh_tw"]}'),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20), // 增加间距使布局更清晰

                  // 车站设施表格
                  Text(
                    AppLocalizations.of(context)!.text_248,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10), // 表格标题与表格之间的间距

                  DataTable(
                    columnSpacing: 30,
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                    dataRowHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Icon')),
                      DataColumn(label: Text('Facility')),
                      DataColumn(label: Text('Location')),
                    ],
                    rows: facilitiesNotifier.value.map((facility) {
                      return DataRow(cells: [
                        DataCell(Icon(
                          getIcon(facility['icon']),
                          color: Colors.black54,
                          size: 24,
                        )),
                        DataCell(Text(facility['facility'])),
                        DataCell(Text(facility['location'])),
                      ]);
                    }).toList(),
                  ),
                ],
              ),
            );
          } else {
            return Text(AppLocalizations.of(context)!.text_825);
          }
        },
      );
    },
  );
}