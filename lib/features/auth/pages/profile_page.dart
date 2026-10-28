import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


import '../../../const/app_colors.dart';
import '../../../const/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../sync/state/cloud_sync_provider.dart';
import '../model/auth_user_model.dart';
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
    final colors = context.appColors;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final ok = await auth.updateProfile(avatarBytes: bytes);

    if (!mounted) return;

    _showSnackBar(
      messenger,
      ok ? l10n.profileSaved : l10n.profileVerificationRefreshFailed,
      ok ? colors.success : colors.danger,
    );
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    final ok = await context.read<AuthProvider>().updateProfile(
      displayName: name,
    );

    if (!mounted) return;

    _showSnackBar(
      messenger,
      ok ? l10n.profileSaved : l10n.profileVerificationRefreshFailed,
      ok ? colors.success : colors.danger,
    );
  }

  Future<void> _sendVerificationEmail() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.appColors;

    final succeeded = await auth.sendEmailVerification();

    if (!mounted) return;

    _showSnackBar(
      messenger,
      succeeded
          ? l10n.profileVerificationSent
          : l10n.profileVerificationSendFailed,
      succeeded ? colors.success : colors.danger,
    );
  }

  Future<void> _refreshVerificationStatus() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.appColors;

    final succeeded = await auth.refreshEmailVerification();

    if (!mounted) return;

    final verified = auth.currentUser?.emailVerified ?? false;

    _showSnackBar(
      messenger,
      !succeeded
          ? l10n.profileVerificationRefreshFailed
          : verified
          ? l10n.profileEmailVerified
          : l10n.profileEmailNotVerified,
      !succeeded
          ? colors.danger
          : verified
          ? colors.success
          : colors.warning,
    );
  }

  Future<void> _deleteAccount(AuthUserModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final passwordController = TextEditingController();
    final theme = Theme.of(context);
    final colors = context.appColors;

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
              const SizedBox(height: AppSpacing.lg),
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
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.profileDeleteConfirm),
          ),
        ],
      ),
    );

    final password = passwordController.text;
    passwordController.dispose();

    if (confirmed != true || !mounted) return;

    final ok = await auth.deleteAccount(password: password);

    if (!mounted || !ok) return;

    _showSnackBar(messenger, l10n.profileDeleted, colors.success);

    navigator.pop();
  }

  void _showSnackBar(
      ScaffoldMessengerState messenger,
      String message,
      Color color,
      ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedMd,
        ),
      ),
    );
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
    final colors = context.appColors;
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
            onPressed: () {
              Navigator.of(context).pushNamed('/auth/login');
            },
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // 頭像區域
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.info.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colors.mutedBackground,
                    backgroundImage: user.photoURL == null
                        ? null
                        : NetworkImage(user.photoURL!),
                    child: user.photoURL == null
                        ? Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: colors.info,
                    )
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.info,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      tooltip: l10n.profileChangeAvatar,
                      onPressed: auth.isLoading ? null : _pickAvatar,
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          if (auth.error != null) ...[
            AuthErrorBanner(error: auth.error!),
            const SizedBox(height: AppSpacing.md),
          ],

          // 顯示名稱
          Container(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: AppRadius.roundedLg,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              maxLength: 30,
              onSubmitted: (_) => _saveName(),
              decoration: InputDecoration(
                labelText: l10n.profileDisplayName,
                hintText: l10n.profileDisplayNameHint,
                filled: true,
                fillColor: colors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.roundedLg,
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  tooltip: l10n.profileSave,
                  icon: Icon(
                    Icons.check_rounded,
                    color: colors.info,
                  ),
                  onPressed: auth.isLoading ? null : _saveName,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          _InfoTile(
            icon: Icons.email_outlined,
            label: l10n.profileEmail,
            value: user.email ?? unknown,
          ),

          // 電子郵件驗證卡片
          _buildCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: user.emailVerified
                            ? colors.successContainer
                            : colors.dangerContainer,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Icon(
                        user.emailVerified
                            ? Icons.verified_rounded
                            : Icons.mark_email_unread_rounded,
                        color: user.emailVerified
                            ? colors.success
                            : colors.danger,
                        size: AppSizes.iconMd,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profileEmail,
                            style: TextStyle(
                              fontSize: AppTypography.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.emailVerified
                                ? l10n.profileEmailVerified
                                : l10n.profileEmailNotVerified,
                            style: TextStyle(
                              fontSize: AppTypography.bodyMedium,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!user.emailVerified) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: _PrimaryButton(
                      onPressed:
                      auth.isLoading ? null : _sendVerificationEmail,
                      icon: Icons.outgoing_mail,
                      label: l10n.profileSendVerification,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                    auth.isLoading ? null : _refreshVerificationStatus,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.profileRefreshVerification),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.info,
                      side: BorderSide(
                        color: colors.info.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedMd,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _InfoTile(
            icon: Icons.login_rounded,
            label: l10n.profileLoginMethod,
            value: providers,
          ),

          _InfoTile(
            icon: Icons.event_available_rounded,
            label: l10n.profileCreatedAt,
            value: _formatDate(context, user.createdAt, unknown),
          ),

          _InfoTile(
            icon: Icons.history_rounded,
            label: l10n.profileLastSignIn,
            value: _formatDate(context, user.lastSignInAt, unknown),
          ),

          _buildDivider(context, colors),

          Text(
            l10n.profileSyncSection,
            style: TextStyle(
              fontSize: AppTypography.titleMedium,
              fontWeight: FontWeight.w700,
              color: colors.info,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          _buildCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncStatus,
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    color: colors.textSecondary,
                    height: AppTypography.bodyHeight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: sync.isSyncing ? null : sync.syncNow,
                    icon: sync.isSyncing
                        ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.info,
                      ),
                    )
                        : const Icon(Icons.sync_rounded),
                    label: Text(l10n.profileSyncNow),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.info,
                      side: BorderSide(
                        color: colors.info.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedMd,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDivider(context, colors),

          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: colors.danger,
            ),
            onPressed: auth.isLoading ? null : () => _deleteAccount(user),
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(l10n.profileDeleteAccount),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required Widget child,
  }) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.roundedXl,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDivider(BuildContext context, AppColors colors) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colors.divider,
            Colors.transparent,
          ],
        ),
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
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: AppRadius.roundedSm,
            ),
            child: Icon(
              icon,
              size: AppSizes.iconSm,
              color: colors.info,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.labelLarge,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDisabled = onPressed == null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.roundedMd,
        gradient: isDisabled
            ? null
            : LinearGradient(
          colors: [
            colors.info,
            colors.info.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: isDisabled ? colors.border : null,
        boxShadow: isDisabled
            ? null
            : [
          BoxShadow(
            color: colors.info.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.roundedMd,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppSizes.iconSm, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTypography.bodyLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}