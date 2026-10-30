import 'package:com.rsmn574.app/features/home/widgets/transport_grid.dart';
import 'package:flutter/material.dart';

// 請替換為你專案的實際路徑
import '../../weather/widgets/weather_card.dart';


class HomeBottomSheet extends StatefulWidget {
  final ValueNotifier<double> sheetExtent;
  final String cityName; // 新增：接收城市名稱
  final Function(String) onTransportClick;
  final Function(double) onExtentChanged;

  const HomeBottomSheet({
    super.key,
    required this.sheetExtent,
    required this.cityName,
    required this.onTransportClick,
    required this.onExtentChanged,
  });

  @override
  State<HomeBottomSheet> createState() => _HomeBottomSheetState();
}

class _HomeBottomSheetState extends State<HomeBottomSheet> {
  final DraggableScrollableController _controller =
  DraggableScrollableController();

  static const double _collapsedSize = 0.15;
  static const double _halfExpandedSize = 0.45;
  static const double _fullyExpandedSize = 0.90;

  bool _isCollapsed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: _halfExpandedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _fullyExpandedSize,
      snap: true,
      snapSizes: const [_collapsedSize, _halfExpandedSize, _fullyExpandedSize],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              widget.onExtentChanged(notification.extent);
              final isCollapsed = notification.extent < 0.3;
              if (_isCollapsed != isCollapsed) {
                setState(() => _isCollapsed = isCollapsed);
              }
              return false;
            },
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                // 頂部拖曳把手
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // 交通工具快捷入口
                SliverToBoxAdapter(
                  child: TransportGrid(
                    onClick: widget.onTransportClick,
                    isCollapsed: _isCollapsed,
                  ),
                ),

                // 展開後顯示的內容
                if (!_isCollapsed) ...[
                  // 天氣卡片 (保留)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: WeatherAlertCard(
                        cityName: widget.cityName,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Divider(height: 1, thickness: 1),
                  ),
                  // 常用路線
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '常用路線',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  // 附近站牌
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '附近站牌',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  // 交通公告
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '交通公告',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}