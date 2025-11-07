import 'package:flutter/material.dart';

class TodoListDetailHeader extends StatelessWidget {
  final bool isRootFolder;
  final bool isMobile;
  final String title;
  final VoidCallback onBackTap;
  final VoidCallback onManageTap; // Vecchia funzione per gestire/invitare
  final VoidCallback onInviteTap; // NUOVA funzione per invitare direttamente

  const TodoListDetailHeader({
    super.key,
    required this.isRootFolder,
    required this.isMobile,
    required this.title,
    required this.onBackTap,
    required this.onManageTap,
    required this.onInviteTap, // NUOVO PARAMETRO
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Leading button: Menu (mobile, root) o Back (desktop, o mobile, subfolder)
          if (isMobile && isRootFolder)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            )
          else if (!isRootFolder)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Indietro',
              onPressed: onBackTap,
            ),

          if (isRootFolder && isMobile) const SizedBox(width: 8),

          // Titolo
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Actions
          if (isRootFolder) ...[
            // 1. NUOVO PULSANTE: Invita Utente (apre il form diretto)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Invita Utente',
              onPressed: onInviteTap, // Usa la nuova callback
            ),
            // 2. VECCHIO PULSANTE: Gestisci Membri (apre la lista)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: 'Gestisci Membri',
              onPressed: onManageTap, // Usa la callback originale (rinominata)
            ),
          ],
        ],
      ),
    );
  }
}
