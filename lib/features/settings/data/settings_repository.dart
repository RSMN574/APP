import 'package:com.rsmn574.app/database/sql/schedule.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
}

class SettingsRepository {
  const SettingsRepository();

  static const String notificationsKey = 'notifications';
  static const String languageKey = 'language';

  Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsKey) ?? true;
  }

  Future<String?> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(languageKey);
  }

  Future<void> saveNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsKey, value);
  }

  Future<AppVersionInfo> loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersionInfo(
      appName: info.appName,
      packageName: info.packageName,
      version: info.version,
      buildNumber: info.buildNumber,
    );
  }

  Future<void> clearSchedules() => ScheduleService.instance.clearDatabase();
}
