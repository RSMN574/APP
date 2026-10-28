class BusDirectionResolution {
  final List<int> directions;
  final int? preferredTabIndex;

  const BusDirectionResolution({
    required this.directions,
    this.preferredTabIndex,
  });
}

/// 從 `getBusStopOfRoute` 回傳資料解析「Tab 對應的 TDX Direction」。
class BusDirectionResolver {
  const BusDirectionResolver._();

  /// [tabCount] 必須等於 `TabController.length`。
  /// 回傳的 `directions.length` 保證等於 [tabCount]，避免越界。
  static BusDirectionResolution resolve({
    required bool hasSubRoutes,
    required int tabCount,
    required List<Map<String, dynamic>> routeStopsData,
    int? preferredDirection,
  }) {
    // 收集 API 中存在的方向（保留原始順序）
    final available = <int>[];
    for (final item in routeStopsData) {
      final d = item['Direction'];
      final parsed = d is int ? d : int.tryParse(d?.toString() ?? '');
      if (parsed != null && !available.contains(parsed)) {
        available.add(parsed);
      }
    }

    List<int> directions;
    if (!hasSubRoutes || tabCount == 1) {
      // 單 Tab：優先採用 API 中的方向
      directions = [available.isNotEmpty ? available.first : (preferredDirection ?? 1)];
    } else {
      // 雙 Tab：通常 1 = 去程、0 = 回程
      if (available.contains(1) && available.contains(0)) {
        directions = [1, 0];
      } else if (available.length >= 2) {
        directions = available.sublist(0, 2);
      } else if (available.length == 1) {
        final only = available.first;
        directions = [only, only == 1 ? 0 : 1];
      } else {
        directions = [1, 0];
      }
    }

    // 保證長度 == tabCount
    if (directions.length > tabCount) {
      directions = directions.sublist(0, tabCount);
    } else if (directions.length < tabCount) {
      final fallback = directions.isNotEmpty ? directions.last : 1;
      while (directions.length < tabCount) {
        directions = [...directions, fallback];
      }
    }

    int? preferredTabIndex;
    if (preferredDirection != null) {
      final idx = directions.indexOf(preferredDirection);
      if (idx >= 0) preferredTabIndex = idx;
    }

    return BusDirectionResolution(
      directions: directions,
      preferredTabIndex: preferredTabIndex,
    );
  }
}