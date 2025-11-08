import 'package:flutter/material.dart';

import '../../data/models/tree/node_type.dart';

/// Utility class per gestire colori e icone della tree view
class TreeStyleUtils {
  TreeStyleUtils._();

  static IconData getIconForType(NodeType type) {
    switch (type) {
      case NodeType.todoList:
        return Icons.list_alt;
      case NodeType.folder:
        return Icons.folder;
      case NodeType.task:
        return Icons.task_alt;
    }
  }

  static Color getIconColor(NodeType type, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    switch (type) {
      case NodeType.todoList:
        return colorScheme.primary;
      case NodeType.folder:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFFA000);
      case NodeType.task:
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF43A047);
    }
  }

  static Color getBackgroundColor(NodeType type, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    switch (type) {
      case NodeType.todoList:
        return isDark
            ? colorScheme.surface.withOpacity(0.8)
            : colorScheme.surfaceVariant;
      case NodeType.folder:
      case NodeType.task:
        return colorScheme.surface;
    }
  }

  static double getTitleFontSize(NodeType type) =>
      type == NodeType.todoList ? 18.0 : 16.0;

  static FontWeight getTitleFontWeight(NodeType type) =>
      type == NodeType.todoList ? FontWeight.bold : FontWeight.w500;

  static double getCardElevation(NodeType type) =>
      type == NodeType.todoList ? 2.0 : 1.0;
}
