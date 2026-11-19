import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../const/app_colors.dart';
import '../../../core/city/taiwan_city.dart';
import '../../../firebase/analytics_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widget/app_state_views.dart';
import '../data/bus_schedule_remote_data_source.dart';
import '../data/bus_schedule_repository.dart';
import '../model/bus_daily_timetable.dart';
import '../state/bus_schedule_provider.dart';

/// 公車每日班表頁（TDX DailyStopTimeTable）。
///
/// 顯示「預定班表」，與路線頁的預估到站時間（EstimatedTimeOfArrival）分開，
/// 頁首固定提示兩者差異，避免使用者誤認。
class BusSchedulePage extends StatelessWidget {
  const BusSchedulePage({
    super.key,
    required this.city,
    required this.routeName,
    this.routeId,
    this.repository,
  });

  /// 城市（TDX 代碼或中文名皆可）。
  final String city;
  final String routeName;
  final String? routeId;

  /// 測試時注入。
  final BusScheduleRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusScheduleProvider(
        city: city,
        routeName: routeName,
        routeId: routeId,
        repository: repository,
      )..load(),
      child: _BusScheduleView(routeName: routeName),
    );
  }
}

class _BusScheduleView extends StatefulWidget {
  const _BusScheduleView({required this.routeName});

  final String routeName;

  @override
  State<_BusScheduleView> createState() => _BusScheduleViewState();
}

