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
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    final succeeded = await context.read<AuthProvider>().signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (succeeded && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AuthProvider>();
    final colors = context.appColors;

    return AuthFormLayout(
      title: l10n.authLoginTitle,
      description: l10n.authLoginDescription,
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 錯誤提示橫幅
              if (provider.error != null) ...[
                AuthErrorBanner(error: provider.error!),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 電子郵件輸入框
              AuthEmailField(
                controller: _emailController,
                validator: (value) => _validateEmail(value, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 密碼輸入框
              AuthPasswordField(
                controller: _passwordController,
                label: l10n.authPassword,
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.authValidationPasswordRequired
                    : null,
              ),

              // 忘記密碼按鈕
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.info,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedSm,
                    ),
                  ),
                  child: Text(
                    l10n.authForgotPassword,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTypography.labelLarge,
                      color: colors.info,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 登入按鈕
              AuthSubmitButton(
                label: l10n.authLogin,
                isLoading: provider.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
      footer: Container(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.xs,
          children: [
            Text(
              l10n.authNoAccount,
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
                  builder: (_) => const RegisterPage(),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: colors.info,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedSm,
                ),
              ),
              child: Text(
                l10n.authGoToRegister,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppTypography.labelLarge,
                  color: colors.info,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}