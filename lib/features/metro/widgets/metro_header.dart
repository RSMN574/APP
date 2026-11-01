import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import 'metro_theme.dart';
import 'metro_ui_utils.dart';

/// 營運系統下拉（Bus 頁城市下拉的樣式）。只列出 SQL 實際有車站資料的系統；
/// 下方一行文字說明該系統的資料涵蓋，避免把只有部分資料的系統呈現成「完整支援」。
class MetroSystemDropdown extends StatelessWidget {
  const MetroSystemDropdown({super.key});

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: MetroTheme.cardDecoration(context),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: MetroTheme.card(context), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.subway_rounded, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Text(
                s.system,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MetroTheme.onSurface(context)),
              ),
              const Spacer(),
              Container(
                width: 170,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: MetroTheme.card(context), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: MetroTheme.card(context),
                    borderRadius: BorderRadius.circular(16),
                    isExpanded: true,
                    value: systems.any((x) => x.code == selectedCode) ? selectedCode : null,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: cs.primary),
                    selectedItemBuilder: (_) => [
                      for (final sys in systems)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            sys.name.resolve(locale),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                          ),
                        ),
                    ],
                    items: [
                      for (final sys in systems)
                        DropdownMenuItem<String>(
                          value: sys.code,
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: sys.code == selectedCode ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sys.name.resolve(locale),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: sys.code == selectedCode ? FontWeight.w600 : FontWeight.w500,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) context.read<MetroProvider>().selectSystem(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(
              '${s.stationCountLabel(selected.stationCount)} · ${s.coverageLine(total: selected.stationCount, facility: selected.coverage.facilityStations, transfer: selected.coverage.transferStations, shape: selected.coverage.shape)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// 搜尋區（Bus 頁搜尋區的樣式）：左側是路線篩選下拉，右側是搜尋欄。
/// 輸入時下方會出現建議清單，並依實體站去重。
class MetroSearchSection extends StatelessWidget {
  const MetroSearchSection({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final code = context.select<MetroProvider, String?>((p) => p.selectedSystemCode);
    final selectedLine = context.select<MetroProvider, String?>((p) => p.selectedLineUid);
    final lines = context.read<MetroProvider>().systemLines;
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey(code),
      padding: const EdgeInsets.all(4),
      decoration: MetroTheme.cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 130,
            margin: const EdgeInsets.only(left: 4, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: MetroTheme.card(context), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: lines.any((l) => l.uid == selectedLine) ? selectedLine : null,
                isExpanded: true,
                dropdownColor: MetroTheme.card(context),
                borderRadius: BorderRadius.circular(16),
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: cs.primary),
                selectedItemBuilder: (_) => [
                  _lineRow(context, null, s.allLines, true),
                  for (final l in lines) _lineRow(context, l, metroLineName(l, locale), true),
                ],
                items: [
                  DropdownMenuItem<String?>(value: null, child: _lineRow(context, null, s.allLines, false)),
                  for (final l in lines)
                    DropdownMenuItem<String?>(value: l.uid, child: _lineRow(context, l, metroLineName(l, locale), false)),
                ],
                onChanged: (v) => context.read<MetroProvider>().selectLine(v),
              ),
            ),
          ),
          Container(width: 1, height: 32, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 4, right: 4),
              decoration: BoxDecoration(color: MetroTheme.card(context), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: controller,
                onChanged: context.read<MetroProvider>().setQuery,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.search_rounded, color: cs.primary, size: 20),
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        tooltip: s.clear,
                        icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
                        onPressed: () {
                          controller.clear();
                          context.read<MetroProvider>().setQuery('');
                        },
                      );
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(BuildContext context, MetroLine? line, String label, bool compact) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: line == null ? cs.onSurface.withValues(alpha: 0.35) : metroLineColor(line),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: compact ? 14 : 15, fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}
