import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../database/SQL/schedule.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ValueNotifier<bool> _notificationsEnabled = ValueNotifier(true);
  late ValueNotifier<bool> _isDarkTheme = ValueNotifier(false);
  String _selectedLanguage = '繁體中文';
  String _appVersion = '1.0.0'; // 預設版本號
  late String appName;
  late String packageName;
  late String buildNumber;

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
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      buildNumber = packageInfo.buildNumber;
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
        title: Text('設定'),
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _notificationsEnabled,
            builder: (context, value, child) {
              return SwitchListTile(
                title: const Text('啟用通知'),
                value: value,
                onChanged: null, // 禁用交互
                activeColor: Colors.grey, // 改變顯示顏色以表明禁用狀態
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _isDarkTheme,
            builder: (context, value, child) {
              return SwitchListTile(
                title: const Text('深色模式'),
                value: value,
                onChanged: null, // 禁用交互
                activeColor: Colors.grey, // 改變顯示顏色以表明禁用狀態
              );
            },
          ),

          ListTile(
            title: Text('語言設定'),
            subtitle: Text(_selectedLanguage),
            leading: Icon(Icons.language),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ),
          ListTile(
            title: Text('資料來源'),
            leading: Icon(Icons.info),
            onTap: () => _showInfoDialog(context),
          ),
          ListTile(
            title: const Text('清除數據庫'),
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onTap: () => _showClearDialog(context),
          ),

          ListTile(
            title: Text('關於我們'),
            leading: Icon(Icons.info_outline),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutPage( appName: appName, packageName: packageName, version:  _appVersion, buildNumber: buildNumber,),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('選擇語言'),
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
        title: const Text('確認清除？'),
        content: const Text('這將刪除所有儲存的資料，是否繼續？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ScheduleService.instance.clearDatabase();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 數據庫已清除'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('確定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('資料來源'),
        content: Text(
          '本應用的數據來源於以下平台：\n\n'
              '- TDX 交通部運輸資料流通服務平臺\n'
              '- Google Maps API\n\n'
              '感謝這些平台提供的開放數據與地圖服務。',
          textAlign: TextAlign.start,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }
}
class AboutPage extends StatelessWidget {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const AboutPage({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('關於我們'),
        backgroundColor: Colors.white, // 設置 AppBar 背景為白色
        elevation: 0, // 移除陰影
        iconTheme: IconThemeData(color: Colors.black), // 設置 icon 顏色為黑色
      ),
      backgroundColor: Colors.white, // 設置頁面背景為白色
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildInfoCard('應用名稱', appName),
            SizedBox(height: 16),
            _buildInfoCard('包名', packageName),
            SizedBox(height: 16),
            _buildInfoCard('版本號', version),
            SizedBox(height: 16),
            _buildInfoCard('構建號', buildNumber),
            SizedBox(height: 20),
            Center(
              child: Text(
                '感謝您使用我們的應用！',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54, // 淺灰色字體
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // 保持卡片背景為白色
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // 微弱陰影
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ], // 輕微陰影效果
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black, // 黑色字體
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87, // 深黑字體
            ),
          ),
        ],
      ),
    );
  }
}


