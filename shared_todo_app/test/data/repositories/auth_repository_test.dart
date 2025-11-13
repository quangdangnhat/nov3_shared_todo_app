import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/mock_supabase_client.dart';

void main() {
  group('AuthRepository Tests', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockAuthResponse mockAuthResponse;
    late MockUser mockUser;
    late AuthRepository repository;

    setUpAll(() {
      registerFallbackValue(UserAttributes());
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockAuthResponse = MockAuthResponse();
      mockUser = MockUser();
      repository = AuthRepository(client: mockClient);

      // Setup default auth mock
      when(() => mockClient.auth).thenReturn(mockAuth);
    });

    group('signUp', () {
      test('should sign up successfully', () async {
        // Arrange
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => mockAuthResponse);

        // Act
        await repository.signUp(
          email: 'test@example.com',
          password: 'password123',
          username: 'testuser',
        );

        // Assert
        verify(() => mockAuth.signUp(
              email: 'test@example.com',
              password: 'password123',
              data: {'username': 'testuser'},
            )).called(1);
      });

      test('should throw AuthException when username is already used', () async {
        // Arrange
        final authException = AuthException(
          'Database error saving new user',
        );
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenThrow(authException);

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'test@example.com',
            password: 'password123',
            username: 'existinguser',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should rethrow generic errors', () async {
        // Arrange
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Generic error'));

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'test@example.com',
            password: 'password123',
            username: 'testuser',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should include username in metadata', () async {
        // Arrange
        Map<String, dynamic>? capturedData;
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')]
              as Map<String, dynamic>?;
          return mockAuthResponse;
        });

        // Act
        await repository.signUp(
          email: 'test@example.com',
          password: 'password123',
          username: 'myusername',
        );

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['username'], 'myusername');
      });
    });

    group('signIn', () {
      test('should sign in successfully', () async {
        // Arrange
        when(() => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => mockAuthResponse);

        // Act
        await repository.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        verify(() => mockAuth.signInWithPassword(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
      });

      test('should throw AuthException on invalid credentials', () async {
        // Arrange
        final authException = AuthException('Invalid login credentials');
        when(() => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(authException);

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should rethrow generic errors during sign in', () async {
        // Arrange
        when(() => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        await repository.signOut();

        // Assert
        verify(() => mockAuth.signOut()).called(1);
      });

      test('should rethrow errors during sign out', () async {
        // Arrange
        when(() => mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

        // Act & Assert
        expect(
          () => repository.signOut(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('currentUser', () {
      test('should return current user when logged in', () {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.id).thenReturn('user-123');

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNotNull);
        expect(user?.id, 'user-123');
      });

      test('should return null when not logged in', () {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNull);
      });
    });

    group('authStateChanges', () {
      test('should expose auth state change stream', () {
        // Arrange
        final mockStream = Stream<AuthState>.empty();
        when(() => mockAuth.onAuthStateChange).thenAnswer((_) => mockStream);

        // Act
        final stream = repository.authStateChanges;

        // Assert
        expect(stream, equals(mockStream));
      });
    });

    group('Edge Cases', () {
      test('should handle empty email during sign up', () async {
        // Arrange
        final authException = AuthException('Email is required');
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenThrow(authException);

        // Act & Assert
        expect(
          () => repository.signUp(
            email: '',
            password: 'password123',
            username: 'testuser',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should handle empty password during sign in', () async {
        // Arrange
        final authException = AuthException('Password is required');
        when(() => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(authException);

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'test@example.com',
            password: '',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should handle invalid email format', () async {
        // Arrange
        final authException = AuthException('Invalid email format');
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenThrow(authException);

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'invalid-email',
            password: 'password123',
            username: 'testuser',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
