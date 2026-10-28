import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';

/// A drop-in settings section. Uses the current app locale for basic
/// Traditional Chinese / English text; replace labels with AppLocalizations
/// getters if your project already has corresponding localization keys.
class AppUpdateSection extends StatefulWidget {
  const AppUpdateSection({
    super.key,
    this.service,
  });

  final UpdateService? service;

  @override
  State<AppUpdateSection> createState() => _AppUpdateSectionState();
}

class _AppUpdateSectionState extends State<AppUpdateSection> {
  late final UpdateService _service = widget.service ?? UpdateService();

  bool _checking = false;
  String? _currentVersion;
  String? _message;
  String? _releaseNotes;
  Uri? _releaseUrl;
  bool _updateAvailable = false;
  bool _ownsService = false;

  bool get _isEnglish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'en';

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _currentVersion = info.version);
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentVersion = null);
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _message = _isEnglish ? 'Checking for updates…' : '正在檢查更新…';
      _releaseNotes = null;
      _releaseUrl = null;
      _updateAvailable = false;
    });

    try {
      final info = await PackageInfo.fromPlatform();
      final release = await _service.fetchLatestRelease();
      final hasUpdate =
          UpdateService.isNewerVersion(info.version, release.version);

      if (!mounted) return;
      setState(() {
        _currentVersion = info.version;
        _updateAvailable = hasUpdate;
        _releaseUrl = release.releaseUrl;
        _releaseNotes = release.notes;
        _message = hasUpdate
            ? (_isEnglish
                ? 'New version ${release.version} is available.'
                : '發現新版本 ${release.version}。')
            : (_isEnglish
                ? 'You are using the latest version.'
                : '目前已是最新版本。');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _isEnglish
            ? 'Unable to check for updates. Please try again later.'
            : '目前無法檢查更新，請稍後再試。';
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openRelease() async {
    final uri = _releaseUrl;
    if (uri == null) return;
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEnglish ? 'Unable to open the release page.' : '無法開啟 Release 頁面。'),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = _isEnglish ? 'App updates' : '版本更新';

    return Card(
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.system_update_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        _currentVersion == null
                            ? (_isEnglish ? 'Installed version unavailable' : '無法讀取目前版本')
                            : (_isEnglish
                                ? 'Current version: $_currentVersion'
                                : '目前版本：$_currentVersion'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _isEnglish ? 'Check for updates' : '檢查更新',
                  onPressed: _checking ? null : _checkForUpdates,
                  icon: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: theme.textTheme.bodyMedium),
            ],
            if (_releaseNotes != null && _releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _isEnglish ? 'Release notes' : '更新說明',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _releaseNotes!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_updateAvailable && _releaseUrl != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _openRelease,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(_isEnglish ? 'View release' : '查看更新'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
