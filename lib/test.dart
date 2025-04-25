import 'dart:math';

import 'package:flutter/material.dart';

// 新增的Pair類用於記錄已繪製連接
class Pair<T1, T2> {
  final T1 a;
  final T2 b;

  Pair(this.a, this.b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Pair &&
              ((a == other.a && b == other.b) ||
                  (a == other.b && b == other.a));

  @override
  int get hashCode => a.hashCode ^ b.hashCode;
}

// 修改後的站點數據結構（增加路線顏色屬性）
class Station {
  final String name;
  final Offset position;
   List<Station> connections;
  final Color lineColor;

  Station(this.name, this.position,
      {this.connections = const [], this.lineColor = Colors.blue});
}

class MetroMapScreen extends StatefulWidget {
  @override
  _MetroMapScreenState createState() => _MetroMapScreenState();
}

class _MetroMapScreenState extends State<MetroMapScreen> {
  final TransformationController _transformationController = TransformationController();
  String _selectedStation = '';
  final double _stationRadius = 20.0;
// 完整地鐵站點資料範例
  final List<Station> _stations = [
    Station('A站', Offset(50, 100), lineColor: Colors.red),
    Station('B站', Offset(150, 100), lineColor: Colors.red),
    Station('C站', Offset(250, 180), lineColor: Colors.red),
    Station('D站', Offset(350, 180), lineColor: Colors.red),
    Station('E站', Offset(450, 260), lineColor: Colors.red),
    Station('F站', Offset(550, 260), lineColor: Colors.red),

    Station('G站', Offset(150, 300), lineColor: Colors.green),
    Station('H站', Offset(250, 300), lineColor: Colors.green),
    Station('D站', Offset(350, 180), lineColor: Colors.green),
    Station('I站', Offset(350, 100), lineColor: Colors.green),
  ];

// 建立連線關係
  void _initConnections() {
    // 紅線
    _stations[0].connections = [_stations[1]];
    _stations[1].connections = [_stations[0], _stations[2]];
    _stations[2].connections = [_stations[1], _stations[3]];
    _stations[3].connections = [_stations[2], _stations[4]];
    _stations[4].connections = [_stations[3], _stations[5]];
    _stations[5].connections = [_stations[4]];

    // 綠線
    _stations[6].connections = [_stations[7]];
    _stations[7].connections = [_stations[6], _stations[8]];
    _stations[8].connections = [_stations[7], _stations[9]];
    _stations[9].connections = [_stations[8]];
    Map<String, List<Station>> stationGroups = {};

    for (var station in _stations) {
      stationGroups.putIfAbsent(station.name, () => []).add(station);
    }

    Set<String> transferStationNames = stationGroups.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toSet();

  }

  @override
  Widget build(BuildContext context) {
    _initConnections();
    return Scaffold(
      appBar: AppBar(title: const Text('動態捷運路線圖')),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 4.0,
            child: Container(
              width: 600,  // 調整容器的寬度
              height: 600, // 調整容器的高度
              child: GestureDetector(
                onTapUp: (details) => _handleTap(details),
                child: CustomPaint(
                  painter: _MetroMapPainter(_stations),
                  child: Stack(
                    children: [
                      ..._stations.map((station) => Positioned(
                        left: station.position.dx - _stationRadius,
                        top: station.position.dy - _stationRadius,
                        child: GestureDetector(
                          onTap: () => _showStationInfo(station),
                          child: Container(
                            width: _stationRadius * 2,
                            height: _stationRadius * 2,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_selectedStation.isNotEmpty)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: Text('當前選擇: $_selectedStation'),
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(TapUpDetails details) {
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final tapPosition = details.localPosition;
    final untransformedPosition = MatrixUtils.transformPoint(inverseMatrix, tapPosition);

    for (final station in _stations) {
      final dx = station.position.dx - untransformedPosition.dx;
      final dy = station.position.dy - untransformedPosition.dy;
      final distance = dx * dx + dy * dy;

      if (distance < _stationRadius * _stationRadius) {
        setState(() {
          _selectedStation = station.name;
        });
        return;
      }
    }
  }

  void _showStationInfo(Station station) {
    setState(() {
      _selectedStation = station.name;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(station.name),
        content: Text('車站詳細資訊...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('關閉'),
          ),
        ],
      ),
    );
  }
}

class _MetroMapPainter extends CustomPainter {
  final List<Station> stations;
  final double stationRadius;

  _MetroMapPainter(this.stations, {this.stationRadius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    final drawnConnections = <Pair<Station, Station>>{};
    final displayedStationNames = <String>{};

    // 預先找出轉乘站
    final transferStationNames = <String>{};
    final nameGroup = <String, List<Station>>{};
    for (var station in stations) {
      nameGroup.putIfAbsent(station.name, () => []).add(station);
    }
    nameGroup.forEach((name, list) {
      if (list.length > 1) transferStationNames.add(name);
    });

    // 繪製路線連接（修改後版本）
    final Set<Pair<Station, Station>> _drawnConnections = {};

    for (final station in stations) {
      for (final connectedStation in station.connections) {
        // 避免重複繪製相同連接
        final connectionPair = Pair(station, connectedStation);
        if (!_drawnConnections.contains(connectionPair)) {
          final path = Path()
            ..moveTo(station.position.dx, station.position.dy)
            ..lineTo(connectedStation.position.dx, connectedStation.position.dy);

          final linePaint = Paint()
            ..color = station.lineColor
            ..strokeWidth = 6
            ..style = PaintingStyle.stroke;

          canvas.drawPath(path, linePaint);
          _drawnConnections.add(Pair(connectedStation, station));
        }
      }
    }

    // 畫站點與站名
    for (final station in stations) {
      final isTransferStation = transferStationNames.contains(station.name);
      final position = station.position;

      if (isTransferStation) {
        canvas.drawCircle(position, stationRadius + 4, Paint()..color = Colors.white);
      }

      canvas.drawCircle(position, stationRadius, Paint()..color = station.lineColor);

      // 顯示站名（只顯示一次）
      if (!displayedStationNames.contains(station.name)) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: station.name,
            style: TextStyle(fontSize: 12, color: Colors.black),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(position.dx + 10, position.dy + 10));
        displayedStationNames.add(station.name);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

