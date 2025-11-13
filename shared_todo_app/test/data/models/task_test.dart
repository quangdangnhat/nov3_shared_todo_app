import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/task.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('Task Model Tests', () {
    late Map<String, dynamic> validTaskMap;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 11, 13);
      validTaskMap = TestFixtures.createTaskMap(
        id: 'task-123',
        folderId: 'folder-456',
        title: 'Test Task',
        desc: 'Test Description',
        priority: 'High',
        status: 'Pending',
        startDate: testDate,
        dueDate: testDate.add(const Duration(days: 7)),
        createdAt: testDate,
        updatedAt: testDate.add(const Duration(hours: 1)),
      );
    });

    test('should create Task from valid map with snake_case keys', () {
      // Act
      final task = Task.fromMap(validTaskMap);

      // Assert
      expect(task.id, 'task-123');
      expect(task.folderId, 'folder-456');
      expect(task.title, 'Test Task');
      expect(task.desc, 'Test Description');
      expect(task.priority, 'High');
      expect(task.status, 'Pending');
      expect(task.startDate, isNotNull);
      expect(task.dueDate, isNotNull);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('should create Task from map with camelCase keys', () {
      // Arrange
      final camelCaseMap = {
        'id': 'task-123',
        'folderId': 'folder-456',
        'title': 'Test Task',
        'desc': 'Test Description',
        'priority': 'Medium',
        'status': 'Completed',
        'startDate': testDate.toIso8601String(),
        'dueDate': testDate.add(const Duration(days: 5)).toIso8601String(),
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.add(const Duration(hours: 2)).toIso8601String(),
      };

      // Act
      final task = Task.fromMap(camelCaseMap);

      // Assert
      expect(task.id, 'task-123');
      expect(task.folderId, 'folder-456');
      expect(task.title, 'Test Task');
      expect(task.priority, 'Medium');
      expect(task.status, 'Completed');
    });

    test('should handle null startDate and updatedAt', () {
      // Arrange
      final mapWithNulls = TestFixtures.createTaskMap(
        id: 'task-null',
        startDate: null,
        updatedAt: null,
      );
      mapWithNulls.remove('start_date');
      mapWithNulls.remove('updated_at');

      // Act
      final task = Task.fromMap(mapWithNulls);

      // Assert
      expect(task.id, 'task-null');
      expect(task.startDate, isNull);
      expect(task.updatedAt, isNull);
      expect(task.dueDate, isNotNull);
    });

    test('should handle optional desc field', () {
      // Arrange
      final mapWithoutDesc = TestFixtures.createTaskMap(desc: null);
      mapWithoutDesc['desc'] = null;

      // Act
      final task = Task.fromMap(mapWithoutDesc);

      // Assert
      expect(task.desc, isNull);
    });

    test('should convert Task to map correctly', () {
      // Arrange
      final task = Task.fromMap(validTaskMap);

      // Act
      final map = task.toMap();

      // Assert
      expect(map['id'], 'task-123');
      expect(map['folder_id'], 'folder-456');
      expect(map['title'], 'Test Task');
      expect(map['desc'], 'Test Description');
      expect(map['priority'], 'High');
      expect(map['status'], 'Pending');
      expect(map['start_date'], isNotNull);
      expect(map['due_date'], isNotNull);
      expect(map['created_at'], isNotNull);
      expect(map['updated_at'], isNotNull);
    });

    test('should handle invalid date format gracefully', () {
      // Arrange
      final invalidMap = TestFixtures.createTaskMap();
      invalidMap['start_date'] = 'invalid-date';

      // Act
      final task = Task.fromMap(invalidMap);

      // Assert
      expect(task.startDate, isNull); // Should return null for invalid date
    });

    test('should throw FormatException for missing required date fields', () {
      // Arrange
      final invalidMap = TestFixtures.createTaskMap();
      invalidMap['due_date'] = null; // Required field

      // Act & Assert
      expect(
        () => Task.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should handle different priority values', () {
      // Test High priority
      final highTask = Task.fromMap(
        TestFixtures.createTaskMap(priority: 'High'),
      );
      expect(highTask.priority, 'High');

      // Test Medium priority
      final mediumTask = Task.fromMap(
        TestFixtures.createTaskMap(priority: 'Medium'),
      );
      expect(mediumTask.priority, 'Medium');

      // Test Low priority
      final lowTask = Task.fromMap(
        TestFixtures.createTaskMap(priority: 'Low'),
      );
      expect(lowTask.priority, 'Low');
    });

    test('should handle different status values', () {
      // Test Pending status
      final pendingTask = Task.fromMap(
        TestFixtures.createTaskMap(status: 'Pending'),
      );
      expect(pendingTask.status, 'Pending');

      // Test Completed status
      final completedTask = Task.fromMap(
        TestFixtures.createTaskMap(status: 'Completed'),
      );
      expect(completedTask.status, 'Completed');
    });
  });
}
