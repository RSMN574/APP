import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:com.rsmn574.app/features/railway/provider/railway_provider.dart';

import 'package:com.rsmn574.app/database/sql/schedule.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/railway/widgets/route_planner.dart';
import 'package:com.rsmn574.app/const/app_colors.dart';

String _localizedHsrName(dynamic names, BuildContext context) {
  if (names is! Map) return names?.toString() ?? '';

  final isEnglish = Localizations.localeOf(context).languageCode == 'en';
  final preferred = names[isEnglish ? 'En' : 'Zh_tw']?.toString() ?? '';
  if (preferred.isNotEmpty) return preferred;

  return names[isEnglish ? 'Zh_tw' : 'En']?.toString() ?? '';
}

class HSRSchedulePage extends StatelessWidget {
  // 高鐵品牌橘（保留靜態常數供品牌識別）
  static const Color primaryHSR = Color(0xFFDC5321);

  final Map<String, dynamic> trainData;
  final String type;
  final DateTime time;

  const HSRSchedulePage({
    super.key,
    required this.trainData,
    required this.type,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trainNo = trainData['DailyTrainInfo']['TrainNo'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.text_393,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryHSR,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryHSR),
        actions: [
          // 加入行程
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () async {
                final railway = context.read<RailwayProvider>();
                List<dynamic> stationNames = trainData["StopTimes"]
                    .map((stop) => stop["StationName"] as Map)
                    .toList();

                final result = await showDialog(
                  context: context,
                  builder: (context) {
                    return StationSelectionDialog(stationNames: stationNames);
                  },
                );

                if (result != null) {
                  String getCategory(String category) {
                    switch (category) {
                      case '上班通勤':
                        return 'commute';
                      case '旅行':
                        return 'trip';
                      default:
                        return 'other';
                    }
                  }

                  final schedule = ScheduleModel(
                    userStartingStopName: result['departure'],
                    userDestinationStopName: result['destination'],
                    startingStopName: trainData['DailyTrainInfo']
                    ['StartingStationName']['Zh_tw'],
                    finalStopName: trainData['DailyTrainInfo']
                    ['EndingStationName']['Zh_tw'],
                    route: trainData['DailyTrainInfo']['TrainNo'],
                    type: 'HSR',
                    category: getCategory(result['category']),
                    time: time.toString(),
                    seatNumber: result["seatNumber"],
                    other: {
                      "DateTime": time.toString(),
                      "trainType": AppLocalizations.of(context)!.text_394,
                      "category": getCategory(result['category'])
                    },
                  );

                  final output = await railway.addSchedule(schedule);

                  if (!context.mounted) return;

                  if (output == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.text_395),
                        backgroundColor: colors.warning,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else if (output == 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.text_396),
                        backgroundColor: colors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.text_397),
                        backgroundColor: colors.danger,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: primaryHSR,
                ),
              ),
            ),
          ),
          // 列車資訊
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                _showTrainInfoDialog(context);
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: primaryHSR,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrainInfoCard(context),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.timeline_rounded,
                      size: 20, color: primaryHSR),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.text_398,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryHSR,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStopTimesList(context),
            _buildHSRInfoCard(context),
          ],
        ),
      ),
    );
  }

  // ==================== 列車資訊對話框 ====================
  void _showTrainInfoDialog(BuildContext context) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 320),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryHSR.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.train_rounded,
                          color: primaryHSR,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.text_394,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryHSR,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_399,
                    '12節車廂（9M3T）',
                    colors,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_400,
                    '304.2m',
                    colors,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_401,
                    '300km/h',
                    colors,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_402,
                    '295km/h',
                    colors,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_403,
                    AppLocalizations.of(context)!.text_404,
                    colors,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_405,
                    AppLocalizations.of(context)!.text_406,
                    colors,
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.text_407,
                    AppLocalizations.of(context)!.text_406,
                    colors,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        '關閉',
                        style: TextStyle(
                          color: primaryHSR,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 車次資訊卡片 ====================
  Widget _buildTrainInfoCard(BuildContext context) {
    final colors = context.appColors;
    final trainNo = trainData['DailyTrainInfo']['TrainNo'];

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 車次標題
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryHSR,
                        primaryHSR.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    trainNo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.text_408,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryHSR.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '700T 列車',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryHSR,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 起站/終站
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryHSR.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: primaryHSR,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.text_409,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localizedHsrName(
                            trainData['DailyTrainInfo']['StartingStationName'],
                            context,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: primaryHSR,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                AppLocalizations.of(context)!.text_410,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.flag_rounded,
                                size: 16,
                                color: colors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _localizedHsrName(
                            trainData['DailyTrainInfo']['EndingStationName'],
                            context,
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 備註
            if (_localizedHsrName(
              trainData['DailyTrainInfo']['Note'],
              context,
            ).isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localizedHsrName(
                          trainData['DailyTrainInfo']['Note'],
                          context,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 停靠站列表 ====================
  Widget _buildStopTimesList(BuildContext context) {
    final colors = context.appColors;
    final stopTimes = trainData['StopTimes'] as List<dynamic>;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stopTimes.length,
      itemBuilder: (context, index) {
        final stop = stopTimes[index];
        final isLast = index == stopTimes.length - 1;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 時間
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stop['ArrivalTime'] ?? '--:--',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primaryHSR,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stop['DepartureTime'] ?? '--:--',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 時間軸
              Column(
                children: [
                  if (index > 0)
                    Container(
                      width: 2,
                      height: 24,
                      color: primaryHSR.withValues(alpha: 0.3),
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryHSR,
                          primaryHSR.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryHSR.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 24,
                      color: primaryHSR.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // 車站
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedHsrName(stop['StationName'], context).isNotEmpty
                          ? _localizedHsrName(stop['StationName'], context)
                          : AppLocalizations.of(context)!.text_160,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.text_411,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 里程
              if (stop['Distance'] != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stop['Distance']}km',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== 高鐵列車介紹卡片 ====================
  Widget _buildHSRInfoCard(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.train_rounded,
                  size: 20,
                  color: primaryHSR,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.text_394,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryHSR,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryHSR.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Row(
            children: [
              _buildHSRFeature(
                context,
                icon: Icons.speed_rounded,
                title: AppLocalizations.of(context)!.text_401,
                value: '300 km/h',
              ),
              _buildHSRFeature(
                context,
                icon: Icons.timer_rounded,
                title: AppLocalizations.of(context)!.text_412,
                value: '90 分鐘',
              ),
              _buildHSRFeature(
                context,
                icon: Icons.event_seat_rounded,
                title: AppLocalizations.of(context)!.text_413,
                value: '989 席',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHSRFeature(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
      }) {
    final colors = context.appColors;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: primaryHSR),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}