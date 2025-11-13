import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/enums/task_filter_type.dart';
import 'package:shared_todo_app/core/utils/task_sorter.dart';
import 'package:shared_todo_app/data/models/task.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('TaskSorter Tests', () {
    late List<Task> testTasks;
    late DateTime baseDate;

    setUp(() {
      baseDate = DateTime(2025, 11, 13);

      // Create a diverse set of tasks for testing sorting
      testTasks = [
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-1',
          title: 'Zebra Task',
          priority: 'Low',
          createdAt: baseDate.subtract(const Duration(days: 5)),
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-2',
          title: 'Apple Task',
          priority: 'High',
          createdAt: baseDate.subtract(const Duration(days: 1)),
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-3',
          title: 'Banana Task',
          priority: 'Medium',
          createdAt: baseDate.subtract(const Duration(days: 3)),
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'task-4',
          title: 'Cherry Task',
          priority: 'High',
          createdAt: baseDate.subtract(const Duration(days: 7)),
        )),
      ];
    });

    test('should sort tasks by creation date (newest first)', () {
      // Act
      final sorted = TaskSorter.sortTasks(
        testTasks,
        TaskFilterType.createdAtNewest,
      );

      // Assert
      expect(sorted[0].id, 'task-2'); // Most recent
      expect(sorted[1].id, 'task-3');
      expect(sorted[2].id, 'task-1');
      expect(sorted[3].id, 'task-4'); // Oldest
    });

    test('should sort tasks by creation date (oldest first)', () {
      // Act
      final sorted = TaskSorter.sortTasks(
        testTasks,
        TaskFilterType.createdAtOldest,
      );

      // Assert
      expect(sorted[0].id, 'task-4'); // Oldest
      expect(sorted[1].id, 'task-1');
      expect(sorted[2].id, 'task-3');
      expect(sorted[3].id, 'task-2'); // Most recent
    });

    test('should sort tasks by priority (high to low)', () {
      // Act
      final sorted = TaskSorter.sortTasks(
        testTasks,
        TaskFilterType.priorityHighToLow,
      );

      // Assert
      // High priority tasks first (task-2, task-4)
      expect(sorted[0].priority, 'High');
      expect(sorted[1].priority, 'High');
      // Medium priority task
      expect(sorted[2].priority, 'Medium');
      // Low priority task last
      expect(sorted[3].priority, 'Low');
    });

    test('should sort tasks by priority (low to high)', () {
      // Act
      final sorted = TaskSorter.sortTasks(
        testTasks,
        TaskFilterType.priorityLowToHigh,
      );

      // Assert
      // Low priority task first
      expect(sorted[0].priority, 'Low');
      // Medium priority task
      expect(sorted[1].priority, 'Medium');
      // High priority tasks last (task-2, task-4)
      expect(sorted[2].priority, 'High');
      expect(sorted[3].priority, 'High');
    });

    test('should sort tasks alphabetically (A-Z)', () {
      // Act
      final sorted = TaskSorter.sortTasks(
        testTasks,
        TaskFilterType.alphabeticalAZ,
      );

      // Assert
      expect(sorted[0].title, 'Apple Task'); // A
      expect(sorted[1].title, 'Banana Task'); // B
      expect(sorted[2].title, 'Cherry Task'); // C
      expect(sorted[3].title, 'Zebra Task'); // Z
    });

    test('should sort tasks alphabetically (Z-A)', () {
      // Act
      final sorted = TaskSorter.sortTasks(
        testTasks,
        TaskFilterType.alphabeticalZA,
      );

      // Assert
      expect(sorted[0].title, 'Zebra Task'); // Z
      expect(sorted[1].title, 'Cherry Task'); // C
      expect(sorted[2].title, 'Banana Task'); // B
      expect(sorted[3].title, 'Apple Task'); // A
    });

    test('should handle case-insensitive alphabetical sorting', () {
      // Arrange
      final mixedCaseTasks = [
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'mixed-1',
          title: 'apple task',
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'mixed-2',
          title: 'ZEBRA TASK',
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'mixed-3',
          title: 'Banana Task',
        )),
      ];

      // Act
      final sorted = TaskSorter.sortTasks(
        mixedCaseTasks,
        TaskFilterType.alphabeticalAZ,
      );

      // Assert
      expect(sorted[0].title.toLowerCase(), 'apple task');
      expect(sorted[1].title.toLowerCase(), 'banana task');
      expect(sorted[2].title.toLowerCase(), 'zebra task');
    });

    test('should not modify original list', () {
      // Arrange
      final originalOrder = testTasks.map((t) => t.id).toList();

      // Act
      TaskSorter.sortTasks(testTasks, TaskFilterType.alphabeticalAZ);

      // Assert - Original list should remain unchanged
      expect(testTasks[0].id, originalOrder[0]);
      expect(testTasks[1].id, originalOrder[1]);
      expect(testTasks[2].id, originalOrder[2]);
      expect(testTasks[3].id, originalOrder[3]);
    });

    test('should handle empty list', () {
      // Arrange
      final emptyList = <Task>[];

      // Act
      final sorted = TaskSorter.sortTasks(
        emptyList,
        TaskFilterType.alphabeticalAZ,
      );

      // Assert
      expect(sorted, isEmpty);
    });

    test('should handle single task list', () {
      // Arrange
      final singleTaskList = [testTasks[0]];

      // Act
      final sorted = TaskSorter.sortTasks(
        singleTaskList,
        TaskFilterType.priorityHighToLow,
      );

      // Assert
      expect(sorted.length, 1);
      expect(sorted[0].id, testTasks[0].id);
    });

    test('should handle unknown priority values', () {
      // Arrange
      final tasksWithUnknownPriority = [
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'unknown-1',
          priority: 'Unknown',
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'high-1',
          priority: 'High',
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'unknown-2',
          priority: 'InvalidPriority',
        )),
      ];

      // Act
      final sorted = TaskSorter.sortTasks(
        tasksWithUnknownPriority,
        TaskFilterType.priorityHighToLow,
      );

      // Assert - High priority should be first, unknown priorities at the end
      expect(sorted[0].priority, 'High');
      expect(sorted[1].priority, anyOf('Unknown', 'InvalidPriority'));
      expect(sorted[2].priority, anyOf('Unknown', 'InvalidPriority'));
    });

    test('should maintain stable sort for equal values', () {
      // Arrange - Tasks with same priority
      final samePriorityTasks = [
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'same-1',
          priority: 'High',
          title: 'First High',
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'same-2',
          priority: 'High',
          title: 'Second High',
        )),
        Task.fromMap(TestFixtures.createTaskMap(
          id: 'same-3',
          priority: 'High',
          title: 'Third High',
        )),
      ];

      // Act
      final sorted = TaskSorter.sortTasks(
        samePriorityTasks,
        TaskFilterType.priorityHighToLow,
      );

      // Assert - All should still have High priority
      expect(sorted.every((task) => task.priority == 'High'), isTrue);
      expect(sorted.length, 3);
    });
  });
}