class _BusScheduleViewState extends State<_BusScheduleView> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<BusScheduleProvider>();
    unawaited(AppAnalytics.logBusScheduleView(
      city: BusScheduleRemoteDataSource.resolveCity(provider.city) ?? 'unknown',
      supported: provider.isCitySupported,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<BusScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.busScheduleTitle(widget.routeName),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (provider.status != BusScheduleStatus.unsupported)
            IconButton(
              tooltip: l10n.busScheduleRefresh,
              onPressed: provider.status == BusScheduleStatus.loading
                  ? null
                  : () => provider.load(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, provider, l10n)),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BusScheduleProvider provider,
    AppLocalizations l10n,
  ) {
    switch (provider.status) {
      case BusScheduleStatus.idle:
      case BusScheduleStatus.loading:
        if (provider.result == null) {
          return AppLoadingView(message: l10n.busScheduleLoading);
        }
        return _ScheduleContent(provider: provider);
      case BusScheduleStatus.unsupported:
        final isEnglish = Localizations.localeOf(context).languageCode == 'en';
        final city = TaiwanCity.tryParse(provider.city);
        final cityName = city == null
            ? provider.city
            : (isEnglish ? city.enName : city.zhName);
        return AppEmptyView(
          icon: Icons.event_busy_rounded,
          title: l10n.busScheduleUnsupportedTitle,
          message: l10n.busScheduleUnsupported(cityName),
        );
      case BusScheduleStatus.empty:
        return RefreshIndicator(
          onRefresh: () => provider.load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              AppEmptyView(
                icon: Icons.schedule_rounded,
                message: l10n.busScheduleEmpty,
              ),
            ],
          ),
        );
      case BusScheduleStatus.error:
        return AppErrorView(
          message: l10n.busScheduleError,
          onRetry: () => provider.load(forceRefresh: true),
        );
      case BusScheduleStatus.loaded:
        return _ScheduleContent(provider: provider);
    }
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({required this.provider});

  final BusScheduleProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final direction = provider.selectedDirection;
    final stop = provider.selectedStop;
    final result = provider.result;
    if (direction == null || stop == null || result == null) {
      return AppEmptyView(message: l10n.busScheduleEmpty);
    }

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('MM-dd HH:mm');
    String twDate(DateTime d) =>
        dateFormat.format(d.toUtc().add(const Duration(hours: 8)));
    String twTime(DateTime d) =>
        timeFormat.format(d.toUtc().add(const Duration(hours: 8)));

    final next = provider.nextDeparture;

    return RefreshIndicator(
      onRefresh: () => provider.load(forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(children: [
              _NoticeCard(
                icon: Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
                text: direction.isEstimatedOnly
                    ? '${l10n.busScheduleNotice}\n${l10n.busScheduleEstimatedNotice}'
                    : l10n.busScheduleNotice,
              ),
              if (provider.isStale)
                _NoticeCard(
                  icon: Icons.cloud_off_rounded,
                  color: colors.warning,
                  text: l10n.busScheduleStale(twTime(result.fetchedAt)),
                ),
              if (provider.isOutdated && direction.busDate != null)
                _NoticeCard(
                  icon: Icons.warning_amber_rounded,
                  color: colors.warning,
                  text: l10n.busScheduleOutdated(twDate(direction.busDate!)),
                ),
              const SizedBox(height: 8),
              if (provider.directions.length > 1) ...[
                Text(l10n.busScheduleDirectionLabel,
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < provider.directions.length; i++)
                      ChoiceChip(
                        label: Text(_directionLabel(
                            provider.directions[i], l10n, isEnglish)),
                        selected: i == provider.directionIndex,
                        onSelected: (_) => provider.selectDirection(i),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _directionLabel(direction, l10n, isEnglish),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              if (provider.stops.length > 1)
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: provider.stopIndex,
                  decoration:
                      InputDecoration(labelText: l10n.busScheduleStopLabel),
                  items: [
                    for (var i = 0; i < provider.stops.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          provider.stops[i].name
                                  ?.localized(english: isEnglish) ??
                              provider.stops[i].stopId,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (i) {
                    if (i != null) provider.selectStop(i);
                  },
                )
              else
                Text(
                  '${l10n.busScheduleStopLabel}：'
                  '${stop.name?.localized(english: isEnglish) ?? stop.stopId}',
                  style: theme.textTheme.titleSmall,
                ),
              const SizedBox(height: 12),
              _SummaryCard(
                stop: stop,
                next: next,
                outdated: provider.isOutdated,
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (direction.busDate != null)
                    l10n.busScheduleServiceDate(twDate(direction.busDate!)),
                  if (direction.updateTime != null)
                    l10n.busScheduleUpdated(twTime(direction.updateTime!)),
                ].join('・'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: _TimeGrid(stop: stop, next: next),
          ),
        ],
      ),
    );
  }

  String _directionLabel(
      BusDailyTimetable t, AppLocalizations l10n, bool isEnglish) {
    final dest = t.destinationStopName?.localized(english: isEnglish);
    final sub = t.subRouteName?.localized(english: isEnglish);
    final base =
        dest == null ? (sub ?? t.subRouteId) : l10n.busScheduleTowards(dest);
    // 不同附屬路線同方向時，附上附屬路線名稱區分。
    if (sub != null && sub != t.routeName.localized(english: isEnglish)) {
      return '$sub・$base';
    }
    return base;
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.stop,
    required this.next,
    required this.outdated,
  });

  final BusTimetableStop stop;
  final BusTimetableEntry? next;
  final bool outdated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final first = stop.firstDeparture;
    final last = stop.lastDeparture;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!outdated)
              Text(
                next == null
                    ? l10n.busScheduleNoMore
                    : l10n.busScheduleNext(next!.departure.format()),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              [
                if (first != null && last != null)
                  l10n.busScheduleFirstLast(first.format(), last.format()),
                l10n.busScheduleTrips(stop.entries.length),
              ].join('・'),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeGrid extends StatelessWidget {
  const _TimeGrid({required this.stop, required this.next});

  final BusTimetableStop stop;
  final BusTimetableEntry? next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final entries = stop.entries;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 96 * textScale.clamp(1.0, 2.0),
        mainAxisExtent: 44 * textScale.clamp(1.0, 2.0),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isNext = identical(entry, next);
        return Semantics(
          label: isNext
              ? l10n.busScheduleNext(entry.departure.format())
              : entry.departure.format(),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isNext
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.departure.format(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isNext
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (entry.departure.isNextDay || entry.isLowFloor == true)
                  Text(
                    [
                      if (entry.departure.isNextDay) l10n.busScheduleNextDay,
                      if (entry.isLowFloor == true) l10n.busScheduleLowFloor,
                    ].join(' '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isNext
                          ? theme.colorScheme.onPrimary
                          : colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
