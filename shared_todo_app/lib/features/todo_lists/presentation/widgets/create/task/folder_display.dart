// lib/presentation/widgets/task/folder_display_card.dart

import 'package:flutter/material.dart';
import 'package:shared_todo_app/data/models/todo_list.dart';
import '../../../../../../data/models/folder.dart';

class FolderDisplayCard extends StatelessWidget {
  final TodoList? selectedTodoList;
  final Folder? selectedFolder;
  final VoidCallback onTap;

  const FolderDisplayCard({
    super.key,
    required this.selectedTodoList,
    required this.selectedFolder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedTodoList != null && selectedFolder != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.list,
              color: hasSelection ? Colors.blue[700] : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destination',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    hasSelection
                        ? '${selectedTodoList!.title} / ${selectedFolder!.title}'
                        : 'Select the destination',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: hasSelection ? Colors.black : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
