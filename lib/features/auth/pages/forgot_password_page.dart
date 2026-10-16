import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../state/auth_provider.dart';
import '../widgets/auth_email_field.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_submit_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return l10n.authValidationEmail;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context
        .read<AuthProvider>()
        .sendPasswordResetEmail(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AuthProvider>();

    return AuthFormLayout(
      title: l10n.authForgotPasswordTitle,
      description: l10n.authForgotPasswordDescription,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.error != null) ...[
              AuthErrorBanner(error: provider.error!),
              const SizedBox(height: 16),
            ],
            if (provider.passwordResetSent) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.authResetEmailSent,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AuthEmailField(
              controller: _emailController,
              validator: (value) => _validateEmail(value, l10n),
            ),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: l10n.authSendResetEmail,
              isLoading: provider.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      footer: TextButton(
        onPressed:
            provider.isLoading ? null : () => Navigator.of(context).pop(),
        child: Text(l10n.authBackToLogin),
      ),
    );
  }
}
