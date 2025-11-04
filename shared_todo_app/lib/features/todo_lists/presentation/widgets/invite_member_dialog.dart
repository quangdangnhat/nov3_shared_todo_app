import 'package:flutter/material.dart';
import '../../../../data/repositories/invitation_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Dialog per invitare un nuovo membro alla lista.
class InviteMemberDialog extends StatefulWidget {
  final String todoListId;

  const InviteMemberDialog({super.key, required this.todoListId});

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _invitationRepo = InvitationRepository();
  final _roles = ['admin', 'collaborator'];
  String _selectedRole = 'collaborator';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _invitationRepo.inviteUserToList(
        todoListId: widget.todoListId,
        email: _emailController.text.trim(),
        role: _selectedRole,
      );
      
      // Se l'invito ha successo, chiudi il dialog e ritorna 'true'
      if (mounted) {
         Navigator.of(context).pop(true); 
      }

    } catch (error) {
       // Se fallisce, mostra l'errore in questo dialog
       if (mounted) {
         showErrorSnackBar(context, message: error.toString().replaceFirst("Exception: ", ""));
       }
    } finally {
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Member'),
      content: Form(
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
                if (value == null || value.trim().isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: _roles.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value[0].toUpperCase() + value.substring(1)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedRole = newValue!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvite,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Invite'),
        ),
      ],
    );
  }
}
