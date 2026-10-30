import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_state_views.dart';
import 'metro_station_sheet.dart';
import 'metro_ui_utils.dart';

/// 依路線分組的車站清單。使用 ListView.builder 延遲建構，300 站規模不需要額外虛擬化。
class MetroStationList extends StatelessWidget {
  const MetroStationList({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = context.select<MetroProvider, List<MetroLineSection>>((p) => p.sections);
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final catalog = context.read<MetroProvider>().catalog;
    final cs = Theme.of(context).colorScheme;

    if (sections.isEmpty) {
      final hasQuery = context.read<MetroProvider>().query.isNotEmpty;
      return MetroEmptyView(message: hasQuery ? s.emptyStations : s.emptySystem);
    }

    // 攤平成「標題 / 車站」兩種項目
    final items = <Object>[];
    for (final sec in sections) {
      items.add(sec.line);
      items.addAll(sec.stations.map((st) => _Row(sec.line, st)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        if (it is MetroLine) {
          final name = it.name.resolve(locale);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: metroLineColor(it), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name.isEmpty ? it.id : '$name (${it.id})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          );
        }
        final row = it as _Row;
        final st = row.station;
        final isInterchange = st.lineUids.length > 1 || (catalog?.linksOf(st.uid).isNotEmpty ?? false);
        final name = st.name.resolve(locale);
        return ListTile(
          key: ValueKey('${row.line.uid}/${st.uid}'),
          leading: Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(color: metroLineColor(row.line), borderRadius: BorderRadius.circular(2)),
          ),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${s.stationCode} ${st.code} · ${catalog?.systemByCode[st.operator]?.name.resolve(locale) ?? st.operator}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          trailing: isInterchange ? MetroTag(text: s.transferStation, color: cs.tertiary) : null,
          onTap: () => showMetroStationSheet(context, st.uid),
        );
      },
    );
  }
}

class _Row {
  const _Row(this.line, this.station);
  final MetroLine line;
  final MetroStation station;
}
