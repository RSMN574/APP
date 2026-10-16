import 'package:com.rsmn574.app/features/settings/data/settings_repository.dart';
import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? const SettingsRepository();

  final SettingsRepository _repository;
  bool _notificationsEnabled = true;
  String? _language;
  AppVersionInfo? _versionInfo;
  bool _disposed = false;

  bool get notificationsEnabled => _notificationsEnabled;
  String? get language => _language;
  AppVersionInfo? get versionInfo => _versionInfo;

  Future<void> load() async {
    final enabled = await _repository.loadNotificationsEnabled();
    final language = await _repository.loadLanguage();
    final version = await _repository.loadVersionInfo();
    if (_disposed) return;
    _notificationsEnabled = enabled;
    _language = language;
    _versionInfo = version;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    await _repository.saveNotificationsEnabled(value);
  }

  Future<void> clearSchedules() => _repository.clearSchedules();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
