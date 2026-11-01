import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:com.rsmn574.app/const/app_colors.dart';
import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/const/regular_const.dart';

import '../../../firebase/analytics_service.dart';
import '../../../widget/app_custom_bar.dart';
import '../data/models/metro_models.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import '../widgets/metro_geo_map.dart';
import '../widgets/metro_header.dart';
import '../widgets/metro_lines_tab.dart';
import '../widgets/metro_plan_tab.dart';
import '../widgets/metro_state_views.dart';
import '../widgets/metro_station_sheet.dart';
import '../widgets/metro_suggestions.dart';
import '../widgets/metro_tab_bar.dart';
import '../widgets/metro_theme.dart';
import '../widgets/metro_ui_utils.dart';

/// 捷運入口頁。類別名稱沿用 `Metro`，既有的路由與 Provider 註冊不需要修改。
/// 版型與 Bus 頁一致：AppCustomBar、系統下拉、搜尋區、圓角主卡片（Tab 列 + 內容）、搜尋建議蓋在內容上。
class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(AppAnalytics.logFeatureOpened('metro'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<MetroProvider>();
      if (p.catalog == null) p.load(); // 已載入過就不重複請求；要更新請按右上角重新整理
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  /// 點選搜尋建議：切到地圖、聚焦該站並開啟詳情。
  void _pickGroup(MetroStationGroup g) {
    _hideKeyboard();
    _search.clear();
    final p = context.read<MetroProvider>();
    p.setQuery('');
    _tabs.animateTo(0);
    p.requestFocusGroup(g.id);
    showMetroGroupSheet(context, g.id);
  }

  void _showRouteOnMap() {
    _tabs.animateTo(0);
    context.read<MetroProvider>().requestFitRoute();
  }

  void _showLineOnMap(String lineUid) {
    final p = context.read<MetroProvider>();
    p.selectLine(lineUid);
    _tabs.animateTo(0);
    p.requestFocusLine(lineUid);
  }

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final status = context.select<MetroProvider, MetroLoadStatus>((p) => p.status);

    return Scaffold(
      appBar: AppCustomBar(
        title: s.title,
        actions: [
          appBarActionButton(
            context: context,
            icon: Icons.refresh_rounded,
            tooltip: s.refresh,
            onPressed: () => context.read<MetroProvider>().load(),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _hideKeyboard,
        child: switch (status) {
          MetroLoadStatus.loading => const MetroLoadingView(),
          MetroLoadStatus.error => MetroErrorView(
              kind: context.read<MetroProvider>().error,
              onRetry: () => context.read<MetroProvider>().load(),
            ),
          MetroLoadStatus.ready => _buildReady(context),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context) {
    final s = MetroStrings.of(context);
    final stale = context.select<MetroProvider, bool>((p) => p.isStale);

    return Column(
      children: [
        if (stale)
          MetroNoticeBar(
            message: s.staleBanner,
            actionLabel: s.retry,
            onAction: () => context.read<MetroProvider>().load(),
            icon: Icons.cloud_off_rounded,
          ),
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: MetroSystemDropdown()),
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: MetroSearchSection(controller: _search)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Container(
                  decoration: MetroTheme.cardDecoration(context, radius: 16, shadow: 0.05),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _PageTabBar(controller: _tabs),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          // 地圖會用到平移手勢，因此不允許左右滑動換分頁（與 Bus 頁的 PageView 相同）
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            MetroGeoMap(onOpenPlan: () => _tabs.animateTo(1)),
                            MetroPlanTab(onShowOnMap: _showRouteOnMap),
                            MetroLinesTab(onShowLine: _showLineOnMap),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                MetroSuggestionsOverlay(onPick: _pickGroup),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Tab 列的第二行文字會顯示各分頁目前的狀態。
class _PageTabBar extends StatelessWidget {
  const _PageTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final locale = metroLocale(context);
    final system = context.select<MetroProvider, MetroSystem?>((p) => p.selectedSystem);
    final plan = context.select<MetroProvider, Object?>((p) => p.plan);
    final hasStart = context.select<MetroProvider, bool>((p) => p.startGroup != null);
    final hasEnd = context.select<MetroProvider, bool>((p) => p.endGroup != null);
    final p = context.read<MetroProvider>();

    final planSub = plan != null
        ? s.routeSummaryShort(p.plan!.rideStops, p.plan!.transferCount)
        : (hasStart || hasEnd ? s.pickRest : s.tabPlanEmpty);

    return MetroTabBar(
      controller: controller,
      tabs: [
        MetroTabSpec(icon: Icons.map_rounded, title: s.tabMap, subtitle: system?.name.resolve(locale)),
        MetroTabSpec(icon: Icons.alt_route_rounded, title: s.tabPlan, subtitle: planSub),
        MetroTabSpec(icon: Icons.timeline_rounded, title: s.tabLines, subtitle: system == null ? null : s.lineCountLabel(system.lineUids.length)),
      ],
    );
  }
}
