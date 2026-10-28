import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../const/app_colors.dart';
import '../../../const/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../state/auth_provider.dart';
import '../widgets/auth_email_field.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_submit_button.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    final auth = context.read<AuthProvider>();
    final colors = context.appColors;

    final registered = await auth.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || !registered) return;

    final emailSent = await auth.sendEmailVerification();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          emailSent
              ? AppLocalizations.of(context)!.authVerificationSent
              : AppLocalizations.of(context)!.authVerificationSendFailed,
        ),
        backgroundColor: emailSent ? colors.success : colors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedMd,
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AuthProvider>();
    final colors = context.appColors;

    return AuthFormLayout(
      title: l10n.authRegisterTitle,
      description: l10n.authRegisterDescription,
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (provider.error != null) ...[
                AuthErrorBanner(error: provider.error!),
                const SizedBox(height: AppSpacing.lg),
              ],
              AuthEmailField(
                controller: _emailController,
                validator: (value) => _validateEmail(value, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthPasswordField(
                controller: _passwordController,
                label: l10n.authPassword,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return l10n.authValidationPasswordLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthPasswordField(
                controller: _confirmPasswordController,
                label: l10n.authConfirmPassword,
                confirm: true,
                validator: (value) => value != _passwordController.text
                    ? l10n.authValidationPasswordMismatch
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthSubmitButton(
                label: l10n.authRegister,
                isLoading: provider.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.authHaveAccount,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: AppTypography.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: provider.isLoading
                ? null
                : () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const LoginPage(),
              ),
            ),
            child: Text(
              l10n.authLogin,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}