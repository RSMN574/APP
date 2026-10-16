import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../const/regular_const.dart';
import '../data/metro_repository.dart';
import '../state/metro_provider.dart';
import '../widgets/metro_map_painter.dart';

class Metro extends StatefulWidget {
  const Metro({super.key});

  @override
  State<Metro> createState() => _MetroState();
}

class _MetroState extends State<Metro> with SingleTickerProviderStateMixin {
  late final MetroProvider _metroState;

  final TransformationController _transformationController =
      TransformationController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _glowAnimationController;

  CityMetroData get _currentCity => _metroState.currentCity;
  Station? get _startStation => _metroState.startStation;
  Station? get _endStation => _metroState.endStation;
  RouteResult? get _routeResult => _metroState.routeResult;
  List<Station> get _filteredStations => _metroState.filteredStations;

  Rect get _stationBounds {
    if (_currentCity.stations.isEmpty) {
      return Rect.zero;
    }
    final positions = _currentCity.stations.map((station) => station.position);
    final minX = positions.map((position) => position.dx).reduce(min);
    final maxX = positions.map((position) => position.dx).reduce(max);
    final minY = positions.map((position) => position.dy).reduce(min);
    final maxY = positions.map((position) => position.dy).reduce(max);
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Offset get _mapOrigin => Offset(
        _stationBounds.left - 56,
        _stationBounds.top - 56,
      );

  Offset _mapPosition(Offset position) => position - _mapOrigin;

  Size _mapSize(Size viewportSize) {
    const mapPadding = 112.0;
    final bounds = _stationBounds;
    return Size(
      max(viewportSize.width, bounds.width + mapPadding),
      max(viewportSize.height, bounds.height + mapPadding),
    );
  }

  @override
  void initState() {
    super.initState();
    _metroState = context.read<MetroProvider>()
      ..addListener(_onMetroStateChanged);

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _metroState.removeListener(_onMetroStateChanged);
    _transformationController.dispose();
    _searchController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _onMetroStateChanged() {
    if (mounted) setState(() {});
  }

  void _changeCity(CityMetroData city) {
    _metroState.changeCity(city);
    _searchController.clear();
    _resetZoom();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _filterStations(String query) {
    _metroState.filterStations(query);
  }

  void _onStationTapped(Station station) {
    _metroState.selectStation(station);
    _showStationDialog(station);
  }

  // 規範需求：對話框選擇與卡片 modal
  void _showStationDialog(Station station) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 圖標容器 (寬高 48px，漸變背景，圓角 14px，白色圖標)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, blue],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.subway_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '車站代碼: ${station.id}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (station.isTransfer)
                      _buildTag('轉乘站', colorScheme.tertiary),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: station.lineIds.map((lId) {
                    final line =
                        _currentCity.lines.firstWhere((l) => l.id == lId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTag(line.name, line.color),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildGradientButton(
                        label: '設為起點',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          _metroState.setStartStation(station);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOutlineButton(
                        label: '設為終點',
                        icon: Icons.flag_rounded,
                        onPressed: () {
                          _metroState.setEndStation(station);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // 規範需求：標籤 (圓角 20px，背景色 10% 透明度，邊框 30% 透明度)
  Widget _buildTag(String text, Color baseColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: baseColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 規範需求：主要按鈕樣式 (漸變 #1A73E8 到 #1A73E8(80%)，圓角 12px，陰影 #1A73E8 30% 透明度，模糊 12px)
  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, blue],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 18),
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) const Icon(Icons.subway, color: primary, size: 18),
          if (icon != null) const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final citySelector = DropdownButtonHideUnderline(
      child: DropdownButton<CityMetroData>(
        isExpanded: true,
        value: _currentCity,
        icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
        style: Theme.of(context).textTheme.titleMedium,
        items: MetroRepository.allCities.map((city) {
          return DropdownMenuItem(
            value: city,
            child:
                Text(city.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (city) => city != null ? _changeCity(city) : null,
      ),
    );
    final searchField = Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStations,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: '搜尋車站...',
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterStations('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // 規範需求：AppBar 白色背景，無陰影，標題 20px 字重 700 主色，居中
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '捷運路線與票價查詢',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.center_focus_strong, color: colorScheme.primary),
            tooltip: '重置視角',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 規範需求：搜尋輸入框與城市選擇卡片
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surface,
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              child: citySelector,
                            ),
                            const SizedBox(height: 8),
                            searchField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(width: 220, child: citySelector),
                          const SizedBox(width: 12),
                          Expanded(child: searchField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // 主畫布區域 (Canvas Map & Floating Card Overlays)
            Expanded(
              child: Stack(
                children: [
                  // 向量縮放地圖 (Pan & Zoom Canvas)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final mapSize = _mapSize(viewportSize);
                      final visibleStationIds = _filteredStations
                          .map((station) => station.id)
                          .toSet();

                      return InteractiveViewer(
                        transformationController: _transformationController,
                        constrained: false,
                        minScale: 0.5,
                        maxScale: 3.5,
                        boundaryMargin: const EdgeInsets.all(80),
                        child: SizedBox(
                          key: const ValueKey('metro-route-canvas'),
                          width: mapSize.width,
                          height: mapSize.height,
                          child: AnimatedBuilder(
                            animation: _glowAnimationController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: mapSize,
                                painter: MetroMapPainter(
                                  cityData: _currentCity,
                                  startStation: _startStation,
                                  endStation: _endStation,
                                  routeResult: _routeResult,
                                  animationValue:
                                      _glowAnimationController.value,
                                  mapOrigin: _mapOrigin,
                                  visibleStationIds: visibleStationIds,
                                  backgroundColor: colorScheme.surface,
                                  gridColor: colorScheme.outlineVariant,
                                  stationLabelColor: colorScheme.onSurface,
                                ),
                                child: Stack(
                                  children: _filteredStations.map((station) {
                                    final isStart =
                                        _startStation?.id == station.id;
                                    final isEnd = _endStation?.id == station.id;
                                    final isInRoute = _routeResult?.path.any(
                                            (item) => item.id == station.id) ??
                                        false;
                                    final stationPosition =
                                        _mapPosition(station.position);

                                    return Positioned(
                                      key: ValueKey(station.id),
                                      left: stationPosition.dx - 18,
                                      top: stationPosition.dy - 18,
                                      child: Semantics(
                                        button: true,
                                        label: '${station.name}，${station.id}',
                                        child: Tooltip(
                                          message:
                                              '${station.name} (${station.id})',
                                          child: GestureDetector(
                                            onTap: () =>
                                                _onStationTapped(station),
                                            child: SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: Center(
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                  width: (isStart || isEnd)
                                                      ? 22
                                                      : 14,
                                                  height: (isStart || isEnd)
                                                      ? 22
                                                      : 14,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isStart
                                                        ? startColor
                                                        : isEnd
                                                            ? endColor
                                                            : isInRoute
                                                                ? primary
                                                                : colorScheme
                                                                    .surface,
                                                    border: Border.all(
                                                      color: (isStart ||
                                                              isEnd ||
                                                              isInRoute)
                                                          ? primary
                                                          : colorScheme
                                                              .onSurfaceVariant,
                                                      width: station.isTransfer
                                                          ? 3
                                                          : 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  // 起終點即時提示小卡 (通知中心風格卡片)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const CircleAvatar(
                                    radius: 5, backgroundColor: startColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startStation?.name ?? '選擇起點',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: (_startStation != null
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium)
                                        ?.copyWith(
                                      color: _startStation != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.east_rounded,
                              color: colorScheme.onSurfaceVariant, size: 18),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    _endStation?.name ?? '選擇終點',
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: (_endStation != null
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium)
                                        ?.copyWith(
                                      color: _endStation != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const CircleAvatar(
                                    radius: 5, backgroundColor: endColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 規範需求：通知中心風格的列表查詢結果卡片
                  if (_routeResult != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // 圖標容器 (48px, 漸變, 白色圖標)
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [colorScheme.primary, blue],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                      Icons.directions_subway_rounded,
                                      color: Colors.white,
                                      size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '規劃路線資訊',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '經過 ${_routeResult!.stationCount} 站 · 轉乘 ${_routeResult!.transferCount} 次',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                _buildTag(
                                    'NT\$ ${_routeResult!.fare}', startColor),
                              ],
                            ),
                            Divider(
                              height: 24,
                              color: colorScheme.outlineVariant,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '預估時間: ~${_routeResult!.durationMinutes} 分鐘',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '單程票價: NT\$ ${_routeResult!.fare}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: colorScheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 行經路徑水平捲動標籤
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _routeResult!.path
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int idx = entry.key;
                                  Station s = entry.value;
                                  bool isLast =
                                      idx == _routeResult!.path.length - 1;
                                  return Row(
                                    children: [
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          color: (idx == 0)
                                              ? startColor
                                              : isLast
                                                  ? endColor
                                                  : colorScheme.onSurface,
                                          fontWeight: (idx == 0 || isLast)
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (!isLast)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: colorScheme.onSurfaceVariant,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. 向量路網與動態發光繪製器 (Custom Painter)
// ==========================================
