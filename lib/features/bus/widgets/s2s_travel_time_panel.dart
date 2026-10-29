import 'package:flutter/material.dart';
import '../model/s2s_travel_time.dart';
import '../services/s2s_travel_time_service.dart';

typedef S2STravelTimeLoader = Future<dynamic> Function();

class S2STravelTimePanel extends StatefulWidget {
  const S2STravelTimePanel({
    super.key, required this.loadData, required this.stops, required this.direction, this.title,
  });
  final S2STravelTimeLoader loadData;
  final List<Map<String, dynamic>> stops;
  final int direction;
  final String? title;

  @override
  State<S2STravelTimePanel> createState() => _S2STravelTimePanelState();
}

class _S2STravelTimePanelState extends State<S2STravelTimePanel> {
  final _service = const S2STravelTimeService();
  bool _loading = true;
  String? _error;
  List<S2SSegmentAnalysis> _segments = [];
  DateTime? _checkedAt;
  bool get _en => Localizations.localeOf(context).languageCode == 'en';

  @override
  void initState() { super.initState(); _load(); }

  @override
  void didUpdateWidget(covariant S2STravelTimePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction || oldWidget.loadData != widget.loadData || oldWidget.stops != widget.stops) _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final routes = _service.parseResponse(await widget.loadData());
      final result = _service.analyze(routes: routes, stops: widget.stops, direction: widget.direction);
      if (!mounted) return;
      setState(() {
        _segments = result; _checkedAt = DateTime.now(); _loading = false;
        if (routes.isEmpty) _error = _en ? 'No travel-time data available.' : '目前沒有站間行車時間資料。';
        else if (result.isEmpty) _error = _en ? 'Could not match route direction.' : '無法配對路線方向。';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = _en ? 'Failed to load travel-time data.' : '載入站間行車時間失敗。'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.route_rounded, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.title ?? (_en ? 'Stop-to-stop travel time' : '站間行車時間分析'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            IconButton(onPressed: _loading ? null : _load, tooltip: _en ? 'Refresh' : '重新載入', icon: const Icon(Icons.refresh_rounded)),
          ]),
          Text(_en ? 'Typical runtime by weekday and time period' : '依星期與時段顯示 TDX 提供的預期行車時間',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 12),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_error != null) _message(_error!, colors)
          else ..._segments.map((s) => _segment(s, theme)),
          if (!_loading && _checkedAt != null) ...[
            const SizedBox(height: 8),
            Text('${_en ? 'Checked' : '查詢時間'}: ${TimeOfDay.fromDateTime(_checkedAt!).format(context)}',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          ],
          const SizedBox(height: 8),
          Container(width: double.infinity, padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
              child: Text(_en
                  ? 'This is a runtime baseline, not a live delay measurement. Actual delay requires observed or reliable real-time passage/arrival times.'
                  : '這是預期行車時間基準，不代表即時延誤。要計算實際延誤，還需要公車實際通過時間或可靠的即時到站資料。',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))),
        ]),
      ),
    );
  }

  Widget _segment(S2SSegmentAnalysis s, ThemeData theme) {
    final colors = theme.colorScheme;
    final seconds = s.expectedSeconds;
    final duration = seconds == null ? (_en ? 'Unavailable' : '無資料')
        : seconds < 60 ? '${seconds}s' : '${(seconds / 60).round()} ${_en ? 'min' : '分鐘'}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.circle, size: 9, color: seconds == null ? colors.outline : colors.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.fromStopName.isEmpty ? s.fromStopId : s.fromStopName,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Padding(padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Icon(Icons.south_rounded, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${_en ? 'To' : '至'} ', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                Expanded(child: Text(s.toStopName.isEmpty ? s.toStopId : s.toStopName, style: theme.textTheme.bodySmall)),
              ])),
        ])),
        const SizedBox(width: 8),
        Text(duration, style: theme.textTheme.titleSmall?.copyWith(color: seconds == null ? colors.onSurfaceVariant : colors.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _message(String text, ColorScheme colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [Icon(Icons.info_outline_rounded, color: colors.onSurfaceVariant), const SizedBox(width: 8), Expanded(child: Text(text))]),
  );
}
