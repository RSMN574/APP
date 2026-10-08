import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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
  late final List<City> _cities = [
    City(
        name: AppLocalizations.of(context)!.text_174,
        englishName: 'Taipei',
        image: 'assets/cities/taipei.jpg'),
    City(
        name: AppLocalizations.of(context)!.text_8,
        englishName: 'New Taipei',
        image: 'assets/cities/new_taipei.jpg'),
    City(
        name: AppLocalizations.of(context)!.text_184,
        englishName: 'Taichung',
        image: 'assets/cities/taichung.jpg'),
    City(
        name: AppLocalizations.of(context)!.text_188,
        englishName: 'Tainan',
        image: 'assets/cities/tainan.jpg'),
    City(
        name: AppLocalizations.of(context)!.text_11,
        englishName: 'Kaohsiung',
        image: 'assets/cities/kaohsiung.jpg'),
    City(
        name: AppLocalizations.of(context)!.text_12,
        englishName: 'Keelung',
        image: 'assets/cities/keelung.jpg'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.text_368),
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
          crossAxisCount: 2, // 一列兩個城市
          mainAxisSpacing: 16, // 上下間距
          crossAxisSpacing: 16, // 左右間距
          childAspectRatio: 0.85, // 卡片長寬比
        ),
        itemCount: _cities.length,
        itemBuilder: (context, index) {
          return _buildCityCard(_cities[index], index);
        },
      ),
    );
  }

  Widget _buildCityCard(City city, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (colorScheme.brightness == Brightness.light)
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
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
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    child: Center(
                      child: Icon(
                        Icons.location_city_rounded,
                        size: 40,
                        color: colorScheme.primary.withValues(alpha: 0.7),
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
                          color: colorScheme.onSurfaceVariant,
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
                        : colorScheme.scrim.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    // backdropFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  ),
                  child: Icon(
                    city.isCheckedIn
                        ? Icons.beenhere_rounded
                        : Icons.add_location_alt_rounded,
                    size: 20,
                    color: colorScheme.onPrimary,
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
