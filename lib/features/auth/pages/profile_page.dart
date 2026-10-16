import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../sync/state/cloud_sync_provider.dart';
import '../data/models/auth_user_model.dart';
import '../state/auth_provider.dart';
import '../widgets/auth_error_banner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  bool _nameInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ok = await auth.updateProfile(avatarBytes: bytes);
    if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ok = await context.read<AuthProvider>().updateProfile(
          displayName: name,
        );
    if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  }

  Future<void> _deleteAccount(AuthUserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileDeleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileDeleteBody),
            if (user.hasPasswordProvider) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.profileDeletePassword,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.profileCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.profileDeleteConfirm),
          ),
        ],
      ),
    );
    final password = passwordController.text;
    passwordController.dispose();
    if (confirmed != true) return;
    final ok = await auth.deleteAccount(password: password);
    if (!ok) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.profileDeleted)));
    navigator.pop();
  }

  String _providerLabel(String id, AppLocalizations l10n) => switch (id) {
        'password' => l10n.profileProviderPassword,
        'google.com' => l10n.profileProviderGoogle,
        'apple.com' => l10n.profileProviderApple,
        _ => l10n.profileProviderOther,
      };

  String _formatDate(BuildContext context, DateTime? value, String fallback) {
    if (value == null) return fallback;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<CloudSyncProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(
          child: auth.isLoading
              ? const CircularProgressIndicator()
              : FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/auth/login'),
                  child: Text(l10n.authLoginOrRegister),
                ),
        ),
      );
    }

    if (!_nameInitialized) {
      _nameController.text = user.displayName ?? '';
      _nameInitialized = true;
    }

    final unknown = l10n.profileUnknown;
    final providers = user.providerIds.isEmpty
        ? unknown
        : user.providerIds.map((id) => _providerLabel(id, l10n)).join(', ');
    final syncStatus = sync.isSyncing
        ? l10n.profileSyncing
        : sync.hasError
            ? l10n.profileSyncFailed
            : sync.lastSyncedAt == null
                ? l10n.profileSyncNever
                : '${l10n.profileLastSynced(_formatDate(context, sync.lastSyncedAt, unknown))}\n'
                    '${l10n.profileSyncResult('${sync.lastResult?.uploaded ?? 0}', '${sync.lastResult?.downloaded ?? 0}')}';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.photoURL == null
                      ? null
                      : NetworkImage(user.photoURL!),
                  child: user.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    tooltip: l10n.profileChangeAvatar,
                    onPressed: auth.isLoading ? null : _pickAvatar,
                    icon: const Icon(Icons.camera_alt, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (auth.error != null) ...[
            AuthErrorBanner(error: auth.error!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            maxLength: 30,
            onSubmitted: (_) => _saveName(),
            decoration: InputDecoration(
              labelText: l10n.profileDisplayName,
              hintText: l10n.profileDisplayNameHint,
              suffixIcon: IconButton(
                tooltip: l10n.profileSave,
                icon: const Icon(Icons.check),
                onPressed: auth.isLoading ? null : _saveName,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.email_outlined,
            label: l10n.profileEmail,
            value: user.email ?? unknown,
          ),
          _InfoTile(
            icon: Icons.login,
            label: l10n.profileLoginMethod,
            value: providers,
          ),
          _InfoTile(
            icon: Icons.event_available,
            label: l10n.profileCreatedAt,
            value: _formatDate(context, user.createdAt, unknown),
          ),
          _InfoTile(
            icon: Icons.history,
            label: l10n.profileLastSignIn,
            value: _formatDate(context, user.lastSignInAt, unknown),
          ),
          const Divider(height: 32),
          Text(l10n.profileSyncSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(syncStatus, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: sync.isSyncing ? null : sync.syncNow,
            icon: sync.isSyncing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(l10n.profileSyncNow),
          ),
          const Divider(height: 32),
          TextButton.icon(
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: auth.isLoading ? null : () => _deleteAccount(user),
            icon: const Icon(Icons.delete_forever),
            label: Text(l10n.profileDeleteAccount),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
