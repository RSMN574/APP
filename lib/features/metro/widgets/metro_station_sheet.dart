import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_ui_utils.dart';

Future<void> showMetroStationSheet(BuildContext context, String stationUid) {
  final provider = context.read<MetroProvider>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
    builder: (_) => ChangeNotifierProvider<MetroProvider>.value(
      value: provider,
      child: MetroStationSheet(stationUid: stationUid),
    ),
  );
}

class MetroStationSheet extends StatefulWidget {
  const MetroStationSheet({super.key, required this.stationUid});
  final String stationUid;
  @override
  State<MetroStationSheet> createState() => _MetroStationSheetState();
}

class _MetroStationSheetState extends State<MetroStationSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MetroProvider>().loadDetail(widget.stationUid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MetroProvider>();
    final catalog = provider.catalog;
    final station = catalog?.stationByUid[widget.stationUid];
    if (catalog == null || station == null) return const SizedBox.shrink();

    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final links = catalog.linksOf(station.uid);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標頭
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.subway_rounded, color: cs.onPrimary, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name.resolve(locale), style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${s.stationCode} ${station.code} · ${catalog.systemByCode[station.operator]?.name.resolve(locale) ?? station.operator}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in station.lineUids)
                  MetroTag(
                    text: _lineLabel(catalog.lineByUid[u], locale),
                    color: metroLineColor(catalog.lineByUid[u]),
                  ),
              ],
            ),
            if (station.address != null) ...[
              const SizedBox(height: 12),
              Text('${s.address}：${station.address}', style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      provider.setStart(station.uid);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(s.setStart),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.setEnd(station.uid);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.flag_rounded),
                    label: Text(s.setEnd),
                  ),
                ),
              ],
            ),

            // 轉乘
            _SectionTitle(s.transferSection),
            if (links.isEmpty)
              Text(s.noTransferLinks, style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
            else
              for (final l in links) _LinkTile(link: l, selfUid: station.uid, catalog: catalog),

            // 設施與接駁（來自詳情 API）
            _SectionTitle(s.facilities),
            Selector<MetroProvider, MetroDetailState>(
              selector: (_, p) => p.detailOf(widget.stationUid),
              builder: (context, st, _) {
                switch (st.state) {
                  case MetroAsyncState.idle:
                  case MetroAsyncState.loading:
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                  case MetroAsyncState.error:
                    return SizedBox(
                      height: 160,
                      child: MetroErrorView(kind: st.error, onRetry: () => provider.loadDetail(widget.stationUid, retry: true)),
                    );
                  case MetroAsyncState.ready:
                    return _DetailBody(detail: st.detail!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _lineLabel(MetroLine? l, Locale locale) {
    if (l == null) return '';
    final n = l.name.resolve(locale);
    return n.isEmpty ? l.id : n;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link, required this.selfUid, required this.catalog});
  final StationLink link;
  final String selfUid;
  final MetroCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final other = catalog.stationByUid[link.other(selfUid)];
    if (other == null) return const SizedBox.shrink();
    final sys = catalog.systemByCode[other.operator]?.name.resolve(locale) ?? other.operator;
    final notes = <String>[
      link.isCrossSystem ? s.crossSystemTransfer : s.sameSystemTransfer,
      link.isDerived ? s.derivedLink : s.sqlLink,
      if (link.isOnSite == true) s.onSite,
      if (link.floor != null) s.floor(link.floor!),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${other.name.resolve(locale)}  ${other.code} · $sys', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(notes.join(' · '), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            if (link.description != null) ...[
              const SizedBox(height: 6),
              Text(link.description!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});
  final StationDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final f = detail.facilities;
    final a = detail.access;
    final locale = metroLocale(context);
    final modeEntries = (a?.byMode.entries ?? const <MapEntry<String, List<AccessEntry>>>[])
        .where((e) => e.value.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (f == null)
          Text(s.noFacilityData, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
        else ...[
          _FacilityGroup(label: s.elevators, entries: f.elevators),
          _FacilityGroup(label: s.infoSpots, entries: f.infoSpots),
          _FacilityGroup(label: s.drinkingFountains, entries: f.drinkingFountains),
          _FacilityGroup(label: s.toilets, entries: f.toilets),
          if (f.maps.isNotEmpty) _MapLinks(label: s.stationMaps, maps: f.maps),
        ],
        if (a != null && a.interiorMaps.isNotEmpty) _MapLinks(label: s.stationMaps, maps: a.interiorMaps),
        if (modeEntries.isNotEmpty) ...[
          _SectionTitle(s.otherAccess),
          for (final e in modeEntries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text('${s.modeLabel(e.key)} (${e.value.length})', style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final x in e.value.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  [
                    x.operatorName.resolve(locale),
                    x.stationName.resolve(locale),
                    if (x.floor != null) s.floor(x.floor!),
                  ].where((t) => t.isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (e.value.length > 3)
              Text(s.more(e.value.length - 3), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ],
    );
  }
}

class _FacilityGroup extends StatelessWidget {
  const _FacilityGroup({required this.label, required this.entries});
  final String label;
  final List<FacilityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entries.isEmpty ? label : '$label (${entries.length})', style: text.titleSmall),
          const SizedBox(height: 4),
          if (entries.isEmpty)
            Text(s.noneListed, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          else ...[
            for (final e in entries.take(4))
              Text(
                [if (e.floor != null) e.floor!, if (e.description != null) e.description!].join('  '),
                style: text.bodySmall,
              ),
            if (entries.length > 4) Text(s.more(entries.length - 4), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _MapLinks extends StatelessWidget {
  const _MapLinks({required this.label, required this.maps});
  final String label;
  final List<MapLink> maps;

  @override
  Widget build(BuildContext context) {
    final locale = metroLocale(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          for (final m in maps)
            TextButton.icon(
              style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
              onPressed: () => launchUrl(Uri.parse(m.url), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(m.name.resolve(locale).isEmpty ? m.url : m.name.resolve(locale), overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
