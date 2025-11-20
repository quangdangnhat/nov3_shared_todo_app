// coverage:ignore-file

import 'package:flutter/material.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/invitation.dart';
import '../../../../data/repositories/invitation_repository.dart';

/// Widget bottone campanella + Logica Dialog
class InvitationsNotificationButton extends StatelessWidget {
  const InvitationsNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Usiamo un'istanza del repo. Assicurati che il tuo repo gestisca bene lo stream.
    // Se il repo è un Singleton, questo va bene.
    final InvitationRepository invitationRepo = InvitationRepository();

    return StreamBuilder<List<Invitation>>(
      stream: invitationRepo.getPendingInvitationsStream(),
      builder: (context, snapshot) {
        final invitations = snapshot.data ?? [];
        final count = invitations.length;

        return IconButton(
          tooltip: 'Notifications',
          icon: Badge(
            label: count > 0 ? Text('$count') : null,
            isLabelVisible: count > 0,
            backgroundColor: Theme.of(context).colorScheme.error,
            child: Icon(
              count > 0 ? Icons.notifications_active : Icons.notifications_outlined,
            ),
          ),
          onPressed: () {
            _showModernInvitationsDialog(context);
          },
        );
      },
    );
  }

  void _showModernInvitationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.all(20),
        elevation: 10,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const InvitationsPanel(),
      ),
    );
  }
}

/// Contenuto del Dialog
class InvitationsPanel extends StatefulWidget {
  const InvitationsPanel({super.key});

  @override
  State<InvitationsPanel> createState() => _InvitationsPanelState();
}

class _InvitationsPanelState extends State<InvitationsPanel> {
  final InvitationRepository _invitationRepo = InvitationRepository();
  
  // Set per tracciare quali inviti stanno caricando (spinner)
  final Set<String> _loadingInvitations = {};
  
  // NUOVO: Set per nascondere immediatamente gli inviti gestiti con successo
  // Questo garantisce il refresh istantaneo della UI anche se lo Stream ritarda
  final Set<String> _processedInvitationsIds = {};

  Future<void> _handleResponse(Invitation invitation, bool accept) async {
    if (_loadingInvitations.contains(invitation.id)) return;

    setState(() => _loadingInvitations.add(invitation.id));

    try {
      // 1. Eseguiamo l'operazione SQL
      await _invitationRepo.respondToInvitation(invitation.id, accept);

      if (mounted) {
        showSuccessSnackBar(
          context,
          message: 'Invitation ${accept ? 'accepted' : 'declined'}',
        );

        // 2. CRUCIALE: Aggiorniamo immediatamente la UI locale
        // Aggiungiamo l'ID alla lista dei "processati" così sparisce subito dalla lista visibile
        setState(() {
          _processedInvitationsIds.add(invitation.id);
        });

        // Opzionale: Se abbiamo gestito tutto, chiudiamo il dialog dopo un istante
        // Nota: Lo facciamo dentro il builder controllando la lunghezza della lista filtrata
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message: 'Error: ${error.toString().replaceFirst("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingInvitations.remove(invitation.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder<List<Invitation>>(
      stream: _invitationRepo.getPendingInvitationsStream(),
      builder: (context, snapshot) {
        // Se lo stream sta caricando inizialmente
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
           return const SizedBox(
             height: 200, 
             child: Center(child: CircularProgressIndicator())
           );
        }

        // Prendiamo i dati grezzi dallo stream
        final rawInvitations = snapshot.data ?? [];

        // 3. FILTRO REALTIME:
        // Mostriamo solo gli inviti che arrivano dallo stream MENO quelli che abbiamo 
        // appena processato con successo in questa sessione del dialog.
        final visibleInvitations = rawInvitations
            .where((inv) => !_processedInvitationsIds.contains(inv.id))
            .toList();

        // Auto-chiusura soft: se non c'è nulla da mostrare ed abbiamo processato qualcosa
        if (visibleInvitations.isEmpty && _processedInvitationsIds.isNotEmpty) {
           // Usiamo un post frame callback per non chiudere durante il build
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted && Navigator.canPop(context)) {
               Navigator.pop(context);
             }
           });
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.6,
            maxWidth: 400,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(Icons.mail_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Invitations',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1),
                
                // Lista
                Flexible(
                  child: visibleInvitations.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          shrinkWrap: true,
                          itemCount: visibleInvitations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final invitation = visibleInvitations[index];
                            return _InvitationCard(
                              key: ValueKey(invitation.id),
                              invitation: invitation,
                              isLoading: _loadingInvitations.contains(invitation.id),
                              onAccept: () => _handleResponse(invitation, true),
                              onDecline: () => _handleResponse(invitation, false),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No pending invitations',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    super.key, 
    required this.invitation,
    required this.isLoading,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invitation.todoListTitle ?? 'Unknown List',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invitation.role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Invited by: ${invitation.invitedByUserEmail ?? 'Unknown'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}