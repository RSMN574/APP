import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../database/getData.dart';

class StationDialog {
  // 高鐵主題色 - 保留高鐵橘
  static const Color primaryHSR = Color(0xFFDC5321); // 高鐵標準橘
  static const Color backgroundLight = Color(0xFFF8FAFD); // 通知中心背景色
  static const Color surfaceColor = Color(0xFFEEF3FB); // 通知中心表面色
  static const Color textPrimary = Color(0xFF2D3748); // 主要文字
  static const Color textSecondary = Color(0xFF718096); // 次要文字
  static const Color successGreen = Color(0xFF34C759); // 成功綠色
  static const Color errorRed = Color(0xFFFF3B30); // 錯誤紅色

  static Future<Map<String, dynamic>?> showStationDialog(BuildContext context) async {
    // 獲取高鐵車站數據
    List stationData = await mysqlSelect("SELECT StationID, StationName, StationPosition, URL FROM HSR.HSR_Station ORDER BY StationID;");

    // 轉換數據格式
    List<Map<String, dynamic>> stationDataMap = stationData.map((item) {
      final stationName = json.decode(item["StationName"]);
      return {
        'StationName': {
          'Zh_tw': stationName['Zh_tw'],
          'En': stationName['En'],
        },
        'StationID': item['StationID'],
        'StationPosition': item['StationPosition'],
        'URL': item['URL']
      };
    }).toList();

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
                    color: Colors.white,
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
                      // 頂部標題欄 - 高鐵橘漸層
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
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
                                  const Text(
                                    '選擇高鐵車站',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '請選擇您要查詢的高鐵車站',
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

                      // 車站列表
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 標題列
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryHSR.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 16,
                                      color: primaryHSR,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '高鐵車站列表',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryHSR.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${stationDataMap.length} 個車站',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: primaryHSR,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 車站列表
                              Expanded(
                                child: ListView.builder(
                                  itemCount: stationDataMap.length,
                                  itemBuilder: (context, index) {
                                    final station = stationDataMap[index];
                                    final stationName = station['StationName']['Zh_tw'];
                                    final stationEn = station['StationName']['En'];
                                    final stationID = station['StationID'];
                                    final isSelected = _selectedStation == stationName;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isSelected
                                            ? primaryHSR.withOpacity(0.05)
                                            : Colors.transparent,
                                        border: isSelected
                                            ? Border.all(
                                          color: primaryHSR.withOpacity(0.3),
                                          width: 1.5,
                                        )
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => setState(() {
                                            _selectedStation = stationName;
                                            selectedStationData = station;
                                          }),
                                          borderRadius: BorderRadius.circular(12),
                                          splashColor: primaryHSR.withOpacity(0.1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                // 車站圖標
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? primaryHSR
                                                        : primaryHSR.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    Icons.train_rounded,
                                                    size: 18,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : primaryHSR,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),

                                                // 車站資訊
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        stationName,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w600,
                                                          color: isSelected
                                                              ? primaryHSR
                                                              : textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        stationEn,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: textSecondary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // 車站代碼
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: surfaceColor,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    stationID,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: textSecondary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 8),

                                                // 選中標記
                                                if (isSelected)
                                                  Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: primaryHSR,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_rounded,
                                                      size: 14,
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

                      // 底部按鈕區
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                            // 取消按鈕
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
                                          '取消',
                                          style: TextStyle(
                                            color: textSecondary,
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

                            // 確認按鈕
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: selectedStationData != null
                                      ? LinearGradient(
                                    colors: [primaryHSR, primaryHSR.withOpacity(0.8)],
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
                                      color: primaryHSR.withOpacity(0.3),
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
                                            '確認選擇',
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
}