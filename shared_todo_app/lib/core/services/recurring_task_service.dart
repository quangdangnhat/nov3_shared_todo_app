// coverage:ignore-file

import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../enums/recurrence_type.dart';

/// Service for managing recurring tasks and generating next instances
class RecurringTaskService {
  final TaskRepository _taskRepo;

  RecurringTaskService({TaskRepository? taskRepository})
      : _taskRepo = taskRepository ?? TaskRepository();

  /// Calculate the next due date based on recurrence type
  DateTime calculateNextDueDate(DateTime currentDueDate, RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return currentDueDate.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return currentDueDate.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        // Add one month, handling edge cases (e.g., Jan 31 -> Feb 28)
        final year = currentDueDate.month == 12
            ? currentDueDate.year + 1
            : currentDueDate.year;
        final month =
            currentDueDate.month == 12 ? 1 : currentDueDate.month + 1;

        // Handle day overflow (e.g., Jan 31 -> Feb 31 doesn't exist)
        int day = currentDueDate.day;
        final daysInNextMonth = DateTime(year, month + 1, 0).day;
        if (day > daysInNextMonth) {
          day = daysInNextMonth;
        }

        return DateTime(year, month, day);
      default:
        return currentDueDate;
    }
  }

  /// Calculate the next start date based on recurrence type
  DateTime? calculateNextStartDate(
      DateTime? currentStartDate, DateTime currentDueDate, RecurrenceType type) {
    if (currentStartDate == null) return null;

    // Calculate the difference between start and due date
    final daysDifference = currentDueDate.difference(currentStartDate).inDays;

    // Get the next due date
    final nextDueDate = calculateNextDueDate(currentDueDate, type);

    // Apply the same difference to get the next start date
    return nextDueDate.subtract(Duration(days: daysDifference));
  }

  /// Generate the next instance of a recurring task
  Future<Task?> generateNextInstance(Task completedTask) async {
    // Validate that this is a recurring task
    if (!completedTask.isRecurring ||
        completedTask.recurrenceType == 'none') {
      debugPrint(
          '⚠️ RecurringTaskService: Task ${completedTask.id} is not recurring');
      return null;
    }

    try {
      final recurrenceType =
          RecurrenceType.fromString(completedTask.recurrenceType);

      // Calculate next dates
      final nextDueDate =
          calculateNextDueDate(completedTask.dueDate, recurrenceType);
      final nextStartDate = calculateNextStartDate(
          completedTask.startDate, completedTask.dueDate, recurrenceType);

      debugPrint(
          '🔄 RecurringTaskService: Generating next instance of "${completedTask.title}"');
      debugPrint('   Current due date: ${completedTask.dueDate}');
      debugPrint('   Next due date: $nextDueDate');
      debugPrint('   Recurrence type: ${recurrenceType.displayName}');

      // Create the next task instance
      final newTask = await _taskRepo.createTask(
        folderId: completedTask.folderId,
        title: completedTask.title,
        desc: completedTask.desc,
        priority: completedTask.priority,
        status: 'To Do', // Reset status for new instance
        startDate: nextStartDate,
        dueDate: nextDueDate,
        // Copy location data
        latitude: completedTask.latitude,
        longitude: completedTask.longitude,
        placeName: completedTask.placeName,
        // Mark as recurring with same pattern
        isRecurring: true,
        recurrenceType: completedTask.recurrenceType,
        // Link to the completed task as parent
        parentRecurringTaskId: completedTask.id,
      );

      debugPrint(
          '✅ RecurringTaskService: Created new instance with ID: ${newTask.id}');

      return newTask;
    } catch (e) {
      debugPrint('❌ RecurringTaskService: Failed to generate next instance: $e');
      rethrow;
    }
  }

  /// Check if a task should generate a new instance
  /// (i.e., it's recurring and was just marked as Done)
  bool shouldGenerateNextInstance(Task task, String newStatus) {
    return task.isRecurring &&
        task.recurrenceType != 'none' &&
        newStatus == 'Done';
  }

  /// Handle task status change and generate next instance if needed
  Future<Task?> handleTaskStatusChange(
      Task task, String oldStatus, String newStatus) async {
    // Only generate when transitioning TO 'Done' status
    if (oldStatus == 'Done' || newStatus != 'Done') {
      return null;
    }

    if (shouldGenerateNextInstance(task, newStatus)) {
      debugPrint(
          '🎯 RecurringTaskService: Task marked as Done, generating next instance...');
      return await generateNextInstance(task);
    }

    return null;
  }
}
