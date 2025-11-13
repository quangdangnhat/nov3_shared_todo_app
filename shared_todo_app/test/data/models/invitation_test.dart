import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/invitation.dart';

void main() {
  group('Invitation Model Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 11, 13);
    });

    test('should create Invitation from valid map', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {'title': 'My Todo List'},
        'users': {'email': 'inviter@example.com'},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.id, 'invitation-123');
      expect(invitation.todoListId, 'list-456');
      expect(invitation.invitedByUserId, 'user-789');
      expect(invitation.invitedUserId, 'user-012');
      expect(invitation.role, 'collaborator');
      expect(invitation.status, 'pending');
      expect(invitation.todoListTitle, 'My Todo List');
      expect(invitation.invitedByUserEmail, 'inviter@example.com');
    });

    test('should create Invitation with camelCase keys', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todoListId': 'list-456',
        'invitedByUserId': 'user-789',
        'invitedUserId': 'user-012',
        'role': 'admin',
        'status': 'accepted',
        'createdAt': testDate.toIso8601String(),
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.id, 'invitation-123');
      expect(invitation.todoListId, 'list-456');
      expect(invitation.role, 'admin');
      expect(invitation.status, 'accepted');
    });

    test('should handle missing todo_lists join data', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, isNull);
    });

    test('should handle missing users join data', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, isNull);
    });

    test('should handle null todo_lists value', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': null,
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, isNull);
    });

    test('should handle null users value', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': null,
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, isNull);
    });

    test('should handle different status values', () {
      final statuses = ['pending', 'accepted', 'rejected'];

      for (final status in statuses) {
        final invitationMap = {
          'id': 'invitation-$status',
          'todo_list_id': 'list-456',
          'invited_by_user_id': 'user-789',
          'invited_user_id': 'user-012',
          'role': 'collaborator',
          'status': status,
          'created_at': testDate.toIso8601String(),
        };

        final invitation = Invitation.fromMap(invitationMap);
        expect(invitation.status, status);
      }
    });

    test('should handle different role values', () {
      final roles = ['admin', 'collaborator', 'viewer'];

      for (final role in roles) {
        final invitationMap = {
          'id': 'invitation-$role',
          'todo_list_id': 'list-456',
          'invited_by_user_id': 'user-789',
          'invited_user_id': 'user-012',
          'role': role,
          'status': 'pending',
          'created_at': testDate.toIso8601String(),
        };

        final invitation = Invitation.fromMap(invitationMap);
        expect(invitation.role, role);
      }
    });

    test('should parse createdAt correctly', () {
      // Arrange
      final specificDate = DateTime(2025, 3, 15, 10, 30);
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': specificDate.toIso8601String(),
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.createdAt.year, 2025);
      expect(invitation.createdAt.month, 3);
      expect(invitation.createdAt.day, 15);
    });

    test('should extract title from nested todo_lists map', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {
          'title': 'Project Tasks',
          'desc': 'Project description',
        },
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, 'Project Tasks');
    });

    test('should extract email from nested users map', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {
          'email': 'sender@example.com',
          'username': 'sender',
        },
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, 'sender@example.com');
    });

    test('should throw FormatException for missing createdAt', () {
      // Arrange
      final invalidMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
      };

      // Act & Assert
      expect(
        () => Invitation.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should throw FormatException for invalid createdAt format', () {
      // Arrange
      final invalidMap = {
        'id': 'invitation-123',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': 'not-a-valid-date',
      };

      // Act & Assert
      expect(
        () => Invitation.fromMap(invalidMap),
        throwsA(isA<FormatException>()),
      );
    });

    test('should handle invitation created in the past', () {
      // Arrange
      final pastDate = DateTime(2020, 6, 15);
      final invitationMap = {
        'id': 'invitation-past',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'accepted',
        'created_at': pastDate.toIso8601String(),
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.createdAt.isBefore(DateTime.now()), isTrue);
      expect(invitation.createdAt.year, 2020);
      expect(invitation.createdAt.month, 6);
    });

    test('should handle ISO 8601 date strings correctly', () {
      // Arrange
      final date = DateTime(2025, 11, 13, 14, 30, 45);
      final isoString = date.toIso8601String();
      final invitationMap = {
        'id': 'invitation-iso',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': isoString,
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.createdAt.toIso8601String(), isoString);
    });

    test('should handle special characters in todo list title', () {
      // Arrange
      const specialTitle = 'List <>&"\' with émojis 📋';
      final invitationMap = {
        'id': 'invitation-special',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {'title': specialTitle},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, specialTitle);
    });

    test('should handle very long todo list title', () {
      // Arrange
      final longTitle = 'Long Title ' * 100;
      final invitationMap = {
        'id': 'invitation-long',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {'title': longTitle},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, longTitle);
      expect(invitation.todoListTitle!.length, greaterThan(1000));
    });

    test('should handle different email formats', () {
      // Test standard email
      final standard = Invitation.fromMap({
        'id': 'inv-1',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {'email': 'user@example.com'},
      });
      expect(standard.invitedByUserEmail, 'user@example.com');

      // Test email with subdomain
      final subdomain = Invitation.fromMap({
        'id': 'inv-2',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {'email': 'user@mail.example.com'},
      });
      expect(subdomain.invitedByUserEmail, 'user@mail.example.com');

      // Test email with plus sign
      final plusSign = Invitation.fromMap({
        'id': 'inv-3',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {'email': 'user+tag@example.com'},
      });
      expect(plusSign.invitedByUserEmail, 'user+tag@example.com');
    });

    test('should handle empty string in todo_lists title', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-empty',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {'title': ''},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, isEmpty);
    });

    test('should handle empty string in users email', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-empty-email',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {'email': ''},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, isEmpty);
    });

    test('should handle todo_lists with extra fields', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-extra',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {
          'id': 'list-456',
          'title': 'My List',
          'desc': 'Description',
          'created_at': '2025-01-01T00:00:00Z',
        },
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, 'My List');
      // Extra fields should be ignored
    });

    test('should handle users with extra fields', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-extra-user',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {
          'id': 'user-789',
          'email': 'sender@example.com',
          'username': 'sender',
          'created_at': '2025-01-01T00:00:00Z',
        },
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, 'sender@example.com');
      // Extra fields should be ignored
    });

    test('should create invitation with constructor directly', () {
      // Arrange & Act
      final invitation = Invitation(
        id: 'direct-inv',
        todoListId: 'direct-list',
        invitedByUserId: 'inviter-123',
        invitedUserId: 'invitee-456',
        role: 'admin',
        status: 'accepted',
        createdAt: DateTime.now(),
        todoListTitle: 'Direct List',
        invitedByUserEmail: 'inviter@example.com',
      );

      // Assert
      expect(invitation.id, 'direct-inv');
      expect(invitation.todoListId, 'direct-list');
      expect(invitation.invitedByUserId, 'inviter-123');
      expect(invitation.invitedUserId, 'invitee-456');
      expect(invitation.role, 'admin');
      expect(invitation.status, 'accepted');
      expect(invitation.todoListTitle, 'Direct List');
      expect(invitation.invitedByUserEmail, 'inviter@example.com');
    });

    test('should create invitation without optional fields using constructor', () {
      // Arrange & Act
      final invitation = Invitation(
        id: 'minimal-inv',
        todoListId: 'minimal-list',
        invitedByUserId: 'inviter-123',
        invitedUserId: 'invitee-456',
        role: 'collaborator',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(invitation.id, 'minimal-inv');
      expect(invitation.todoListTitle, isNull);
      expect(invitation.invitedByUserEmail, isNull);
    });

    test('should handle same user invited to multiple lists', () {
      // Arrange
      final invitation1Map = {
        'id': 'inv-1',
        'todo_list_id': 'list-1',
        'invited_by_user_id': 'admin-123',
        'invited_user_id': 'same-user',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
      };

      final invitation2Map = {
        'id': 'inv-2',
        'todo_list_id': 'list-2',
        'invited_by_user_id': 'admin-456',
        'invited_user_id': 'same-user',
        'role': 'viewer',
        'status': 'accepted',
        'created_at': testDate.toIso8601String(),
      };

      // Act
      final invitation1 = Invitation.fromMap(invitation1Map);
      final invitation2 = Invitation.fromMap(invitation2Map);

      // Assert
      expect(invitation1.invitedUserId, invitation2.invitedUserId);
      expect(invitation1.todoListId, isNot(invitation2.todoListId));
      expect(invitation1.role, isNot(invitation2.role));
      expect(invitation1.status, isNot(invitation2.status));
    });

    test('should handle multiple invitations for same list', () {
      // Arrange
      final invitation1Map = {
        'id': 'inv-1',
        'todo_list_id': 'same-list',
        'invited_by_user_id': 'admin-123',
        'invited_user_id': 'user-1',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
      };

      final invitation2Map = {
        'id': 'inv-2',
        'todo_list_id': 'same-list',
        'invited_by_user_id': 'admin-123',
        'invited_user_id': 'user-2',
        'role': 'viewer',
        'status': 'accepted',
        'created_at': testDate.add(const Duration(hours: 1)).toIso8601String(),
      };

      // Act
      final invitation1 = Invitation.fromMap(invitation1Map);
      final invitation2 = Invitation.fromMap(invitation2Map);

      // Assert
      expect(invitation1.todoListId, invitation2.todoListId);
      expect(invitation1.invitedByUserId, invitation2.invitedByUserId);
      expect(invitation1.invitedUserId, isNot(invitation2.invitedUserId));
    });

    test('should handle all role and status combinations', () {
      final roles = ['admin', 'collaborator', 'viewer'];
      final statuses = ['pending', 'accepted', 'rejected'];

      for (final role in roles) {
        for (final status in statuses) {
          final invitationMap = {
            'id': 'inv-$role-$status',
            'todo_list_id': 'list-456',
            'invited_by_user_id': 'user-789',
            'invited_user_id': 'user-012',
            'role': role,
            'status': status,
            'created_at': testDate.toIso8601String(),
          };

          final invitation = Invitation.fromMap(invitationMap);
          expect(invitation.role, role);
          expect(invitation.status, status);
        }
      }
    });

    test('should handle unicode characters in email', () {
      // Arrange
      const unicodeEmail = 'user@example.中文.com';
      final invitationMap = {
        'id': 'invitation-unicode',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': {'email': unicodeEmail},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, unicodeEmail);
    });

    test('should handle todo_lists as empty map', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-empty-map',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': <String, dynamic>{},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.todoListTitle, isNull);
    });

    test('should handle users as empty map', () {
      // Arrange
      final invitationMap = {
        'id': 'invitation-empty-user-map',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'users': <String, dynamic>{},
      };

      // Act
      final invitation = Invitation.fromMap(invitationMap);

      // Assert
      expect(invitation.invitedByUserEmail, isNull);
    });

    test('should preserve all field values from complex join', () {
      // Arrange - Simulating complex Supabase join
      final complexJoin = {
        'id': 'complex-inv',
        'todo_list_id': 'complex-list',
        'invited_by_user_id': 'inviter-123',
        'invited_user_id': 'invitee-456',
        'role': 'admin',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
        'todo_lists': {
          'id': 'complex-list',
          'title': 'Complex Project',
          'desc': 'Project description',
          'created_at': '2025-01-01T00:00:00Z',
        },
        'users': {
          'id': 'inviter-123',
          'email': 'inviter@example.com',
          'username': 'inviter',
          'created_at': '2024-12-01T00:00:00Z',
        },
      };

      // Act
      final invitation = Invitation.fromMap(complexJoin);

      // Assert
      expect(invitation.id, 'complex-inv');
      expect(invitation.todoListId, 'complex-list');
      expect(invitation.invitedByUserId, 'inviter-123');
      expect(invitation.invitedUserId, 'invitee-456');
      expect(invitation.role, 'admin');
      expect(invitation.status, 'pending');
      expect(invitation.todoListTitle, 'Complex Project');
      expect(invitation.invitedByUserEmail, 'inviter@example.com');
    });

    test('should handle status case sensitivity', () {
      // Arrange
      final upperCaseMap = {
        'id': 'inv-upper',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'PENDING',
        'created_at': testDate.toIso8601String(),
      };

      final lowerCaseMap = {
        'id': 'inv-lower',
        'todo_list_id': 'list-456',
        'invited_by_user_id': 'user-789',
        'invited_user_id': 'user-012',
        'role': 'collaborator',
        'status': 'pending',
        'created_at': testDate.toIso8601String(),
      };

      // Act
      final upper = Invitation.fromMap(upperCaseMap);
      final lower = Invitation.fromMap(lowerCaseMap);

      // Assert
      expect(upper.status, 'PENDING');
      expect(lower.status, 'pending');
      expect(upper.status, isNot(lower.status));
    });
  });
}
