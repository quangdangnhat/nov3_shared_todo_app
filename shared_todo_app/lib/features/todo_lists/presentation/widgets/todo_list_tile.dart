// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../core/utils/date_format_util.dart'; // Assicurati che questo percorso sia corretto

/// Widget per visualizzare una singola riga di TodoList.
class TodoListTile extends StatelessWidget {
  final TodoList list;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete; // Questa callback ora è per "Leave"

  const TodoListTile({
    super.key,
    required this.list,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    // --- Rimosso onViewParticipants ---
  });

  @override
  Widget build(BuildContext context) {
    // Determina se l'utente è admin per questa lista
    final bool isAdmin = list.role == 'admin';

    final roleColor = isAdmin ? Colors.blue : Colors.grey;

    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.only(bottom: 12.0), // Spazio tra le card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 16.0,
        ),
        leading: const Icon(
          Icons.list_alt_rounded,
          size: 40,
          color: Colors.blue,
        ),
        title: Text(
          list.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        // Sottotitolo con descrizione, ruolo e data
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
            // Riga per i metadati (Ruolo e Data)
            Row(
              children: [
                // CHIP PER IL RUOLO
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    list.role, // Mostra il ruolo
                    style: TextStyle(
                      color: roleColor.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // DATA DI CREAZIONE
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  // Usa l'utility di formattazione
                  formatDate(list.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),

        // --- MODIFICA TRAILING ---
        // Opzione "View Participants" rimossa
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'List Options',
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
            // Rimossa logica per 'participants'
          },
          itemBuilder: (BuildContext context) {
            final List<PopupMenuEntry<String>> items = [];

            // Voce "Edit" (Visibile SOLO agli admin)
            if (isAdmin) {
              items.add(
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit List'),
                ),
              );
            }

            // Voce "Leave List" (Visibile a tutti)
            items.add(
              const PopupMenuItem<String>(
                value: 'delete', // 'delete' è la chiave per l'azione 'Leave'
                child: Text('Leave List', style: TextStyle(color: Colors.red)),
              ),
            );

            return items;
          },
        ),

        // --- FINE MODIFICA ---
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
