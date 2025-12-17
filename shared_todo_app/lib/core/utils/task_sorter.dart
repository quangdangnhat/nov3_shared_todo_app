import '../../data/models/task.dart';
import '../enums/task_filter_type.dart';

/// Utility class to sort Task list with stable ordering for date-based sorts
class TaskSorter {
  // Cache SOLO dell'ordine degli ID (non dei task stessi!)
  static List<String>? _cachedOrderIds;
  static TaskFilterType? _cachedFilterType;

  /// Sort task list by filter type
  /// Per i filtri basati su data (newest/oldest), mantiene l'ordine stabile
  /// quando cambiano solo gli stati dei task (non aggiunta/rimozione).
  static List<Task> sortTasks(List<Task> tasks, TaskFilterType filterType) {
    if (tasks.isEmpty) {
      _invalidateCacheIfFilterChanged(filterType);
      return [];
    }

    final isDateBasedFilter = filterType == TaskFilterType.createdAtNewest ||
        filterType == TaskFilterType.createdAtOldest;

    // Se il filtro è cambiato, invalida la cache
    if (_cachedFilterType != filterType) {
      _cachedOrderIds = null;
      _cachedFilterType = filterType;
    }

    // Per filtri NON basati su data, esegui sempre il sort normale
    if (!isDateBasedFilter) {
      return _performSort(List<Task>.from(tasks), filterType);
    }

    // === FILTRI BASATI SU DATA ===

    final currentIds = tasks.map((t) => t.id).toSet();

    // Verifica se la struttura è cambiata (aggiunti/rimossi task)
    final bool structureChanged = _hasStructureChanged(currentIds);

    if (structureChanged || _cachedOrderIds == null) {
      // Struttura cambiata: ricalcola il sort e aggiorna la cache
      final sortedTasks = _performSort(List<Task>.from(tasks), filterType);
      _cachedOrderIds = sortedTasks.map((t) => t.id).toList();
      return sortedTasks;
    }

    // Struttura invariata: usa l'ordine dalla cache ma con i TASK AGGIORNATI dallo stream
    return _applyOrderWithFreshTasks(tasks);
  }

  /// Verifica se la struttura della lista è cambiata (aggiunti/rimossi task)
  static bool _hasStructureChanged(Set<String> currentIds) {
    if (_cachedOrderIds == null) return true;

    final cachedIds = _cachedOrderIds!.toSet();

    // Se il numero è diverso o gli ID non corrispondono, la struttura è cambiata
    if (cachedIds.length != currentIds.length) return true;
    if (!cachedIds.containsAll(currentIds)) return true;

    return false;
  }

  /// Applica l'ordine dalla cache usando i TASK FRESCHI dallo stream
  /// Questo garantisce che i dati siano sempre quelli aggiornati dal DB
  static List<Task> _applyOrderWithFreshTasks(List<Task> freshTasks) {
    // Crea una mappa ID -> Task con i dati FRESCHI dallo stream
    final taskMap = {for (var t in freshTasks) t.id: t};

    // Restituisce i task nell'ordine della cache, ma con i dati aggiornati
    final result = <Task>[];
    for (final id in _cachedOrderIds!) {
      final task = taskMap[id];
      if (task != null) {
        result.add(task); // Task FRESCO, non dalla cache!
      }
    }

    return result;
  }

  /// Invalida la cache se il filtro è cambiato
  static void _invalidateCacheIfFilterChanged(TaskFilterType filterType) {
    if (_cachedFilterType != filterType) {
      _cachedOrderIds = null;
      _cachedFilterType = filterType;
    }
  }

  /// Invalida la cache manualmente (es. per pull-to-refresh)
  static void invalidateCache() {
    _cachedOrderIds = null;
    _cachedFilterType = null;
  }

  /// Esegue il sort effettivo
  static List<Task> _performSort(
      List<Task> sortedTasks, TaskFilterType filterType) {
    switch (filterType) {
      case TaskFilterType.createdAtNewest:
        sortedTasks.sort((a, b) {
          int result = b.createdAt.compareTo(a.createdAt);
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.createdAtOldest:
        sortedTasks.sort((a, b) {
          int result = a.createdAt.compareTo(b.createdAt);
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.priorityHighToLow:
        sortedTasks.sort((a, b) {
          int result = _comparePriority(a.priority, b.priority);
          if (result == 0) return _resolveTieByDueDate(a, b);
          return result;
        });
        break;

      case TaskFilterType.priorityLowToHigh:
        sortedTasks.sort((a, b) {
          int result = _comparePriority(b.priority, a.priority);
          if (result == 0) return _resolveTieByDueDate(a, b);
          return result;
        });
        break;

      case TaskFilterType.highPriorityOnly:
        // Filter to keep only HIGH priority tasks
        sortedTasks.removeWhere(
            (task) => task.priority.toLowerCase() != 'high');
        // Sort by due date (earliest first)
        sortedTasks.sort((a, b) {
          int result = a.dueDate.compareTo(b.dueDate);
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.alphabeticalAZ:
        sortedTasks.sort((a, b) {
          int result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          if (result == 0) return a.id.compareTo(b.id);
          return result;
        });
        break;

      case TaskFilterType.alphabeticalZA:
        sortedTasks.sort((a, b) {
          int result = b.title.toLowerCase().compareTo(a.title.toLowerCase());
          if (result == 0) return a.id.compareTo(b.id);
          return result;
        });
        break;
    }
    return sortedTasks;
  }

  static int _resolveTie(Task a, Task b) {
    int titleResult = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (titleResult != 0) return titleResult;
    return a.id.compareTo(b.id);
  }

  /// Resolve tie by due date for HIGH priority only, otherwise by title
  static int _resolveTieByDueDate(Task a, Task b) {
    // Only sort by due date if both tasks are HIGH priority
    if (a.priority.toLowerCase() == 'high' &&
        b.priority.toLowerCase() == 'high') {
      int dateResult = a.dueDate.compareTo(b.dueDate);
      if (dateResult != 0) return dateResult;
    }
    // For other priorities, resolve by title
    int titleResult = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (titleResult != 0) return titleResult;
    return a.id.compareTo(b.id);
  }

  static int _comparePriority(String priorityA, String priorityB) {
    final priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};
    final valueA = priorityOrder[priorityA] ?? 999;
    final valueB = priorityOrder[priorityB] ?? 999;
    return valueA.compareTo(valueB);
  }
}
