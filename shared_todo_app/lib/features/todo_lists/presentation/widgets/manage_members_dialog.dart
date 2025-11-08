import 'package:flutter/material.dart';
import '../../../../core/utils/snackbar_utils.dart';
// --- MODIFICA: Rimossi import non più necessari ---
// import '../../../data/models/participant.dart';
// import '../../../main.dart'; // per accedere a supabase
import '../controllers/todo_list_detail_viewmodel.dart';

/// Un dialogo per invitare nuovi membri.
class ManageMembersDialog extends StatefulWidget {
  final TodoListDetailViewModel viewModel;
  final String todoListId;

  const ManageMembersDialog({
    super.key,
    required this.viewModel,
    required this.todoListId,
  });

  @override
  State<ManageMembersDialog> createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<ManageMembersDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _roles = ['admin', 'collaborator'];
  String _selectedRole = 'collaborator';

  bool _isInviteLoading = false;
  // --- MODIFICA: Rimossa mappa _removingStatus ---
  // final Map<String, bool> _removingStatus = {};

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Gestisce l'invio di un invito
  Future<void> _onInvitePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isInviteLoading = true);
    try {
      await widget.viewModel.inviteUser(
        widget.todoListId,
        _emailController.text.trim(),
        _selectedRole,
      );

      _emailController.clear();
      if (mounted) {
        showSuccessSnackBar(context, message: 'Invitation sent successfully!');
        // --- MODIFICA: Chiude il dialog con 'true' per notificare il successo ---
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message: error.toString().replaceFirst("Exception: ", ""),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInviteLoading = false);
      }
    }
  }

  // --- MODIFICA: Rimossa la funzione _onRemovePressed ---
  // Future<void> _onRemovePressed(String participantId) async { ... }

  @override
  Widget build(BuildContext context) {
    // --- MODIFICA: Rimosso currentUserId ---
    // final currentUserId = supabase.auth.currentUser?.id ?? '';

    return AlertDialog(
      // --- MODIFICA: Titolo aggiornato ---
      title: const Text('Invite Member'),
      content:
          // --- MODIFICA: Rimosso SingleChildScrollView e SizedBox ---
          Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'User Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: _roles.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value[0].toUpperCase() + value.substring(1),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedRole = newValue!);
              },
            ),
          ],
        ),
      ),
      // --- MODIFICA: Rimossa tutta la sezione "Current members" ---
      // const SizedBox(height: 24),
      // const Divider(),
      // ... (StreamBuilder rimosso) ...

      actions: [
        TextButton(
          onPressed:
              _isInviteLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isInviteLoading ? null : _onInvitePressed,
          child: _isInviteLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invite'),
        ),
      ],
    );
  }
}
