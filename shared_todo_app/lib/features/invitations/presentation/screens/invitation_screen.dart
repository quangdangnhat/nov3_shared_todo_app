import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/router/app_router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/invitation.dart';
import '../../../../data/repositories/invitation_repository.dart';

/// Schermata che mostra gli inviti in sospeso per l'utente corrente.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final InvitationRepository _invitationRepo = InvitationRepository();
  
  // --- CORREZIONE: Rimosso 'final' ---
  // Questo permette alla variabile di essere riassegnata in setState
  late Stream<List<Invitation>> _invitationsStream;
  // --- FINE CORREZIONE ---
  
  // Set per tenere traccia degli inviti in corso di elaborazione
  final Set<String> _loadingInvitations = {};

  @override
  void initState() {
    super.initState();
    // Inizializza lo stream
    _invitationsStream = _invitationRepo.getPendingInvitationsStream();
  }

  /// Gestisce la risposta (accetta o rifiuta) a un invito.
  Future<void> _handleResponse(Invitation invitation, bool accept) async {
    // Impedisci doppi click
    if (_loadingInvitations.contains(invitation.id)) return;

    if (mounted) {
      setState(() {
        _loadingInvitations.add(invitation.id);
      });
    }

    try {
      // Chiama il repository per rispondere all'invito
      await _invitationRepo.respondToInvitation(invitation.id, accept);
      
      if (mounted) {
        showSuccessSnackBar(context, 
          message: 'Invitation ${accept ? 'accepted' : 'declined'} successfully'
        );
      }
      
      // Questa logica (che prima falliva) ora funzionerà,
      // forzando il refresh dello stream.
      if (mounted) {
        setState(() {
          _invitationsStream = _invitationRepo.getPendingInvitationsStream();
        });
      }

    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, 
          message: 'Failed to respond: ${error.toString().replaceFirst("Exception: ", "")}'
        );
      }
    } finally {
      // Assicurati di rimuovere l'ID dal set di caricamento
      if (mounted) {
        setState(() {
          _loadingInvitations.remove(invitation.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Invitations'),
        // Aggiunge un back button per tornare alla pagina precedente (es. Home)
        leading: BackButton(
          onPressed: () {
            // Usa GoRouter per tornare alla home
            context.goNamed(AppRouter.home);
          },
        ),
      ),
      body: StreamBuilder<List<Invitation>>(
        stream: _invitationsStream, // Ascolta lo stream
        builder: (context, snapshot) {
          // Stato di caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Stato di errore
          if (snapshot.hasError) {
            debugPrint('Error loading invitations: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading invitations: ${snapshot.error}'),
              ),
            );
          }

          final invitations = snapshot.data;

          // Stato vuoto (nessun invito)
          if (invitations == null || invitations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "You have no pending invitations.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          // Mostra la lista degli inviti
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final bool isLoading = _loadingInvitations.contains(invitation.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invitation to join list:', 
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        // Mostra il titolo della lista (se c'è), altrimenti l'ID
                        invitation.todoListTitle ?? invitation.todoListId, 
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'You have been invited as an ',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                          children: [
                            TextSpan(
                              text: invitation.role, // Mostra il ruolo
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pulsanti di Azione
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Mostra un loader o i pulsanti
                          if (isLoading)
                            const CircularProgressIndicator()
                          else ...[
                            TextButton(
                              onPressed: () => _handleResponse(invitation, false), // Rifiuta
                              child: const Text('Decline'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _handleResponse(invitation, true), // Accetta
                              child: const Text('Accept'),
                            ),
                          ],
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}