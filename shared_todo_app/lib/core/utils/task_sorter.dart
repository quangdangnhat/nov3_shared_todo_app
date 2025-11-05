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
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case TaskFilterType.createdAtOldest:
        sortedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;

      case TaskFilterType.priorityHighToLow:
        sortedTasks.sort((a, b) => _comparePriority(a.priority, b.priority));
        break;

      case TaskFilterType.priorityLowToHigh:
        sortedTasks.sort((a, b) => _comparePriority(b.priority, a.priority));
        break;

      case TaskFilterType.alphabeticalAZ:
        sortedTasks.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;

      case TaskFilterType.alphabeticalZA:
        sortedTasks.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }

    return sortedTasks;
  }

  /// Helper method for comparing priorities
  /// High = 1, Medium = 2, Low = 3
  static int _comparePriority(String priorityA, String priorityB) {
    final priorityOrder = {
      'High': 1,
      'Medium': 2,
      'Low': 3,
    };

    final valueA =
        priorityOrder[priorityA] ?? 999; // Unknown priority at the end
    final valueB = priorityOrder[priorityB] ?? 999;

    return valueA.compareTo(valueB);
  }
}
