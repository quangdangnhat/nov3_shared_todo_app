import 'package:flutter/material.dart';
import '../../../../data/models/folder.dart';
import '../../../../core/utils/date_format_util.dart';

/// Un widget che visualizza una singola cartella in stile ListTile.
class FolderListTile extends StatelessWidget {
  final Folder folder;
  final String currentUserRole; // Ruolo dell'utente per i permessi
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FolderListTile({
    super.key,
    required this.folder,
    required this.currentUserRole,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Determina se mostrare le opzioni di admin
    final bool isAdmin = currentUserRole == 'admin';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.folder, color: Colors.blue),
        ),
        title: Text(
          folder.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Created: ${formatDate(folder.createdAt)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        // Mostra il menu solo se l'utente è admin
        trailing: isAdmin
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Folder Options',
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null, // Nessun menu per i non-admin
        onTap: onTap,
      ),
    );
  }
}
