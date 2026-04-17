import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class City {
  final String name;
  final String englishName;
  final String image; // 城市縮圖
  bool isCheckedIn;

  City({
    required this.name,
    required this.englishName,
    required this.image,
    this.isCheckedIn = false,
  });
}
class TaiwanCitiesPage extends StatefulWidget {
  const TaiwanCitiesPage({super.key});

  @override
  State<TaiwanCitiesPage> createState() => _TaiwanCitiesPageState();
}

class _TaiwanCitiesPageState extends State<TaiwanCitiesPage> {
  // 模擬全台灣城市數據
  final List<City> _cities = [
    City(name: '台北市', englishName: 'Taipei', image: 'assets/cities/taipei.jpg'),
    City(name: '新北市', englishName: 'New Taipei', image: 'assets/cities/new_taipei.jpg'),
    City(name: '台中市', englishName: 'Taichung', image: 'assets/cities/taichung.jpg'),
    City(name: '台南市', englishName: 'Tainan', image: 'assets/cities/tainan.jpg'),
    City(name: '高雄市', englishName: 'Kaohsiung', image: 'assets/cities/kaohsiung.jpg'),
    City(name: '基隆市', englishName: 'Keelung', image: 'assets/cities/keelung.jpg'),
    // ... 依此類推
  ];

  void _toggleCheckIn(int index) {
    setState(() {
      _cities[index].isCheckedIn = !_cities[index].isCheckedIn;
    });

    // 打卡回饋
    if (_cities[index].isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功在 ${_cities[index].name} 打卡！📍'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('探索台灣城市'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_rounded),
            onPressed: () {}, // 切換地圖模式
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,       // 一列兩個城市
          mainAxisSpacing: 16,     // 上下間距
          crossAxisSpacing: 16,    // 左右間距
          childAspectRatio: 0.85,  // 卡片長寬比
        ),
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          return _buildCityCard(_cities[index], index);
        },
      ),
    );
  }

  Widget _buildCityCard(City city, int index) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 城市名稱與背景
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: isDark ? Colors.blueGrey.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
                    child: Center(
                      child: Icon(
                        Icons.location_city_rounded,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        city.englishName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 打卡按鈕 (右上角)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _toggleCheckIn(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: city.isCheckedIn
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    // backdropFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  ),
                  child: Icon(
                    city.isCheckedIn ? Icons.beenhere_rounded : Icons.add_location_alt_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}