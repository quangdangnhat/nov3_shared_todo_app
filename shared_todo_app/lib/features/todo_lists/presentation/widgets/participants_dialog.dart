import 'package:flutter/material.dart';
import '../../../../data/models/participant.dart';
import '../../../../data/repositories/participant_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/confirmation_dialog.dart'; // Importa il dialog di conferma
import 'manage_members_dialog.dart';

/// Dialog per visualizzare i partecipanti e invitare nuovi membri.
class ParticipantsDialog extends StatefulWidget {
  final String todoListId;
  final String todoListTitle;
  final String currentUserId; // ID dell'utente che sta guardando
  final String currentUserRole; // Ruolo dell'utente che sta guardando
  final VoidCallback onInvitationSent;
  final VoidCallback onParticipantsChanged; // Callback per forzare refresh

  const ParticipantsDialog({
    super.key,
    required this.todoListId,
    required this.todoListTitle,
    required this.currentUserId,
    required this.currentUserRole,
    required this.onInvitationSent,
    required this.onParticipantsChanged,
  });

  @override
  State<ParticipantsDialog> createState() => _ParticipantsDialogState();
}

class _ParticipantsDialogState extends State<ParticipantsDialog> {
  final ParticipantRepository _participantRepo = ParticipantRepository();
  late Future<List<Participant>> _participantsFuture;
  bool _isLoadingAction = false; // Stato di caricamento per le azioni

  @override
  void initState() {
    super.initState();
    _participantsFuture = _participantRepo.getParticipants(widget.todoListId);
  }

  // Ricarica la lista dei partecipanti
  void _refreshParticipants() {
    if (!mounted) return;
    setState(() {
      _participantsFuture = _participantRepo.getParticipants(widget.todoListId);
    });
  }

  // Apre il sub-dialog per invitare un nuovo membro
  void _openInviteDialog(BuildContext parentContext) {
    showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) =>
          ManageMembersDialog(todoListId: widget.todoListId),
    ).then((invitationSent) {
      if (invitationSent == true) {
        widget.onInvitationSent();
      }
    });
  }

  // Mostra dialog di conferma prima di rimuovere un utente
  void _showDeleteParticipantConfirmation(Participant participantToRemove) {
    if (participantToRemove.userId == widget.currentUserId) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ConfirmationDialog(
          title: 'Remove Participant?',
          content:
              'Are you sure you want to remove ${participantToRemove.username} (${participantToRemove.email}) from this list?',
          confirmText: 'Remove',
          onConfirm: () => _handleRemoveParticipant(participantToRemove),
        );
      },
    );
  }

  // Gestisce l'effettiva rimozione
  Future<void> _handleRemoveParticipant(Participant participantToRemove) async {
    if (!mounted) return;
    setState(() => _isLoadingAction = true);
    try {
      await _participantRepo.removeParticipant(
        todoListId: participantToRemove.todoListId,
        userIdToRemove: participantToRemove.userId,
      );

      if (mounted) {
        showSuccessSnackBar(context,
            message: '${participantToRemove.username} removed.');
        _refreshParticipants(); // Ricarica la lista nel dialog
        widget.onParticipantsChanged(); // Notifica la schermata home
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst("Exception: ", "");
        if (errorMessage.contains('permission denied') ||
            errorMessage.contains('violates row-level security')) {
          errorMessage =
              "You do not have permission to remove this user (e.g., they might be an admin).";
        }
        showErrorSnackBar(context, message: errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserAdmin = widget.currentUserRole == 'admin';

    return FutureBuilder<List<Participant>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        // Stato di Caricamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator())),
          );
        }

        // Stato di Errore
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content:
                Text(snapshot.error.toString().replaceFirst("Exception: ", "")),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close')),
            ],
          );
        }

        // Stato di Successo
        final participants = snapshot.data ?? [];

        return AlertDialog(
          title: Text('Participants (${participants.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingAction
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      // --- DEFINIZIONE CORRETTA ---
                      // Assicurati che il tuo codice locale abbia 'participant'
                      // scritto correttamente qui.
                      final participant = participants[index];
                      // --- FINE ---
                      final bool isParticipantAdmin =
                          participant.role == 'admin';

                      final bool canRemove = isCurrentUserAdmin &&
                          participant.userId != widget.currentUserId &&
                          !isParticipantAdmin;

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(participant.username.isNotEmpty
                              ? participant.username[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(participant.username),
                        subtitle: Text(participant.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Chip Ruolo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isParticipantAdmin
                                        ? Colors.blue
                                        : Colors.grey)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                participant.role,
                                style: TextStyle(
                                  color: (isParticipantAdmin
                                          ? Colors.blue
                                          : Colors.grey)
                                      .shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            // Pulsante Rimuovi (condizionale)
                            if (canRemove)
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.red[400]),
                                tooltip: 'Remove ${participant.username}',
                                onPressed: () =>
                                    _showDeleteParticipantConfirmation(
                                        participant),
                              )
                            else
                              // Spacer per allineare i chip
                              const SizedBox(width: 48),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            // Pulsante Invita (solo per admin)
            if (isCurrentUserAdmin)
              TextButton.icon(
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Invite'),
                onPressed: () {
                  _openInviteDialog(context);
                },
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
