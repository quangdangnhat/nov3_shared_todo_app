import 'package:flutter/material.dart';
import '../../../../../../data/models/folder.dart';
import '../../../../../../data/models/todo_list.dart';
import '../../../controllers/base_controller.dart';
import '../folder/todo_list_selector.dart';
import '../folder/folder_selector.dart';

class FolderSelectionDialog extends StatefulWidget {
  final BaseFolderSelectionController controller;

  const FolderSelectionDialog({super.key, required this.controller});

  @override
  State<FolderSelectionDialog> createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleTodoListSelection(TodoList list) async {
    try {
      await widget.controller.selectTodoList(list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading folders: $e')));
      }
    }
  }

  Future<void> _handleFolderSelection(Folder folder) async {
    try {
      await widget.controller.selectFolder(folder);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting folder: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Folder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose the list and folder for your task',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // TodoList Selector
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return TodoListSelector(
                  controller: widget.controller,
                  searchController: _searchController,
                  onSearchChanged: (query) {
                    widget.controller.updateSearchQuery(query);
                  },
                  onTodoListSelected: _handleTodoListSelection,
                );
              },
            ),

            const SizedBox(height: 12),

            // Folder Selector
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return FolderSelector(
                  controller: widget.controller,
                  onFolderSelected: _handleFolderSelection,
                );
              },
            ),

            const SizedBox(height: 20),

            // Confirm Button
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.controller.selectedFolder != null
                        ? () => Navigator.of(context).pop()
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
