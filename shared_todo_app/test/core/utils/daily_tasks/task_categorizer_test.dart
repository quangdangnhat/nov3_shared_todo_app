import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/daily_tasks/task_category.dart';
import 'package:shared_todo_app/core/utils/daily_tasks/task_categorizer.dart';
import 'package:shared_todo_app/data/models/task.dart';
import '../../../helpers/test_fixtures.dart';

void main() {
  group('TaskCategorizer Tests', () {
    late DateTime today;
    late DateTime yesterday;
    late DateTime tomorrow;

    setUp(() {
      final now = DateTime.now();
      today = DateTime(now.year, now.month, now.day);
      yesterday = today.subtract(const Duration(days: 1));
      tomorrow = today.add(const Duration(days: 1));
    });

    group('categorize', () {
      test('should categorize overdue tasks', () {
        // Arrange - Task with due date in the past
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'overdue-1',
            dueDate: yesterday,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.overdue]!.length, 1);
        expect(categorized[TaskCategory.overdue]![0].id, 'overdue-1');
      });

      test('should categorize tasks due today', () {
        // Arrange - Task with due date today
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'due-today-1',
            dueDate: today,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.dueToday]!.length, 1);
        expect(categorized[TaskCategory.dueToday]![0].id, 'due-today-1');
      });

      test('should categorize ongoing tasks', () {
        // Arrange - Task that started before today and due in the future
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'ongoing-1',
            startDate: yesterday,
            dueDate: tomorrow,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.ongoing]!.length, 1);
        expect(categorized[TaskCategory.ongoing]![0].id, 'ongoing-1');
      });

      test('should categorize tasks starting today', () {
        // Arrange - Task starting today with future due date
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'starting-today-1',
            startDate: today,
            dueDate: tomorrow,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.startingToday]!.length, 1);
        expect(
            categorized[TaskCategory.startingToday]![0].id, 'starting-today-1');
      });

      test('should not categorize tasks without start date and future due date',
          () {
        // Arrange - Task with no start date and future due date
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'no-category',
            startDate: null,
            dueDate: tomorrow,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.overdue]!.length, 0);
        expect(categorized[TaskCategory.dueToday]!.length, 0);
        expect(categorized[TaskCategory.ongoing]!.length, 0);
        expect(categorized[TaskCategory.startingToday]!.length, 0);
      });

      test('should categorize multiple tasks correctly', () {
        // Arrange
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'overdue',
            dueDate: yesterday,
          )),
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'due-today',
            dueDate: today,
          )),
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'ongoing',
            startDate: yesterday,
            dueDate: tomorrow,
          )),
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'starting-today',
            startDate: today,
            dueDate: tomorrow,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.overdue]!.length, 1);
        expect(categorized[TaskCategory.dueToday]!.length, 1);
        expect(categorized[TaskCategory.ongoing]!.length, 1);
        expect(categorized[TaskCategory.startingToday]!.length, 1);
      });

      test('should handle empty task list', () {
        // Arrange
        final tasks = <Task>[];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.overdue]!.isEmpty, isTrue);
        expect(categorized[TaskCategory.dueToday]!.isEmpty, isTrue);
        expect(categorized[TaskCategory.ongoing]!.isEmpty, isTrue);
        expect(categorized[TaskCategory.startingToday]!.isEmpty, isTrue);
      });

      test('should handle tasks with start date equal to due date (today)', () {
        // Arrange - Task that starts and ends today
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'same-day',
            startDate: today,
            dueDate: today,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert - Should be categorized as due today
        expect(categorized[TaskCategory.dueToday]!.length, 1);
        expect(categorized[TaskCategory.startingToday]!.length, 0);
      });

      test('should handle multiple overdue tasks', () {
        // Arrange
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'overdue-1',
            dueDate: yesterday,
          )),
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'overdue-2',
            dueDate: yesterday.subtract(const Duration(days: 5)),
          )),
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'overdue-3',
            dueDate: yesterday.subtract(const Duration(days: 10)),
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.overdue]!.length, 3);
      });

      test('should handle ongoing tasks that started weeks ago', () {
        // Arrange - Task that started 2 weeks ago and due next week
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'long-ongoing',
            startDate: today.subtract(const Duration(days: 14)),
            dueDate: today.add(const Duration(days: 7)),
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert
        expect(categorized[TaskCategory.ongoing]!.length, 1);
      });
    });

    group('getSearchRange', () {
      test('should return correct date range', () {
        // Act
        final range = TaskCategorizer.getSearchRange();

        // Assert
        expect(range.start.isBefore(today), isTrue);
        expect(range.end.isAfter(today), isTrue);
        expect(range.start, equals(yesterday));
      });

      test('should have 8-day range (yesterday to 7 days ahead)', () {
        // Act
        final range = TaskCategorizer.getSearchRange();

        // Assert - From yesterday to 7 days in the future + 1
        final expectedEnd = today.add(const Duration(days: 8));
        expect(range.start, equals(yesterday));
        expect(range.end, equals(expectedEnd));
      });

      test('should return range with normalized dates (midnight)', () {
        // Act
        final range = TaskCategorizer.getSearchRange();

        // Assert - Times should be normalized to midnight
        expect(range.start.hour, 0);
        expect(range.start.minute, 0);
        expect(range.start.second, 0);
        expect(range.end.hour, 0);
        expect(range.end.minute, 0);
        expect(range.end.second, 0);
      });
    });

    group('DateRange', () {
      test('should create DateRange with start and end', () {
        // Arrange
        final start = DateTime(2025, 11, 1);
        final end = DateTime(2025, 11, 30);

        // Act
        final range = DateRange(start: start, end: end);

        // Assert
        expect(range.start, equals(start));
        expect(range.end, equals(end));
      });
    });

    group('Edge Cases', () {
      test('should ignore time component in date comparisons', () {
        // Arrange - Task due today but with different time
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'time-test',
            dueDate: DateTime(today.year, today.month, today.day, 23, 59),
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert - Should still be categorized as due today
        expect(categorized[TaskCategory.dueToday]!.length, 1);
      });

      test('should handle task starting yesterday but due today', () {
        // Arrange
        final tasks = [
          Task.fromMap(TestFixtures.createTaskMap(
            id: 'yesterday-today',
            startDate: yesterday,
            dueDate: today,
          )),
        ];

        // Act
        final categorized = TaskCategorizer.categorize(tasks);

        // Assert - Due today takes precedence
        expect(categorized[TaskCategory.dueToday]!.length, 1);
        expect(categorized[TaskCategory.ongoing]!.length, 0);
      });
    });
  });
}
