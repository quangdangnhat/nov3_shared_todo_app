// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';

class TodoListDetailHeader extends StatelessWidget {
  final bool isRootFolder;
  final bool isMobile;
  final String title;
  final VoidCallback onBackTap;
  final VoidCallback onManageTap;
  final VoidCallback onInviteTap;

  const TodoListDetailHeader({
    super.key,
    required this.isRootFolder,
    required this.isMobile,
    required this.title,
    required this.onBackTap,
    required this.onManageTap,
    required this.onInviteTap,
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
          // 1. HAMBURGER MENU
          // Visibile SOLO se siamo su Mobile.
          // Su Tablet e Desktop (isMobile = false) questo blocco viene ignorato.
          if (isMobile)
            // 2. FRECCIA INDIETRO
            // Visibile SEMPRE (Desktop, Tablet e Mobile), subito dopo l'eventuale menu.
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Indietro',
              onPressed: onBackTap,
            ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),

          const SizedBox(width: 8),

          // 3. TITOLO
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

          // 4. AZIONI (A DESTRA)
          // Visibili solo se siamo nella root folder
          if (isRootFolder) ...[
            /*
            // Decommenta se vuoi usare l'invito diretto
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Invite User',
              onPressed: onInviteTap,
            ),
            */
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: 'Manage Members',
              onPressed: onManageTap,
            ),
          ],
        ],
      ),
    );
  }
}
