import 'package:flutter/material.dart';

import '../../data/models/daily_tasks/task_category.dart';

class TaskColors {
  static Color getCategoryColor(TaskCategory category, ThemeData theme) {
    switch (category) {
      case TaskCategory.overdue:
        return theme.colorScheme.error;
      case TaskCategory.dueToday:
        return theme.colorScheme.secondary;
      case TaskCategory.ongoing:
      case TaskCategory.startingToday:
        return theme.colorScheme.primary;
    }
  }

  static Color getPriorityColor(String priority, ThemeData theme) {
    final p = priority.toLowerCase();
    if (p.contains('alta') || p.contains('high')) {
      return theme.colorScheme.error;
    } else if (p.contains('media') || p.contains('medium')) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.primary;
  }

  static Color getStatusColor(String status, ThemeData theme) {
    final s = status.toLowerCase();
    if (s.contains('completato') || s.contains('done')) {
      return theme.colorScheme.primary;
    } else if (s.contains('progresso') || s.contains('progress')) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.onSurface.withOpacity(0.6);
  }
}
