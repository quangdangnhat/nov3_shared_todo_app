import 'package:flutter/material.dart';

/// Enum per le categorie dei task nella vista giornaliera
enum TaskCategory {
  overdue,
  dueToday,
  ongoing,
  startingToday,
}

/// Extension per aggiungere metodi utili all'enum
extension TaskCategoryExtension on TaskCategory {
  /// Restituisce il titolo localizzato della categoria
  String get title {
    switch (this) {
      case TaskCategory.overdue:
        return 'Expired';
      case TaskCategory.dueToday:
        return 'Expires Today';
      case TaskCategory.ongoing:
        return 'In Progress';
      case TaskCategory.startingToday:
        return 'They start today';
    }
  }

  /// Restituisce il sottotitolo della categoria
  String get subtitle {
    switch (this) {
      case TaskCategory.overdue:
        return 'Requires immediate attention';
      case TaskCategory.dueToday:
        return 'To be completed by today';
      case TaskCategory.ongoing:
        return 'Already started, future deadline';
      case TaskCategory.startingToday:
        return 'New tasks to start';
    }
  }

  /// Restituisce l'icona associata alla categoria
  IconData get icon {
    switch (this) {
      case TaskCategory.overdue:
        return Icons.warning_amber_rounded;
      case TaskCategory.dueToday:
        return Icons.event_available;
      case TaskCategory.ongoing:
        return Icons.pending_actions;
      case TaskCategory.startingToday:
        return Icons.play_circle_outline;
    }
  }

  /// Restituisce il label per il filtro
  String get filterLabel {
    switch (this) {
      case TaskCategory.overdue:
        return 'Expired';
      case TaskCategory.dueToday:
        return 'Expire Today';
      case TaskCategory.ongoing:
        return 'In Progress';
      case TaskCategory.startingToday:
        return 'Start today';
    }
  }
}
