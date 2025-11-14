// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import '../../../../../core/utils/daily_tasks/date_formatter.dart';
import '../../../../../data/models/task.dart';

/// Dialog per mostrare i dettagli di un task
class TaskDetailsDialog extends StatelessWidget {
  final Task task;

  const TaskDetailsDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(task.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.desc != null && task.desc!.isNotEmpty) ...[
              _buildSectionTitle('Description:', theme),
              const SizedBox(height: 4),
              Text(task.desc!),
              const SizedBox(height: 16),
            ],
            _DetailRow(label: 'Priority', value: task.priority, theme: theme),
            _DetailRow(label: 'Status', value: task.status, theme: theme),
            _DetailRow(
              label: 'Start Date',
              value: DateFormatter.formatFull(task.startDate),
              theme: theme,
            ),
            _DetailRow(
              label: 'Expire Date',
              value: DateFormatter.formatFull(task.dueDate),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _DurationInfo(task: task, theme: theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Mostra il dialog
  static void show(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );
  }
}

/// Widget per una riga di dettaglio
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Widget per le informazioni sulla durata
class _DurationInfo extends StatelessWidget {
  final Task task;
  final ThemeData theme;

  const _DurationInfo({
    required this.task,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final startDate = task.startDate ?? DateTime.now();
    final duration = DateFormatter.daysBetween(startDate, task.dueDate);
    // final daysRemaining = DateFormatter.daysUntil(task.dueDate);
    final isOverdue = DateFormatter.isOverdue(task.dueDate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total duration: $duration ${duration <= 1 ? "day" : "days"}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormatter.formatDaysRemaining(task.dueDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isOverdue
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
