import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/surface_decoration.dart';
import 'package:com.rsmn574.app/database/get_data.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';

class StationDialog {
  static Future<Map<String, dynamic>?> showStationDialog(
      BuildContext context) async {
    // ── 資料取得與轉換（邏輯不動）────────────────────────
    final List stationData = await mysqlSelect(
        "SELECT StationID,StationClass,StationName,StationPosition,LocationCity FROM Train.Train_Station;");

    final List<Map<String, dynamic>> stationDataMap =
    stationData.map((item) {
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

    final Map<String, List<String>> stationsList = {};
    for (var entry in stationDataMap) {
      final String city = entry['LocationCity'];
      final String stationName = entry['StationName']['Zh_tw'];
      stationsList.putIfAbsent(city, () => []).add(stationName);
    }

    String selectedCity = AppLocalizations.of(context)!.text_6;
    String? selectedStation;
    Map<String, dynamic>? selectedStationData;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.appColors.scrim,
      builder: (BuildContext context) {
        final colors = context.appColors;
        final l10n = AppLocalizations.of(context)!;

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
                    color: colors.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 頂部標題欄 ──────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.info,
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
                                  Text(
                                    l10n.text_925,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.text_930,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
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

                      // ── 主內容區 ────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 城市列表（左）
                              Container(
                                width:
                                MediaQuery.of(context).size.width * 0.3,
                                decoration: SurfaceDecoration.outlined(
                                  context,
                                  radius: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding:
                                            const EdgeInsets.all(6),
                                            decoration:
                                            SurfaceDecoration.muted(
                                              context,
                                              radius: 8,
                                            ),
                                            child: Icon(
                                              Icons.location_city_rounded,
                                              size: 16,
                                              color: colors.info,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              l10n.text_931,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                              TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(
                                      height: 1,
                                      color: colors.divider,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: stationsList.keys.length,
                                        itemBuilder: (context, index) {
                                          final city =
                                          stationsList.keys.elementAt(index);
                                          final isSelected =
                                              selectedCity == city;

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 4),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              color: isSelected
                                                  ? colors.info
                                                  .withOpacity(0.1)
                                                  : Colors.transparent,
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => setState(() {
                                                  selectedCity = city;
                                                  selectedStation = null;
                                                  selectedStationData = null;
                                                }),
                                                borderRadius:
                                                BorderRadius.circular(10),
                                                splashColor: colors.info
                                                    .withOpacity(0.1),
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                    vertical: 12,
                                                    horizontal: 12,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .location_on_rounded,
                                                        size: 16,
                                                        color: isSelected
                                                            ? colors.info
                                                            : colors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(
                                                          width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          city,
                                                          style: TextStyle(
                                                            color: isSelected
                                                                ? colors.info
                                                                : colors
                                                                .textSecondary,
                                                            fontWeight: isSelected
                                                                ? FontWeight
                                                                .w600
                                                                : FontWeight
                                                                .w500,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Container(
                                                          padding:
                                                          const EdgeInsets
                                                              .all(2),
                                                          decoration:
                                                          BoxDecoration(
                                                            color:
                                                            colors.info,
                                                            shape: BoxShape
                                                                .circle,
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .check_rounded,
                                                            size: 12,
                                                            color: colors
                                                                .cardBackground,
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

                              // 車站列表（右）
                              Expanded(
                                child: Container(
                                  decoration: SurfaceDecoration.outlined(
                                    context,
                                    radius: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                              const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: colors
                                                    .warningContainer,
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.train_rounded,
                                                size: 16,
                                                color: colors.warning,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.text_226,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (stationsList[selectedCity] !=
                                                null)
                                              Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colors
                                                      .warningContainer,
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      12),
                                                ),
                                                child: Text(
                                                  // TODO: i18n（{count}個 / {count}）
                                                  '${stationsList[selectedCity]!.length}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                    color: colors.warning,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Divider(
                                          height: 1, color: colors.divider),
                                      Expanded(
                                        child: stationsList[selectedCity] ==
                                            null
                                            ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .info_outline_rounded,
                                                size: 40,
                                                color: colors.textHint,
                                              ),
                                              const SizedBox(
                                                  height: 12),
                                              Text(
                                                l10n.text_932,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colors
                                                      .textSecondary,
                                                  fontWeight:
                                                  FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                            : ListView.builder(
                                          padding:
                                          const EdgeInsets.all(8),
                                          itemCount: stationsList[
                                          selectedCity]
                                              ?.length ??
                                              0,
                                          itemBuilder:
                                              (context, index) {
                                            final station =
                                            stationsList[
                                            selectedCity]![index];
                                            final stationEntry =
                                            stationDataMap
                                                .firstWhere(
                                                  (entry) =>
                                              entry['StationName']
                                              [
                                              'Zh_tw'] ==
                                                  station,
                                            );
                                            final isSelected =
                                                selectedStation ==
                                                    station;
                                            final stationClass =
                                            stationEntry[
                                            'StationClass'];
                                            final stationColor =
                                            _getStationColor(
                                              context,
                                              stationClass,
                                            );
                                            final stationIcon =
                                            _getStationIcon(
                                                stationClass);

                                            return Container(
                                              margin:
                                              const EdgeInsets.only(
                                                  bottom: 4),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius
                                                    .circular(10),
                                                color: isSelected
                                                    ? stationColor
                                                    .withOpacity(0.1)
                                                    : Colors
                                                    .transparent,
                                                border: isSelected
                                                    ? Border.all(
                                                    color: stationColor
                                                        .withOpacity(
                                                        0.3),
                                                    width: 1.5)
                                                    : null,
                                              ),
                                              child: Material(
                                                color:
                                                Colors.transparent,
                                                child: InkWell(
                                                  onTap: () =>
                                                      setState(() {
                                                        selectedStation =
                                                            station;
                                                        selectedStationData =
                                                            stationEntry;
                                                      }),
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  splashColor:
                                                  stationColor
                                                      .withOpacity(
                                                      0.1),
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                      vertical: 12,
                                                      horizontal: 12,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                          const EdgeInsets
                                                              .all(6),
                                                          decoration:
                                                          BoxDecoration(
                                                            color: isSelected
                                                                ? stationColor
                                                                : stationColor
                                                                .withOpacity(
                                                                0.1),
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                8),
                                                          ),
                                                          child: Icon(
                                                            stationIcon,
                                                            size: 16,
                                                            color: isSelected
                                                                ? colors
                                                                .cardBackground
                                                                : stationColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                            children: [
                                                              Text(
                                                                station,
                                                                style:
                                                                TextStyle(
                                                                  color: isSelected
                                                                      ? stationColor
                                                                      : colors.textPrimary,
                                                                  fontSize:
                                                                  15,
                                                                  fontWeight: isSelected
                                                                      ? FontWeight.w600
                                                                      : FontWeight.w500,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height:
                                                                  2),
                                                              Text(
                                                                _getStationClassName(
                                                                    context,
                                                                    stationClass),
                                                                style:
                                                                TextStyle(
                                                                  fontSize:
                                                                  11,
                                                                  color: colors
                                                                      .textHint,
                                                                  fontWeight:
                                                                  FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (isSelected)
                                                          Container(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(
                                                                4),
                                                            decoration:
                                                            BoxDecoration(
                                                              color:
                                                              stationColor,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .check_rounded,
                                                              size: 12,
                                                              color: colors
                                                                  .cardBackground,
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

                      // ── 底部按鈕區 ──────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 取消
                            Expanded(
                              child: Container(
                                decoration: SurfaceDecoration.outlined(
                                  context,
                                  radius: 12,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      child: Center(
                                        child: Text(
                                          l10n.text_36,
                                          style: TextStyle(
                                            color: colors.textSecondary,
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
                            // 確認
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: selectedStationData != null
                                      ? colors.info
                                      : colors.mutedBackground,
                                  boxShadow: selectedStationData != null
                                      ? [
                                    BoxShadow(
                                      color: colors.info
                                          .withOpacity(0.3),
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
                                        ? () => Navigator.pop(
                                        context, selectedStationData)
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor:
                                    Colors.white.withOpacity(0.2),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color:
                                              selectedStationData != null
                                                  ? Colors.white
                                                  : colors.textHint,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                l10n.text_619,
                                                style: TextStyle(
                                                  color:
                                                  selectedStationData !=
                                                      null
                                                      ? Colors.white
                                                      : colors.textHint,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow.ellipsis,
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

  // ── 車站等級顏色（改用 AppColors）──────────────────────
  static Color _getStationColor(
      BuildContext context, String stationClass) {
    final colors = context.appColors;
    switch (stationClass) {
      case "0":
        return colors.warning; // 特等站
      case "1":
        return colors.info; // 一等站
      case "2":
        return colors.success; // 二等站
      case "3":
        return colors.info; // 三等站
      case "4":
        return colors.success; // 簡易站
      case "5":
        return colors.warning; // 招呼站
      default:
        return colors.textSecondary;
    }
  }

  // ── 車站等級圖標（不變）──────────────────────────────
  static IconData _getStationIcon(String stationClass) {
    switch (stationClass) {
      case "0":
        return Icons.star_rounded;
      case "1":
        return Icons.directions_railway_filled_rounded;
      case "2":
        return Icons.train_rounded;
      case "3":
        return Icons.subway_rounded;
      case "4":
        return Icons.directions_bus_rounded;
      case "5":
        return Icons.location_on_rounded;
      default:
        return Icons.location_city_rounded;
    }
  }

  // ── 車站等級名稱（不變）──────────────────────────────
  static String _getStationClassName(
      BuildContext context, String stationClass) {
    final l10n = AppLocalizations.of(context)!;
    switch (stationClass) {
      case "0":
        return l10n.text_857;
      case "1":
        return l10n.text_858;
      case "2":
        return l10n.text_859;
      case "3":
        return l10n.text_860;
      case "4":
        return l10n.text_861;
      case "5":
        return l10n.text_862;
      default:
        return l10n.text_863;
    }
  }
}