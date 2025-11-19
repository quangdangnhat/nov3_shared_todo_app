import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/auth/presentation/domain/validators/auth_validators.dart';

class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String
      label; // Aggiunto per permettere testi diversi (New, Current, Confirm)
  final bool isObscure;
  final VoidCallback onToggleVisibility;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label, // Ora è richiesto
    required this.isObscure,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica tema richiesto
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      // Usa il validatore se necessario, assicurati che AuthValidators esista nel tuo progetto
      validator: AuthValidators.validatePassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          // Adatta il colore in base al tema se necessario
          color: isDark ? theme.colorScheme.primary : theme.primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        // Fallback sicuro per il colore di riempimento
        fillColor: isDark
            ? Colors.grey[800]
            : theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
