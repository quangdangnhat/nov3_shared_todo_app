import 'package:flutter/material.dart';

/// Header personalizzato per la schermata di dettaglio.
class TodoListDetailHeader extends StatelessWidget {
  final bool isMobile;
  final bool isRootFolder;
  final String title;
  final VoidCallback onMenuPressed;
  final VoidCallback onBackPressed;
  final VoidCallback onInvitePressed;

  const TodoListDetailHeader({
    super.key,
    required this.isMobile,
    required this.isRootFolder,
    required this.title,
    required this.onMenuPressed,
    required this.onBackPressed,
    required this.onInvitePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Leading button
          if (isMobile && isRootFolder)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
              tooltip: 'Menu',
            )
          else if (!isMobile)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: onBackPressed,
            )
          else if (isMobile && !isRootFolder)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: onBackPressed,
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
          if (isRootFolder)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Invite Member',
              onPressed: onInvitePressed,
            ),
        ],
      ),
    );
  }
}
