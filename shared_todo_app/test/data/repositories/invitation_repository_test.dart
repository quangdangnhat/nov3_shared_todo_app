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
    });
  });
}
