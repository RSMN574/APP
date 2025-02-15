import 'package:com.rsmn574.app/utils/MRTColor.dart';

import 'package:flutter/material.dart';


class Station {
  final String name; // 车站中文名称
  final Offset position; // 车站英文名称
  final String type;
  Station( {required this.type,required this.name, required this.position});
}

class test extends StatefulWidget {



  @override
  _test createState() => _test();
}

class _test extends State<test> with MRTColor {
  var lineName="green";
  var color=MRTColor.taichungGreen;
    Station? clickedStation= Station(name: '一号线', position: Offset(113.2677, 23.0958), type: 'point'); // 当前被点击的站点

  final List<Station> markPoints = [
    Station(name: '一号线', position: Offset(113.2677, 23.0958), type: 'point'),
    Station(name: '一号线', position: Offset(113.3528, 23.1338), type: 'point'),
  ];
// 基准点 (高鐵臺中站)
  static const Offset basePoint = Offset(120.61405, 24.11011);
// 在 _test 类中定义转换方法（与 MetroMapPainter 的 transform 一致）
  Offset _transformPosition(Offset point) {
    const double scale = 2400;
    const double refLongitude = 120.64903;
    const double refLatitude = 24.16199;
    return Offset(
      (point.dx - refLongitude) * scale,
      (refLatitude - point.dy) * scale, // Y轴需取反
    );
  }
  // 画布坐标系参数
  static const double _canvasScale = 2400;  // 缩放比例
  static const Offset _canvasOrigin = Offset(120.64903, 24.16199); // 画布原点（对应市政府站的经纬度）

  // 经纬度 → 画布坐标
  Offset _geoToCanvas(Offset geoPoint) {
    return Offset(
      (geoPoint.dx - _canvasOrigin.dx) * _canvasScale,
      (_canvasOrigin.dy - geoPoint.dy) * _canvasScale, // Y轴取反
    );
  }

  // 画布坐标 → 经纬度（用于点击位置转换）
  Offset _canvasToGeo(Offset canvasPoint) {
    return Offset(
      (canvasPoint.dx / _canvasScale) + _canvasOrigin.dx,
      _canvasOrigin.dy - (canvasPoint.dy / _canvasScale),
    );
  }
// // 经纬度转相对坐标的函数
//   static Offset convertToRelativePosition(double longitude, double latitude) {
//     double deltaLongitude = longitude - basePoint.dx;
//     double deltaLatitude = latitude - basePoint.dy;
//     return Offset(deltaLongitude, deltaLatitude);
//   }
  void _handleTap(Offset tapPosition) {
    final transformedTap = _transformPosition(tapPosition);
    final tolerance = 8.0 / currentScale; // 动态容差

    for (var line in lineData.values) {
      for (var segment in line) {
        for (var station in segment) {
          final dxDiff = (transformedTap.dx - station.position.dx).abs();
          final dyDiff = (transformedTap.dy - station.position.dy).abs();
print("$dxDiff,$dyDiff --$tolerance");
          if (dxDiff < tolerance && dyDiff < tolerance) {
            setState(() => clickedStation = station);
            return;
          }
        }
      }
    }
  }


