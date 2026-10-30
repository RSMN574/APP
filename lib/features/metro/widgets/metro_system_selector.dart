import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_ui_utils.dart';

/// 營運系統選擇。只列出 SQL 實際有車站資料的系統，並以文字標示資料涵蓋範圍，
/// 沒有設施或轉乘資料的系統不會被顯示成「完整支援」。
class MetroSystemSelector extends StatelessWidget {
  const MetroSystemSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final systems = context.select<MetroProvider, List<MetroSystem>>((p) => p.catalog?.systems ?? const []);
    final selectedCode = context.select<MetroProvider, String?>((p) => p.selectedSystemCode);
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;
    MetroSystem? selected;
    for (final sys in systems) {
      if (sys.code == selectedCode) selected = sys;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: systems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final sys = systems[i];
              return ChoiceChip(
                label: Text(sys.name.resolve(locale)),
                selected: sys.code == selectedCode,
                onSelected: (_) => context.read<MetroProvider>().selectSystem(sys.code),
              );
            },
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              '${s.stationCountLabel(selected.stationCount)} · ${s.coverageLine(total: selected.stationCount, facility: selected.coverage.facilityStations, transfer: selected.coverage.transferStations, shape: selected.coverage.shape)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// 搜尋框 + 路線篩選。以系統代碼作為 key，切換系統時搜尋框會跟著重置。
class MetroSearchBar extends StatelessWidget {
  const MetroSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final code = context.select<MetroProvider, String?>((p) => p.selectedSystemCode);
    final selectedLine = context.select<MetroProvider, String?>((p) => p.selectedLineUid);
    final lines = context.read<MetroProvider>().systemLines;
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          _SearchField(key: ValueKey(code), hint: s.searchHint, clearLabel: s.clear),
          if (lines.length > 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                    child: ChoiceChip(
                      label: Text(s.allLines),
                      selected: selectedLine == null,
                      onSelected: (_) => context.read<MetroProvider>().selectLine(null),
                    ),
                  ),
                  for (final l in lines)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                      child: ChoiceChip(
                        avatar: CircleAvatar(radius: 6, backgroundColor: metroLineColor(l)),
                        label: Text(l.name.resolve(locale).isEmpty ? l.id : l.name.resolve(locale)),
                        selected: selectedLine == l.uid,
                        onSelected: (_) => context.read<MetroProvider>().selectLine(selectedLine == l.uid ? null : l.uid),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({super.key, required this.hint, required this.clearLabel});
  final String hint;
  final String clearLabel;
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: context.read<MetroProvider>().query);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TextField(
        controller: _c,
        onChanged: (v) {
          context.read<MetroProvider>().setQuery(v);
          setState(() {});
        },
        style: Theme.of(context).textTheme.bodyLarge,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
          suffixIcon: _c.text.isEmpty
              ? null
              : IconButton(
                  tooltip: widget.clearLabel,
                  icon: Icon(Icons.clear, color: cs.onSurfaceVariant, size: 18),
                  onPressed: () {
                    _c.clear();
                    context.read<MetroProvider>().setQuery('');
                    setState(() {});
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
