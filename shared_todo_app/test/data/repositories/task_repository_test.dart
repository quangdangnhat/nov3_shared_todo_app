import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/mock_supabase_client.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('TaskRepository Tests', () {
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;
    late TaskRepository repository;
    late DateTime testDate;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      repository = TaskRepository(client: mockClient);
      testDate = DateTime(2025, 11, 13);
    });

    group('createTask', () {
      test('should create task successfully', () async {
        // Arrange
        final taskMap = TestFixtures.createTaskMap(
          id: 'new-task-id',
          folderId: 'folder-123',
          title: 'New Task',
          priority: 'High',
          status: 'Pending',
          dueDate: testDate.add(const Duration(days: 7)),
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => taskMap);

        // Act
        final task = await repository.createTask(
          folderId: 'folder-123',
          title: 'New Task',
          priority: 'High',
          status: 'Pending',
          dueDate: testDate.add(const Duration(days: 7)),
        );

        // Assert
        expect(task.id, 'new-task-id');
        expect(task.title, 'New Task');
        expect(task.priority, 'High');
        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.insert(any())).called(1);
      });

      test('should create task with optional startDate', () async {
        // Arrange
        final taskMap = TestFixtures.createTaskMap(
          id: 'task-with-start',
          startDate: testDate,
          dueDate: testDate.add(const Duration(days: 7)),
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => taskMap);

        // Act
        final task = await repository.createTask(
          folderId: 'folder-123',
          title: 'Task with Start Date',
          priority: 'Medium',
          status: 'Pending',
          startDate: testDate,
          dueDate: testDate.add(const Duration(days: 7)),
        );

        // Assert
        expect(task.startDate, isNotNull);
      });

      test('should throw exception when creation fails', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.createTask(
            folderId: 'folder-123',
            title: 'Failed Task',
            priority: 'High',
            status: 'Pending',
            dueDate: testDate,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateTask', () {
      test('should update task successfully', () async {
        // Arrange
        final updatedTaskMap = TestFixtures.createTaskMap(
          id: 'task-123',
          title: 'Updated Task',
          priority: 'Low',
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => updatedTaskMap);

        // Act
        final task = await repository.updateTask(
          taskId: 'task-123',
          title: 'Updated Task',
          priority: 'Low',
        );

        // Assert
        expect(task.title, 'Updated Task');
        expect(task.priority, 'Low');
        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.update(any())).called(1);
      });

      test('should update task status', () async {
        // Arrange
        final updatedTaskMap = TestFixtures.createTaskMap(
          id: 'task-123',
          status: 'Completed',
        );

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenAnswer((_) async => updatedTaskMap);

        // Act
        final task = await repository.updateTask(
          taskId: 'task-123',
          status: 'Completed',
        );

        // Assert
        expect(task.status, 'Completed');
      });

      test('should throw exception when update fails', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockTransformBuilder);
        when(() => mockTransformBuilder.single())
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => repository.updateTask(
            taskId: 'task-123',
            title: 'Failed Update',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteTask', () {
      test('should delete task successfully', () async {
        // Arrange
        final taskMap = TestFixtures.createTaskMap(id: 'task-to-delete');

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenAnswer((_) async => [taskMap]);

        // Act
        await repository.deleteTask('task-to-delete');

        // Assert
        verify(() => mockClient.from('tasks')).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
        verify(() => mockFilterBuilder.eq('id', 'task-to-delete')).called(1);
      });

      test('should handle non-existent task deletion', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenAnswer((_) async => []);

        // Act
        await repository.deleteTask('non-existent-task');

        // Assert - Should not throw, just complete
        verify(() => mockClient.from('tasks')).called(1);
      });

      test('should throw exception when deletion fails', () async {
        // Arrange
        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenThrow(Exception('Deletion failed'));

        // Act & Assert
        expect(
          () => repository.deleteTask('task-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getTasksForCalendar', () {
      test('should get tasks for date range', () async {
        // Arrange
        final startDate = DateTime(2025, 11, 1);
        final endDate = DateTime(2025, 11, 30);
        final tasks = [
          TestFixtures.createTaskMap(
            id: 'task-1',
            dueDate: DateTime(2025, 11, 10),
          ),
          TestFixtures.createTaskMap(
            id: 'task-2',
            dueDate: DateTime(2025, 11, 20),
          ),
        ];

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt(any(), any()))
            .thenAnswer((_) async => tasks);

        // Act
        final result = await repository.getTasksForCalendar(startDate, endDate);

        // Assert
        expect(result.length, 2);
        expect(result[0].id, 'task-1');
        expect(result[1].id, 'task-2');
        verify(() => mockClient.from('tasks')).called(1);
      });

      test('should return empty list when no tasks in range', () async {
        // Arrange
        final startDate = DateTime(2025, 11, 1);
        final endDate = DateTime(2025, 11, 30);

        when(() => mockClient.from('tasks')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.gte(any(), any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.lt(any(), any()))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getTasksForCalendar(startDate, endDate);

        // Assert
        expect(result.isEmpty, isTrue);
      });
    });
  });
}
