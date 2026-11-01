import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_ui_utils.dart';

Future<void> showMetroGroupSheet(BuildContext context, String groupId) {
  final provider = context.read<MetroProvider>();
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cs.surface,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
    builder: (_) => ChangeNotifierProvider<MetroProvider>.value(
      value: provider,
      child: MetroGroupSheet(groupId: groupId),
    ),
  );
}

/// 實體站詳情。同一個實體站的多個站碼（如 R10 / BL12）合併顯示，
/// 設施與接駁資料依內容去重，避免同樣的資料出現兩次。
class MetroGroupSheet extends StatefulWidget {
  const MetroGroupSheet({super.key, required this.groupId});
  final String groupId;
  @override
  State<MetroGroupSheet> createState() => _MetroGroupSheetState();
}

class _MetroGroupSheetState extends State<MetroGroupSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<MetroProvider>();
      final g = p.catalog?.groupById[widget.groupId];
      if (g == null) return;
      for (final u in g.stationUids) {
        p.loadDetail(u);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MetroProvider>();
    final catalog = provider.catalog;
    final group = catalog?.groupById[widget.groupId];
    if (catalog == null || group == null) return const SizedBox.shrink();

    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final members = group.stationUids.map((u) => catalog.stationByUid[u]).whereType<MetroStation>().toList(growable: false);
    final systemName = catalog.systemByCode[group.operator]?.name.resolve(locale) ?? group.operator;
    final address = members.map((m) => m.address).firstWhere((a) => a != null, orElse: () => null);

    // 轉乘：排除「同一實體站內部」的連結（那就是本站自己）
    final memberSet = group.stationUids.toSet();
    final links = <StationLink>[];
    final candidates = <StationLink>[];
    for (final u in group.stationUids) {
      for (final l in catalog.linksOf(u)) {
        if (!memberSet.contains(l.other(u))) links.add(l);
      }
      candidates.addAll(catalog.candidatesOf(u));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Text(group.name.resolve(locale), style: text.titleLarge),
                      const SizedBox(height: 4),
                      Text(systemName, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 每個站碼一個標籤，顏色為該站所屬路線
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in members)
                  MetroTag(
                    text: '${m.code}  ${m.lineUids.isEmpty ? '' : metroLineName(catalog.lineByUid[m.lineUids.first], locale)}',
                    color: metroLineColor(m.lineUids.isEmpty ? null : catalog.lineByUid[m.lineUids.first]),
                  ),
              ],
            ),
            if (members.length > 1) ...[
              const SizedBox(height: 8),
              Text(s.mergedNote(group.codes), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
            if (address != null) ...[
              const SizedBox(height: 12),
              Text('${s.address}：$address', style: text.bodyMedium),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      provider.setStartGroup(group.id);
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
                      provider.setEndGroup(group.id);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.flag_rounded),
                    label: Text(s.setEnd),
                  ),
                ),
              ],
            ),

            // 行經路線與方向（StationOfRoute）
            _SectionTitle(s.directions),
            ..._directionRows(context, catalog, members, locale, s),

            // 轉乘
            _SectionTitle(s.transferSection),
            if (group.stationUids.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.interchangeLines(group.lineUids.map((u) => metroLineName(catalog.lineByUid[u], locale)).toList()),
                  style: text.bodyMedium,
                ),
              ),
            if (links.isEmpty && candidates.isEmpty && group.stationUids.length <= 1)
              Text(s.noTransferLinks, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            for (final l in links) _LinkTile(link: l, selfUids: memberSet, catalog: catalog, candidate: false),
            for (final l in candidates) _LinkTile(link: l, selfUids: memberSet, catalog: catalog, candidate: true),

            // 設施與接駁
            _SectionTitle(s.facilities),
            Selector<MetroProvider, List<MetroDetailState>>(
              selector: (_, p) => group.stationUids.map(p.detailOf).toList(growable: false),
              shouldRebuild: (a, b) {
                if (a.length != b.length) return true;
                for (var i = 0; i < a.length; i++) {
                  if (!identical(a[i], b[i])) return true;
                }
                return false;
              },
              builder: (context, states, _) {
                if (states.any((x) => x.state == MetroAsyncState.idle || x.state == MetroAsyncState.loading)) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                if (states.every((x) => x.state == MetroAsyncState.error)) {
                  return SizedBox(
                    height: 160,
                    child: MetroErrorView(
                      kind: states.first.error,
                      onRetry: () {
                        for (final u in group.stationUids) {
                          provider.loadDetail(u, retry: true);
                        }
                      },
                    ),
                  );
                }
                final ready = <MapEntry<MetroStation, StationDetail>>[];
                for (var i = 0; i < states.length; i++) {
                  final d = states[i].detail;
                  final st = catalog.stationByUid[group.stationUids[i]];
                  if (d != null && st != null) ready.add(MapEntry(st, d));
                }
                return _DetailBody(entries: ready);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _directionRows(BuildContext context, MetroCatalog catalog, List<MetroStation> members, Locale locale, MetroStrings s) {
    final text = Theme.of(context).textTheme;
    final rows = <Widget>[];
    for (final m in members) {
      for (final lineUid in m.lineUids) {
        final terminals = <String>[];
        for (final r in catalog.routesOfLine(lineUid)) {
          final i = r.stationUids.indexOf(m.uid);
          if (i < 0 || i == r.stationUids.length - 1) continue; // 不在此交路，或本站就是終點
          final t = catalog.stationByUid[r.terminalUid]?.name.resolve(locale) ?? '';
          if (t.isNotEmpty && !terminals.contains(t)) terminals.add(t);
        }
        if (terminals.isEmpty) continue;
        final line = catalog.lineByUid[lineUid];
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MetroTag(text: metroLineName(line, locale), color: metroLineColor(line)),
              const SizedBox(width: 10),
              Expanded(child: Text(terminals.map(s.towards).join('  ·  '), style: text.bodyMedium)),
            ],
          ),
        ));
      }
    }
    if (rows.isEmpty) {
      rows.add(Text(s.noneListed, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)));
    }
    return rows;
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
  const _LinkTile({required this.link, required this.selfUids, required this.catalog, required this.candidate});
  final StationLink link;
  final Set<String> selfUids;
  final MetroCatalog catalog;
  final bool candidate;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final selfUid = selfUids.contains(link.a) ? link.a : link.b;
    final other = catalog.stationByUid[link.other(selfUid)];
    if (other == null) return const SizedBox.shrink();
    final sys = catalog.systemByCode[other.operator]?.name.resolve(locale) ?? other.operator;
    final notes = <String>[
      if (candidate) s.candidateLink else link.isCrossSystem ? s.crossSystemTransfer : s.sameSystemTransfer,
      if (!candidate) (link.isDerived ? s.derivedLink : s.sqlLink),
      if (link.distanceM != null) s.distanceM(link.distanceM!),
      if (link.isOnSite == true) s.onSite,
      if (link.floor != null) s.floor(link.floor!),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: candidate ? cs.surfaceContainerLowest : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: candidate ? BorderSide(color: cs.outlineVariant) : BorderSide.none,
      ),
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
  const _DetailBody({required this.entries});
  final List<MapEntry<MetroStation, StationDetail>> entries;

  static String _sig(StationFacilities f) {
    String e(List<FacilityEntry> l) => l.map((x) => '${x.floor}|${x.description}').join(';');
    return [e(f.elevators), e(f.infoSpots), e(f.drinkingFountains), e(f.toilets), f.maps.map((m) => m.url).join(';')].join('#');
  }

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = metroLocale(context);
    final text = Theme.of(context).textTheme;

    // 設施：內容相同的站碼只顯示一次；不同才分開列出並標示站碼
    final facilitySets = <String, _FacSet>{};
    for (final e in entries) {
      final f = e.value.facilities;
      if (f == null) continue;
      final set = facilitySets.putIfAbsent(_sig(f), () => _FacSet(f));
      set.codes.add(e.key.code);
    }

    // 接駁：合併所有站碼並以內容去重
    final access = <String, List<AccessEntry>>{};
    final seen = <String>{};
    final interiorMaps = <MapLink>[];
    final seenMaps = <String>{};
    for (final e in entries) {
      final a = e.value.access;
      if (a == null) continue;
      for (final m in a.interiorMaps) {
        if (seenMaps.add(m.url)) interiorMaps.add(m);
      }
      a.byMode.forEach((mode, list) {
        for (final x in list) {
          final key = '$mode|${x.operatorCode}|${x.stationName.zh}|${x.description}|${x.floor}';
          if (seen.add(key)) access.putIfAbsent(mode, () => []).add(x);
        }
      });
    }
    final modeEntries = access.entries.where((e) => e.value.isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (facilitySets.isEmpty)
          Text(s.noFacilityData, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
        else
          for (final set in facilitySets.values) ...[
            if (facilitySets.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(set.codes.join(' / '), style: text.labelLarge?.copyWith(color: cs.primary)),
              ),
            _FacilityGroup(label: s.elevators, entries: set.value.elevators),
            _FacilityGroup(label: s.infoSpots, entries: set.value.infoSpots),
            _FacilityGroup(label: s.drinkingFountains, entries: set.value.drinkingFountains),
            _FacilityGroup(label: s.toilets, entries: set.value.toilets),
            if (set.value.maps.isNotEmpty) _MapLinks(label: s.stationMaps, maps: set.value.maps),
          ],
        if (interiorMaps.isNotEmpty) _MapLinks(label: s.interiorMaps, maps: interiorMaps),
        if (modeEntries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 4),
            child: Text(s.otherAccess, style: text.titleMedium),
          ),
          for (final e in modeEntries)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text('${s.modeLabel(e.key)} (${e.value.length})', style: text.titleSmall),
                children: [
                  for (final x in e.value)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          [
                            x.operatorName.resolve(locale),
                            x.stationName.resolve(locale),
                            if (x.floor != null) s.floor(x.floor!),
                            if (x.description != null && !x.description!.startsWith('http')) x.description!,
                          ].where((t) => t.isNotEmpty).join(' · '),
                          style: text.bodySmall,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _FacSet {
  _FacSet(this.value);
  final StationFacilities value;
  final List<String> codes = [];
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
          else
            for (final e in entries)
              Text([if (e.floor != null) e.floor!, if (e.description != null) e.description!].join('  '), style: text.bodySmall),
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
