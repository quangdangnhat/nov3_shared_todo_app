import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/participant.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  group('Participant Model Tests', () {
    late Map<String, dynamic> validParticipantMap;

    setUp(() {
      validParticipantMap = TestFixtures.createParticipantMap(
        userId: 'user-123',
        todoListId: 'list-456',
        role: 'admin',
        username: 'johndoe',
        email: 'john@example.com',
      );
    });

    test('should create Participant from valid map', () {
      // Act
      final participant = Participant.fromMap(validParticipantMap);

      // Assert
      expect(participant.userId, 'user-123');
      expect(participant.todoListId, 'list-456');
      expect(participant.role, 'admin');
      expect(participant.username, 'johndoe');
      expect(participant.email, 'john@example.com');
    });

    test('should handle nested users data', () {
      // Arrange
      final mapWithNestedUsers = {
        'user_id': 'user-789',
        'todo_list_id': 'list-999',
        'role': 'collaborator',
        'users': {
          'username': 'janedoe',
          'email': 'jane@example.com',
        },
      };

      // Act
      final participant = Participant.fromMap(mapWithNestedUsers);

      // Assert
      expect(participant.userId, 'user-789');
      expect(participant.username, 'janedoe');
      expect(participant.email, 'jane@example.com');
      expect(participant.role, 'collaborator');
    });

    test('should handle null users data gracefully', () {
      // Arrange
      final mapWithNullUsers = {
        'user_id': 'user-000',
        'todo_list_id': 'list-000',
        'role': 'viewer',
        'users': null,
      };

      // Act
      final participant = Participant.fromMap(mapWithNullUsers);

      // Assert
      expect(participant.userId, 'user-000');
      expect(participant.username, 'Unknown User');
      expect(participant.email, 'Unknown Email');
      expect(participant.role, 'viewer');
    });

    test('should handle missing users field', () {
      // Arrange
      final mapWithoutUsers = {
        'user_id': 'user-111',
        'todo_list_id': 'list-111',
        'role': 'collaborator',
      };

      // Act
      final participant = Participant.fromMap(mapWithoutUsers);

      // Assert
      expect(participant.userId, 'user-111');
      expect(participant.username, 'Unknown User');
      expect(participant.email, 'Unknown Email');
    });

    test('should handle null username in users data', () {
      // Arrange
      final mapWithNullUsername = {
        'user_id': 'user-222',
        'todo_list_id': 'list-222',
        'role': 'admin',
        'users': {
          'username': null,
          'email': 'test@example.com',
        },
      };

      // Act
      final participant = Participant.fromMap(mapWithNullUsername);

      // Assert
      expect(participant.username, 'Unknown User');
      expect(participant.email, 'test@example.com');
    });

    test('should handle null email in users data', () {
      // Arrange
      final mapWithNullEmail = {
        'user_id': 'user-333',
        'todo_list_id': 'list-333',
        'role': 'collaborator',
        'users': {
          'username': 'testuser',
          'email': null,
        },
      };

      // Act
      final participant = Participant.fromMap(mapWithNullEmail);

      // Assert
      expect(participant.username, 'testuser');
      expect(participant.email, 'Unknown Email');
    });

    test('should create empty Participant', () {
      // Act
      final participant = Participant.empty();

      // Assert
      expect(participant.userId, '');
      expect(participant.todoListId, '');
      expect(participant.role, 'collaborator');
      expect(participant.username, 'Unknown User');
      expect(participant.email, 'Unknown Email');
    });

    test('should handle different role values', () {
      // Test admin
      final admin = Participant.fromMap(
        TestFixtures.createParticipantMap(role: 'admin'),
      );
      expect(admin.role, 'admin');

      // Test collaborator
      final collaborator = Participant.fromMap(
        TestFixtures.createParticipantMap(role: 'collaborator'),
      );
      expect(collaborator.role, 'collaborator');

      // Test viewer
      final viewer = Participant.fromMap(
        TestFixtures.createParticipantMap(role: 'viewer'),
      );
      expect(viewer.role, 'viewer');
    });

    test('should maintain data integrity from join query', () {
      // Arrange - Simulating a Supabase join query result
      final joinResult = {
        'user_id': 'user-join-test',
        'todo_list_id': 'list-join-test',
        'role': 'admin',
        'users': {
          'username': 'joinuser',
          'email': 'join@test.com',
        },
      };

      // Act
      final participant = Participant.fromMap(joinResult);

      // Assert - All data should be correctly extracted
      expect(participant.userId, 'user-join-test');
      expect(participant.todoListId, 'list-join-test');
      expect(participant.role, 'admin');
      expect(participant.username, 'joinuser');
      expect(participant.email, 'join@test.com');
    });
  });
}
