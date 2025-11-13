import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/repositories/invitation_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/mock_supabase_client.dart';

// Mock classes for Functions
class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFunctionResponse extends Mock implements FunctionResponse {}

void main() {
  group('InvitationRepository Tests', () {
    late MockSupabaseClient mockClient;
    late MockFunctionsClient mockFunctions;
    late MockFunctionResponse mockResponse;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late InvitationRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockFunctions = MockFunctionsClient();
      mockResponse = MockFunctionResponse();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      repository = InvitationRepository(client: mockClient);

      when(() => mockClient.functions).thenReturn(mockFunctions);
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('test-user-id');
    });

    group('inviteUserToList', () {
      test('should invite user successfully', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'newuser@example.com',
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(
              'create-invitation',
              body: any(named: 'body'),
            )).called(1);
      });

      test('should throw exception when invitation fails with non-200 status',
          () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data)
            .thenReturn({'error': 'User already invited'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on FunctionException', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(FunctionException(
          status: 500,
          reasonPhrase: 'Internal Server Error',
        ));

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow generic exceptions', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle invalid email format', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Invalid email format'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'invalid-email',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('inviteUserToList - Edge Cases', () {
      test('should invite user with empty list ID', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: '',
          email: 'user@example.com',
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should invite user with very long list ID', () async {
        // Arrange
        final longId = 'id' * 100;
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: longId,
          email: 'user@example.com',
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should invite user with special characters in email', () async {
        // Arrange
        const specialEmail = 'user+tag@sub-domain.example.com';
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: specialEmail,
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should invite user with unicode in email', () async {
        // Arrange
        const unicodeEmail = 'user@example.中文.com';
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: unicodeEmail,
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should invite user with very long email', () async {
        // Arrange
        final longEmail = '${'verylongemail' * 10}@example.com';
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: longEmail,
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should invite user with different roles', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Test admin role
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'admin@example.com',
          role: 'admin',
        );

        // Test collaborator role
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'collab@example.com',
          role: 'collaborator',
        );

        // Test viewer role
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'viewer@example.com',
          role: 'viewer',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(3);
      });

      test('should handle empty email', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Email is required'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: '',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle uppercase email', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'USER@EXAMPLE.COM',
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should handle custom role values', () async {
        // Arrange
        const customRole = 'owner';
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'user@example.com',
          role: customRole,
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should handle special characters in list ID', () async {
        // Arrange
        const specialId = 'list-123-@#\$%';
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: specialId,
          email: 'user@example.com',
          role: 'collaborator',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });
    });

    group('respondToInvitation', () {
      test('should accept invitation successfully', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.respondToInvitation('invitation-123', true);

        // Assert
        verify(() => mockFunctions.invoke(
              'respond-to-invitation',
              body: any(named: 'body'),
            )).called(1);
      });

      test('should reject invitation successfully', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.respondToInvitation('invitation-123', false);

        // Assert
        verify(() => mockFunctions.invoke(
              'respond-to-invitation',
              body: any(named: 'body'),
            )).called(1);
      });

      test('should throw exception when response fails', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Invitation already responded'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.respondToInvitation('invitation-123', true),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on FunctionException', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(FunctionException(
          status: 500,
          reasonPhrase: 'Internal Server Error',
        ));

        // Act & Assert
        expect(
          () => repository.respondToInvitation('invitation-123', true),
          throwsA(isA<Exception>()),
        );
      });

      test('should rethrow generic exceptions', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.respondToInvitation('invitation-123', false),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle non-existent invitation', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(404);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Invitation not found'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.respondToInvitation('non-existent', true),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('respondToInvitation - Edge Cases', () {
      test('should respond with empty invitation ID', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.respondToInvitation('', true);

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should respond with very long invitation ID', () async {
        // Arrange
        final longId = 'inv' * 100;
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.respondToInvitation(longId, true);

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should respond with special characters in invitation ID', () async {
        // Arrange
        const specialId = 'inv-123-@#\$%';
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.respondToInvitation(specialId, true);

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(1);
      });

      test('should handle multiple responses to same invitation', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act - First accept
        await repository.respondToInvitation('inv-123', true);

        // Then try to reject (should still call)
        await repository.respondToInvitation('inv-123', false);

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(2);
      });

      test('should handle expired invitation', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Invitation has expired'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.respondToInvitation('expired-inv', true),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle unauthorized response', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(401);
        when(() => mockResponse.data).thenReturn({'error': 'Unauthorized'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.respondToInvitation('inv-123', true),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Error Handling', () {
      test('should handle timeout errors', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(Exception('Request timeout'));

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle server errors', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(500);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Internal server error'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout on respond', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => repository.respondToInvitation('inv-123', true),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle connection refused error', () async {
        // Arrange
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenThrow(Exception('Connection refused'));

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle rate limit error', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(429);
        when(() => mockResponse.data)
            .thenReturn({'error': 'Too many requests'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle null error data', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data).thenReturn(null);
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Failed to send invitation'))),
        );
      });

      test('should handle missing error field in response', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(400);
        when(() => mockResponse.data).thenReturn({'message': 'Error occurred'});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user@example.com',
            role: 'collaborator',
          ),
          throwsA(predicate((e) =>
              e is Exception &&
              e.toString().contains('Failed to send invitation'))),
        );
      });
    });

    group('Multiple Operations', () {
      test('should handle multiple invitations sequentially', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'user1@example.com',
          role: 'collaborator',
        );
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'user2@example.com',
          role: 'viewer',
        );
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'user3@example.com',
          role: 'admin',
        );

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(3);
      });

      test('should handle invite followed by respond', () async {
        // Arrange
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'user@example.com',
          role: 'collaborator',
        );
        await repository.respondToInvitation('inv-123', true);

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(2);
      });

      test('should handle mixed success and failure responses', () async {
        // Arrange
        var callCount = 0;
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            when(() => mockResponse.status).thenReturn(200);
            when(() => mockResponse.data).thenReturn({'success': true});
          } else {
            when(() => mockResponse.status).thenReturn(400);
            when(() => mockResponse.data)
                .thenReturn({'error': 'Already invited'});
          }
          return mockResponse;
        });

        // Act - First should succeed
        await repository.inviteUserToList(
          todoListId: 'list-123',
          email: 'user1@example.com',
          role: 'collaborator',
        );

        // Second should fail
        try {
          await repository.inviteUserToList(
            todoListId: 'list-123',
            email: 'user1@example.com',
            role: 'collaborator',
          );
        } catch (e) {
          // Expected
        }

        // Assert
        verify(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .called(2);
      });
    });

    group('Data Validation', () {
      test('should send correct body data for invite', () async {
        // Arrange
        Map<String, dynamic>? capturedBody;
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((invocation) async {
          capturedBody =
              invocation.namedArguments[#body] as Map<String, dynamic>;
          return mockResponse;
        });

        // Act
        await repository.inviteUserToList(
          todoListId: 'list-456',
          email: 'test@example.com',
          role: 'admin',
        );

        // Assert
        expect(capturedBody, isNotNull);
        expect(capturedBody!['todo_list_id'], 'list-456');
        expect(capturedBody!['invited_email'], 'test@example.com');
        expect(capturedBody!['assigned_role'], 'admin');
      });

      test('should send correct body data for respond', () async {
        // Arrange
        Map<String, dynamic>? capturedBody;
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((invocation) async {
          capturedBody =
              invocation.namedArguments[#body] as Map<String, dynamic>;
          return mockResponse;
        });

        // Act
        await repository.respondToInvitation('inv-789', true);

        // Assert
        expect(capturedBody, isNotNull);
        expect(capturedBody!['invitation_id'], 'inv-789');
        expect(capturedBody!['accept'], true);
      });

      test('should send false for reject invitation', () async {
        // Arrange
        Map<String, dynamic>? capturedBody;
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({'success': true});
        when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
            .thenAnswer((invocation) async {
          capturedBody =
              invocation.namedArguments[#body] as Map<String, dynamic>;
          return mockResponse;
        });

        // Act
        await repository.respondToInvitation('inv-789', false);

        // Assert
        expect(capturedBody, isNotNull);
        expect(capturedBody!['accept'], false);
      });
    });
  });
}
