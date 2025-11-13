import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/repositories/participant_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/mock_supabase_client.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('ParticipantRepository Tests', () {
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late ParticipantRepository repository;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      repository = ParticipantRepository(client: mockClient);
    });

    group('getParticipants', () {
      test('should get participants successfully', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
            username: 'admin',
            email: 'admin@example.com',
          ),
          TestFixtures.createParticipantMap(
            userId: 'user-2',
            todoListId: 'list-123',
            role: 'collaborator',
            username: 'collab',
            email: 'collab@example.com',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 2);
        expect(result[0].userId, 'user-1');
        expect(result[0].role, 'admin');
        expect(result[1].userId, 'user-2');
        expect(result[1].role, 'collaborator');
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should return empty list when no participants', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.isEmpty, isTrue);
      });

      test('should throw exception when fetch fails', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenThrow(Exception('Fetch failed'));

        // Act & Assert
        expect(
          () => repository.getParticipants('list-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('removeParticipant', () {
      test('should remove participant successfully', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: 'user-456',
        );

        // Assert
        verify(() => mockClient.from('participations')).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
      });

      test('should throw exception when permission denied', () async {
        // Arrange
        final postgrestException = PostgrestException(
          message: 'Permission denied',
          code: '42501',
        );

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenThrow(postgrestException);

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('Permission denied')),
          ),
        );
      });

      test('should throw generic exception when removal fails', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Removal failed'));

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle database connection errors', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Connection timeout'));

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling', () {
      test('should handle malformed participant data', () async {
        // Arrange
        final malformedData = [
          {
            'user_id': 'user-1',
            'todo_list_id': 'list-123',
            'role': 'admin',
            // Missing 'users' field
          }
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(malformedData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert - Should use fallback values from Participant.fromMap
        expect(result.length, 1);
        expect(result[0].username, 'Unknown User');
        expect(result[0].email, 'Unknown Email');
      });

      test('should handle empty user data in join', () async {
        // Arrange
        final dataWithNullUsers = [
          {
            'user_id': 'user-1',
            'todo_list_id': 'list-123',
            'role': 'admin',
            'users': null,
          }
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(dataWithNullUsers));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].username, 'Unknown User');
        expect(result[0].email, 'Unknown Email');
      });
    });

    group('getParticipants - Edge Cases', () {
      test('should get participants with empty list ID', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        final result = await repository.getParticipants('');

        // Assert
        expect(result, isEmpty);
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should get participants with very long list ID', () async {
        // Arrange
        final longId = 'id' * 100;
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        final result = await repository.getParticipants(longId);

        // Assert
        expect(result, isEmpty);
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should get participants with special characters in list ID',
          () async {
        // Arrange
        const specialId = 'list-123-@#\$%';
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        final result = await repository.getParticipants(specialId);

        // Assert
        expect(result, isEmpty);
      });

      test('should get single participant', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
            username: 'admin',
            email: 'admin@example.com',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].userId, 'user-1');
      });

      test('should get many participants', () async {
        // Arrange
        final participantsData = List.generate(
          10,
          (i) => TestFixtures.createParticipantMap(
            userId: 'user-$i',
            todoListId: 'list-123',
            role: i == 0 ? 'admin' : 'collaborator',
            username: 'user$i',
            email: 'user$i@example.com',
          ),
        );

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 10);
        expect(result[0].role, 'admin');
        expect(result[1].role, 'collaborator');
      });

      test('should get participants with different roles', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
          ),
          TestFixtures.createParticipantMap(
            userId: 'user-2',
            todoListId: 'list-123',
            role: 'collaborator',
          ),
          TestFixtures.createParticipantMap(
            userId: 'user-3',
            todoListId: 'list-123',
            role: 'viewer',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 3);
        expect(result.map((p) => p.role).toList(),
            containsAll(['admin', 'collaborator', 'viewer']));
      });

      test('should get participants with unicode usernames', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
            username: '用户名',
            email: 'user@example.com',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].username, '用户名');
      });

      test('should get participants with special characters in email', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
            username: 'user',
            email: 'user+tag@sub-domain.example.com',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].email, 'user+tag@sub-domain.example.com');
      });
    });

    group('removeParticipant - Edge Cases', () {
      test('should remove participant with empty list ID', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: '',
          userIdToRemove: 'user-123',
        );

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should remove participant with empty user ID', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: '',
        );

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should remove participant with very long IDs', () async {
        // Arrange
        final longListId = 'list' * 100;
        final longUserId = 'user' * 100;
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: longListId,
          userIdToRemove: longUserId,
        );

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should remove participant with special characters in IDs', () async {
        // Arrange
        const specialListId = 'list-123-@#\$%';
        const specialUserId = 'user-456-@#\$%';
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: specialListId,
          userIdToRemove: specialUserId,
        );

        // Assert
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should handle removing non-existent participant', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: 'non-existent-user',
        );

        // Assert - Should not throw
        verify(() => mockClient.from('participations')).called(1);
      });

      test('should handle unauthorized removal attempt', () async {
        // Arrange
        final postgrestException = PostgrestException(
          message: 'Unauthorized',
          code: '401',
        );

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete()).thenThrow(postgrestException);

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout on removal', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle constraint violation on removal', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Foreign key constraint violation'));

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Multiple Operations', () {
      test('should get participants multiple times sequentially', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        await repository.getParticipants('list-123');
        await repository.getParticipants('list-123');
        await repository.getParticipants('list-123');

        // Assert
        verify(() => mockClient.from('participations')).called(3);
      });

      test('should remove multiple participants sequentially', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: 'user-1',
        );
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: 'user-2',
        );
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: 'user-3',
        );

        // Assert
        verify(() => mockClient.from('participations')).called(3);
        verify(() => mockQueryBuilder.delete()).called(3);
      });

      test('should get participants from different lists', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.getParticipants('list-1');
        await repository.getParticipants('list-2');
        await repository.getParticipants('list-3');

        // Assert
        verify(() => mockClient.from('participations')).called(3);
      });

      test('should handle get followed by remove', () async {
        // Arrange
        final participantsData = [
          TestFixtures.createParticipantMap(
            userId: 'user-1',
            todoListId: 'list-123',
            role: 'admin',
          ),
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));
        when(() => mockQueryBuilder.delete())
            .thenReturn(StubPostgrestFilterBuilder([]));

        // Act
        await repository.getParticipants('list-123');
        await repository.removeParticipant(
          todoListId: 'list-123',
          userIdToRemove: 'user-1',
        );

        // Assert
        verify(() => mockClient.from('participations')).called(2);
      });
    });

    group('Data Validation', () {
      test('should correctly parse participant data with all fields', () async {
        // Arrange
        final participantsData = [
          {
            'user_id': 'user-123',
            'todo_list_id': 'list-456',
            'role': 'admin',
            'users': {
              'username': 'testuser',
              'email': 'test@example.com',
            },
          }
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-456');

        // Assert
        expect(result.length, 1);
        expect(result[0].userId, 'user-123');
        expect(result[0].todoListId, 'list-456');
        expect(result[0].role, 'admin');
        expect(result[0].username, 'testuser');
        expect(result[0].email, 'test@example.com');
      });

      test('should handle participants with empty username', () async {
        // Arrange
        final participantsData = [
          {
            'user_id': 'user-1',
            'todo_list_id': 'list-123',
            'role': 'admin',
            'users': {
              'username': '',
              'email': 'user@example.com',
            },
          }
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].username, isEmpty);
      });

      test('should handle participants with empty email', () async {
        // Arrange
        final participantsData = [
          {
            'user_id': 'user-1',
            'todo_list_id': 'list-123',
            'role': 'admin',
            'users': {
              'username': 'testuser',
              'email': '',
            },
          }
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].email, isEmpty);
      });

      test('should handle participants with partial user data', () async {
        // Arrange
        final participantsData = [
          {
            'user_id': 'user-1',
            'todo_list_id': 'list-123',
            'role': 'admin',
            'users': {
              'username': 'testuser',
              // Missing email
            },
          }
        ];

        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(StubPostgrestFilterBuilder(participantsData));

        // Act
        final result = await repository.getParticipants('list-123');

        // Assert
        expect(result.length, 1);
        expect(result[0].username, 'testuser');
        expect(result[0].email, 'Unknown Email');
      });
    });

    group('Network and Database Errors', () {
      test('should throw descriptive exception on network error', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.getParticipants('list-123'),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Failed to load'))),
        );
      });

      test('should throw descriptive exception on database error', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenThrow(Exception('Database connection lost'));

        // Act & Assert
        expect(
          () => repository.getParticipants('list-123'),
          throwsA(predicate((e) =>
              e is Exception && e.toString().contains('Failed to load'))),
        );
      });

      test('should handle timeout on get participants', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenThrow(Exception('Request timeout'));

        // Act & Assert
        expect(
          () => repository.getParticipants('list-123'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle server error on remove participant', () async {
        // Arrange
        when(() => mockClient.from('participations'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.delete())
            .thenThrow(Exception('Internal server error'));

        // Act & Assert
        expect(
          () => repository.removeParticipant(
            todoListId: 'list-123',
            userIdToRemove: 'user-456',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
