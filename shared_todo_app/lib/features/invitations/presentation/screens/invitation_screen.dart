import 'package:flutter/material.dart';
import '../../../../config/responsive.dart';
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

  late Stream<List<Invitation>> _invitationsStream;

  // Set per tenere traccia degli inviti in corso di elaborazione
  final Set<String> _loadingInvitations = {};

  @override
  void initState() {
    super.initState();
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
      await _invitationRepo.respondToInvitation(invitation.id, accept);

      if (mounted) {
        showSuccessSnackBar(context,
            message:
                'Invitation ${accept ? 'accepted' : 'declined'} successfully');
      }
      
      // Forza il refresh dello stream
      if (mounted) {
        setState(() {
          _invitationsStream = _invitationRepo.getPendingInvitationsStream();
        });
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context,
            message:
                'Failed to respond: ${error.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingInvitations.remove(invitation.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      children: [
        // Header personalizzato che sostituisce l'AppBar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Hamburger menu SOLO su mobile
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                ),
                const SizedBox(width: 8),
              ],
              // Titolo
              Text(
                'My Invitations',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Contenuto principale
        Expanded(
          child: StreamBuilder<List<Invitation>>(
            stream: _invitationsStream,
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

              // Stato vuoto
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

              // Lista degli inviti
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
                            invitation.todoListTitle ?? '[List Name Not Found]', 
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              text: 'Invited by: ',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: invitation.invitedByUserEmail ?? '[Unknown User]',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: Theme.of(context).textTheme.bodyMedium?.color
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              text: 'As: ',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: invitation.role,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: Theme.of(context).textTheme.bodyMedium?.color
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Pulsanti di Azione
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isLoading)
                                const CircularProgressIndicator()
                              else ...[
                                TextButton(
                                  onPressed: () => _handleResponse(invitation, false),
                                  child: const Text('Decline'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _handleResponse(invitation, true),
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
        ),
      ],
    );
  }
}