import 'package:flutter/material.dart';

/// I due FloatingActionButton per la creazione di folder e task.
/// Questi pulsanti sono visibili solo se l'utente corrente è un 'admin'.
class DetailActionButtons extends StatelessWidget {
  final VoidCallback onNewFolder;
  final VoidCallback onNewTask;
  final bool isMobile;
  // --- AGGIUNTO ---
  // Aggiungiamo il ruolo dell'utente per decidere se mostrare i pulsanti
  final String currentUserRole;
  // --- FINE ---

  const DetailActionButtons({
    super.key,
    required this.onNewFolder,
    required this.onNewTask,
    required this.isMobile,
    required this.currentUserRole, // --- AGGIUNTO ---
  });

  @override
  Widget build(BuildContext context) {
    // --- AGGIUNTA LOGICA PERMESSI ---
    // Se l'utente non è un 'admin', non mostrare nulla
    if (currentUserRole != 'admin') {
      // Ritorna un widget vuoto che non occupa spazio
      return const SizedBox.shrink();
    }
    // --- FINE ---

    // Se l'utente è admin, mostra i pulsanti come prima
    if (isMobile) {
      // Layout per mobile: Colonna di FAB
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'new-folder-fab',
            onPressed: onNewFolder,
            label: const Text('New Folder'),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'new-task-fab',
            onPressed: onNewTask,
            label: const Text('New Task'),
            icon: const Icon(Icons.add_task_outlined),
          ),
        ],
      );
    } else {
      // Layout per desktop/tablet: Riga di FAB
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'new-folder-fab',
            onPressed: onNewFolder,
            label: const Text('New Folder'),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'new-task-fab',
            onPressed: onNewTask,
            label: const Text('New Task'),
            icon: const Icon(Icons.add_task_outlined),
          ),
        ],
      );
    }
  }
}
