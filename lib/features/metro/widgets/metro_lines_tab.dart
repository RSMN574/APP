import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_theme.dart';
import 'metro_ui_utils.dart';

/// 路線資訊分頁（取代車站清單）：目前系統的路線、起迄站、營運交路，以及「這個系統有哪些資料」。
class MetroLinesTab extends StatelessWidget {
  const MetroLinesTab({super.key, required this.onShowLine});
  final ValueChanged<String> onShowLine;

  @override
  Widget build(BuildContext context) {
    final system = context.select<MetroProvider, MetroSystem?>((p) => p.selectedSystem);
    final catalog = context.read<MetroProvider>().catalog;
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    if (system == null || catalog == null) return MetroEmptyView(message: s.emptySystem);

    final lines = system.lineUids.map((u) => catalog.lineByUid[u]).whereType<MetroLine>().toList(growable: false);
    final candidates = catalog.candidateLinks.where((l) => catalog.stationByUid[l.a]?.operator == system.code || catalog.stationByUid[l.b]?.operator == system.code).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CoverageCard(system: system, candidateCount: candidates, version: catalog.version),
        const SizedBox(height: 12),
        for (final l in lines) _LineCard(line: l, catalog: catalog, locale: locale, onShow: () => onShowLine(l.uid)),
      ],
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.system, required this.candidateCount, required this.version});
  final MetroSystem system;
  final int candidateCount;
  final String version;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = system.coverage;

    Widget row(IconData icon, String label, bool ok) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(ok ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded, size: 18, color: ok ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: text.bodyMedium)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MetroTheme.cardDecoration(context, radius: 16, shadow: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(system.name.resolve(locale), style: text.titleMedium),
          const SizedBox(height: 4),
          Text(s.stationCountLabel(system.stationCount), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          row(Icons.map_rounded, c.shape ? s.coverShape : s.coverNoShape, c.shape),
          row(Icons.elevator_rounded, c.facilityStations > 0 ? s.coverFacility(c.facilityStations, system.stationCount) : s.coverNoFacility, c.facilityStations > 0),
          row(Icons.transfer_within_a_station_rounded, c.transferStations > 0 ? s.coverTransfer(c.transferStations) : s.coverNoTransfer, c.transferStations > 0),
          if (candidateCount > 0) row(Icons.help_outline_rounded, s.coverCandidates(candidateCount), false),
          if (version.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(s.dataVersion(version), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, required this.catalog, required this.locale, required this.onShow});
  final MetroLine line;
  final MetroCatalog catalog;
  final Locale locale;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = metroLineColor(line);
    final routes = catalog.routesOfLine(line.uid);

    // 起迄站：取站數最多的交路（全線），沒有交路資料時用路線的站序
    List<String> seq = line.stationUids;
    for (final r in routes) {
      if (r.stationUids.length > seq.length) seq = r.stationUids;
    }
    String name(String uid) => catalog.stationByUid[uid]?.name.resolve(locale) ?? uid;
    final ends = seq.length >= 2 ? '${name(seq.first)} ↔ ${name(seq.last)}' : '';

    // 交路名稱（方向 0 即可，方向 1 只是反向）
    final routeNames = <String>[];
    for (final r in routes) {
      if (r.direction != 0) continue;
      final n = r.name.resolve(locale);
      if (n.isNotEmpty && !routeNames.contains(n)) routeNames.add(n);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: MetroTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onShow,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(metroLineName(line, locale), style: text.titleSmall, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        MetroTag(text: line.id, color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [s.stationCountLabel(line.stationUids.length), if (ends.isNotEmpty) ends].join(' · '),
                      style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (routeNames.length > 1) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final n in routeNames) MetroTag(text: n, color: cs.onSurfaceVariant)],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(tooltip: s.showOnMap, icon: Icon(Icons.map_rounded, color: cs.primary), onPressed: onShow),
            ],
          ),
        ),
      ),
    );
  }
}
