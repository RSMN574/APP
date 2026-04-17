import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // 建議安裝此套件處理外部連結

import '../../database/SQL/schedule.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ValueNotifier<bool> _notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _isDarkTheme = ValueNotifier(false);
  String _selectedLanguage = '繁體中文';
  String _appVersion = '1.0.0';
  String _appName = '交通助手';
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
    _isDarkTheme.value = prefs.getBool('darkTheme') ?? false;
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? '繁體中文';
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
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
    _isDarkTheme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('設定', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,

      ),
      body: ListView(
        children: [
          _buildSectionTitle('系統設定'),
          _buildSettingCard([
            ValueListenableBuilder<bool>(
              valueListenable: _notificationsEnabled,
              builder: (context, value, child) {
                return SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
                  title: const Text('啟用即時通知'),
                  subtitle: const Text('接收公車到站與天氣警報'),
                  value: value,
                  onChanged: (bool newValue) {
                    _notificationsEnabled.value = newValue;
                    _savePreference('notifications', newValue);
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isDarkTheme,
              builder: (context, value, child) {
                return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: Colors.orange),
                  title: const Text('深色模式'),
                  value: value,
                  onChanged: (bool newValue) {
                    _isDarkTheme.value = newValue;
                    _savePreference('darkTheme', newValue);
                    // 這裡通常需要通知 MyApp 重新 build 以切換主題
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.green),
              title: const Text('語言設定'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(),
            ),
          ]),

          _buildSectionTitle('資料管理'),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.teal),
              title: const Text('資料來源說明'),
              onTap: () => _showInfoDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              title: const Text('清除數據庫'),
              subtitle: const Text('刪除所有儲存的常用行程與快取'),
              onTap: () => _showClearDialog(context),
            ),
          ]),

          _buildSectionTitle('支援與關於'),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.star_border_rounded, color: Colors.amber),
              title: const Text('評分我們'),
              onTap: () {
                // TODO: 實作 Store 跳轉
              },
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email, color: Colors.blueGrey),
              title: const Text('問題回饋'),
              onTap: () {
                // TODO: 實作郵件跳轉
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.indigo),
              title: const Text('關於我們'),
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
            ),   ListTile(
              leading: const Icon(Icons.settings_accessibility_rounded, color: Colors.indigo),
              title: const Text('開發者設定'),
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
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  // 輔助組件：設定卡片容器
  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  // --- Dialogs 保持原邏輯但稍微美化 ---

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('選擇語言'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['繁體中文', 'English']
                .map((language) => RadioListTile(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                  _savePreference('language', value);
                });
                Navigator.pop(context);
              },
            ))
                .toList(),
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('確認清除？'),
          ],
        ),
        content: const Text('這將刪除所有儲存的資料，且無法復原。是否繼續？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ScheduleService.instance.clearDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ 數據庫已清除'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('確定清除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        title: const Text('資料來源'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本應用的數據來源於以下平台：'),
            SizedBox(height: 12),
            Text('• TDX 交通部運輸資料流通服務平臺', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('• CWA 中央氣象署開放資料平臺', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('• Google Maps API', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 12),
            Text('所有即時資訊以各平臺官方發佈為準。', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}