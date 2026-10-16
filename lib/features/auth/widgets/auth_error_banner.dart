import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/models/auth_failure.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.error});

  final AuthFailureCode error;

  String _message(AppLocalizations l10n) {
    return switch (error) {
      AuthFailureCode.invalidEmail => l10n.authErrorInvalidEmail,
      AuthFailureCode.userDisabled => l10n.authErrorUserDisabled,
      AuthFailureCode.userNotFound => l10n.authErrorInvalidCredentials,
      AuthFailureCode.wrongPassword => l10n.authErrorInvalidCredentials,
      AuthFailureCode.emailAlreadyInUse => l10n.authErrorEmailInUse,
      AuthFailureCode.weakPassword => l10n.authErrorWeakPassword,
      AuthFailureCode.operationNotAllowed => l10n.authErrorNotEnabled,
      AuthFailureCode.tooManyRequests => l10n.authErrorTooManyRequests,
      AuthFailureCode.networkRequestFailed => l10n.authErrorNetwork,
      AuthFailureCode.requiresRecentLogin => l10n.authErrorRecentLogin,
      AuthFailureCode.storageFailed => l10n.authErrorStorage,
      AuthFailureCode.unavailable => l10n.authErrorUnavailable,
      AuthFailureCode.unknown => l10n.authErrorUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _message(AppLocalizations.of(context)!),
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