  Map<String, List<List<Station>>> lineData = {
    'Line1': [
      [
        Station(name: '高鐵臺中站', position: Offset(120.61405, 24.11011), type: 'normalPoints'),
        Station(name: '烏日', position: Offset(120.62490, 24.10890), type: 'normalPoints'),
        Station(name: '九德', position: Offset(120.63448, 24.11104), type: 'normalPoints'),
        Station(name: '九張犁', position: Offset(120.64010, 24.11450), type: 'normalPoints'),
        Station(name: '大慶', position: Offset(120.64760, 24.11910), type: 'normalPoints'),
        Station(name: '豐樂公園', position: Offset(120.64635, 24.13260), type: 'normalPoints'),
        Station(name: '南屯', position: Offset(120.64660, 24.14050), type: 'normalPoints'),
        Station(name: '文心森林公園', position: Offset(120.64660, 24.14540), type: 'normalPoints'),
        Station(name: '水安宮', position: Offset(120.64668, 24.15311), type: 'normalPoints'),
        Station(name: '市政府', position: Offset(120.64903, 24.16199), type: 'normalPoints'),
        Station(name: '文心櫻花', position: Offset(120.65367, 24.16763), type: 'normalPoints'),
        Station(name: '文華高中', position: Offset(120.66045, 24.17141), type: 'normalPoints'),
        Station(name: '文心中清', position: Offset(120.67059, 24.17368), type: 'normalPoints'),
        Station(name: '文心崇德', position: Offset(120.68486, 24.17219), type: 'normalPoints'),
        Station(name: '四維國小', position: Offset(120.69329, 24.17124), type: 'normalPoints'),
        Station(name: '松竹', position: Offset(120.70145, 24.18080), type: 'normalPoints'),
        Station(name: '舊社', position: Offset(120.70729, 24.18228), type: 'normalPoints'),
        Station(name: '北屯總站', position: Offset(120.70864, 24.18913), type: 'normalPoints'),

      ],
    ],
  };
  double currentScale = 1.0; // 跟踪当前缩放比例
// 在State类中定义GlobalKey
  final GlobalKey _customPaintKey = GlobalKey();
  // 在 State 类中定义变换跟踪变量
  Matrix4 _transformMatrix = Matrix4.identity();
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.grey[700],
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          final RenderBox renderBox = _customPaintKey.currentContext!.findRenderObject() as RenderBox;

          // 获取从 CustomPaint 到全局的变换矩阵
          final matrix = renderBox.getTransformTo(null);

          // 将点击位置转换为画布坐标（考虑缩放/平移）
          final localTap = renderBox.globalToLocal(details.globalPosition);
          final canvasTap = _canvasToGeo(localTap); // 转换为经纬度

          _handleTap(canvasTap);
        },
        child: Center(child: InteractiveViewer(
          onInteractionUpdate: (details) {
            setState(() => currentScale *= details.scale);
          },
          boundaryMargin: const EdgeInsets.all(200),
          minScale: 0.5,
          maxScale: 8.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                key: _customPaintKey, // 分配GlobalKey
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: MetroMapPainter(lineData: lineData, clickedStation: clickedStation),
              );
            },
          ),
        ),)
      )

    );
  }
}

class MetroMapPainter extends CustomPainter {
  final Map<String, List<List<Station>>> lineData;
  final Station? clickedStation; // 当前被点击的站点

  MetroMapPainter({required this.lineData, this.clickedStation});

  // 經緯度轉畫布座標（縮小範圍）
  Offset transform(Offset point) {
    double scale = 2400; // 调整缩放比例
    print(point);
    return Offset((point.dx - 120.64903) * scale, (24.16199 - point.dy) * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..color = MRTColor.taichungGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Paint stationPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    Paint effectPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5) // 圆形特效的颜色和透明度
      ..style = PaintingStyle.fill;
    for (var line in lineData.values) {
      for (var segment in line) {
        if (segment.isEmpty) continue;
        Path path = Path();
        path.moveTo(transform(segment[0].position).dx, transform(segment[0].position).dy);

        for (int i = 1; i < segment.length; i++) {
          path.lineTo(transform(segment[i].position).dx, transform(segment[i].position).dy);
        }

        canvas.drawPath(path, linePaint);

        // 畫站點與站名
        for (var point in segment) {
          Offset pos = transform(point.position);
          canvas.drawCircle(pos, 1.5, stationPaint); // 畫圓點
// 如果当前站点是被点击的站点，绘制特效圆圈
          if (point == clickedStation) {

            canvas.drawCircle(pos, 3.0, effectPaint); // 特效圆圈
          }
          // 畫站名
          drawText(canvas, point.name, pos);
        }
      }
    }
  }
  // 繪製站名
  void drawText(Canvas canvas, String text, Offset position) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 4,
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    Offset textOffset = position.translate(-textPainter.width / 2, 2);

    textPainter.paint(canvas, textOffset);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


