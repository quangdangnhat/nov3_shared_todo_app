import 'package:flutter/material.dart';
import '../../../../data/models/participant.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/confirmation_dialog.dart'; // Importa il dialog di conferma
import '../widgets/manage_members_dialog.dart';
import '../controllers/todo_list_detail_viewmodel.dart';

/// Dialog per visualizzare i partecipanti e invitare nuovi membri.
class ParticipantsDialog extends StatefulWidget {
  final String todoListId;
  final String todoListTitle;
  final String currentUserId; // ID dell'utente che sta guardando
  final String currentUserRole; // Ruolo dell'utente che sta guardando
  final VoidCallback onInvitationSent;
  final VoidCallback onParticipantsChanged; // Callback per forzare refresh
  final TodoListDetailViewModel viewModel;

  const ParticipantsDialog({
    super.key,
    required this.todoListId,
    required this.todoListTitle,
    required this.currentUserId,
    required this.currentUserRole,
    required this.onInvitationSent,
    required this.onParticipantsChanged,
    required this.viewModel,
  });

  @override
  State<ParticipantsDialog> createState() => _ParticipantsDialogState();
}

class _ParticipantsDialogState extends State<ParticipantsDialog> {
  final Map<String, bool> _removingStatus = {};

  // Apre il sub-dialog per invitare un nuovo membro
  void _openInviteDialog(BuildContext parentContext) {
    showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => ManageMembersDialog(
        todoListId: widget.todoListId,
        // Passa il viewModel al sub-dialog
        viewModel: widget.viewModel,
      ),
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
          onConfirm: () {
            Navigator.of(dialogContext).pop(); // Chiude il dialog di conferma
            _handleRemoveParticipant(participantToRemove);
          },
        );
      },
    );
  }

  // Gestisce l'effettiva rimozione
  Future<void> _handleRemoveParticipant(Participant participantToRemove) async {
    if (!mounted) return;
    
    setState(() => _removingStatus[participantToRemove.userId] = true);
    
    try {
      // 1. Chiama il ViewModel per la logica di business (rimozione)
      await widget.viewModel.removeParticipant(
        participantId: participantToRemove.userId,
        todoListId: participantToRemove.todoListId,
      );

      // 2. *** FIX PER AGGIORNAMENTO IMMEDIATO ***
      // Forziamo il ViewModel a ricaricare i dati completi con JOIN
      await widget.viewModel.forceParticipantsReload(widget.todoListId);
      // *** FINE FIX ***

      if (mounted) {
        showSuccessSnackBar(
            context, message: '${participantToRemove.username} removed.');
        
        // Non è strettamente necessario, ma lascia la notifica per completezza
        widget.onParticipantsChanged(); 
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
        setState(() => _removingStatus.remove(participantToRemove.userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserAdmin = widget.currentUserRole == 'admin';

    // --- Sostituito FutureBuilder con StreamBuilder (Logica MVVM) ---
    return StreamBuilder<List<Participant>>(
      stream: widget.viewModel
          .participantsStream, // Usa lo stream dal ViewModel
      builder: (context, snapshot) {
        // Stato di Caricamento (ConnectionState.waiting e no data)
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const AlertDialog(
            content: SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator())),
          );
        }

        // Stato di Errore
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(
                snapshot.error.toString().replaceFirst("Exception: ", "")),
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                final bool isParticipantAdmin = participant.role == 'admin';
                final bool isRemoving =
                    _removingStatus[participant.userId] == true;

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
                          color: (isParticipantAdmin ? Colors.blue : Colors.grey)
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
                      // Logica di visualizzazione per il caricamento
                      if (isRemoving)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      // Pulsante Rimuovi (condizionale)
                      else if (canRemove)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: Colors.red[400]),
                          tooltip: 'Remove ${participant.username}',
                          onPressed: () =>
                              _showDeleteParticipantConfirmation(participant),
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
