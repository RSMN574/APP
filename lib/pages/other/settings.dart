import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../const/regular_class.dart';
import '../../database/sql/schedule.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ValueNotifier<bool> _notificationsEnabled = ValueNotifier(true);
  late String _selectedLanguage = AppLocalizations.of(context)!.text_72;
  String _appVersion = '1.0.0';
  late String _appName = AppLocalizations.of(context)!.text_445;
  String _packageName = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled.value = prefs.getBool('notifications') ?? true;
    if (!mounted) return;
    setState(() {
      _selectedLanguage =
          prefs.getString('language') ?? AppLocalizations.of(context)!.text_72;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  void dispose() {
    _notificationsEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.text_446,
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(AppLocalizations.of(context)!.text_447),
          _buildSettingCard([
            ValueListenableBuilder<bool>(
              valueListenable: _notificationsEnabled,
              builder: (context, value, child) {
                return SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(AppLocalizations.of(context)!.text_448),
                  subtitle: Text(AppLocalizations.of(context)!.text_449),
                  value: value,
                  onChanged: (bool newValue) {
                    _notificationsEnabled.value = newValue;
                    _savePreference('notifications', newValue);
                  },
                );
              },
            ),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                return SwitchListTile(
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: colorScheme.tertiary,
                  ),
                  title: Text(AppLocalizations.of(context)!.text_450),
                  value: appProvider.isDarkTheme,
                  onChanged: appProvider.toggleTheme,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: colorScheme.secondary),
              title: Text(AppLocalizations.of(context)!.text_451),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(),
            ),
          ]),
          _buildSectionTitle(AppLocalizations.of(context)!.text_452),
          _buildSettingCard([
            ListTile(
              leading: Icon(Icons.info_outline, color: colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.text_453),
              onTap: () => _showInfoDialog(context),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_sweep_outlined,
                color: colorScheme.error,
              ),
              title: Text(AppLocalizations.of(context)!.text_454),
              subtitle: Text(AppLocalizations.of(context)!.text_455),
              onTap: () => _showClearDialog(context),
            ),
          ]),
          _buildSectionTitle(AppLocalizations.of(context)!.text_456),
          _buildSettingCard([
            ListTile(
              leading: Icon(
                Icons.star_border_rounded,
                color: colorScheme.tertiary,
              ),
              title: Text(AppLocalizations.of(context)!.text_457),
              onTap: () {
                // TODO: 實作 Store 跳轉
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.alternate_email, color: colorScheme.secondary),
              title: Text(AppLocalizations.of(context)!.text_458),
              onTap: () {
                // TODO: 實作郵件跳轉
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: colorScheme.primary),
              title: Text(AppLocalizations.of(context)!.text_459),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => AboutPage(
                //       appName: _appName,
                //       packageName: _packageName,
                //       version: _appVersion,
                //       buildNumber: _buildNumber,
                //     ),
                //   ),
                // );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings_accessibility_rounded,
                color: colorScheme.primary,
              ),
              title: Text(AppLocalizations.of(context)!.text_460),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => AboutPage(
                //       appName: _appName,
                //       packageName: _packageName,
                //       version: _appVersion,
                //       buildNumber: _buildNumber,
                //     ),
                //   ),
                // );
              },
            ),
          ]),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Version $_appVersion ($_buildNumber)',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 輔助組件：區塊標題
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  // 輔助組件：設定卡片容器
  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // --- Dialogs 保持原邏輯但稍微美化 ---

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // ✅ 使用 watch 監聽變化，對話框內會自動更新
        final appProvider = context.watch<AppProvider>();

        return AlertDialog(
          title: Text(l10n.text_461),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(l10n.text_72),
                value: 'zh',
                onChanged: (value) {
                  context.read<AppProvider>().setLanguage(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                onChanged: (value) {
                  context.read<AppProvider>().setLanguage(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.text_462),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.text_463),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.text_36,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ScheduleService.instance.clearDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)!.text_464),
                      behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.text_465,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.text_466),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.text_467),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.text_468,
                style: TextStyle(fontWeight: FontWeight.w500)),
            Text(AppLocalizations.of(context)!.text_469,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const Text('• Google Maps API',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.text_470,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.text_471),
          ),
        ],
      ),
    );
  }
}
