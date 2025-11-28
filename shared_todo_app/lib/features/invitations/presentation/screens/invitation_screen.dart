// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/invitation.dart';
import '../../../../data/repositories/invitation_repository.dart';

// --- MODELLO DI SUPPORTO PER LE NOTIFICHE ---
class AppNotification {
  final String id;
  final String title;
  final String? taskId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    this.taskId,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      taskId: map['task_id'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
    );
  }
}

/// Widget bottone campanella + Logica Dialog (SINGLETON)
class InvitationsNotificationButton extends StatelessWidget {
  // 1. REPOSITORY & CLIENT STATICI
  static final InvitationRepository _invitationRepo = InvitationRepository();
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 2. MEMORIA GLOBALE STATICA
  static final Set<String> _hiddenInvitationIds = {};
  static final Set<String> _hiddenNotificationIds = {};

  // 3. NOTIFIER PER AGGIORNAMENTO ISTANTANEO DEL BADGE (FIX NUMERO)
  // Questo permette al bottone di ricostruirsi subito quando nascondiamo qualcosa localmente
  static final ValueNotifier<int> _uiUpdateNotifier = ValueNotifier(0);

  const InvitationsNotificationButton({super.key});

  /// Metodo helper per forzare l'aggiornamento UI
  static void refreshBadge() {
    _uiUpdateNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    // Avvolgiamo tutto in un ValueListenableBuilder per reagire alle modifiche locali
    return ValueListenableBuilder<int>(
      valueListenable: _uiUpdateNotifier,
      builder: (context, _, __) {
        return StreamBuilder<List<Invitation>>(
          stream: _invitationRepo.getPendingInvitationsStream(),
          builder: (context, invSnapshot) {
            final invitations = invSnapshot.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('is_read', false)
                  .order('created_at'),
              builder: (context, notifSnapshot) {
                final rawNotifications = notifSnapshot.data ?? [];

                // Calcolo conteggi filtrati (escludendo quelli nascosti localmente)
                final validInvitationsCount = invitations
                    .where((i) => !_hiddenInvitationIds.contains(i.id))
                    .length;

                final validNotificationsCount = rawNotifications
                    .where((n) => !_hiddenNotificationIds.contains(n['id']))
                    .length;

                final totalCount =
                    validInvitationsCount + validNotificationsCount;

                return IconButton(
                  tooltip: 'Notifications',
                  icon: Badge(
                    label: totalCount > 0 ? Text('$totalCount') : null,
                    isLabelVisible: totalCount > 0,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    child: Icon(
                      totalCount > 0
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
        child: const InvitationsPanel(
            key: ValueKey('singleton_notifications_panel')),
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
  final Set<String> _loadingIds = {};

  // --- GESTIONE INVITI ---
  Future<void> _handleInvitation(Invitation invitation, bool accept) async {
    if (_loadingIds.contains(invitation.id)) return;
    setState(() => _loadingIds.add(invitation.id));

    try {
      await InvitationsNotificationButton._invitationRepo
          .respondToInvitation(invitation.id, accept);

      if (mounted) {
        showSuccessSnackBar(
          context,
          message: 'Invitation ${accept ? 'accepted' : 'declined'}',
        );

        // Aggiorna lista nera e notifica il badge
        InvitationsNotificationButton._hiddenInvitationIds.add(invitation.id);
        InvitationsNotificationButton.refreshBadge();

        // Ridisegna il pannello per nascondere l'elemento
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, message: 'Error: ${error.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(invitation.id));
    }
  }

  // --- GESTIONE NOTIFICHE ---
  Future<void> _handleNotificationRead(AppNotification notification) async {
    if (_loadingIds.contains(notification.id)) return;
    setState(() => _loadingIds.add(notification.id));

    try {
      // Aggiorna DB
      await InvitationsNotificationButton._supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notification.id);

      if (mounted) {
        // Aggiorna lista nera e notifica il badge
        InvitationsNotificationButton._hiddenNotificationIds
            .add(notification.id);
        InvitationsNotificationButton.refreshBadge();

        // Ridisegna il pannello per nascondere l'elemento
        setState(() {});
      }
    } catch (e) {
      debugPrint("Errore notifica: $e");
    } finally {
      if (mounted) setState(() => _loadingIds.remove(notification.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.6,
        maxWidth: 400,
        minWidth: 300,
        minHeight: 200,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.notifications,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Notifications',
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

            // LISTA UNIFICATA
            Flexible(
              child: StreamBuilder<List<Invitation>>(
                stream: InvitationsNotificationButton._invitationRepo
                    .getPendingInvitationsStream(),
                builder: (context, invSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: InvitationsNotificationButton._supabase
                        .from('notifications')
                        .stream(primaryKey: ['id'])
                        .eq('is_read', false)
                        .order('created_at'),
                    builder: (context, notifSnapshot) {
                      if (invSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          notifSnapshot.connectionState ==
                              ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 1. Converti e Filtra Inviti
                      final invitations = (invSnapshot.data ?? [])
                          .where((i) => !InvitationsNotificationButton
                              ._hiddenInvitationIds
                              .contains(i.id))
                          .toList();

                      // 2. Converti e Filtra Notifiche
                      final notifications = (notifSnapshot.data ?? [])
                          .map((map) => AppNotification.fromMap(map))
                          .where((n) => !InvitationsNotificationButton
                              ._hiddenNotificationIds
                              .contains(n.id))
                          .toList();

                      // 3. Unisci tutto
                      final List<dynamic> allItems = [
                        ...invitations,
                        ...notifications
                      ];

                      // 4. Ordina per data
                      allItems.sort((a, b) {
                        DateTime dateA = a is Invitation
                            ? a.createdAt
                            : (a as AppNotification).createdAt;
                        DateTime dateB = b is Invitation
                            ? b.createdAt
                            : (b as AppNotification).createdAt;
                        return dateB.compareTo(dateA);
                      });

                      // --- FIX: RIMOSSO IL BLOCCO DI AUTO-CLOSE AGGRESSIVO ---
                      // Mostriamo invece l'Empty State se la lista è vuota
                      if (allItems.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(24),
                        shrinkWrap: true,
                        itemCount: allItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = allItems[index];

                          if (item is Invitation) {
                            return _InvitationCard(
                              key: ValueKey(item.id),
                              invitation: item,
                              isLoading: _loadingIds.contains(item.id),
                              onAccept: () => _handleInvitation(item, true),
                              onDecline: () => _handleInvitation(item, false),
                            );
                          } else if (item is AppNotification) {
                            return _NotificationCard(
                              key: ValueKey(item.id),
                              notification: item,
                              isLoading: _loadingIds.contains(item.id),
                              onDismiss: () => _handleNotificationRead(item),
                            );
                          }
                          return const SizedBox();
                        },
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.done_all, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No new notifications', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ... Le classi _InvitationCard e _NotificationCard restano identiche al codice precedente ...
// Copiale dal messaggio precedente se non le hai salvate, o lasciale se sono nello stesso file.
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
              const Icon(Icons.group_add, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Group Invitation',
                  style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            invitation.todoListTitle ?? 'Unknown List',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Invited by: ${invitation.invitedByUserEmail ?? 'Unknown'}',
            style: Theme.of(context).textTheme.bodySmall,
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
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
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

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isLoading;
  final VoidCallback onDismiss;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.isLoading,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on,
                color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nearby Task',
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'You are in the radius area.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: colorScheme.primary,
              tooltip: 'Mark as read',
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
