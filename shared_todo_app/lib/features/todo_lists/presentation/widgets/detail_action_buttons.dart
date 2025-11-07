import 'package:flutter/material.dart';

/// I due FloatingActionButton per la creazione di folder e task.
class DetailActionButtons extends StatelessWidget {
  final VoidCallback onNewFolder;
  final VoidCallback onNewTask;
  final bool isMobile;

  const DetailActionButtons({
    super.key,
    required this.onNewFolder,
    required this.onNewTask,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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