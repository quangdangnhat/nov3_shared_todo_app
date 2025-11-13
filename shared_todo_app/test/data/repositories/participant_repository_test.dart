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
  });
}
