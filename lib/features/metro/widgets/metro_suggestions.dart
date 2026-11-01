import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_theme.dart';
import 'metro_ui_utils.dart';

/// 實體站的清單項目（搜尋建議與起訖點選擇器共用）。
/// 轉乘站只有一列，站碼以「R10 / BL12」並列，路線以色點表示。
class MetroGroupTile extends StatelessWidget {
  const MetroGroupTile({super.key, required this.group, required this.onTap, this.highlight = false, this.showSystem = false});
  final MetroStationGroup group;
  final VoidCallback onTap;
  final bool highlight;
  final bool showSystem;

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<MetroProvider>().catalog;
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    final lines = group.lineUids.map((u) => catalog?.lineByUid[u]).toList(growable: false);
    final sys = catalog?.systemByCode[group.operator]?.name.resolve(locale) ?? group.operator;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlight ? cs.primary.withValues(alpha: 0.12) : MetroTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.place, size: 18, color: cs.primary),
        ),
        title: Text(
          group.name.resolve(locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
        subtitle: Row(
          children: [
            MetroLineDots(lines: lines),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                showSystem ? '${group.codes.join(' / ')} · $sys' : group.codes.join(' / '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        trailing: group.stationUids.length > 1 ? MetroTag(text: s.transferStation, color: cs.tertiary) : null,
      ),
    );
  }
}

/// 搜尋建議（Bus 頁 `_buildSuggestionsOverlay` 的樣式）：蓋在內容區上方，每個實體站只出現一次。
class MetroSuggestionsOverlay extends StatelessWidget {
  const MetroSuggestionsOverlay({super.key, required this.onPick});
  final ValueChanged<MetroStationGroup> onPick;

  @override
  Widget build(BuildContext context) {
    final query = context.select<MetroProvider, String>((p) => p.query);
    final results = context.select<MetroProvider, List<MetroStationGroup>>((p) => p.searchResults);
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    if (query.trim().isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: MetroTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: results.isEmpty
            ? Center(child: Text(s.emptyStations, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))))
            : ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: results.length,
                itemBuilder: (context, i) => MetroGroupTile(group: results[i], highlight: i == 0, onTap: () => onPick(results[i])),
              ),
      ),
    );
  }
}
