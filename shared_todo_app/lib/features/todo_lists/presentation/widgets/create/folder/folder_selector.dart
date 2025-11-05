// lib/presentation/widgets/folder/folder_selector.dart

import 'package:flutter/material.dart';
import '../../../../../../data/models/folder.dart';
import '../../../controllers/base_controller.dart';

class FolderSelector extends StatelessWidget {
  final BaseFolderSelectionController controller;
  final ValueChanged<Folder> onFolderSelected;

  const FolderSelector({
    super.key,
    required this.controller,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Folder>>(
      stream: controller.folderStream,
      builder: (context, snapshot) {
        final subFolders = snapshot.data ?? [];
        final isEnabled = controller.selectedTodoList != null;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return PopupMenuButton<Folder>(
          offset: const Offset(0, 50),
          enabled: isEnabled && !isLoading,
          constraints: BoxConstraints(
            minWidth: (MediaQuery.of(context).size.width - 40) / 2,
            maxWidth: (MediaQuery.of(context).size.width - 40) / 2,
          ),
          itemBuilder: (context) => _buildMenuItems(subFolders),
          onSelected: onFolderSelected,
          child: _buildSelectorButton(isEnabled, isLoading),
        );
      },
    );
  }

  Widget _buildSelectorButton(bool isEnabled, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled ? Colors.grey : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isEnabled ? null : Colors.grey[100],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 18,
                  color: isEnabled ? null : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isLoading
                        ? 'Loading...'
                        : controller.selectedFolder?.title ?? 'Select folder',
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.selectedFolder != null
                          ? Colors.white
                          : isEnabled
                              ? Colors.grey
                              : Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 24,
            color: isEnabled && !isLoading ? null : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<Folder>> _buildMenuItems(List<Folder> subFolders) {
    return [
      // Mostra la cartella corrente (dove ci troviamo)
      if (controller.selectedFolder != null)
        PopupMenuItem<Folder>(
          value: controller.selectedFolder,
          child: Row(
            children: [
              const Icon(
                Icons.folder_open,
                size: 18,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '... (${controller.selectedFolder!.title})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

      // Divider se ci sono sottocartelle
      if (controller.selectedFolder != null && subFolders.isNotEmpty)
        const PopupMenuDivider(),

      // Mostra le sottocartelle della cartella corrente
      if (subFolders.isEmpty && controller.selectedFolder != null)
        const PopupMenuItem<Folder>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'No subfolders',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

      // Lista delle sottocartelle
      ...subFolders.map((folder) {
        return PopupMenuItem<Folder>(
          value: folder,
          child: Row(
            children: [
              const Icon(Icons.folder, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder.title,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }
}
