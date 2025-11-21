import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/maps/map_dialog.dart';
import '../../../../data/models/task.dart';
import '../../../../config/responsive.dart';

class TaskListTile extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;
  final String? currentUserRole;

  const TaskListTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    this.currentUserRole,
  });

  @override
  State<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends State<TaskListTile> {
  // Variabile locale per gestire l'aggiornamento immediato del chip
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }

  @override
  void didUpdateWidget(covariant TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se lo stream invia un aggiornamento reale dal database, allineiamo lo stato
    if (widget.task.status != oldWidget.task.status) {
      _currentStatus = widget.task.status;
    }
  }

  void _updateStatusOptimistically(String newStatus) {
    if (_currentStatus == newStatus) return;

    setState(() {
      _currentStatus = newStatus;
    });
    // Notifica il genitore/backend
    widget.onStatusChanged(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAdmin = widget.currentUserRole == 'admin';
    final task = widget.task;

    // Usiamo _currentStatus invece di task.status per la logica visiva immediata
    final bool isOverdue = task.dueDate.isBefore(
          DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day),
        ) &&
        _currentStatus != 'Done';
    final bool isDone = _currentStatus == 'Done';

    final Color borderColor =
        isOverdue ? colorScheme.error.withOpacity(0.5) : theme.dividerColor;

    final Color titleColor = isDone
        ? theme.disabledColor
        : theme.textTheme.titleMedium?.color ?? Colors.black;

    final double titleSize = ResponsiveLayout.isMobile(context) ? 16 : 18;
    final double bodySize = ResponsiveLayout.isMobile(context) ? 13 : 14;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize:
              MainAxisSize.min, // Importante per evitare espansioni errate
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ICONA
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 2),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: isDone ? theme.disabledColor : colorScheme.primary,
                    size: 28,
                  ),
                ),

                // 2. CONTENUTO TESTUALE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titolo
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Data
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14,
                              color:
                                  isOverdue ? colorScheme.error : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(task.dueDate),
                            style: TextStyle(
                              fontSize: bodySize,
                              color: isOverdue
                                  ? colorScheme.error
                                  : Colors.grey[700],
                              fontWeight: isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),

                      // Descrizione
                      if (task.desc != null && task.desc!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.notes,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.desc!,
                                  style: TextStyle(
                                      fontSize: bodySize,
                                      color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Luogo
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => MapDialog(
                                taskId: task.id,
                                taskRepository: TaskRepository(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: task.placeName != null
                                    ? colorScheme.secondary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  task.placeName ?? "No place indicated",
                                  style: TextStyle(
                                    fontSize: bodySize,
                                    color: task.placeName != null
                                        ? Colors.black87
                                        : Colors.grey,
                                    fontStyle: task.placeName == null
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. MENU OPZIONI
                if (isAdmin)
                  SizedBox(
                    width: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit')
                          widget.onEdit();
                        else if (value == 'delete') widget.onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  )
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 4. CHIPS STATO
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['To Do', 'In Progress', 'Done'].map((status) {
                  // Confrontiamo con lo stato locale per update immediato
                  final bool isSelected = _currentStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        // Cambiamo stato solo se è diverso e selezionato
                        if (selected && !isSelected) {
                          _updateStatusOptimistically(status);
                        }
                      },
                      selectedColor: colorScheme.primary,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade300),
                      showCheckmark: false,
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
