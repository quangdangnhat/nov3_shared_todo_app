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

    test('should handle participant with special characters in username', () {
      // Arrange
      const specialUsername = 'user_name-123.test';
      final mapWithSpecialUsername = TestFixtures.createParticipantMap(
        username: specialUsername,
      );

      // Act
      final participant = Participant.fromMap(mapWithSpecialUsername);

      // Assert
      expect(participant.username, specialUsername);
    });

    test('should handle participant with very long username', () {
      // Arrange
      final longUsername = 'username' * 50;
      final mapWithLongUsername = TestFixtures.createParticipantMap(
        username: longUsername,
      );

      // Act
      final participant = Participant.fromMap(mapWithLongUsername);

      // Assert
      expect(participant.username, longUsername);
      expect(participant.username.length, greaterThan(300));
    });

    test('should handle participant with unicode characters in username', () {
      // Arrange
      const unicodeUsername = 'usuario_用户_пользователь';
      final mapWithUnicode = TestFixtures.createParticipantMap(
        username: unicodeUsername,
      );

      // Act
      final participant = Participant.fromMap(mapWithUnicode);

      // Assert
      expect(participant.username, unicodeUsername);
    });

    test('should handle different email formats', () {
      // Test standard email
      final standard = Participant.fromMap(
        TestFixtures.createParticipantMap(email: 'user@example.com'),
      );
      expect(standard.email, 'user@example.com');

      // Test email with subdomain
      final subdomain = Participant.fromMap(
        TestFixtures.createParticipantMap(email: 'user@mail.example.com'),
      );
      expect(subdomain.email, 'user@mail.example.com');

      // Test email with plus sign
      final plusSign = Participant.fromMap(
        TestFixtures.createParticipantMap(email: 'user+tag@example.com'),
      );
      expect(plusSign.email, 'user+tag@example.com');

      // Test email with dots
      final withDots = Participant.fromMap(
        TestFixtures.createParticipantMap(email: 'first.last@example.com'),
      );
      expect(withDots.email, 'first.last@example.com');
    });

    test('should handle participant with very long email', () {
      // Arrange
      final longEmail = '${'verylongemailaddress' * 10}@example.com';
      final mapWithLongEmail = TestFixtures.createParticipantMap(
        email: longEmail,
      );

      // Act
      final participant = Participant.fromMap(mapWithLongEmail);

      // Assert
      expect(participant.email, longEmail);
      expect(participant.email.length, greaterThan(100));
    });

    test('should handle empty string in users data', () {
      // Arrange
      final mapWithEmptyStrings = {
        'user_id': 'user-empty',
        'todo_list_id': 'list-empty',
        'role': 'viewer',
        'users': {
          'username': '',
          'email': '',
        },
      };

      // Act
      final participant = Participant.fromMap(mapWithEmptyStrings);

      // Assert
      expect(participant.username, isEmpty);
      expect(participant.email, isEmpty);
    });

    test('should handle users data with extra fields', () {
      // Arrange
      final mapWithExtraFields = {
        'user_id': 'user-extra',
        'todo_list_id': 'list-extra',
        'role': 'admin',
        'users': {
          'username': 'testuser',
          'email': 'test@example.com',
          'avatar_url': 'https://example.com/avatar.jpg',
          'full_name': 'Test User',
          'created_at': '2025-01-01T00:00:00Z',
        },
      };

      // Act
      final participant = Participant.fromMap(mapWithExtraFields);

      // Assert
      expect(participant.username, 'testuser');
      expect(participant.email, 'test@example.com');
      // Extra fields should be ignored
    });

    test('should handle same user in multiple todo lists', () {
      // Arrange
      final participant1Map = TestFixtures.createParticipantMap(
        userId: 'same-user',
        todoListId: 'list-1',
        role: 'admin',
      );

      final participant2Map = TestFixtures.createParticipantMap(
        userId: 'same-user',
        todoListId: 'list-2',
        role: 'collaborator',
      );

      // Act
      final participant1 = Participant.fromMap(participant1Map);
      final participant2 = Participant.fromMap(participant2Map);

      // Assert
      expect(participant1.userId, participant2.userId);
      expect(participant1.todoListId, isNot(participant2.todoListId));
      expect(participant1.role, isNot(participant2.role));
    });

    test('should handle multiple participants in same todo list', () {
      // Arrange
      final participant1Map = TestFixtures.createParticipantMap(
        userId: 'user-1',
        todoListId: 'same-list',
        username: 'user1',
      );

      final participant2Map = TestFixtures.createParticipantMap(
        userId: 'user-2',
        todoListId: 'same-list',
        username: 'user2',
      );

      // Act
      final participant1 = Participant.fromMap(participant1Map);
      final participant2 = Participant.fromMap(participant2Map);

      // Assert
      expect(participant1.todoListId, participant2.todoListId);
      expect(participant1.userId, isNot(participant2.userId));
      expect(participant1.username, isNot(participant2.username));
    });

    test('should create participant with constructor directly', () {
      // Arrange & Act
      final participant = Participant(
        userId: 'direct-user',
        todoListId: 'direct-list',
        role: 'admin',
        username: 'directuser',
        email: 'direct@example.com',
      );

      // Assert
      expect(participant.userId, 'direct-user');
      expect(participant.todoListId, 'direct-list');
      expect(participant.role, 'admin');
      expect(participant.username, 'directuser');
      expect(participant.email, 'direct@example.com');
    });

    test(
        'should handle nested users data with null values mixed with valid values',
        () {
      // Arrange
      final mapMixedNulls = {
        'user_id': 'user-mixed',
        'todo_list_id': 'list-mixed',
        'role': 'collaborator',
        'users': {
          'username': 'validuser',
          'email': null,
        },
      };

      // Act
      final participant = Participant.fromMap(mapMixedNulls);

      // Assert
      expect(participant.username, 'validuser');
      expect(participant.email, 'Unknown Email');
    });

    test('should handle camelCase keys in nested users', () {
      // Arrange - Some APIs might return camelCase
      final mapWithCamelCase = {
        'user_id': 'user-camel',
        'todo_list_id': 'list-camel',
        'role': 'viewer',
        'users': {
          'userName': 'cameluser', // Wrong key, should fallback
          'userEmail': 'camel@example.com', // Wrong key, should fallback
        },
      };

      // Act
      final participant = Participant.fromMap(mapWithCamelCase);

      // Assert
      // Since the keys don't match, should use defaults
      expect(participant.username, 'Unknown User');
      expect(participant.email, 'Unknown Email');
    });

    test('should handle users data as empty map', () {
      // Arrange
      final mapWithEmptyUsers = {
        'user_id': 'user-empty-map',
        'todo_list_id': 'list-empty-map',
        'role': 'collaborator',
        'users': <String, dynamic>{},
      };

      // Act
      final participant = Participant.fromMap(mapWithEmptyUsers);

      // Assert
      expect(participant.userId, 'user-empty-map');
      expect(participant.username, 'Unknown User');
      expect(participant.email, 'Unknown Email');
    });

    test('should handle special characters in email', () {
      // Arrange
      const specialEmail = "user's.email+tag@sub-domain.example.com";
      final mapWithSpecialEmail = TestFixtures.createParticipantMap(
        email: specialEmail,
      );

      // Act
      final participant = Participant.fromMap(mapWithSpecialEmail);

      // Assert
      expect(participant.email, specialEmail);
    });

    test('should handle empty factory correctly', () {
      // Act
      final empty1 = Participant.empty();
      final empty2 = Participant.empty();

      // Assert
      expect(empty1.userId, empty2.userId);
      expect(empty1.todoListId, empty2.todoListId);
      expect(empty1.role, 'collaborator');
      expect(empty1.username, 'Unknown User');
      expect(empty1.email, 'Unknown Email');
    });

    test('should handle role case sensitivity', () {
      // Arrange
      final upperCaseMap = TestFixtures.createParticipantMap(role: 'ADMIN');
      final lowerCaseMap = TestFixtures.createParticipantMap(role: 'admin');
      final mixedCaseMap = TestFixtures.createParticipantMap(role: 'Admin');

      // Act
      final upper = Participant.fromMap(upperCaseMap);
      final lower = Participant.fromMap(lowerCaseMap);
      final mixed = Participant.fromMap(mixedCaseMap);

      // Assert
      expect(upper.role, 'ADMIN');
      expect(lower.role, 'admin');
      expect(mixed.role, 'Admin');
      // All are different due to case sensitivity
      expect(upper.role, isNot(lower.role));
    });

    test('should preserve user data through complex join scenarios', () {
      // Arrange - Simulating a complex Supabase join with multiple relations
      final complexJoin = {
        'user_id': 'complex-user',
        'todo_list_id': 'complex-list',
        'role': 'admin',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-02T00:00:00Z',
        'users': {
          'id': 'complex-user',
          'username': 'complexuser',
          'email': 'complex@example.com',
          'created_at': '2024-12-01T00:00:00Z',
        },
        'todo_lists': {
          'id': 'complex-list',
          'title': 'Complex List',
        },
      };

      // Act
      final participant = Participant.fromMap(complexJoin);

      // Assert
      expect(participant.userId, 'complex-user');
      expect(participant.todoListId, 'complex-list');
      expect(participant.role, 'admin');
      expect(participant.username, 'complexuser');
      expect(participant.email, 'complex@example.com');
    });
  });
}
