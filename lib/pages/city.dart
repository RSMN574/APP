import 'package:flutter/material.dart';

class City extends StatefulWidget {
  @override
  _CityPageState createState() => _CityPageState();
}

class _CityPageState extends State<City> {
  // 模擬的地標數據
  final List<Map<String, dynamic>> landmarks = [
    {'name': '台北101', 'image': 'assets/taipei101.png', 'isLit': false},
    {'name': '士林夜市', 'image': 'assets/shilin.png', 'isLit': false},
    {'name': '中正紀念堂', 'image': 'assets/cksm.png', 'isLit': false},
    {'name': '國立故宮博物院', 'image': 'assets/palace_museum.png', 'isLit': false},
    {'name': '象山', 'image': 'assets/xiangshan.png', 'isLit': false},
    {'name': '北投溫泉', 'image': 'assets/beitou.png', 'isLit': false},
    {'name': '華山文創園區', 'image': 'assets/huashan.png', 'isLit': false},
    {'name': '淡水老街', 'image': 'assets/danshui.png', 'isLit': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台北地標'),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: landmarks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 每行2個地標
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3 / 4, // 調整卡片比例
          ),
          itemBuilder: (context, index) {
            final landmark = landmarks[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  // 切換地標是否點亮
                  landmark['isLit'] = !landmark['isLit'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: landmark['isLit'] ? Colors.amber[200] : Colors.grey[300],
                  boxShadow: [
                    if (landmark['isLit'])
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 地標圖片
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        landmark['image'],
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      landmark['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: landmark['isLit'] ? Colors.black : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
