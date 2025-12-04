import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/maps/map_dialog.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/badges/recurring_badge.dart';
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
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }

  @override
  void didUpdateWidget(covariant TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isUpdating && widget.task.status != _currentStatus) {
      setState(() {
        _currentStatus = widget.task.status;
      });
    }
  }

  void _updateStatusOptimistically(String newStatus) {
    if (_currentStatus == newStatus || _isUpdating) return;

    setState(() {
      _currentStatus = newStatus;
      _isUpdating = true;
    });

    widget.onStatusChanged(newStatus);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    });
  }

  void _openMapDialog() async {
    final result = await showDialog<LocationData>(
      context: context,
      builder: (BuildContext context) {
        return MapDialog.forUpdate(
          taskId: widget.task.id,
          taskRepository: TaskRepository(),
          currentLat: widget.task.latitude,
          currentLong: widget.task.longitude,
          currentTitle: widget.task.title,
          onPlaceUpdated: () {},
        );
      },
    );

    if (result != null && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAdmin = widget.currentUserRole == 'admin';
    final task = widget.task;

    final bool isDone = _currentStatus == 'Done';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bool isOverdue = task.dueDate.isBefore(today) && !isDone;

    // --- LOGICA COLORI CORRETTA PER DARK/LIGHT MODE ---

    // Colore Bordo Card
    final Color borderColor = theme.dividerColor;

    // Colore Titolo: Se fatto -> Grigio scuro/disabilitato.
    // Altrimenti -> Colore testo principale del tema (Bianco in dark, Nero in light)
    final Color titleColor =
        isDone ? theme.disabledColor : colorScheme.onSurface;

    // Colore Data
    final Color dateColor =
        isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant;

    // Colore Descrizione: Usa onSurfaceVariant (grigio chiaro in dark mode)
    final bool hasDescription = task.desc != null && task.desc!.isNotEmpty;
    final String descriptionText =
        hasDescription ? task.desc! : 'No description';
    final Color descriptionColor = hasDescription
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withOpacity(0.3);

    // Colore Luogo
    final bool hasPlace = task.placeName != null && task.placeName!.isNotEmpty;
    final String placeText = hasPlace ? task.placeName! : "No place indicated";

    // Se c'è il luogo, usa il colore primario o onSurface, NON nero.
    final Color placeTextColor = hasPlace
        ? colorScheme.onSurface
        : colorScheme.onSurface.withOpacity(0.4);

    final Color placeIconColor =
        hasPlace ? colorScheme.primary : theme.disabledColor;

    // Dimensioni responsive
    final double titleSize = ResponsiveLayout.isMobile(context) ? 16 : 18;
    final double bodySize = ResponsiveLayout.isMobile(context) ? 13 : 14;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor, // Colore sfondo card dal tema
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICONA PRINCIPALE
                SizedBox(
                  width: 40,
                  height: 28,
                  child: Icon(
                    Icons.assignment_outlined,
                    color: isDone ? theme.disabledColor : colorScheme.primary,
                    size: 28,
                  ),
                ),

                // CONTENUTO TESTUALE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Titolo
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.2,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Data
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: dateColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(task.dueDate),
                            style: TextStyle(
                              fontSize: bodySize,
                              color: dateColor,
                              fontWeight: FontWeight.normal,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Descrizione
                      Row(
                        children: [
                          Icon(
                            Icons.notes,
                            size: 14,
                            color: descriptionColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              descriptionText,
                              style: TextStyle(
                                fontSize: bodySize,
                                color: descriptionColor,
                                height: 1.2,
                                fontStyle: hasDescription
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Luogo
                      InkWell(
                        onTap: _openMapDialog,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: placeIconColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                placeText,
                                style: TextStyle(
                                  fontSize: bodySize,
                                  color: placeTextColor,
                                  fontStyle: hasPlace
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                  height: 1.2,
                                  decoration: hasPlace
                                      ? TextDecoration.underline
                                      : null,
                                  decorationColor:
                                      placeTextColor.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Recurring Badge
                      RecurringBadge(
                        isRecurring: task.isRecurring,
                        recurrenceType: task.recurrenceType,
                        isMobile: ResponsiveLayout.isMobile(context),
                      ),
                    ],
                  ),
                ),

                // MENU OPZIONI
                if (isAdmin)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      // Icona grigia chiara per visibilità su sfondo scuro
                      icon: Icon(Icons.more_vert,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit();
                        } else if (value == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // BOTTONI STATO
            Row(
              children: [
                _buildStatusButton(context, 'To Do', _currentStatus == 'To Do'),
                const SizedBox(width: 8),
                _buildStatusButton(
                    context, 'In Progress', _currentStatus == 'In Progress'),
                const SizedBox(width: 8),
                _buildStatusButton(context, 'Done', _currentStatus == 'Done'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      BuildContext context, String label, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected && !_isUpdating) {
            _updateStatusOptimistically(label);
          }
        },
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              // Bordo visibile anche in dark mode (onSurface con opacità o outline)
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              // Testo bianco se selezionato (perché primary di solito è scuro/colorato)
              // Altrimenti usa il colore del testo su superficie (bianco in dark mode)
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.normal,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
