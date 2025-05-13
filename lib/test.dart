import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'database/getData.dart';
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
    // 创建共享的换乘站D
    // final dStation = Station('D站', Offset(350, 180), lineColor: Colors.red);

    _stations.addAll([
      Station('北屯總站', Offset(0.5, 0.05), lineColor: Colors.green),
      Station('舊社站', Offset(0.5, 0.10), lineColor: Colors.green),
      Station('松竹站', Offset(0.5, 0.15), lineColor: Colors.green),
      Station('四維國小站', Offset(0.5, 0.20), lineColor: Colors.green),
      Station('文心崇德站', Offset(0.5, 0.25), lineColor: Colors.green),
      Station('文心中清站', Offset(0.5, 0.30), lineColor: Colors.green),
      Station('文華高中站', Offset(0.5, 0.35), lineColor: Colors.green),
      Station('文心櫻花站', Offset(0.5, 0.40), lineColor: Colors.green),
      Station('市政府站', Offset(0.5, 0.45), lineColor: Colors.green),
      Station('水安宮站', Offset(0.5, 0.50), lineColor: Colors.green),
      Station('文心森林公園站', Offset(0.5, 0.55), lineColor: Colors.green),
      Station('南屯站', Offset(0.5, 0.60), lineColor: Colors.green),
      Station('豐樂公園站', Offset(0.65, 0.7), lineColor: Colors.green),
      Station('大慶站', Offset(0.7, 0.75), lineColor: Colors.green),
      Station('九張犁站', Offset(0.75, 0.8), lineColor: Colors.green),
      Station('九德站', Offset(0.8, 0.85), lineColor: Colors.green),
      Station('烏日站', Offset(0.85, 0.9), lineColor: Colors.green),
      Station('高鐵台中站', Offset(0.9, 0.95), lineColor: Colors.green),
    ]);

  }

  void _initConnections() {
    // 綠線全線連接
    for (int i = 0; i < _stations.length - 1; i++) {
      _stations[i].connections.add(Connection(_stations[i + 1], Colors.green));
      _stations[i + 1].connections.add(Connection(_stations[i], Colors.green));
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
      appBar: AppBar(title: const Text('動態捷運路線圖')),
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
                child:LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                    return CustomPaint(
                      painter: _MetroMapPainter(
                        stations: _stations,
                        selectedStation: _selectedStation,
                        stationRadius: _stationRadius,
                        canvasSize: canvasSize, // 傳入畫布大小給 painter
                      ),
                      child: Stack(
                        children: _stations
                            .map((station) => _buildStationDot(station, canvasSize))
                            .toList(),
                      ),
                    );
                  },
                )





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
      station.relativePosition.dx * canvasSize.width,  // 相對轉換為絕對座標
      station.relativePosition.dy * canvasSize.height,
    );

    return Positioned(
      left: actualOffset.dx - _stationRadius,
      top: actualOffset.dy - _stationRadius,
      child: GestureDetector(
        onTap: () {
          _updateSelectedStation(station);  // 更新選中的站點
          // _showStationInfo(station);  // 顯示站點資訊
          buildStationInfo(context,"");
        },
        child: Container(
          width: _stationRadius * 2,
          height: _stationRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            // border: Border.all(color: Colors.black),  // 可選，幫助顯示邊界
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
            child: Text('關閉'),
          ),
        ],
      ),
    );
  }

  String _getLineColorName(Color color) {
    if (color == Colors.red) return '紅線';
    if (color == Colors.green) return '綠線';
    return '其他路線';
  }
}

class _MetroMapPainter extends CustomPainter {
  final List<Station> stations;
  final Station? selectedStation;
  final double stationRadius;

  _MetroMapPainter({
    required this.stations,
    this.selectedStation,
    this.stationRadius = 3, required Size canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drawnConnections = <Pair<Station, Station>>{};

    // 繪製連接線
    for (final station in stations) {
      for (final connection in station.connections) {
        final pair = Pair(station, connection.station);
        if (!drawnConnections.contains(pair)) {
          final paint = Paint()
            ..color = connection.color  // 用連線自己帶的顏色
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke;

          final startPosition = _getAbsolutePosition(station.relativePosition, size);
          final endPosition = _getAbsolutePosition(connection.station.relativePosition, size);

          canvas.drawLine(startPosition, endPosition, paint);
          drawnConnections.add(pair);
        }
      }
    }

    // 繪製站點
    for (final station in stations) {
      _drawStation(canvas, station, size);
    }
  }

  // 將相對位置轉換為絕對座標
  Offset _getAbsolutePosition(Offset relativePosition, Size size) {
    final x = relativePosition.dx * size.width;
    final y = relativePosition.dy * size.height;
    return Offset(x, y);
  }

  // 繪製站點
  void _drawStation(Canvas canvas, Station station, Size size) {
    final isSelected = station == selectedStation;
    final position = _getAbsolutePosition(station.relativePosition, size);

    // 繪製外圈
    final outerPaint = Paint()
      ..color = station.lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, stationRadius, outerPaint);

    // 繪製內圈（如果被選中）
    if (isSelected) {
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, stationRadius * 0.6, innerPaint);
    }

    // 繪製時間文字
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

    // 繪製站名
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
            return const Text("無法載入車站資訊"); // 显示错误信息
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
                  const Text(
                    "車站設施",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            return const Text("未找到任何車站資訊");
          }
        },
      );
    },
  );
}