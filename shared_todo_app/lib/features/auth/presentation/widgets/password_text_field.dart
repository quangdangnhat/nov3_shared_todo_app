// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/auth/presentation/domain/validators/auth_validators.dart';

class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isObscure;
  final VoidCallback onToggleVisibility;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.isObscure,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: theme.colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: AuthValidators.validatePassword,
    );
  }
}
