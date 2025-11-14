// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:shared_todo_app/data/models/daily_tasks/task_category.dart';
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
    final categoryColor = ColorHelper.getCategoryColor(category, theme);
    final priorityColor = ColorHelper.getPriorityColor(task.priority, theme);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Card(
      elevation: category == TaskCategory.overdue ? 3 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: category == TaskCategory.overdue
                ? Border.all(
                    color: ColorHelper.getOverdueBorderColor(theme),
                    width: 2,
                  )
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleRow(context, theme, priorityColor, isMobile),
                SizedBox(height: isMobile ? 8 : 12),
                _buildInfoChips(theme, categoryColor, isMobile),
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
      children: [
        Expanded(
          child: Text(
            task.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveLayout.responsive<double>(
                context,
                mobile: 14,
                desktop: 16,
              ),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _PriorityBadge(
            priority: task.priority, color: priorityColor, isMobile: isMobile),
      ],
    );
  }

  Widget _buildInfoChips(ThemeData theme, Color categoryColor, bool isMobile) {
    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.play_arrow,
          text:
              'start date: ${DateFormatter.formatShort(task.startDate ?? DateTime.now())}',
          color: theme.colorScheme.primary,
          isMobile: isMobile,
        ),
        _InfoChip(
          icon: Icons.flag,
          text: 'expire date: ${DateFormatter.formatShort(task.dueDate)}',
          color: categoryColor,
          isMobile: isMobile,
        ),
        _StatusChip(status: task.status, theme: theme, isMobile: isMobile),
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
        horizontal: isMobile ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: isMobile ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget per un chip informativo
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isMobile;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 10 : 11,
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
        horizontal: isMobile ? 8 : 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontSize: isMobile ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
