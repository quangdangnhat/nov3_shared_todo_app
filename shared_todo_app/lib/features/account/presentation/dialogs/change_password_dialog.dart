// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/account/presentation/widgets/password_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/account_service.dart';
// Assicurati che l'import del widget PasswordTextField sia corretto:

Future<void> showChangePasswordDialog(
  BuildContext context, {
  required AccountService accountService,
}) async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null || user.email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No logged in user.')),
    );
    return;
  }

  await showDialog(
    context: context,
    builder: (_) => _ChangePasswordDialog(accountService: accountService),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  final AccountService accountService;

  const _ChangePasswordDialog({super.key, required this.accountService});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Stati per la visibilità delle password
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleSave() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match.'),
        ),
      );
      return;
    }

    final confirm = await _confirmAction(
      'Change password',
      'Are you sure you want to change your password?',
    );

    if (!confirm) return;

    try {
      // Nota: AccountService dovrebbe gestire anche la verifica della vecchia password
      // se Supabase non lo fa automaticamente nel metodo update.
      await widget.accountService.updatePassword(newPassword);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
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
    return AlertDialog(
      title: const Text('Edit password'),
      // backgroundColor: isDark ? Colors.grey[900] : Colors.white, // Opzionale: forza colore se il tema non lo fa
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordTextField(
              controller: _currentPasswordController,
              label: 'Current password',
              isObscure: _obscureCurrent,
              onToggleVisibility: () {
                setState(() {
                  _obscureCurrent = !_obscureCurrent;
                });
              },
            ),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: _newPasswordController,
              label: 'New password',
              isObscure: _obscureNew,
              onToggleVisibility: () {
                setState(() {
                  _obscureNew = !_obscureNew;
                });
              },
            ),
            const SizedBox(height: 12),
            PasswordTextField(
              controller: _confirmPasswordController,
              label: 'Confirm new password',
              isObscure: _obscureConfirm,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
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
