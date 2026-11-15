import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../../const/app_colors.dart';
import '../../../const/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/transit_alert.dart';
import '../state/transit_alert_provider.dart';

class TransitAlertCenter extends StatefulWidget {
  const TransitAlertCenter({super.key});

  @override
  State<TransitAlertCenter> createState() => _TransitAlertCenterState();
}

class _TransitAlertCenterState extends State<TransitAlertCenter> {
  TransportType? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransitAlertProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<TransitAlertProvider>();
    final colors = context.appColors;
    final alerts = provider.alerts
        .where((alert) => _filter == null || alert.transportType == _filter)
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        AppSpacing.sm,
        AppSpacing.pageMargin,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 標題卡片 =====
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: AppRadius.roundedXl,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.info,
                        colors.info.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.roundedMd,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: AppSizes.iconMd,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transitAlertCenterTitle,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: AppTypography.titleMedium,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        alerts.isEmpty
                            ? l10n.transitAlertNoNew
                            : l10n.transitAlertCount(alerts.length),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // 重新整理
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: provider.isLoading
                        ? null
                        : () => provider.load(force: true),
                    borderRadius: AppRadius.roundedSm,
                    child: Tooltip(
                      message: l10n.transitAlertRefreshTooltip,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.mutedBackground,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: AppSizes.iconSm,
                          color: colors.info,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 查看全部
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: provider.alerts.isEmpty
                        ? null
                        : () => _showAllAlerts(context, provider.alerts),
                    borderRadius: AppRadius.roundedSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.infoContainer,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Text(
                        l10n.transitAlertViewAll,
                        style: TextStyle(
                          color: colors.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ===== 篩選晶片 =====
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(context, l10n.transitAlertFilterAll, null),
                for (final type in const [
                  TransportType.bus,
                  TransportType.metro,
                  TransportType.thsr,
                ])
                  _filterChip(context, _transportLabel(l10n, type), type),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ===== 內容 =====
          if (provider.isLoading && provider.alerts.isEmpty)
            _buildLoadingState(colors, l10n)
          else if (alerts.isEmpty)
            _buildEmptyState(colors, provider, l10n)
          else
            for (final alert in alerts) _AlertCard(alert: alert),

          if (provider.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.transitAlertLastUpdated(
                  _formatTime(provider.lastUpdated, l10n),
                ),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppColors colors, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.roundedXl,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.info,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.transitAlertLoading,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, TransportType? type) {
    final colors = context.appColors;
    final isSelected = _filter == type;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filter = type),
          borderRadius: AppRadius.roundedFull,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.info : colors.cardBackground,
              borderRadius: AppRadius.roundedFull,
              border: Border.all(
                color: isSelected
                    ? colors.info
                    : colors.border.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: colors.info.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type != null) ...[
                  Icon(
                    _transportIcon(type),
                    size: 14,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      AppColors colors,
      TransitAlertProvider provider,
      AppLocalizations l10n,
      ) {
    final message = provider.hasSourceErrors
        ? l10n.transitAlertPartialSourceError
        : l10n.transitAlertEmptyMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.roundedXl,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.infoContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 32,
              color: colors.info,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.transitAlertEmptyTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: AppTypography.titleMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: AppTypography.bodyHeight,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllAlerts(BuildContext context, List<TransitAlert> alerts) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: AppRadius.roundedFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.info,
                          colors.info.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      size: AppSizes.iconMd,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.transitAlertAllTitle,
                      style: TextStyle(
                        fontSize: AppTypography.titleLarge,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    l10n.transitAlertCountSuffix(alerts.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final alert in alerts)
                      _AlertCard(
                        alert: alert,
                        onTap: () => _showDetailsDialog(sheetContext, alert),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 詳情對話框（共用） ====================

void _showDetailsDialog(BuildContext context, TransitAlert alert) {
  final colors = context.appColors;
  final l10n = AppLocalizations.of(context)!;
  final severityColor = _severityColor(colors, alert.severity);

  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 標題 =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Icon(
                      _transportIcon(alert.transportType),
                      color: severityColor,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: AppTypography.titleMedium,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            _buildTag(
                              _severityLabel(l10n, alert.severity),
                              severityColor,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _buildTag(
                              _alertTypeLabel(l10n, alert.alertType),
                              colors.info,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(dialogContext),
                      borderRadius: AppRadius.roundedFull,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.close_rounded,
                          size: AppSizes.iconSm,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ===== 內文 =====
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: AppRadius.roundedLg,
                ),
                child: Text(
                  alert.description,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: colors.textPrimary,
                    height: AppTypography.bodyHeight,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ===== 詳細資訊 =====
              _detailRow(
                colors,
                Icons.adjust_rounded,
                l10n.transitAlertDetailImpact,
                _impactText(alert, l10n),
              ),
              if (alert.location != null)
                _detailRow(
                  colors,
                  Icons.location_on_outlined,
                  l10n.transitAlertDetailLocation,
                  alert.location!,
                ),
              _detailRow(
                colors,
                Icons.source_outlined,
                l10n.transitAlertDetailSource,
                alert.source,
              ),
              if (alert.publishedAt != null)
                _detailRow(
                  colors,
                  Icons.schedule_rounded,
                  l10n.transitAlertDetailPublishedAt,
                  _formatTime(alert.publishedAt, l10n),
                ),
              if (alert.updatedAt != null)
                _detailRow(
                  colors,
                  Icons.update_rounded,
                  l10n.transitAlertDetailUpdatedAt,
                  _formatTime(alert.updatedAt, l10n),
                ),

              const SizedBox(height: AppSpacing.xl),

              // ===== 按鈕 =====
              Row(
                children: [
                  if (alert.sourceUrl != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final opened = await launchUrl(
                            Uri.parse(alert.sourceUrl!),
                            mode: LaunchMode.externalApplication,
                          );
                          if (!opened && dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(l10n.transitAlertOpenLinkFailed),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: Text(l10n.transitAlertViewOriginal),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.info,
                          side: BorderSide(
                            color: colors.info.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.roundedMd,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: _PrimaryButton(
                      label: l10n.transitAlertClose,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildTag(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppRadius.roundedFull,
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _detailRow(
    AppColors colors,
    IconData icon,
    String label,
    String value,
    ) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.textHint),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label：',
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ==================== 公告卡片 ====================

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, this.onTap});

  final TransitAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final severityColor = _severityColor(colors, alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.roundedXl,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.roundedXl,
          onTap: onTap ?? () => _showDetailsDialog(context, alert),
          splashColor: severityColor.withValues(alpha: 0.1),
          child: Stack(
            children: [
              // 左側裝飾線
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        severityColor,
                        severityColor.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg + AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 圖標容器
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            severityColor,
                            severityColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppRadius.roundedMd,
                      ),
                      child: Icon(
                        _transportIcon(alert.transportType),
                        color: Colors.white,
                        size: AppSizes.iconMd,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            alert.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _buildTag(
                                _severityLabel(l10n, alert.severity),
                                severityColor,
                              ),
                              _buildTag(
                                '${_transportLabel(l10n, alert.transportType)}・'
                                    '${_alertTypeLabel(l10n, alert.alertType)}',
                                colors.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${alert.source}・'
                                '${l10n.transitAlertDetailUpdatedAt} '
                                '${_formatTime(alert.updatedAt ?? alert.publishedAt, l10n)}',
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.mutedBackground,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: colors.textSecondary,
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
  }
}

// ==================== 共用主色按鈕 ====================

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.roundedMd,
        gradient: LinearGradient(
          colors: [colors.info, colors.info.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.info.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.roundedMd,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.bodyLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== 翻譯輔助函數 ====================

String _transportLabel(AppLocalizations l10n, TransportType type) =>
    switch (type) {
      TransportType.bus => l10n.transportBus,
      TransportType.metro => l10n.transportMetro,
      TransportType.tra => l10n.transportTra,
      TransportType.thsr => l10n.transportThsr,
      TransportType.aviation => l10n.transportAviation,
      TransportType.youbike => l10n.transportYoubike,
      TransportType.other => l10n.transportOther,
    };

String _alertTypeLabel(AppLocalizations l10n, AlertType type) =>
    switch (type) {
      AlertType.serviceDisruption => l10n.alertTypeServiceDisruption,
      AlertType.routeDetour => l10n.alertTypeRouteDetour,
      AlertType.suspension => l10n.alertTypeSuspension,
      AlertType.delay => l10n.alertTypeDelay,
      AlertType.scheduleChange => l10n.alertTypeScheduleChange,
      AlertType.stationNotice => l10n.alertTypeStationNotice,
      AlertType.facilityNotice => l10n.alertTypeFacilityNotice,
      AlertType.weatherImpact => l10n.alertTypeWeatherImpact,
      AlertType.generalNotice => l10n.alertTypeGeneralNotice,
    };

String _severityLabel(AppLocalizations l10n, AlertSeverity severity) =>
    switch (severity) {
      AlertSeverity.info => l10n.alertSeverityInfo,
      AlertSeverity.minor => l10n.alertSeverityMinor,
      AlertSeverity.moderate => l10n.alertSeverityModerate,
      AlertSeverity.major => l10n.alertSeverityMajor,
      AlertSeverity.critical => l10n.alertSeverityCritical,
      AlertSeverity.unknown => l10n.alertSeverityUnknown,
    };

IconData _transportIcon(TransportType type) => switch (type) {
  TransportType.bus => Icons.directions_bus_outlined,
  TransportType.metro => Icons.subway_outlined,
  TransportType.tra || TransportType.thsr => Icons.train_outlined,
  TransportType.aviation => Icons.flight_outlined,
  TransportType.youbike => Icons.pedal_bike_outlined,
  TransportType.other => Icons.commute_outlined,
};

Color _severityColor(AppColors colors, AlertSeverity severity) =>
    switch (severity) {
      AlertSeverity.info => colors.info,
      AlertSeverity.minor => colors.success,
      AlertSeverity.moderate => colors.warning,
      AlertSeverity.major || AlertSeverity.critical => colors.danger,
      AlertSeverity.unknown => colors.textHint,
    };

String _impactText(TransitAlert alert, AppLocalizations l10n) {
  final values = [...alert.affectedRoutes, ...alert.affectedStops];
  return values.isEmpty ? l10n.transitAlertNotProvided : values.join('、');
}

String _formatTime(DateTime? time, AppLocalizations l10n) =>
    time == null
        ? l10n.transitAlertUnknown
        : DateFormat('MM/dd HH:mm').format(time.toLocal());