import 'package:flutter/foundation.dart';

import '../../auth/state/auth_provider.dart';
import '../data/schedule_sync_repository.dart';

class CloudSyncProvider extends ChangeNotifier {
  CloudSyncProvider({ScheduleSyncRepository? repository})
      : _repository = repository;

  ScheduleSyncRepository? _repository;
  ScheduleSyncRepository get _repo => _repository ??= ScheduleSyncRepository();

  String? _uid;
  bool _isSyncing = false;
  bool _disposed = false;
  DateTime? _lastSyncedAt;
  bool _hasError = false;
  ScheduleSyncResult? _lastResult;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get hasError => _hasError;
  ScheduleSyncResult? get lastResult => _lastResult;

  /// Called by the provider proxy whenever the auth state changes.
  void attach(AuthProvider auth) {
    final uid = auth.currentUser?.uid;
    if (uid == _uid) return;
    _uid = uid;
    _lastSyncedAt = null;
    _lastResult = null;
    _hasError = false;
    if (uid != null) Future.microtask(syncNow);
  }

  Future<bool> syncNow() async {
    final uid = _uid;
    if (uid == null || _isSyncing || _disposed) return false;
    _isSyncing = true;
    _hasError = false;
    notifyListeners();
    try {
      final result = await _repo.sync(uid);
      if (_uid != uid) return false;
      _lastResult = result;
      _lastSyncedAt = DateTime.now();
      return true;
    } catch (error) {
      debugPrint('Schedule sync failed: $error');
      _hasError = true;
      return false;
    } finally {
      _isSyncing = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
