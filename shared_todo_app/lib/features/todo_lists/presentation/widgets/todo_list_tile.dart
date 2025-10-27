import 'package:flutter/material.dart';
import '../../../../../../data/models/todo_list.dart';

class TodoListTile extends StatelessWidget {
  final TodoList list;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoListTile({
    super.key,
    required this.list,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // Helper per formattare la data
  String formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/${localDate.month.toString().padLeft(2, '0')}/${localDate.year}';
  }

  // Helper per formattare il ruolo
  String formatRole(String role) {
    if (role == 'admin') return 'Admin';
    if (role == 'collaborator') return 'Collaborator';
    return role; // Gestisce 'Unknown' o altri futuri ruoli
  }

  @override
  Widget build(BuildContext context) {
    // Colore del "chip" del ruolo
    final roleColor = list.role == 'admin' ? Colors.blue : Colors.grey;

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.only(bottom: 12.0), // Spazio tra le card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        leading: const Icon(Icons.list_alt_rounded,
            size: 40, color: Colors.blue),
        title: Text(
          list.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        // --- SOTTOTITOLO MODIFICATO ---
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Descrizione
            Text(
              list.desc ?? 'No description', // Mostra la descrizione
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10), // Spaziatore

            // --- NUOVA RIGA PER I METADATI ---
            Row(
              children: [
                // CHIP PER IL RUOLO
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatRole(list.role),
                    style: TextStyle(
                      color: roleColor.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // DATA DI CREAZIONE
                Icon(Icons.calendar_today,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  formatDate(list.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Il menu a 3 puntini va qui
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
