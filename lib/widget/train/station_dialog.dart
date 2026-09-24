import 'dart:convert';
import 'package:flutter/material.dart';
import '../../database/get_data.dart';
import '../../l10n/app_localizations.dart';

class StationDialog {
  // 通知中心主題配色
  static const Color _backgroundWhite = Color(0xFFFFFFFF);
  static const Color _surfaceColor = Color(0xFFF8FAFD);
  static const Color _primaryColor = Color(0xFF1A73E8);
  static const Color _accentColor = Color(0xFFFF9500);
  static const Color _successColor = Color(0xFF34C759);
  static const Color _errorColor = Color(0xFFFF3B30);
  static const Color _textPrimary = Color(0xFF2D3748);
  static const Color _textSecondary = Color(0xFF718096);

  static Future<Map<String, dynamic>?> showStationDialog(context) async {
    // 原有數據獲取與處理邏輯保持不變
    List stationData = await mysqlSelect("SELECT StationID,StationClass,StationName,StationPosition,LocationCity FROM Train.Train_Station;");

    // 原有數據轉換邏輯保持不變
    List<Map<String, dynamic>> stationDataMap = stationData.map((item) {
      final stationName = json.decode(item["StationName"]);
      return {
        'StationName': {
          'Zh_tw': stationName['Zh_tw'],
          'En': stationName['En'],
        },
        'LocationCity': item['LocationCity'],
        'StationClass': item['StationClass'],
        'StationID': item['StationID'],
        'StationPosition': item['StationPosition'],
      };
    }).toList();

    // 構建 stationsList
    final Map<String, List<String>> stationsList = {};
    for (var entry in stationDataMap) {
      String city = entry['LocationCity'];
      String stationName = entry['StationName']['Zh_tw'];
      stationsList.putIfAbsent(city, () => []).add(stationName);
    }

    String _selectedCity = AppLocalizations.of(context)!.text_6;
    String? _selectedStation;
    Map<String, dynamic>? selectedStationData;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: _backgroundWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 頂部標題欄 - 統一使用漸變背景
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, Color(0xFF0D47A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.train_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.text_925,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.text_930,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 關閉按鈕
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 主內容區
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 城市列表 - 左側
                              Container(
                                width: MediaQuery.of(context).size.width * 0.3,
                                decoration: BoxDecoration(
                                  color: _surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFEEF3FB),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: _primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.location_city_rounded,
                                              size: 16,
                                              color: _primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                           Text(
                                            AppLocalizations.of(context)!.text_931,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: stationsList.keys.length,
                                        itemBuilder: (context, index) {
                                          final city = stationsList.keys.elementAt(index);
                                          final isSelected = _selectedCity == city;

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => setState(() {
                                                  _selectedCity = city;
                                                  _selectedStation = null;
                                                  selectedStationData = null;
                                                }),
                                                borderRadius: BorderRadius.circular(10),
                                                splashColor: _primaryColor.withOpacity(0.1),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on_rounded,
                                                        size: 16,
                                                        color: isSelected ? _primaryColor : _textSecondary,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          city,
                                                          style: TextStyle(
                                                            color: isSelected ? _primaryColor : _textSecondary,
                                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Container(
                                                          padding: const EdgeInsets.all(2),
                                                          decoration: const BoxDecoration(
                                                            color: _primaryColor,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.check_rounded,
                                                            size: 12,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // 車站列表 - 右側
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _surfaceColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFEEF3FB),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: _accentColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.train_rounded,
                                                size: 16,
                                                color: _accentColor,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!.text_226,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: _textPrimary,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (stationsList[_selectedCity] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _accentColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${stationsList[_selectedCity]!.length}個',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: _accentColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: stationsList[_selectedCity] == null
                                            ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: 40,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                AppLocalizations.of(context)!.text_932,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                            : ListView.builder(
                                          padding: const EdgeInsets.all(8),
                                          itemCount: stationsList[_selectedCity]?.length ?? 0,
                                          itemBuilder: (context, index) {
                                            final station = stationsList[_selectedCity]![index];
                                            final stationEntry = stationDataMap.firstWhere(
                                                  (entry) => entry['StationName']['Zh_tw'] == station,
                                            );
                                            final isSelected = _selectedStation == station;
                                            final stationClass = stationEntry['StationClass'];
                                            final stationColor = _getStationColor(stationClass);
                                            final stationIcon = _getStationIcon(stationClass);

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 4),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: isSelected ? stationColor.withOpacity(0.1) : Colors.transparent,
                                                border: isSelected
                                                    ? Border.all(color: stationColor.withOpacity(0.3), width: 1.5)
                                                    : null,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => setState(() {
                                                    _selectedStation = station;
                                                    selectedStationData = stationEntry;
                                                  }),
                                                  borderRadius: BorderRadius.circular(10),
                                                  splashColor: stationColor.withOpacity(0.1),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(6),
                                                          decoration: BoxDecoration(
                                                            color: isSelected ? stationColor : stationColor.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Icon(
                                                            stationIcon,
                                                            size: 16,
                                                            color: isSelected ? Colors.white : stationColor,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                station,
                                                                style: TextStyle(
                                                                  color: isSelected ? stationColor : _textPrimary,
                                                                  fontSize: 15,
                                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                _getStationClassName(context,stationClass),
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.grey[500],
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          Container(
                                                            padding: const EdgeInsets.all(4),
                                                            decoration: BoxDecoration(
                                                              color: stationColor,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: const Icon(
                                                              Icons.check_rounded,
                                                              size: 12,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 底部按鈕區
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _backgroundWhite,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Center(
                                        child: Text(
                                          AppLocalizations.of(context)!.text_36,
                                          style: TextStyle(
                                            color: _textSecondary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: selectedStationData != null
                                      ? const LinearGradient(
                                    colors: [_primaryColor, Color(0xFF0D47A1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                      : LinearGradient(
                                    colors: [Colors.grey[400]!, Colors.grey[500]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: selectedStationData != null
                                      ? [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: selectedStationData != null
                                        ? () => Navigator.pop(context, selectedStationData)
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor: Colors.white.withOpacity(0.2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!.text_619,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 輔助方法：獲取車站等級顏色
  static Color _getStationColor(String stationClass) {
    switch (stationClass) {
      case "0":
        return _accentColor; // 特等站 - 橙色
      case "1":
        return _primaryColor; // 一等站 - 藍色
      case "2":
        return _successColor; // 二等站 - 綠色
      case "3":
        return const Color(0xFFAF52DE); // 三等站 - 紫色
      case "4":
        return const Color(0xFF5856D6); // 簡易站 - 靛藍
      case "5":
        return const Color(0xFFFF9F0A); // 招呼站 - 金色
      default:
        return _textSecondary;
    }
  }

  // 輔助方法：獲取車站等級圖標
  static IconData _getStationIcon(String stationClass) {
    switch (stationClass) {
      case "0":
        return Icons.star_rounded; // 特等站
      case "1":
        return Icons.directions_railway_filled_rounded; // 一等站
      case "2":
        return Icons.train_rounded; // 二等站
      case "3":
        return Icons.subway_rounded; // 三等站
      case "4":
        return Icons.directions_bus_rounded; // 簡易站
      case "5":
        return Icons.location_on_rounded; // 招呼站
      default:
        return Icons.location_city_rounded;
    }
  }

  // 輔助方法：獲取車站等級名稱
  static String _getStationClassName(context,String stationClass) {
    switch (stationClass) {
      case "0":
        return AppLocalizations.of(context)!.text_857;
      case "1":
        return AppLocalizations.of(context)!.text_858;
      case "2":
        return AppLocalizations.of(context)!.text_859;
      case "3":
        return AppLocalizations.of(context)!.text_860;
      case "4":
        return AppLocalizations.of(context)!.text_861;
      case "5":
        return AppLocalizations.of(context)!.text_862;
      default:
        return AppLocalizations.of(context)!.text_863;
    }
  }
}