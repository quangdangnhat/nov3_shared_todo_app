import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/account/presentation/widgets/password_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/account_service.dart';

Future<String?> showChangeEmailDialog(
  BuildContext context, {
  required AccountService accountService,
}) async {
  return await showDialog<String>(
    context: context,
    builder: (_) => _ChangeEmailDialog(accountService: accountService),
  );
}

class _ChangeEmailDialog extends StatefulWidget {
  final AccountService accountService;

  const _ChangeEmailDialog({super.key, required this.accountService});

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _newEmailController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  // Aggiunto stato per gestire la visibilità della password
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newEmail = _newEmailController.text.trim();
    final currentPassword = _currentPasswordController.text;

    if (newEmail.isEmpty || currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both fields.'),
        ),
      );
      return;
    }

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('No logged in user');
      }

      // Riesegue il login per sicurezza prima di cambiare dati sensibili
      await Supabase.instance.client.auth.signInWithPassword(
        email: currentUser.email!,
        password: currentPassword,
      );

      await widget.accountService.updateEmail(newEmail);

      if (!mounted) return;
      Navigator.pop(context, newEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // VERIFICA TEMA RICHIESTA
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit email'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo Email (stilizzato per coerenza con PasswordTextField)
            TextField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'New email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  // Usa lo stesso colore primario definito nel tema o logica isDark
                  color:
                      isDark ? theme.colorScheme.primary : theme.primaryColor,
                ),
                filled: true,
                // Fallback sicuro per il colore di riempimento (lo stesso usato in PasswordTextField)
                fillColor: isDark
                    ? Colors.grey[800]
                    : theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // PasswordTextField aggiornato
            PasswordTextField(
              controller: _currentPasswordController,
              label:
                  'Current password', // Parametro label ora passato correttamente
              isObscure:
                  _obscurePassword, // Collegato allo stato locale, non al tema
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
