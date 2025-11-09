import '../../../../data/models/task.dart';
import '../../../data/models/daily_tasks/task_category.dart';

/// Classe per la categorizzazione dei task
class TaskCategorizer {
  /// Categorizza una lista di task in base alla data odierna
  static Map<TaskCategory, List<Task>> categorize(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<TaskCategory, List<Task>> categorized = {
      TaskCategory.overdue: [],
      TaskCategory.dueToday: [],
      TaskCategory.ongoing: [],
      TaskCategory.startingToday: [],
    };

    for (final task in tasks) {
      final category = _categorizeTask(task, today);
      if (category != null) {
        categorized[category]!.add(task);
      }
    }

    return categorized;
  }

  /// Determina la categoria di un singolo task
  static TaskCategory? _categorizeTask(Task task, DateTime today) {
    final startDate = task.startDate != null
        ? DateTime(
            task.startDate!.year,
            task.startDate!.month,
            task.startDate!.day,
          )
        : null;

    final dueDate = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );

    // Task scaduti
    if (dueDate.isBefore(today)) {
      return TaskCategory.overdue;
    }

    // Task in scadenza oggi
    if (dueDate.isAtSameMomentAs(today)) {
      return TaskCategory.dueToday;
    }

    // Task in corso (iniziati prima di oggi, scadenza futura)
    if (startDate != null &&
        startDate.isBefore(today) &&
        dueDate.isAfter(today)) {
      return TaskCategory.ongoing;
    }

    // Task che iniziano oggi (scadenza futura)
    if (startDate != null &&
        startDate.isAtSameMomentAs(today) &&
        dueDate.isAfter(today)) {
      return TaskCategory.startingToday;
    }

    return null;
  }

  /// Calcola le date per il range di ricerca
  static DateRange getSearchRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final endDate = today.add(const Duration(days: 8)); // 7 giorni + 1

    return DateRange(start: yesterday, end: endDate);
  }
}

/// Classe per rappresentare un range di date
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}
