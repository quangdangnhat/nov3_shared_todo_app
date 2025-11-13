import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/repositories/todo_list_repository.dart';
import '../../helpers/mock_supabase_client.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('TodoListRepository Tests', () {
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late TodoListRepository repository;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      repository = TodoListRepository(client: mockClient);

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('test-user-id');
    });

    group('createTodoList', () {
      test('should create todo list successfully', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(
          title: 'New List',
          desc: 'Description',
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
        verify(() => mockQueryBuilder.insert(any())).called(1);
      });

      test('should create todo list with null description', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: 'New List');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should throw exception when creation fails', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenThrow(Exception('Creation failed'));

        // Act & Assert
        expect(
          () => repository.createTodoList(title: 'Failed List'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateTodoList', () {
      test('should update todo list successfully', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(
          listId: 'list-123',
          title: 'Updated Title',
          desc: 'Updated Description',
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
        verify(() => mockQueryBuilder.update(any())).called(1);
      });

      test('should update todo list with null description', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(
          listId: 'list-123',
          title: 'Updated Title',
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should throw exception when update fails', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => repository.updateTodoList(
            listId: 'list-123',
            title: 'Failed Update',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('leaveTodoList', () {
      test('should leave todo list successfully', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.leaveTodoList('list-123');

        // Assert
        verify(() => mockClient.from('participations')).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
      });

      test('should throw exception when user is not authenticated', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => repository.leaveTodoList('list-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when leave fails', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Leave failed'));

        // Act & Assert
        expect(
          () => repository.leaveTodoList('list-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling', () {
      test('should handle database connection errors', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenThrow(Exception('Connection timeout'));

        // Act & Assert
        expect(
          () => repository.createTodoList(title: 'Test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle permission errors', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenThrow(Exception('Permission denied'));

        // Act & Assert
        expect(
          () => repository.updateTodoList(
            listId: 'list-123',
            title: 'Test',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
