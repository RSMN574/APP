import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../domain/metro_route_planner.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_ui_utils.dart';

/// 起訖點與路徑摘要。不顯示票價與時間（資料中沒有），只顯示站數、轉乘次數與各路線區段。
class MetroRoutePanel extends StatelessWidget {
  const MetroRoutePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final start = context.select<MetroProvider, MetroStation?>((p) => p.startStation);
    final end = context.select<MetroProvider, MetroStation?>((p) => p.endStation);
    final plan = context.select<MetroProvider, RoutePlan?>((p) => p.plan);
    final noRoute = context.select<MetroProvider, bool>((p) => p.noRoute);
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final catalog = context.read<MetroProvider>().catalog;

    Widget endpoint(MetroStation? st, String placeholder, Color dot, {bool alignEnd = false}) {
      return Expanded(
        child: Row(
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) CircleAvatar(radius: 5, backgroundColor: dot),
            if (!alignEnd) const SizedBox(width: 8),
            Flexible(
              child: Text(
                st == null ? placeholder : st.name.resolve(locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: (st != null ? text.bodyLarge : text.bodyMedium)?.copyWith(
                  color: st != null ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ),
            if (alignEnd) const SizedBox(width: 8),
            if (alignEnd) CircleAvatar(radius: 5, backgroundColor: dot),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              endpoint(start, s.pickStart, cs.tertiary),
              IconButton(
                tooltip: s.swap,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.swap_horiz_rounded, color: cs.onSurfaceVariant),
                onPressed: (start == null && end == null) ? null : context.read<MetroProvider>().swapEndpoints,
              ),
              endpoint(end, s.pickEnd, cs.error, alignEnd: true),
              if (start != null || end != null)
                IconButton(
                  tooltip: s.clear,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  onPressed: context.read<MetroProvider>().clearRoute,
                ),
            ],
          ),
          if (noRoute)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(s.noRoute, style: text.bodySmall?.copyWith(color: cs.error)),
            ),
          if (plan != null && catalog != null) ...[
            const Divider(height: 16),
            Text(s.routeSummary(plan.rideStops, plan.transferCount), style: text.titleSmall),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final leg in plan.legs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: MetroTag(
                        text: '${_legName(catalog.lineByUid[leg.lineUid], locale)} ${catalog.stationByUid[leg.fromUid]?.name.resolve(locale) ?? ''}→${catalog.stationByUid[leg.toUid]?.name.resolve(locale) ?? ''} · ${s.legLabel(leg.stops)}',
                        color: metroLineColor(catalog.lineByUid[leg.lineUid]),
                      ),
                    ),
                ],
              ),
            ),
            if (plan.usesCrossSystem)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(s.crossSystemNote, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            if (plan.usesDerivedLink)
              Text(s.derivedNote, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text(s.noFareNote, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  static String _legName(MetroLine? l, Locale locale) {
    if (l == null) return '';
    final n = l.name.resolve(locale);
    return n.isEmpty ? l.id : n;
  }
}
