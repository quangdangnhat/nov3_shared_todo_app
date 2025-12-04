// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:shared_todo_app/data/models/daily_tasks/task_category.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/badges/recurring_badge.dart';
import '../../../../../config/responsive.dart';
import '../../../../../core/utils/daily_tasks/color_helper.dart';
import '../../../../../core/utils/daily_tasks/date_formatter.dart';
import '../../../../../data/models/task.dart';

/// Card per visualizzare un singolo task
class TaskCard extends StatelessWidget {
  final Task task;
  final TaskCategory category;
  final VoidCallback onTap;

  const TaskCard({
    Key? key,
    required this.task,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = category == TaskCategory.overdue;

    // Colore neutro per i testi
    final neutralColor = Colors.grey[800]!;

    final priorityColor = ColorHelper.getPriorityColor(task.priority, theme);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Card(
      // Usiamo l'elevation per dare stacco
      elevation: isOverdue ? 3 : 1,
      color: theme.cardColor,
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // --- MODIFICA QUI ---
            border: isOverdue
                ? Border.all(
                    // CASO 1: Scaduto (Contorno esistente, più spesso e colorato)
                    color: ColorHelper.getOverdueBorderColor(theme),
                    width: 2,
                  )
                : Border.all(
                    // CASO 2: Normale (Grigio non troppo chiaro)
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
          ),
          child: Padding(
            // Mantengo la spaziatura "via di mezzo" (16/20)
            padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context, theme, priorityColor, isMobile),
                SizedBox(height: isMobile ? 10 : 12),
                _buildInfoChips(theme, neutralColor, isOverdue, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, ThemeData theme,
      Color priorityColor, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            task.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              // Font size "via di mezzo"
              fontSize: ResponsiveLayout.responsive<double>(
                context,
                mobile: 18,
                desktop: 21,
              ),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        _PriorityBadge(
            priority: task.priority, color: priorityColor, isMobile: isMobile),
      ],
    );
  }

  Widget _buildInfoChips(
      ThemeData theme, Color neutralColor, bool isOverdue, bool isMobile) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        // Start Date
        _InfoChip(
          icon: Icons.play_arrow_rounded,
          text:
              'Start: ${DateFormatter.formatShort(task.startDate ?? DateTime.now())}',
          itemColor: Colors.grey[700]!,
          bgColor: Colors.grey[50]!,
          isMobile: isMobile,
        ),

        // Expire Date
        _InfoChip(
          icon: isOverdue ? Icons.warning_rounded : Icons.flag_rounded,
          text: 'Due: ${DateFormatter.formatShort(task.dueDate)}',
          itemColor: isOverdue ? Colors.red[700]! : Colors.grey[700]!,
          bgColor: isOverdue ? Colors.red[50]! : Colors.grey[50]!,
          isMobile: isMobile,
        ),

        // Status
        _StatusChip(status: task.status, theme: theme, isMobile: isMobile),

        // Recurring Badge
        RecurringBadge(
          isRecurring: task.isRecurring,
          recurrenceType: task.recurrenceType,
          isMobile: isMobile,
        ),
      ],
    );
  }
}

/// Widget per il badge della priorità
class _PriorityBadge extends StatelessWidget {
  final String priority;
  final Color color;
  final bool isMobile;

  const _PriorityBadge({
    required this.priority,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        // NUOVO: Bordo leggero interno
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget per un chip informativo (Date)
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color itemColor;
  final Color bgColor;
  final bool isMobile;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.itemColor,
    required this.bgColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        // NUOVO: Bordo leggero interno (grigio/colorato)
        border: Border.all(
          color: itemColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 16 : 18, color: itemColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: itemColor,
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget per lo status chip
class _StatusChip extends StatelessWidget {
  final String status;
  final ThemeData theme;
  final bool isMobile;

  const _StatusChip({
    required this.status,
    required this.theme,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = ColorHelper.getStatusColor(status, theme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        // NUOVO: Bordo leggero interno
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: isMobile ? 12 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
