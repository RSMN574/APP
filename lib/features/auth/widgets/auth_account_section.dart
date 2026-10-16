import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../state/auth_provider.dart';
import 'auth_error_banner.dart';

class AuthAccountSection extends StatelessWidget {
  const AuthAccountSection({super.key});

  Future<void> _signOut(BuildContext context) async {
    final succeeded = await context.read<AuthProvider>().signOut();
    if (!context.mounted || succeeded) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.authErrorSignOut)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final provider = context.watch<AuthProvider>();
    final user = provider.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user?.photoURL == null
                      ? null
                      : NetworkImage(user!.photoURL!),
                  child: user?.photoURL != null
                      ? null
                      : Icon(
                          user == null ? Icons.person_outline : Icons.person,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ??
                            user?.email ??
                            l10n.authGuestAccount,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        user == null
                            ? l10n.authGuestDescription
                            : user.emailVerified
                                ? l10n.authEmailVerified
                                : l10n.authEmailNotVerified,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (provider.isLoading)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 12),
              AuthErrorBanner(error: provider.error!),
            ],
            const SizedBox(height: 12),
            if (user == null)
              OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => Navigator.of(context).pushNamed('/auth/login'),
                icon: const Icon(Icons.login),
                label: Text(l10n.authLoginOrRegister),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => Navigator.of(context).pushNamed('/auth/profile'),
                icon: const Icon(Icons.manage_accounts),
                label: Text(l10n.profileViewProfile),
              ),
              OutlinedButton.icon(
                onPressed: provider.isLoading ? null : () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: Text(l10n.authSignOut),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
