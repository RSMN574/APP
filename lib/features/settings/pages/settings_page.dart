
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:com.rsmn574.app/const/regular_class.dart';
import 'package:com.rsmn574.app/features/settings/state/settings_provider.dart';
import 'package:com.rsmn574.app/l10n/app_localizations.dart';
import 'package:com.rsmn574.app/features/auth/widgets/auth_account_section.dart';


import '../widget/app_update_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 儲存語言代碼，避免將顯示文字當成設定值。
  String _selectedLanguageCode = 'zh';

  String _appVersion = '1.0.0';
  String _appName = '';
  String _packageName = '';
  String _buildNumber = '';

  bool _isLoadingSettings = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSettings();
      }
    });
  }

  /// 載入設定與應用程式版本資訊。
  Future<void> _loadSettings() async {
    if (_isLoadingSettings) return;
    _isLoadingSettings = true;

    try {
      final settings = context.read<SettingsProvider>();
      await settings.load();

      if (!mounted) return;

      final info = settings.versionInfo;
      final language = settings.language?.toLowerCase();

      setState(() {
        _selectedLanguageCode =
        language == 'en' || language == 'english' ? 'en' : 'zh';

        if (info != null) {
          _appVersion = info.version;
          _appName = info.appName;
          _packageName = info.packageName;
          _buildNumber = info.buildNumber;
        } else {
          _appName = AppLocalizations.of(context)!.text_445;
        }
      });
    } catch (error) {
      debugPrint('SettingsPage 載入設定失敗：$error');
    } finally {
      _isLoadingSettings = false;
    }
  }

  String _languageDisplayName(AppLocalizations l10n) {
    return _selectedLanguageCode == 'en' ? 'English' : l10n.text_72;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEnglish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.text_446,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // 帳號
          _buildSectionTitle(l10n.authAccountSection),
          const AuthAccountSection(),

          // 一般設定
          _buildSectionTitle(l10n.text_447),
          _buildSettingCard([
            Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.primary,
                  ),
                  title: Text(l10n.text_448),
                  subtitle: Text(l10n.text_449),
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    settings.setNotificationsEnabled(value);
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
                  title: Text(l10n.text_450),
                  value: appProvider.isDarkTheme,
                  onChanged: appProvider.toggleTheme,
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.language,
                color: colorScheme.secondary,
              ),
              title: Text(l10n.text_451),
              subtitle: Text(_languageDisplayName(l10n)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguageDialog,
            ),
          ]),

          // App 資訊與行程管理
          _buildSectionTitle(l10n.text_452),
          _buildSettingCard([
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: colorScheme.primary,
              ),
              title: Text(l10n.text_453),
              onTap: () => _showInfoDialog(context),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_sweep_outlined,
                color: colorScheme.error,
              ),
              title: Text(l10n.text_454),
              subtitle: Text(l10n.text_455),
              onTap: _showClearDialog,
            ),
          ]),

          // GitHub Releases 版本更新
          _buildSectionTitle(isEnglish ? 'App updates' : '版本更新'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppUpdateSection(),
          ),

          // 支援
          _buildSectionTitle(l10n.text_456),
          _buildSettingCard([
            ListTile(
              leading: Icon(
                Icons.star_border_rounded,
                color: colorScheme.tertiary,
              ),
              title: Text(l10n.text_457),
              onTap: () {
                // TODO: 實作 Google Play 商店跳轉。
              },
            ),
            ListTile(
              leading: Icon(
                Icons.alternate_email,
                color: colorScheme.secondary,
              ),
              title: Text(l10n.text_458),
              onTap: () {
                // TODO: 實作郵件跳轉。
              },
            ),
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: colorScheme.primary,
              ),
              title: Text(l10n.text_459),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 導向說明頁。
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings_accessibility_rounded,
                color: colorScheme.primary,
              ),
              title: Text(l10n.text_460),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 導向無障礙設定頁。
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

  /// 區塊標題。
  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
        ),
      ),
    );
  }

  /// 共用設定卡片。
  Widget _buildSettingCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  /// 語言選擇。
  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(l10n.text_461),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(l10n.text_72),
                    value: 'zh',
                    groupValue: _selectedLanguageCode,
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        _selectedLanguageCode = value;
                      });

                      context.read<AppProvider>().setLanguage(value);

                      if (mounted) {
                        setState(() {
                          _selectedLanguageCode = value;
                        });
                      }

                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: _selectedLanguageCode,
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        _selectedLanguageCode = value;
                      });

                      context.read<AppProvider>().setLanguage(value);

                      if (mounted) {
                        setState(() {
                          _selectedLanguageCode = value;
                        });
                      }

                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 清除行程確認對話框。
  void _showClearDialog() {
    final pageContext = context;
    final l10n = AppLocalizations.of(pageContext)!;
    final colorScheme = Theme.of(pageContext).colorScheme;

    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.text_462,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(l10n.text_463),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.text_36),
            ),
            TextButton(
              onPressed: () async {
                final settings = pageContext.read<SettingsProvider>();

                Navigator.pop(dialogContext);

                try {
                  await settings.clearSchedules();

                  if (!mounted) return;

                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(pageContext)!.text_464,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (error) {
                  if (!mounted) return;

                  debugPrint('清除行程失敗：$error');

                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        Localizations.localeOf(pageContext)
                            .languageCode ==
                            'en'
                            ? 'Unable to clear schedules. Please try again.'
                            : '清除行程失敗，請稍後再試。',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                l10n.text_465,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// App 資訊。
  void _showInfoDialog(BuildContext pageContext) {
    final l10n = AppLocalizations.of(pageContext)!;
    final colorScheme = Theme.of(pageContext).colorScheme;

    showDialog<void>(
      context: pageContext,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(l10n.text_466),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.text_467),
                const SizedBox(height: 12),
                Text(
                  l10n.text_468,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  l10n.text_469,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Text(
                  '• Google Maps API',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.text_470,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.text_471),
            ),
          ],
        );
      },
    );
  }
}
