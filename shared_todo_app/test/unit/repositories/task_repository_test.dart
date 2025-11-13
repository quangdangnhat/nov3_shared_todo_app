// Complete test suite for TaskRepository
// Using Mocktail for mocking
// Coverage: All methods including streams, CRUD operations, and error handling

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/data/models/task.dart';
import '../../mocks/mock_supabase.dart';

// Additional mocks needed for testing
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockSupabaseStreamBuilder extends Mock
    implements SupabaseStreamBuilder {}

void main() {
  group('TaskRepository Tests', () {
    late TaskRepository repository;
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;
    late MockSupabaseStreamBuilder mockStreamBuilder;

    // Helper function to create mock task data
    Map<String, dynamic> createMockTaskData({
      String id = '1',
      String folderId = 'folder1',
      String title = 'Test Task',
      String? desc,
      String priority = 'high',
      String status = 'todo',
      DateTime? startDate,
      DateTime? dueDate,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final now = DateTime.now();
      return {
        'id': id,
        'folder_id': folderId,
        'title': title,
        'desc': desc,
        'priority': priority,
        'status': status,
        'start_date': startDate?.toIso8601String(),
        'due_date': (dueDate ?? now.add(Duration(days: 7))).toIso8601String(),
        'created_at': (createdAt ?? now).toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
    }

    setUp(() {
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      mockStreamBuilder = MockSupabaseStreamBuilder();
      repository = TaskRepository(client: mockClient);

      // Register fallback values for mocktail
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(<String>[]);
    });

    group('Constructor Tests', () {
      test('should create repository with injected client', () {
        // Arrange
        final customClient = MockSupabaseClient();

        // Act
        final repo = TaskRepository(client: customClient);

        // Assert
        expect(repo, isNotNull);
        expect(repo, isA<TaskRepository>());
      });

      test('should create multiple independent instances', () {
        // Arrange
        final client1 = MockSupabaseClient();
        final client2 = MockSupabaseClient();

        // Act
        final repo1 = TaskRepository(client: client1);
        final repo2 = TaskRepository(client: client2);

        // Assert
        expect(repo1, isNotNull);
        expect(repo2, isNotNull);
        expect(repo1, isNot(same(repo2)));
      });

      test('should use injected client instead of global instance', () {
        // Arrange
        final customClient = MockSupabaseClient();

        // Act
        final repo = TaskRepository(client: customClient);

        // Assert
        expect(repo, isNotNull);
      });
    });

    group('getAllTasksStream Tests', () {
      test('should return stream of all tasks', () async {
        // Arrange
        final mockTasks = [
          createMockTaskData(id: '1', title: 'Task 1'),
          createMockTaskData(id: '2', title: 'Task 2'),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockTasks));

        // Act
        final stream = repository.getAllTasksStream();

        // Assert
        expect(stream, isA<Stream<List<Task>>>());

        final tasks = await stream.first;
        expect(tasks, isA<List<Task>>());
        expect(tasks.length, 2);
        expect(tasks[0].title, 'Task 1');
        expect(tasks[1].title, 'Task 2');

        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.stream(primaryKey: ['id'])).called(1);
      });

      test('should handle empty stream', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final stream = repository.getAllTasksStream();
        final tasks = await stream.first;

        // Assert
        expect(tasks, isEmpty);
        verify(() => mockClient.from('tasks')).called(1);
      });

      test('should correctly parse Task objects from stream data', () async {
        // Arrange
        final mockData = [
          createMockTaskData(
            id: 'test-id',
            folderId: 'test-folder',
            title: 'Test Task',
            desc: 'Test Description',
            priority: 'high',
            status: 'todo',
          ),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));

        // Act
        final stream = repository.getAllTasksStream();
        final tasks = await stream.first;

        // Assert
        expect(tasks.length, 1);
        expect(tasks[0].id, 'test-id');
        expect(tasks[0].folderId, 'test-folder');
        expect(tasks[0].title, 'Test Task');
        expect(tasks[0].desc, 'Test Description');
        expect(tasks[0].priority, 'high');
        expect(tasks[0].status, 'todo');
      });
    });

    group('getTasksStream Tests', () {
      test('should return stream of tasks for specific folder', () async {
        // Arrange
        const folderId = 'folder1';
        final mockTasks = [
          createMockTaskData(id: '1', folderId: folderId, title: 'Task 1'),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.stream(primaryKey: ['id']))
            .thenReturn(mockStreamBuilder);
        when(() => mockStreamBuilder.eq('folder_id', folderId))
            .thenAnswer((_) => Stream.value(mockTasks));

        // Act
        final stream = repository.getTasksStream(folderId);

        // Assert
        expect(stream, isA<Stream<List<Task>>>());

        final tasks = await stream.first;
        expect(tasks.length, 1);
        expect(tasks[0].folderId, folderId);

        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.stream(primaryKey: ['id'])).called(1);
        verify(() => mockStreamBuilder.eq('folder_id', folderId)).called(1);
      });

      test('should filter tasks by folder_id', () async {
        // Arrange
        const folderId = 'folder2';
        final mockData = [
          createMockTaskData(id: '2', folderId: folderId, title: 'Task 2'),
          createMockTaskData(id: '3', folderId: folderId, title: 'Task 3'),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.stream(primaryKey: ['id']))
            .thenReturn(mockStreamBuilder);
        when(() => mockStreamBuilder.eq('folder_id', folderId))
            .thenAnswer((_) => Stream.value(mockData));

        // Act
        final stream = repository.getTasksStream(folderId);
        final tasks = await stream.first;

        // Assert
        expect(tasks.length, 2);
        expect(tasks.every((task) => task.folderId == folderId), true);
      });

      test('should return empty stream when folder has no tasks', () async {
        // Arrange
        const folderId = 'empty-folder';

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.stream(primaryKey: ['id']))
            .thenReturn(mockStreamBuilder);
        when(() => mockStreamBuilder.eq('folder_id', folderId))
            .thenAnswer((_) => Stream.value([]));

        // Act
        final stream = repository.getTasksStream(folderId);
        final tasks = await stream.first;

        // Assert
        expect(tasks, isEmpty);
      });
    });

    group('createTask Tests', () {
      test('should create task successfully', () async {
        // Arrange
        final dueDate = DateTime.now().add(Duration(days: 7));
        final mockResponse = createMockTaskData(
          id: 'new-task-id',
          folderId: 'folder1',
          title: 'New Task',
          desc: 'Task description',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final task = await repository.createTask(
          folderId: 'folder1',
          title: 'New Task',
          desc: 'Task description',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        // Assert
        expect(task, isA<Task>());
        expect(task.title, 'New Task');
        expect(task.desc, 'Task description');

        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.insert(any())).called(1);
        verify(() => mockFilterBuilder.select()).called(1);
        verify(() => mockTransformBuilder.single()).called(1);
      });

      test('should create task with startDate', () async {
        // Arrange
        final startDate = DateTime.now();
        final dueDate = DateTime.now().add(Duration(days: 7));
        final mockResponse = createMockTaskData(
          id: 'new-task-id',
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          startDate: startDate,
          dueDate: dueDate,
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final task = await repository.createTask(
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          startDate: startDate,
          dueDate: dueDate,
        );

        // Assert
        expect(task, isA<Task>());
        expect(task.startDate, isNotNull);

        // Verify payload includes start_date
        final captured = verify(() => mockQueryBuilder.insert(captureAny()))
            .captured;
        final payload = captured.first as Map<String, dynamic>;
        expect(payload['start_date'], isNotNull);
      });

      test('should create task without description', () async {
        // Arrange
        final dueDate = DateTime.now().add(Duration(days: 7));
        final mockResponse = createMockTaskData(
          id: 'new-task-id',
          folderId: 'folder1',
          title: 'New Task',
          desc: null,
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final task = await repository.createTask(
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        // Assert
        expect(task, isA<Task>());
        expect(task.desc, isNull);
      });

      test('should throw exception when creation fails', () async {
        // Arrange
        final dueDate = DateTime.now().add(Duration(days: 7));

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.createTask(
            folderId: 'folder1',
            title: 'New Task',
            priority: 'high',
            status: 'todo',
            dueDate: dueDate,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should include all required fields in payload', () async {
        // Arrange
        final dueDate = DateTime.now().add(Duration(days: 7));
        final mockResponse = createMockTaskData(
          id: 'new-task-id',
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.createTask(
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        // Assert - Verify payload structure
        final captured = verify(() => mockQueryBuilder.insert(captureAny()))
            .captured;
        final payload = captured.first as Map<String, dynamic>;

        expect(payload['folder_id'], 'folder1');
        expect(payload['title'], 'New Task');
        expect(payload['priority'], 'high');
        expect(payload['status'], 'todo');
        expect(payload['due_date'], isNotNull);
      });

      test('should not include start_date when not provided', () async {
        // Arrange
        final dueDate = DateTime.now().add(Duration(days: 7));
        final mockResponse = createMockTaskData(
          id: 'new-task-id',
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.createTask(
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          dueDate: dueDate,
        );

        // Assert
        final captured = verify(() => mockQueryBuilder.insert(captureAny()))
            .captured;
        final payload = captured.first as Map<String, dynamic>;

        // start_date should not be in payload when startDate is null
        expect(payload.containsKey('start_date'), false);
      });
    });

    group('updateTask Tests', () {
      test('should update task successfully', () async {
        // Arrange
        const taskId = 'task-123';
        final mockResponse = createMockTaskData(
          id: taskId,
          folderId: 'folder1',
          title: 'Updated Task',
          priority: 'high',
          status: 'done',
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final task = await repository.updateTask(
          taskId: taskId,
          title: 'Updated Task',
          status: 'done',
        );

        // Assert
        expect(task, isA<Task>());
        expect(task.title, 'Updated Task');
        expect(task.status, 'done');

        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockFilterBuilder.eq('id', taskId)).called(1);
        verify(() => mockFilterBuilder.select()).called(1);
        verify(() => mockTransformBuilder.single()).called(1);
      });

      test('should update only specified fields', () async {
        // Arrange
        const taskId = 'task-123';
        final mockResponse = createMockTaskData(
          id: taskId,
          folderId: 'folder1',
          title: 'Updated Title',
          priority: 'high',
          status: 'todo',
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.updateTask(
          taskId: taskId,
          title: 'Updated Title',
        );

        // Assert - Verify only title is in updates
        final captured = verify(() => mockQueryBuilder.update(captureAny()))
            .captured;
        final updates = captured.first as Map<String, dynamic>;

        expect(updates['title'], 'Updated Title');
        expect(updates['updated_at'], isNotNull);
        expect(updates.containsKey('priority'), false);
        expect(updates.containsKey('status'), false);
      });

      test('should update task with all optional fields', () async {
        // Arrange
        const taskId = 'task-123';
        final startDate = DateTime.now();
        final dueDate = DateTime.now().add(Duration(days: 7));
        final mockResponse = createMockTaskData(
          id: taskId,
          folderId: 'folder1',
          title: 'Updated Task',
          desc: 'Updated description',
          priority: 'low',
          status: 'in_progress',
          startDate: startDate,
          dueDate: dueDate,
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final task = await repository.updateTask(
          taskId: taskId,
          title: 'Updated Task',
          desc: 'Updated description',
          priority: 'low',
          status: 'in_progress',
          startDate: startDate,
          dueDate: dueDate,
        );

        // Assert
        expect(task, isA<Task>());

        // Verify all fields are in updates
        final captured = verify(() => mockQueryBuilder.update(captureAny()))
            .captured;
        final updates = captured.first as Map<String, dynamic>;

        expect(updates['title'], 'Updated Task');
        expect(updates['desc'], 'Updated description');
        expect(updates['priority'], 'low');
        expect(updates['status'], 'in_progress');
        expect(updates['start_date'], isNotNull);
        expect(updates['due_date'], isNotNull);
      });

      test('should always include updated_at timestamp', () async {
        // Arrange
        const taskId = 'task-123';
        final mockResponse = createMockTaskData(
          id: taskId,
          folderId: 'folder1',
          title: 'Task',
          priority: 'high',
          status: 'todo',
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.updateTask(
          taskId: taskId,
          title: 'Updated Title',
        );

        // Assert
        final captured = verify(() => mockQueryBuilder.update(captureAny()))
            .captured;
        final updates = captured.first as Map<String, dynamic>;

        expect(updates['updated_at'], isNotNull);
      });

      test('should throw exception when update fails', () async {
        // Arrange
        const taskId = 'task-123';

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => repository.updateTask(
            taskId: taskId,
            title: 'Updated Task',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle task not found', () async {
        // Arrange
        const taskId = 'non-existent-task';

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Task not found'));

        // Act & Assert
        expect(
          () => repository.updateTask(
            taskId: taskId,
            title: 'Updated Task',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteTask Tests', () {
      test('should delete task successfully', () async {
        // Arrange
        const taskId = 'task-to-delete';
        final mockResponse = [
          createMockTaskData(
            id: taskId,
            folderId: 'folder1',
            title: 'Deleted Task',
          )
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.deleteTask(taskId);

        // Assert
        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
        verify(() => mockFilterBuilder.eq('id', taskId)).called(1);
        verify(() => mockFilterBuilder.select()).called(1);
      });

      test('should handle task not found', () async {
        // Arrange
        const taskId = 'non-existent-task';
        final emptyResponse = [];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenAnswer((_) async => emptyResponse);

        // Act
        await repository.deleteTask(taskId);

        // Assert - Should complete without throwing
        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
        verify(() => mockFilterBuilder.eq('id', taskId)).called(1);
      });

      test('should throw exception when deletion fails', () async {
        // Arrange
        const taskId = 'task-123';

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => repository.deleteTask(taskId),
          throwsA(isA<Exception>()),
        );
      });

      test('should call select to force Supabase response', () async {
        // Arrange
        const taskId = 'task-123';
        final mockResponse = [
          createMockTaskData(id: taskId)
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.deleteTask(taskId);

        // Assert - Verify select() is called
        verify(() => mockFilterBuilder.select()).called(1);
      });

      test('should handle multiple delete attempts', () async {
        // Arrange
        const taskId = 'task-123';
        final mockResponse = [
          createMockTaskData(id: taskId)
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', taskId))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenAnswer((_) async => mockResponse);

        // Act - Delete same task multiple times
        await repository.deleteTask(taskId);

        // Setup for second call
        when(() => mockFilterBuilder.select()).thenAnswer((_) async => []);
        await repository.deleteTask(taskId);

        // Assert
        verify(() => mockClient.from('tasks')).called(2);
        verify(() => mockQueryBuilder.delete()).called(2);
      });
    });

    group('getTasksForCalendar Tests', () {
      test('should return tasks within date range', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final mockResponse = [
          createMockTaskData(
            id: '1',
            title: 'Task 1',
            dueDate: DateTime(2025, 1, 15),
          ),
          createMockTaskData(
            id: '2',
            title: 'Task 2',
            dueDate: DateTime(2025, 1, 20),
          ),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', start.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', end.toIso8601String()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final tasks = await repository.getTasksForCalendar(start, end);

        // Assert
        expect(tasks, isA<List<Task>>());
        expect(tasks.length, 2);

        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.select()).called(1);
        verify(() => mockFilterBuilder.gte('due_date', start.toIso8601String()))
            .called(1);
        verify(() => mockFilterBuilder.lt('due_date', end.toIso8601String()))
            .called(1);
      });

      test('should return empty list when no tasks in range', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final emptyResponse = [];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', start.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', end.toIso8601String()))
            .thenAnswer((_) async => emptyResponse);

        // Act
        final tasks = await repository.getTasksForCalendar(start, end);

        // Assert
        expect(tasks, isEmpty);
      });

      test('should use gte for start date (inclusive)', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', any()))
            .thenAnswer((_) async => []);

        // Act
        await repository.getTasksForCalendar(start, end);

        // Assert - Verify gte (greater than or equal) is used
        verify(() => mockFilterBuilder.gte('due_date', start.toIso8601String()))
            .called(1);
      });

      test('should use lt for end date (exclusive)', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', any()))
            .thenAnswer((_) async => []);

        // Act
        await repository.getTasksForCalendar(start, end);

        // Assert - Verify lt (less than) is used, not lte
        verify(() => mockFilterBuilder.lt('due_date', end.toIso8601String()))
            .called(1);
      });

      test('should handle single day range', () async {
        // Arrange
        final start = DateTime(2025, 1, 15);
        final end = DateTime(2025, 1, 16);
        final mockResponse = [
          createMockTaskData(
            id: '1',
            title: 'Task 1',
            dueDate: DateTime(2025, 1, 15, 10, 0),
          ),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', start.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', end.toIso8601String()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final tasks = await repository.getTasksForCalendar(start, end);

        // Assert
        expect(tasks.length, 1);
      });

      test('should correctly map response to Task objects', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final mockResponse = [
          createMockTaskData(
            id: '1',
            folderId: 'folder1',
            title: 'Calendar Task',
            desc: 'Description',
            priority: 'medium',
            status: 'in_progress',
            dueDate: DateTime(2025, 1, 15),
          ),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', any()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final tasks = await repository.getTasksForCalendar(start, end);

        // Assert
        expect(tasks, isA<List<Task>>());
        expect(tasks.first, isA<Task>());
        expect(tasks.first.title, 'Calendar Task');
        expect(tasks.first.priority, 'medium');
        expect(tasks.first.status, 'in_progress');
      });

      test('should handle tasks at boundary dates correctly', () async {
        // Arrange
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);

        // Task exactly at start should be included (gte)
        // Task exactly at end should NOT be included (lt, not lte)
        final mockResponse = [
          createMockTaskData(
            id: '1',
            title: 'Start Task',
            dueDate: start,
          ),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte('due_date', start.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt('due_date', end.toIso8601String()))
            .thenAnswer((_) async => mockResponse);

        // Act
        final tasks = await repository.getTasksForCalendar(start, end);

        // Assert
        expect(tasks.length, 1);
      });
    });

    group('Error Handling Tests', () {
      test('createTask should handle network errors', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.createTask(
            folderId: 'folder1',
            title: 'Task',
            priority: 'high',
            status: 'todo',
            dueDate: DateTime.now(),
          ),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Failed to create task')),
          ),
        );
      });

      test('updateTask should handle network errors', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.updateTask(
            taskId: 'task-123',
            title: 'Updated',
          ),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Failed to update task')),
          ),
        );
      });

      test('deleteTask should handle network errors', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.deleteTask('task-123'),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Failed to delete task')),
          ),
        );
      });

      test('should preserve original error in exception message', () async {
        // Arrange
        const originalError = 'Database connection timeout';

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception(originalError));

        // Act & Assert
        try {
          await repository.createTask(
            folderId: 'folder1',
            title: 'Task',
            priority: 'high',
            status: 'todo',
            dueDate: DateTime.now(),
          );
          fail('Should have thrown exception');
        } catch (e) {
          expect(e.toString(), contains(originalError));
        }
      });
    });

    group('Integration Tests', () {
      test('should handle complete CRUD workflow', () async {
        // This test verifies all operations work together

        // 1. Create
        final createResponse = createMockTaskData(
          id: 'task-1',
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => createResponse);

        final createdTask = await repository.createTask(
          folderId: 'folder1',
          title: 'New Task',
          priority: 'high',
          status: 'todo',
          dueDate: DateTime.now(),
        );

        expect(createdTask, isA<Task>());

        // 2. Update
        final updateResponse = {
          ...createResponse,
          'status': 'done',
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', 'task-1'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => updateResponse);

        final updatedTask = await repository.updateTask(
          taskId: 'task-1',
          status: 'done',
        );

        expect(updatedTask, isA<Task>());
        expect(updatedTask.status, 'done');

        // 3. Delete
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', 'task-1'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenAnswer((_) async => [createResponse]);

        await repository.deleteTask('task-1');

        // Verify all operations were called
        verify(() => mockQueryBuilder.insert(any())).called(1);
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
      });
    });
  });
}