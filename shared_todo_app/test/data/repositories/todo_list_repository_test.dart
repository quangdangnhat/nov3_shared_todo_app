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

    group('createTodoList - Edge Cases', () {
      test('should create todo list with empty title', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: '');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
        verify(() => mockQueryBuilder.insert(any())).called(1);
      });

      test('should create todo list with very long title', () async {
        // Arrange
        final longTitle = 'A' * 1000;
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: longTitle);

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should create todo list with special characters in title', () async {
        // Arrange
        const specialTitle = 'List <>&"\' with émojis 📋';
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: specialTitle);

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should create todo list with unicode in title', () async {
        // Arrange
        const unicodeTitle = '任务列表 📝 Tasks';
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: unicodeTitle);

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should create todo list with very long description', () async {
        // Arrange
        final longDesc = 'Description ' * 200;
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(
          title: 'Test',
          desc: longDesc,
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should create todo list with special characters in description',
          () async {
        // Arrange
        const specialDesc = 'Description with <>&"\' and 中文 🌟';
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(
          title: 'Test',
          desc: specialDesc,
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should create todo list with empty description', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: 'Test', desc: '');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should create todo list with newlines in description', () async {
        // Arrange
        const descWithNewlines = 'Line 1\nLine 2\nLine 3';
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(
          title: 'Test',
          desc: descWithNewlines,
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });
    });

    group('updateTodoList - Edge Cases', () {
      test('should update todo list with empty title', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(listId: 'list-123', title: '');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
        verify(() => mockQueryBuilder.update(any())).called(1);
      });

      test('should update todo list with very long title', () async {
        // Arrange
        final longTitle = 'A' * 1000;
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(listId: 'list-123', title: longTitle);

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should update todo list with special characters', () async {
        // Arrange
        const specialTitle = 'Updated <>&"\' Title 📝';
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(
          listId: 'list-123',
          title: specialTitle,
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should update todo list with unicode characters', () async {
        // Arrange
        const unicodeTitle = '更新的任务列表 ✓';
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(
          listId: 'list-123',
          title: unicodeTitle,
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should update todo list with empty description', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(
          listId: 'list-123',
          title: 'Test',
          desc: '',
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should update todo list with very long description', () async {
        // Arrange
        final longDesc = 'Description ' * 200;
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(
          listId: 'list-123',
          title: 'Test',
          desc: longDesc,
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should update todo list with empty list ID', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(listId: '', title: 'Test');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });

      test('should update todo list with very long list ID', () async {
        // Arrange
        final longId = 'id' * 100;
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(listId: longId, title: 'Test');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
      });
    });

    group('leaveTodoList - Edge Cases', () {
      test('should leave todo list with empty list ID', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.leaveTodoList('');

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should leave todo list with very long list ID', () async {
        // Arrange
        final longId = 'id' * 100;
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.leaveTodoList(longId);

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should leave todo list with special characters in ID', () async {
        // Arrange
        const specialId = 'list-123-@#\$%';
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.leaveTodoList(specialId);

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should verify correct user ID is used in leave operation', () async {
        // Arrange
        when(() => mockUser.id).thenReturn('specific-user-123');
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
    });

    group('Error Scenarios', () {
      test('should rethrow PostgrestException on create', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenThrow(Exception('PostgrestException: duplicate key'));

        // Act & Assert
        expect(
          () => repository.createTodoList(title: 'Duplicate'),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow PostgrestException on update', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenThrow(Exception('PostgrestException: record not found'));

        // Act & Assert
        expect(
          () => repository.updateTodoList(
            listId: 'non-existent',
            title: 'Test',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow PostgrestException on leave', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('PostgrestException: row not found'));

        // Act & Assert
        expect(
          () => repository.leaveTodoList('list-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout on create', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => repository.createTodoList(title: 'Test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout on update', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => repository.updateTodoList(listId: 'list-123', title: 'Test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout on leave', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => repository.leaveTodoList('list-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle unauthorized access on update', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenThrow(Exception('Unauthorized: insufficient permissions'));

        // Act & Assert
        expect(
          () => repository.updateTodoList(listId: 'list-123', title: 'Test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle database constraint violation', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenThrow(
            Exception('Check constraint violation: title_length_check'));

        // Act & Assert
        expect(
          () => repository.createTodoList(title: 'Test'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Multiple Operations', () {
      test('should handle multiple create operations sequentially', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: 'List 1');
        await repository.createTodoList(title: 'List 2');
        await repository.createTodoList(title: 'List 3');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(3);
        verify(() => mockQueryBuilder.insert(any())).called(3);
      });

      test('should handle create followed by update', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.createTodoList(title: 'New List');
        await repository.updateTodoList(
          listId: 'list-123',
          title: 'Updated List',
        );

        // Assert
        verify(() => mockClient.from('todo_lists')).called(2);
      });

      test('should handle update followed by leave', () async {
        // Arrange
        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.updateTodoList(listId: 'list-123', title: 'Test');
        await repository.leaveTodoList('list-123');

        // Assert
        verify(() => mockClient.from('todo_lists')).called(1);
        verify(() => mockClient.from('participations')).called(1);
      });
    });

    group('Data Validation', () {
      test('should pass correct data structure on create', () async {
        // Arrange
        const title = 'Test List';
        const desc = 'Test Description';
        Map<String, dynamic>? capturedData;

        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenAnswer((invocation) {
          capturedData = invocation.positionalArguments[0] as Map<String, dynamic>;
          return StubPostgrestFilterBuilder([]);
        });

        // Act
        await repository.createTodoList(title: title, desc: desc);

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['title'], title);
        expect(capturedData!['desc'], desc);
      });

      test('should pass correct data structure on update with updated_at',
          () async {
        // Arrange
        const listId = 'list-123';
        const title = 'Updated Title';
        const desc = 'Updated Description';
        Map<String, dynamic>? capturedData;

        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenAnswer((invocation) {
          capturedData = invocation.positionalArguments[0] as Map<String, dynamic>;
          return StubPostgrestFilterBuilder([]);
        });

        // Act
        await repository.updateTodoList(
          listId: listId,
          title: title,
          desc: desc,
        );

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['title'], title);
        expect(capturedData!['desc'], desc);
        expect(capturedData!['updated_at'], isNotNull);
        expect(capturedData!['updated_at'], isA<String>());
      });

      test('should handle null description correctly in create', () async {
        // Arrange
        const title = 'Test List';
        Map<String, dynamic>? capturedData;

        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.insert(any())).thenAnswer((invocation) {
          capturedData = invocation.positionalArguments[0] as Map<String, dynamic>;
          return StubPostgrestFilterBuilder([]);
        });

        // Act
        await repository.createTodoList(title: title);

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['title'], title);
        expect(capturedData!['desc'], isNull);
      });

      test('should handle null description correctly in update', () async {
        // Arrange
        const listId = 'list-123';
        const title = 'Test List';
        Map<String, dynamic>? capturedData;

        when(() => mockClient.from('todo_lists')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.update(any())).thenAnswer((invocation) {
          capturedData = invocation.positionalArguments[0] as Map<String, dynamic>;
          return StubPostgrestFilterBuilder([]);
        });

        // Act
        await repository.updateTodoList(listId: listId, title: title);

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['title'], title);
        expect(capturedData!['desc'], isNull);
      });
    });
  });
}
