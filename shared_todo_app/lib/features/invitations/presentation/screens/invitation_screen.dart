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
              count > 0
                  ? Icons.notifications_active
                  : Icons.notifications_outlined,
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
        // La Key qui è corretta per mantenere lo stato
        child: const InvitationsPanel(key: ValueKey('invitations_panel')),
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

  // Set per nascondere immediatamente gli inviti gestiti con successo
  final Set<String> _processedInvitationsIds = {};

  Future<void> _handleResponse(Invitation invitation, bool accept) async {
    if (_loadingInvitations.contains(invitation.id)) return;

    setState(() => _loadingInvitations.add(invitation.id));

    try {
      await _invitationRepo.respondToInvitation(invitation.id, accept);

      if (mounted) {
        showSuccessSnackBar(
          context,
          message: 'Invitation ${accept ? 'accepted' : 'declined'}',
        );

        setState(() {
          _processedInvitationsIds.add(invitation.id);
        });
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

    // --- FIX DEL GLITCH ---
    // Spostiamo il ConstrainedBox FUORI dallo StreamBuilder.
    // In questo modo il Dialog ha subito la dimensione finale e non "salta"
    // quando arrivano i dati.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.6,
        maxWidth: 400,
        // Impostiamo una larghezza minima per evitare che si restringa troppo
        minWidth: 300,
        // Impostiamo un'altezza minima pari a quella che usavi per il loading (200)
        minHeight: 200,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER (Sempre visibile, anche durante il caricamento)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.mail_outline,
                      color: Theme.of(context).colorScheme.primary),
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

            // CONTENUTO DINAMICO
            Flexible(
              child: StreamBuilder<List<Invitation>>(
                stream: _invitationRepo.getPendingInvitationsStream(),
                builder: (context, snapshot) {
                  // STATO LOADING
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    // Non serve più il SizedBox(height: 200) perché il padre
                    // ha già minHeight: 200.
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rawInvitations = snapshot.data ?? [];

                  final visibleInvitations = rawInvitations
                      .where(
                          (inv) => !_processedInvitationsIds.contains(inv.id))
                      .toList();

                  // Auto-chiusura soft
                  if (visibleInvitations.isEmpty &&
                      _processedInvitationsIds.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    });
                  }

                  // STATO LISTA VUOTA O DATI
                  if (visibleInvitations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Rimuoviamo il padding eccessivo per centrarlo meglio nel ConstrainedBox esistente
    return const Center(
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
            const Center(
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side:
                          BorderSide(color: colorScheme.error.withOpacity(0.5)),
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
