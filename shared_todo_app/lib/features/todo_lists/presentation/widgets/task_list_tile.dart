// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/task.dart';

/// Un widget per visualizzare una singola riga di Task in una lista.
class TaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap; // Per aprire dettagli (futuro)
  final VoidCallback onEdit; // Per modificare
  final VoidCallback onDelete; // Per eliminare
  // Callback per quando lo stato viene cambiato tramite i chip
  final ValueChanged<String> onStatusChanged;
  final String? currentUserRole; // Ruolo dell'utente per i permessi

  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    this.currentUserRole,
  });

  // Helper per ottenere un colore in base alla priorità
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.shade300;
      case 'Medium':
        return Colors.orange.shade300;
      case 'Low':
      default:
        return Colors.green.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determina se mostrare le opzioni di admin
    final bool isAdmin = currentUserRole == 'admin';

    // Determina se il task è scaduto
    final bool isOverdue = task.dueDate.isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        ) &&
        task.status != 'Done';
    final bool isDone = task.status == 'Done';
    final Color? textColor = isDone ? Colors.grey[600] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isOverdue
            ? BorderSide(color: Colors.red.shade200, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        // Aggiunto Padding per separare contenuto e card
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icona Task a sinistra
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4.0,
                    left: 8.0,
                    right: 16.0,
                  ),
                  child: Icon(
                    Icons.assignment_outlined, // NUOVA ICONA
                    color: isDone
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                // Titolo, Sottotitolo (Data, Priorità)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: isOverdue ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yy').format(task.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : Colors.grey[600],
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(/* Chip Priorità (invariato) */),
                        ],
                      ),
                      // Descrizione (se presente)
                      if (task.desc != null && task.desc!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            task.desc!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // Menu 3 puntini a destra
                if (isAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    tooltip: "Task Options",
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
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Wrap(
                // Wrap per andare a capo se non c'è spazio
                spacing: 8.0, // Spazio orizzontale
                runSpacing: 4.0, // Spazio verticale se va a capo
                children: ['To Do', 'In Progress', 'Done'].map((status) {
                  final bool isSelected = task.status == status;
                  return FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      // Chiama la callback solo se si seleziona uno stato diverso
                      if (selected && !isSelected) {
                        onStatusChanged(status);
                      }
                    },
                    checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    shape: StadiumBorder(
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
