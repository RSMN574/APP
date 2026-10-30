import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../firebase/analytics_service.dart';
import '../l10n/metro_strings.dart';
import '../state/metro_provider.dart';
import '../widgets/metro_geo_map.dart';
import '../widgets/metro_route_panel.dart';
import '../widgets/metro_state_views.dart';
import '../widgets/metro_station_list.dart';
import '../widgets/metro_system_selector.dart';

/// 捷運入口頁。類別名稱沿用 `Metro`，既有的路由與導覽不需要修改。
class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro> {
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
  Widget build(BuildContext context) {
    final s = MetroStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(s.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary)),
          actions: [
            IconButton(
              tooltip: s.retry,
              icon: Icon(Icons.refresh_rounded, color: cs.primary),
              onPressed: () => context.read<MetroProvider>().load(),
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: s.tabMap), Tab(text: s.tabList)]),
        ),
        body: const SafeArea(child: _MetroBody()),
      ),
    );
  }
}

class _MetroBody extends StatelessWidget {
  const _MetroBody();

  @override
  Widget build(BuildContext context) {
    final status = context.select<MetroProvider, MetroLoadStatus>((p) => p.status);
    switch (status) {
      case MetroLoadStatus.loading:
        return const MetroLoadingView();
      case MetroLoadStatus.error:
        return MetroErrorView(
          kind: context.read<MetroProvider>().error,
          onRetry: () => context.read<MetroProvider>().load(),
        );
      case MetroLoadStatus.ready:
        return const _ReadyContent();
    }
  }
}

class _ReadyContent extends StatelessWidget {
  const _ReadyContent();

  @override
  Widget build(BuildContext context) {
    final stale = context.select<MetroProvider, bool>((p) => p.isStale);
    final s = MetroStrings.of(context);

    return Column(
      children: [
        if (stale)
          MetroNoticeBar(
            message: s.staleBanner,
            actionLabel: s.retry,
            onAction: () => context.read<MetroProvider>().load(),
            icon: Icons.cloud_off_rounded,
          ),
        const MetroSystemSelector(),
        const MetroSearchBar(),
        const MetroRoutePanel(),
        const Expanded(
          child: TabBarView(
            children: [
              MetroGeoMap(),
              MetroStationList(),
            ],
          ),
        ),
      ],
    );
  }
}
