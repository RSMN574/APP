import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.validator,
    required this.label,
    this.confirm = false,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final String label;
  final bool confirm;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      textInputAction:
          widget.confirm ? TextInputAction.done : TextInputAction.next,
      autofillHints: widget.confirm
          ? const [AutofillHints.newPassword]
          : const [AutofillHints.password],
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscureText ? l10n.authShowPassword : l10n.authHidePassword,
          onPressed: () => setState(() => _obscureText = !_obscureText),
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
