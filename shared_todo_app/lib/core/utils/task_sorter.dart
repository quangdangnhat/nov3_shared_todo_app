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

    // Apply actual filtering first for filter-based types
    List<Task> filteredTasks = _applyFilter(tasks, filterType);

    if (filteredTasks.isEmpty) {
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
      return _performSort(List<Task>.from(filteredTasks), filterType);
    }

    // === FILTRI BASATI SU DATA ===

    final currentIds = filteredTasks.map((t) => t.id).toSet();

    // Verifica se la struttura è cambiata (aggiunti/rimossi task)
    final bool structureChanged = _hasStructureChanged(currentIds);

    if (structureChanged || _cachedOrderIds == null) {
      // Struttura cambiata: ricalcola il sort e aggiorna la cache
      final sortedTasks = _performSort(List<Task>.from(filteredTasks), filterType);
      _cachedOrderIds = sortedTasks.map((t) => t.id).toList();
      return sortedTasks;
    }

    // Struttura invariata: usa l'ordine dalla cache ma con i TASK AGGIORNATI dallo stream
    return _applyOrderWithFreshTasks(filteredTasks);
  }

  /// Apply actual filtering based on filter type
  static List<Task> _applyFilter(List<Task> tasks, TaskFilterType filterType) {
    switch (filterType) {
      case TaskFilterType.highPriorityOnly:
        return tasks.where((task) => task.priority == 'High').toList();
      case TaskFilterType.hasDueDate:
        // All tasks have dueDate (it's required), but we can filter for tasks
        // with due date that is not the default (today or in the future)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        return tasks.where((task) => !task.dueDate.isBefore(today)).toList();
      default:
        return tasks;
    }
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
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.priorityLowToHigh:
        sortedTasks.sort((a, b) {
          int result = _comparePriority(b.priority, a.priority);
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

      case TaskFilterType.highPriorityOnly:
        // Already filtered, just sort by creation date (newest first)
        sortedTasks.sort((a, b) {
          int result = b.createdAt.compareTo(a.createdAt);
          if (result == 0) return _resolveTie(a, b);
          return result;
        });
        break;

      case TaskFilterType.hasDueDate:
        // Already filtered, sort by due date (earliest first)
        sortedTasks.sort((a, b) {
          int result = a.dueDate.compareTo(b.dueDate);
          if (result == 0) return _resolveTie(a, b);
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

  static int _comparePriority(String priorityA, String priorityB) {
    final priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};
    final valueA = priorityOrder[priorityA] ?? 999;
    final valueB = priorityOrder[priorityB] ?? 999;
    return valueA.compareTo(valueB);
  }
}
