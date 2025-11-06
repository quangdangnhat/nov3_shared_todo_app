import 'package:flutter/material.dart';
import '../../../../data/models/participant.dart';
import '../../../../data/repositories/participant_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'invite_member_dialog.dart'; // Importa il dialog di invito

/// Dialog per visualizzare i partecipanti e invitare nuovi membri.
class ParticipantsDialog extends StatefulWidget {
  final String todoListId;
  final String todoListTitle;
  // Aggiungiamo un callback per notificare la schermata principale che un invito è stato inviato
  final VoidCallback onInvitationSent;

  const ParticipantsDialog({
    super.key,
    required this.todoListId,
    required this.todoListTitle,
    required this.onInvitationSent,
  });

  @override
  State<ParticipantsDialog> createState() => _ParticipantsDialogState();
}

class _ParticipantsDialogState extends State<ParticipantsDialog> {
  final ParticipantRepository _participantRepo = ParticipantRepository();
  late Future<List<Participant>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    // Carica i partecipanti quando il dialog viene inizializzato
    _participantsFuture = _participantRepo.getParticipants(widget.todoListId);
  }

  // Apre il sub-dialog per invitare un nuovo membro
  void _openInviteDialog(BuildContext parentContext) {
    showDialog<bool>(
      context: parentContext, // Usa il contesto del ParticipantsDialog
      builder: (dialogContext) =>
          InviteMemberDialog(todoListId: widget.todoListId),
    ).then((invitationSent) {
      // Se l'invito è stato inviato con successo (restituisce true)
      if (invitationSent == true) {
        // Chiama la callback per notificare la schermata precedente
        widget.onInvitationSent();
      }
      // Nota: non aggiorniamo la lista partecipanti qui
      // perché l'invito è solo "inviato", non ancora "accettato".
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usiamo un FutureBuilder per gestire il caricamento dei dati
    return FutureBuilder<List<Participant>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        // Stato di Caricamento
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Stato di Errore
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(
              snapshot.error.toString().replaceFirst("Exception: ", ""),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        }

        // Stato di Successo
        final participants = snapshot.data ?? [];

        return AlertDialog(
          title: Text('Participants (${participants.length})'),
          content: SizedBox(
            width: double.maxFinite, // Prende la larghezza massima del dialog
            // Usa ListView.builder se la lista può essere lunga
            child: ListView.builder(
              shrinkWrap: true, // Adatta l'altezza al contenuto
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final participant = participants[index];
                final bool isAdmin = participant.role == 'admin';
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      participant.username.isNotEmpty
                          ? participant.username[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(participant.username),
                  subtitle: Text(participant.email),
                  // Mostra un "chip" per il ruolo
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isAdmin ? Colors.blue : Colors.grey).withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      participant.role,
                      style: TextStyle(
                        color: (isAdmin ? Colors.blue : Colors.grey).shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            // Pulsante per invitare NUOVI membri
            TextButton.icon(
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Invite'),
              onPressed: () {
                // Chiudi questo dialog e apri quello di invito
                Navigator.of(context).pop(); // Chiude il ParticipantsDialog
                _openInviteDialog(context); // Apre l'InviteMemberDialog
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
