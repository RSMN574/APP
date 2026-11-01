import 'package:flutter/material.dart';

import 'metro_theme.dart';

class MetroTabSpec {
  const MetroTabSpec({required this.icon, required this.title, this.subtitle});
  final IconData icon;
  final String title;

  /// 第二行小字（目前系統、已選起訖、路線數等），讓分頁本身就帶有狀態。
  final String? subtitle;
}

/// Tab 列：沿用 Bus 時刻頁 `_buildTabButton` 的樣式
/// （64 高、選中時 primaryContainer、icon 小方塊、兩行文字），以 Expanded 平均分配寬度。
class MetroTabBar extends StatelessWidget {
  const MetroTabBar({super.key, required this.controller, required this.tabs});
  final TabController controller;
  final List<MetroTabSpec> tabs;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        // 手勢滑動時 animation.value 是小數，取最接近的分頁，避免選中狀態抖動
        final current = (controller.animation?.value ?? controller.index.toDouble()).round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: MetroTheme.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _TabButton(
                    spec: tabs[i],
                    selected: current == i,
                    onTap: () => controller.animateTo(i),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.spec, required this.selected, required this.onTap});
  final MetroTabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(spec.icon, size: 15, color: cs.primary),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: selected ? cs.primary : cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (spec.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    spec.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, height: 1.0, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
