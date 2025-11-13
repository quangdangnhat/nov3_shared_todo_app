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

    test('should throw FormatException for invalid required date type', () {
      // Arrange
      final invalidMap = TestFixtures.createTaskMap();
      invalidMap['due_date'] = 123; // Wrong type (number instead of string)

      // Act & Assert
      expect(
        () => Task.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw FormatException for invalid created_at date', () {
      // Arrange
      final invalidMap = TestFixtures.createTaskMap();
      invalidMap['created_at'] = 'not-a-valid-date';

      // Act & Assert
      expect(
        () => Task.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should handle missing created_at field', () {
      // Arrange
      final invalidMap = TestFixtures.createTaskMap();
      invalidMap['created_at'] = null;

      // Act & Assert
      expect(
        () => Task.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should convert task with null fields to map', () {
      // Arrange
      final mapWithNulls = TestFixtures.createTaskMap(
        startDate: null,
        updatedAt: null,
        desc: null,
      );
      mapWithNulls.remove('start_date');
      mapWithNulls.remove('updated_at');
      mapWithNulls['desc'] = null;

      final task = Task.fromMap(mapWithNulls);

      // Act
      final map = task.toMap();

      // Assert
      expect(map['start_date'], isNull);
      expect(map['updated_at'], isNull);
      expect(map['desc'], isNull);
      expect(map['id'], isNotNull);
      expect(map['folder_id'], isNotNull);
      expect(map['title'], isNotNull);
      expect(map['priority'], isNotNull);
      expect(map['status'], isNotNull);
      expect(map['due_date'], isNotNull);
      expect(map['created_at'], isNotNull);
    });

    test('should preserve all field values in toMap', () {
      // Arrange
      final task = Task.fromMap(validTaskMap);

      // Act
      final map = task.toMap();
      final reconstructedTask = Task.fromMap(map);

      // Assert
      expect(reconstructedTask.id, task.id);
      expect(reconstructedTask.folderId, task.folderId);
      expect(reconstructedTask.title, task.title);
      expect(reconstructedTask.desc, task.desc);
      expect(reconstructedTask.priority, task.priority);
      expect(reconstructedTask.status, task.status);
      expect(reconstructedTask.startDate?.toIso8601String(),
             task.startDate?.toIso8601String());
      expect(reconstructedTask.dueDate.toIso8601String(),
             task.dueDate.toIso8601String());
      expect(reconstructedTask.createdAt.toIso8601String(),
             task.createdAt.toIso8601String());
      expect(reconstructedTask.updatedAt?.toIso8601String(),
             task.updatedAt?.toIso8601String());
    });

    test('should handle task with empty description', () {
      // Arrange
      final mapWithEmptyDesc = TestFixtures.createTaskMap(desc: '');

      // Act
      final task = Task.fromMap(mapWithEmptyDesc);

      // Assert
      expect(task.desc, '');
      expect(task.desc, isNotNull);
      expect(task.desc, isEmpty);
    });

    test('should handle task with very long title', () {
      // Arrange
      final longTitle = 'A' * 1000;
      final mapWithLongTitle = TestFixtures.createTaskMap(title: longTitle);

      // Act
      final task = Task.fromMap(mapWithLongTitle);

      // Assert
      expect(task.title, longTitle);
      expect(task.title.length, 1000);
    });

    test('should handle task with special characters in title', () {
      // Arrange
      const specialTitle = 'Task with special chars: <>&"\' emoji 🎉';
      final mapWithSpecialTitle = TestFixtures.createTaskMap(title: specialTitle);

      // Act
      final task = Task.fromMap(mapWithSpecialTitle);

      // Assert
      expect(task.title, specialTitle);
    });

    test('should handle task created in the past', () {
      // Arrange
      final pastDate = DateTime(2020, 1, 1);
      final mapWithPastDate = TestFixtures.createTaskMap(
        createdAt: pastDate,
        dueDate: pastDate.add(const Duration(days: 1)),
      );

      // Act
      final task = Task.fromMap(mapWithPastDate);

      // Assert
      expect(task.createdAt.isBefore(DateTime.now()), isTrue);
      expect(task.createdAt.year, 2020);
    });

    test('should handle task due in the future', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final mapWithFutureDate = TestFixtures.createTaskMap(
        dueDate: futureDate,
      );

      // Act
      final task = Task.fromMap(mapWithFutureDate);

      // Assert
      expect(task.dueDate.isAfter(DateTime.now()), isTrue);
    });

    test('should handle task with startDate after dueDate', () {
      // This is logically invalid but the model should still accept it
      // Arrange
      final dueDate = DateTime.now();
      final startDate = dueDate.add(const Duration(days: 1));
      final mapWithInvalidDates = TestFixtures.createTaskMap(
        startDate: startDate,
        dueDate: dueDate,
      );

      // Act
      final task = Task.fromMap(mapWithInvalidDates);

      // Assert
      expect(task.startDate!.isAfter(task.dueDate), isTrue);
    });

    test('should handle ISO 8601 date strings correctly', () {
      // Arrange
      final date = DateTime(2025, 11, 13, 14, 30, 45);
      final isoString = date.toIso8601String();
      final mapWithIsoDate = TestFixtures.createTaskMap(
        dueDate: DateTime.parse(isoString),
      );
      mapWithIsoDate['due_date'] = isoString;

      // Act
      final task = Task.fromMap(mapWithIsoDate);

      // Assert
      expect(task.dueDate.toIso8601String(), isoString);
    });

    test('should handle task with all Italian priority values', () {
      // Test Alta
      final altaTask = Task.fromMap(
        TestFixtures.createTaskMap(priority: 'Alta'),
      );
      expect(altaTask.priority, 'Alta');

      // Test Media
      final mediaTask = Task.fromMap(
        TestFixtures.createTaskMap(priority: 'Media'),
      );
      expect(mediaTask.priority, 'Media');

      // Test Bassa
      final bassaTask = Task.fromMap(
        TestFixtures.createTaskMap(priority: 'Bassa'),
      );
      expect(bassaTask.priority, 'Bassa');
    });

    test('should create task with constructor directly', () {
      // Arrange & Act
      final task = Task(
        id: 'direct-123',
        folderId: 'folder-789',
        title: 'Direct Task',
        desc: 'Created directly',
        priority: 'High',
        status: 'In Progress',
        startDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(task.id, 'direct-123');
      expect(task.folderId, 'folder-789');
      expect(task.title, 'Direct Task');
      expect(task.desc, 'Created directly');
      expect(task.priority, 'High');
      expect(task.status, 'In Progress');
      expect(task.startDate, isNotNull);
      expect(task.dueDate, isNotNull);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('should create task without optional fields using constructor', () {
      // Arrange & Act
      final task = Task(
        id: 'minimal-123',
        folderId: 'folder-456',
        title: 'Minimal Task',
        priority: 'Low',
        status: 'Pending',
        dueDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Assert
      expect(task.id, 'minimal-123');
      expect(task.desc, isNull);
      expect(task.startDate, isNull);
      expect(task.updatedAt, isNull);
    });
  });
}
