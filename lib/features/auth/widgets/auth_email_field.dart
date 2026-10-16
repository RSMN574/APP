import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: l10n.authEmail,
        prefixIcon: const Icon(Icons.alternate_email),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
