import '../../data/models/task.dart';
import '../enums/task_filter_type.dart';

/// Utility class to sort Task list
class TaskSorter {
  /// Sort task list by filter type
  static List<Task> sortTasks(List<Task> tasks, TaskFilterType filterType) {
    // Make a copy so as not to modify the original list
    final sortedTasks = List<Task>.from(tasks);

    switch (filterType) {
      case TaskFilterType.createdAtNewest:
        sortedTasks.sort((a, b) {
          // 1. Confronta Date (dal più recente)
          int result = b.createdAt.compareTo(a.createdAt);
          // 2. Se uguali, usa Titolo -> ID
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.createdAtOldest:
        sortedTasks.sort((a, b) {
          // 1. Confronta Date (dal più vecchio)
          int result = a.createdAt.compareTo(b.createdAt);
          // 2. Se uguali, usa Titolo -> ID
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.priorityHighToLow:
        sortedTasks.sort((a, b) {
          // 1. Confronta Priorità (High -> Low)
          int result = _comparePriority(a.priority, b.priority);
          // 2. Se priorità uguale, usa Titolo -> ID
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.priorityLowToHigh:
        sortedTasks.sort((a, b) {
          // 1. Confronta Priorità (Low -> High)
          int result = _comparePriority(b.priority, a.priority);
          // 2. Se priorità uguale, usa Titolo -> ID
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.alphabeticalAZ:
        sortedTasks.sort((a, b) {
          // 1. Confronta Titoli (A-Z)
          int result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          // 2. Se titoli identici, usa ID
          if (result == 0) return a.id.compareTo(b.id);
          return result;
        });
        break;

      case TaskFilterType.alphabeticalZA:
        sortedTasks.sort((a, b) {
          // 1. Confronta Titoli (Z-A)
          int result = b.title.toLowerCase().compareTo(a.title.toLowerCase());
          // 2. Se titoli identici, usa ID
          if (result == 0) return a.id.compareTo(b.id);
          return result;
        });
        break;
    }

    return sortedTasks;
  }

  /// Metodo centrale per gestire lo "spareggio" (Tie-Breaker).
  /// Viene chiamato quando il criterio principale (Data o Priorità) è identico.
  static int _resolveTie(Task a, Task b) {
    // 1. Prima prova in ordine alfabetico (più intuitivo per l'utente)
    int titleResult = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    
    if (titleResult != 0) {
      return titleResult;
    }

    // 2. Se anche il titolo è identico, usa l'ID per stabilità assoluta
    return a.id.compareTo(b.id);
  }

  /// Helper method for comparing priorities
  /// High = 1, Medium = 2, Low = 3
  static int _comparePriority(String priorityA, String priorityB) {
    final priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};

    final valueA = priorityOrder[priorityA] ?? 999;
    final valueB = priorityOrder[priorityB] ?? 999;

    return valueA.compareTo(valueB);
  }
}