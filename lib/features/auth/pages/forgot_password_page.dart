import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../const/app_colors.dart';
import '../../../const/app_design_tokens.dart';
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
    final colors = context.appColors;

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
              const SizedBox(height: AppSpacing.lg),
            ],
            if (provider.passwordResetSent) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  borderRadius: AppRadius.roundedLg,
                  border: Border.all(
                    color: colors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.success,
                      size: AppSizes.iconMd,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.authResetEmailSent,
                        style: TextStyle(
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AuthEmailField(
              controller: _emailController,
              validator: (value) => _validateEmail(value, l10n),
            ),
            const SizedBox(height: AppSpacing.xl),
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
        child: Text(
          l10n.authBackToLogin,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.info,
          ),
        ),
      ),
    );
  }
}