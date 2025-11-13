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
  });
}
