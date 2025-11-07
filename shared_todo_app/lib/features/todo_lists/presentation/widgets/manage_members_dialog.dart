import 'package:flutter/material.dart';
import 'package:shared_todo_app/core/utils/snackbar_utils.dart';
import 'package:shared_todo_app/data/models/participant.dart';
import 'package:shared_todo_app/data/repositories/invitation_repository.dart';
import 'package:shared_todo_app/data/repositories/participant_repository.dart';
import 'package:shared_todo_app/main.dart'; // Per 'supabase'

class ManageMembersDialog extends StatefulWidget {
  final String todoListId;

  const ManageMembersDialog({super.key, required this.todoListId});

  @override
  State<ManageMembersDialog> createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<ManageMembersDialog> {
  // Repository
  final _invitationRepo = InvitationRepository();
  final _participantsRepo = ParticipantRepository();
  final String? _currentUserId = supabase.auth.currentUser?.id;

  // Stato per l'invito
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _roles = ['admin', 'collaborator'];
  String _selectedRole = 'collaborator';
  bool _isInviteLoading = false;

  // Stato per l'eliminazione
  bool _isDeleting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isInviteLoading = true);

    try {
      await _invitationRepo.inviteUserToList(
        todoListId: widget.todoListId,
        email: _emailController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        showSuccessSnackBar(
          context,
          message: 'Invitation sent successfully!',
        );
        _emailController.clear(); // Pulisce il campo dopo l'invio
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

  /// Costruisce il widget 'trailing' per un partecipante nella lista.
  Widget? _buildParticipantTrailing(
      BuildContext dialogContext, Participant participant, String currentUserRole) {
    if (_isDeleting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // L'utente corrente è un admin E il partecipante NON è l'utente corrente
    final bool canRemove = currentUserRole == 'admin' &&
        participant.userId != _currentUserId &&
        participant.role == 'collaborator';

    if (canRemove) {
      return IconButton(
        icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
        tooltip: 'Remove member',
        onPressed: () => _showDeleteParticipantDialog(dialogContext, participant),
      );
    }
    return null; // Nessuna azione
  }

  /// Mostra il dialogo di conferma eliminazione
  void _showDeleteParticipantDialog(
      BuildContext dialogContext, Participant participant) {
    showDialog(
      context: dialogContext, // Usa il contesto del dialogo principale
      builder: (innerDialogContext) {
        return AlertDialog(
          title: const Text('Remove Member'),
          content: Text(
              'Are you sure you want to remove ${participant.username}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(innerDialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                setState(() => _isDeleting = true);
                Navigator.of(innerDialogContext).pop(); // Chiude il mini-dialogo

                try {
                  await _participantsRepo.removeParticipant(
                    todoListId: widget.todoListId,
                    userIdToRemove: participant.userId,
                  );
                  if (mounted) {
                    showSuccessSnackBar(context,
                        message: '${participant.username} removed.');
                  }
                } catch (error) {
                  if (mounted) {
                    showErrorSnackBar(context,
                        message: 'Failed to remove member: $error');
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isDeleting = false);
                  }
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Members'),
      // Usiamo un SingleChildScrollView perché il contenuto può diventare lungo
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400, // Diamo una larghezza fissa per coerenza
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Sezione Lista Partecipanti ---
              Text(
                'Current Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Participant>>(
                // Usiamo il nuovo stream
                stream: _participantsRepo.getParticipantsStream(widget.todoListId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No members found.'));
                  }

                  final participants = snapshot.data!;
                  // Troviamo il ruolo dell'utente corrente
                  final currentUserRole = participants
                      .firstWhere(
                        (p) => p.userId == _currentUserId,
                        orElse: () => Participant(
                          userId: '',
                          email: '',
                          username: '', // Aggiunto per il costruttore
                          role: 'collaborator',
                          todoListId: '',
                        ),
                      )
                      .role;

                  // Usiamo Column invece di ListView per evitare errori di layout
                  return Column(
                    children: participants.map((participant) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person_outline, size: 18),
                        ),
                        title: Text(
                          // Usa username se disponibile, altrimenti email
                          participant.username.isNotEmpty
                              ? participant.username
                              : participant.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          participant.role[0].toUpperCase() +
                              participant.role.substring(1),
                        ),
                        trailing: _buildParticipantTrailing(
                          context, // Passa il contesto del dialogo (builder)
                          participant,
                          currentUserRole,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const Divider(height: 32),

              // --- Sezione Invita Membro ---
              Text(
                'Invite New Member',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
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
                      value: _selectedRole,
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
                    const SizedBox(height: 24),
                    // Pulsante di invito all'interno del form
                    ElevatedButton(
                      onPressed: _isInviteLoading ? null : _sendInvite,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: _isInviteLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Invite'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Un solo pulsante "Close"
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}