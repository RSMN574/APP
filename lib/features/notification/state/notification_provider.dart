import 'package:com.rsmn574.app/features/common/state/load_state.dart';
import 'package:com.rsmn574.app/features/notification/data/notification_repository.dart';
import 'package:flutter/foundation.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  final NotificationRepository _repository;
  LoadState<List<NotificationItem>> _state = const LoadState.initial();
  int _requestId = 0;
  bool _disposed = false;

  LoadState<List<NotificationItem>> get state => _state;
  List<NotificationItem> get items => _state.data ?? const [];

  Future<void> load() async {
    final requestId = ++_requestId;
    _setState(LoadState.loading(previous: _state.data));
    try {
      final items = await _repository.getNotifications();
      if (requestId != _requestId) return;
      _setState(items.isEmpty
          ? const LoadState.empty()
          : LoadState.success(items));
    } catch (error) {
      if (requestId != _requestId) return;
      _setState(LoadState.error(error));
    }
  }

  void _setState(LoadState<List<NotificationItem>> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
