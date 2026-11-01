import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../domain/metro_route_planner.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_suggestions.dart';
import 'metro_theme.dart';
import 'metro_ui_utils.dart';

/// 路線規劃分頁：選起訖點、查看每一段搭乘（含方向與中途站）與轉乘說明。
class MetroPlanTab extends StatelessWidget {
  const MetroPlanTab({super.key, required this.onShowOnMap});
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final start = context.select<MetroProvider, MetroStationGroup?>((p) => p.startGroup);
    final end = context.select<MetroProvider, MetroStationGroup?>((p) => p.endGroup);
    final plan = context.select<MetroProvider, RoutePlan?>((p) => p.plan);
    final noRoute = context.select<MetroProvider, bool>((p) => p.noRoute);
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final provider = context.read<MetroProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _EndpointCard(
          label: s.startPoint,
          placeholder: s.pickStart,
          name: start?.name.resolve(locale),
          dotColor: cs.tertiary,
          onTap: () => showMetroStationPicker(context, forStart: true),
        ),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            tooltip: s.swap,
            onPressed: (start == null && end == null) ? null : provider.swapEndpoints,
            icon: Icon(Icons.swap_vert_rounded, color: cs.primary),
          ),
        ),
        _EndpointCard(
          label: s.endPoint,
          placeholder: s.pickEnd,
          name: end?.name.resolve(locale),
          dotColor: cs.error,
          onTap: () => showMetroStationPicker(context, forStart: false),
        ),
        if (start != null || end != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: provider.clearRoute,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(s.clear),
            ),
          ),
        const SizedBox(height: 8),
        if (noRoute)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: MetroEmptyView(message: s.noRoute, icon: Icons.alt_route_rounded),
          )
        else if (plan != null)
          _PlanResult(plan: plan, onShowOnMap: onShowOnMap)
        else
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: MetroEmptyView(message: s.planHint, icon: Icons.alt_route_rounded),
          ),
      ],
    );
  }
}

class _EndpointCard extends StatelessWidget {
  const _EndpointCard({required this.label, required this.placeholder, required this.name, required this.dotColor, required this.onTap});
  final String label;
  final String placeholder;
  final String? name;
  final Color dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: MetroTheme.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: dotColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      name ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (name != null ? text.titleMedium : text.bodyLarge)?.copyWith(
                        color: name != null ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.search_rounded, color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanResult extends StatelessWidget {
  const _PlanResult({required this.plan, required this.onShowOnMap});
  final RoutePlan plan;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final catalog = context.read<MetroProvider>().catalog;
    if (catalog == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: MetroTheme.cardDecoration(context, radius: 16, shadow: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.routeSummary(plan.rideStops, plan.transferCount), style: text.titleMedium),
              const SizedBox(height: 4),
              Text(s.noFareNote, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              if (plan.usesCrossSystem) ...[
                const SizedBox(height: 8),
                MetroTag(text: s.crossSystemNote, color: cs.tertiary),
              ],
              if (plan.usesDerivedLink) ...[
                const SizedBox(height: 6),
                Text(s.derivedNote, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              const SizedBox(height: 12),
              FilledButton.tonalIcon(onPressed: onShowOnMap, icon: const Icon(Icons.map_rounded), label: Text(s.showOnMap)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final step in plan.steps)
          if (step is PlanLeg) _LegCard(leg: step, catalog: catalog) else if (step is PlanTransfer) _TransferRow(transfer: step, catalog: catalog),
      ],
    );
  }
}

String _stationName(MetroCatalog c, String uid, Locale locale) =>
    c.groupOfStation(uid)?.name.resolve(locale) ?? c.stationByUid[uid]?.name.resolve(locale) ?? uid;

class _LegCard extends StatelessWidget {
  const _LegCard({required this.leg, required this.catalog});
  final PlanLeg leg;
  final MetroCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final line = catalog.lineByUid[leg.lineUid];
    final color = metroLineColor(line);
    final terminal = leg.terminalUid == null ? null : _stationName(catalog, leg.terminalUid!, locale);
    final mid = leg.stationUids.length > 2 ? leg.stationUids.sublist(1, leg.stationUids.length - 1) : const <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: MetroTheme.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MetroTag(text: metroLineName(line, locale), color: color),
              const SizedBox(width: 8),
              if (terminal != null)
                Expanded(child: Text(s.towards(terminal), maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium))
              else
                const Spacer(),
              Text(s.legLabel(leg.stops), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_stationName(catalog, leg.fromUid, locale)}  →  ${_stationName(catalog, leg.toUid, locale)}',
            style: text.titleSmall,
          ),
          if (mid.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(s.intermediateStops(mid.length), style: text.bodySmall?.copyWith(color: cs.primary)),
                children: [
                  for (final u in mid)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Text('${_stationName(catalog, u, locale)}  ${catalog.stationByUid[u]?.code ?? ''}', style: text.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transfer, required this.catalog});
  final PlanTransfer transfer;
  final MetroCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final from = _stationName(catalog, transfer.fromUid, locale);
    final to = _stationName(catalog, transfer.toUid, locale);
    final sameStation = catalog.groupOfStation(transfer.fromUid)?.id == catalog.groupOfStation(transfer.toUid)?.id;
    final desc = transfer.links.map((l) => l.description).whereType<String>().toList(growable: false);

    final title = transfer.isCrossSystem
        ? '${s.crossSystemTransfer}：$from → $to'
        : (sameStation ? s.transferAt(from) : '${s.sameSystemTransfer}：$from → $to');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.transfer_within_a_station_rounded, size: 20, color: transfer.isCrossSystem ? cs.tertiary : cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                for (final d in desc) Text(d, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                if (transfer.isDerived) Text(s.derivedLink, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 起訖點選擇器
// ---------------------------------------------------------------------------

Future<void> showMetroStationPicker(BuildContext context, {required bool forStart}) {
  final provider = context.read<MetroProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => ChangeNotifierProvider<MetroProvider>.value(
      value: provider,
      child: _PickerSheet(forStart: forStart),
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.forStart});
  final bool forStart;
  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _pick(MetroStationGroup g) {
    final p = context.read<MetroProvider>();
    if (widget.forStart) {
      p.setStartGroup(g.id);
    } else {
      p.setEndGroup(g.id);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<MetroProvider>();
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final q = _c.text.trim();
    // 起訖點可跨系統搜尋（例如從淡水到機捷臺北站）
    final results = q.isEmpty ? p.interchangeGroups(p.selectedSystemCode) : p.searchGroups(q, limit: 50);
    final height = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                decoration: BoxDecoration(color: MetroTheme.card(context), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _c,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: widget.forStart ? s.pickStart : s.pickEnd,
                    prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            if (q.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.quickPickInterchange, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
              ),
            Expanded(
              child: results.isEmpty
                  ? MetroEmptyView(message: s.emptyStations)
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) => MetroGroupTile(group: results[i], showSystem: true, onTap: () => _pick(results[i])),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
