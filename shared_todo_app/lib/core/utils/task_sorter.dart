import '../../data/models/task.dart';
import '../enums/task_filter_type.dart';

/// Utility class to sort Task list with stable ordering for date-based sorts
class TaskSorter {
  // Cache dell'ordine degli ID per i filtri basati su data
  static List<String>? _cachedOrderIds;
  static TaskFilterType? _cachedFilterType;
  static int? _cachedTaskCount;

  /// Sort task list by filter type
  /// Per i filtri basati su data (newest/oldest), mantiene l'ordine stabile
  /// quando cambiano solo gli stati dei task.
  static List<Task> sortTasks(List<Task> tasks, TaskFilterType filterType) {
    if (tasks.isEmpty) return [];

    final isDateBasedFilter = filterType == TaskFilterType.createdAtNewest ||
        filterType == TaskFilterType.createdAtOldest;

    // Se è un filtro basato su data e abbiamo una cache valida
    if (isDateBasedFilter && _isCacheValid(tasks, filterType)) {
      return _applyOrderFromCache(tasks);
    }

    // Altrimenti, esegui il sort normale
    final sortedTasks = _performSort(List<Task>.from(tasks), filterType);

    // Salva in cache solo per filtri basati su data
    if (isDateBasedFilter) {
      _updateCache(sortedTasks, filterType);
    }

    return sortedTasks;
  }

  /// Verifica se la cache è valida per essere riutilizzata
  static bool _isCacheValid(List<Task> tasks, TaskFilterType filterType) {
    if (_cachedOrderIds == null || _cachedFilterType != filterType) {
      return false;
    }

    // Se il numero di task è cambiato, invalida la cache
    if (_cachedTaskCount != tasks.length) {
      return false;
    }

    // Verifica che tutti gli ID nella cache esistano ancora
    final currentIds = tasks.map((t) => t.id).toSet();
    final cachedIds = _cachedOrderIds!.toSet();

    return cachedIds.length == currentIds.length &&
        cachedIds.containsAll(currentIds);
  }

  /// Applica l'ordine dalla cache
  static List<Task> _applyOrderFromCache(List<Task> tasks) {
    final taskMap = {for (var t in tasks) t.id: t};
    return _cachedOrderIds!
        .where((id) => taskMap.containsKey(id))
        .map((id) => taskMap[id]!)
        .toList();
  }

  /// Aggiorna la cache con il nuovo ordine
  static void _updateCache(List<Task> sortedTasks, TaskFilterType filterType) {
    _cachedOrderIds = sortedTasks.map((t) => t.id).toList();
    _cachedFilterType = filterType;
    _cachedTaskCount = sortedTasks.length;
  }

  /// Invalida la cache manualmente (chiamare quando necessario)
  static void invalidateCache() {
    _cachedOrderIds = null;
    _cachedFilterType = null;
    _cachedTaskCount = null;
  }

  /// Esegue il sort effettivo
  static List<Task> _performSort(List<Task> sortedTasks, TaskFilterType filterType) {
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