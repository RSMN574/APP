import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ValueNotifier<bool> _notificationsEnabled;
  late ValueNotifier<bool> _isDarkTheme;
  String _selectedLanguage = '繁體中文';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = ValueNotifier(prefs.getBool('notifications') ?? true);
    _isDarkTheme = ValueNotifier(prefs.getBool('darkTheme') ?? false);
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? '繁體中文';
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
                title: Text('啟用通知'),
                value: value,
                onChanged: (newValue) {
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
                title: Text('深色模式'),
                value: value,
                onChanged: (newValue) {
                  _isDarkTheme.value = newValue;
                  _savePreference('darkTheme', newValue);
                },
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
            title: Text('關於我們'),
            leading: Icon(Icons.info_outline),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
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
            children: ['繁體中文', '簡體中文', 'English']
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('資料來源'),
        content: Text('本應用的數據來源於官方開放數據 API。'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('關於我們'),
      ),
      body: Center(
        child: Text(
          '台灣通\n版本 1.0.0\n開發者: YourName',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
