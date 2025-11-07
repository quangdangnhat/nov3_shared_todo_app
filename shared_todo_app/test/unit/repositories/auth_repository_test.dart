import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_todo_app/data/repositories/auth_repository.dart';

// ============================================================
// Mock Classes
// ============================================================
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

// ============================================================
// Unit Tests
// ============================================================
void main() {
  // Declare variables that will be used across tests
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthRepository authRepository;

  // setUp runs before EACH test
  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    // Setup mock: When calling supabase.auth, return mockAuth
    when(() => mockSupabase.auth).thenReturn(mockAuth);

    // Inject mock into repository
    authRepository = AuthRepository(client: mockSupabase);
  });

  // ============================================================
  // GROUP 1: signIn Tests
  // ============================================================
  group('signIn Method Tests', () {
    test(
      'should call signInWithPassword with correct email and password',
      () async {
        // Arrange: Setup mock response (Prepare fake data)
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();

        when(() => mockResponse.user).thenReturn(mockUser);
        when(() => mockUser.email).thenReturn(null);

        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act: Run the function
        await authRepository.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert: Verify that Supabase has been called correctly
        verify(
          () => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    test('should throw AuthException when credentials are invalid', () async {
      // Arrange: Simulate Mock supabase error
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(AuthException('Invalid credentials'));

      // Act & Assert: Make sure it throws an exception
      expect(
        () => authRepository.signIn(
          email: 'wrong@example.com',
          password: 'wrongpass',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test(
      'should throw AuthException with correct message on auth error',
      () async {
        // Arrange
        final authException = AuthException('Email not confirmed');

        when(
          () => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(authException);

        // Act & Assert
        expect(
          () => authRepository.signIn(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Email not confirmed',
            ),
          ),
        );
      },
    );

    test('should rethrow generic exceptions', () async {
      // Arrange: Mock non-AuthException error
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => authRepository.signIn(
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsException,
      );
    });

    test('should handle empty email gracefully', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signIn(email: '', password: 'password123');

      // Assert: Verify it was called (Supabase will validate)
      verify(
        () => mockAuth.signInWithPassword(email: '', password: 'password123'),
      ).called(1);
    });
  });

  // ============================================================
  // GROUP 2: signUp Tests
  // ============================================================
  group('signUp Method Tests', () {
    test(
      'should call signUp with correct email, password, and username',
      () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();

        when(() => mockResponse.user).thenReturn(mockUser);

        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        await authRepository.signUp(
          email: 'newuser@example.com',
          password: 'password123',
          username: 'testuser',
        );

        // Assert: Verify username is passed in data object
        verify(
          () => mockAuth.signUp(
            email: 'newuser@example.com',
            password: 'password123',
            data: {'username': 'testuser'},
          ),
        ).called(1);
      },
    );

    test(
      'should throw custom exception when username is already in use',
      () async {
        // Arrange: Mock database error for duplicate username
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenThrow(AuthException('Database error saving new user'));

        // Act & Assert
        expect(
          () => authRepository.signUp(
            email: 'test@example.com',
            password: 'password123',
            username: 'duplicate_user',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('Username already used'),
            ),
          ),
        );
      },
    );

    test(
      'should rethrow AuthException if not username duplicate error',
      () async {
        // Arrange: Mock different auth error
        when(
          () => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenThrow(AuthException('Email already registered'));

        // Act & Assert
        expect(
          () => authRepository.signUp(
            email: 'test@example.com',
            password: 'password123',
            username: 'testuser',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Email already registered',
            ),
          ),
        );
      },
    );

    test('should rethrow generic exceptions during signup', () async {
      // Arrange
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => authRepository.signUp(
          email: 'test@example.com',
          password: 'password123',
          username: 'testuser',
        ),
        throwsException,
      );
    });

    test('should handle special characters in username', () async {
      // Arrange
      final mockResponse = MockAuthResponse();

      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'user_name-123',
      );

      // Assert
      verify(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          data: {'username': 'user_name-123'},
        ),
      ).called(1);
    });
  });

  // ============================================================
  // GROUP 3: signOut Tests
  // ============================================================
  group('signOut Method Tests', () {
    test('should call signOut on auth client', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await authRepository.signOut();

      // Assert
      verify(() => mockAuth.signOut()).called(1);
    });

    test('should rethrow exceptions during signOut', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenThrow(Exception('SignOut failed'));

      // Act & Assert
      expect(() => authRepository.signOut(), throwsException);
    });

    test('should handle AuthException during signOut', () async {
      // Arrange
      when(
        () => mockAuth.signOut(),
      ).thenThrow(AuthException('Session expired'));

      // Act & Assert
      expect(() => authRepository.signOut(), throwsA(isA<AuthException>()));
    });
  });

  // ============================================================
  // GROUP 4: currentUser Getter Tests
  // ============================================================

  group('currentUser Getter Tests', () {
    test('should return user when logged in', () {
      // Arrange
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      // Act
      final user = authRepository.currentUser;

      // Assert
      expect(user, isNotNull);
      expect(user, mockUser);
      verify(() => mockAuth.currentUser).called(1);
    });

    test('should return null when not logged in', () {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      final user = authRepository.currentUser;

      // Assert
      expect(user, null);
      verify(() => mockAuth.currentUser).called(1);
    });

    test('should not cache user value', () {
      // Arrange
      final mockUser1 = MockUser();
      final mockUser2 = MockUser();

      when(() => mockAuth.currentUser).thenReturn(mockUser1);

      // Act: First call
      final user1 = authRepository.currentUser;

      // Change mock return value
      when(() => mockAuth.currentUser).thenReturn(mockUser2);

      // Act: Second call
      final user2 = authRepository.currentUser;

      // Assert: Should get different users (not cached)
      expect(user1, mockUser1);
      expect(user2, mockUser2);
      verify(() => mockAuth.currentUser).called(2);
    });
  });

  // ============================================================
  // GROUP 5: authStateChanges Stream Tests
  // ============================================================

  group('authStateChanges Stream Tests', () {
    test('should return auth state change stream', () {
      // Arrange
      final mockStream = Stream<AuthState>.empty();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => mockStream);

      // Act
      final stream = authRepository.authStateChanges;

      // Assert
      expect(stream, mockStream);
      verify(() => mockAuth.onAuthStateChange).called(1);
    });

    test('should emit auth state changes when user logs in', () async {
      // Arrange
      final mockUser = MockUser();
      final mockSession = MockSession();
      final authState = AuthState(AuthChangeEvent.signedIn, mockSession);

      final streamController = StreamController<AuthState>();
      when(
        () => mockAuth.onAuthStateChange,
      ).thenAnswer((_) => streamController.stream);

      // Act
      final stream = authRepository.authStateChanges;
      streamController.add(authState);

      // Assert
      expectLater(stream, emits(authState));

      // Cleanup
      await streamController.close();
    });
  });

  // ============================================================
  // GROUP 6: Integration Scenarios (Still Mocked)
  // ============================================================

  group('Integration Scenario Tests', () {
    test('should handle complete signup → login flow', () async {
      // Arrange: Signup
      final signUpResponse = MockAuthResponse();
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => signUpResponse);

      // Arrange: Login
      final signInResponse = MockAuthResponse();
      final mockUser = MockUser();
      when(() => signInResponse.user).thenReturn(mockUser);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => signInResponse);

      // Act: Signup
      await authRepository.signUp(
        email: 'newuser@example.com',
        password: 'password123',
        username: 'newuser',
      );

      // Act: Login
      await authRepository.signIn(
        email: 'newuser@example.com',
        password: 'password123',
      );

      // Assert
      verify(
        () => mockAuth.signUp(
          email: 'newuser@example.com',
          password: 'password123',
          data: {'username': 'newuser'},
        ),
      ).called(1);

      verify(
        () => mockAuth.signInWithPassword(
          email: 'newuser@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('should handle login → logout flow', () async {
      // Arrange: Login
      final signInResponse = MockAuthResponse();
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => signInResponse);

      // Arrange: Logout
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act: Login
      await authRepository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      // Act: Logout
      await authRepository.signOut();

      // Assert
      verify(
        () => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  // ============================================================
  // GROUP 7: Edge Cases
  // ============================================================

  group('Edge Case Tests', () {
    test('should handle very long email', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      final longEmail = 'a' * 100 + '@example.com';

      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signIn(email: longEmail, password: 'password123');

      // Assert
      verify(
        () => mockAuth.signInWithPassword(
          email: longEmail,
          password: 'password123',
        ),
      ).called(1);
    });

    test('should handle very long password', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      final longPassword = 'p' * 200;

      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signUp(
        email: 'test@example.com',
        password: longPassword,
        username: 'testuser',
      );

      // Assert
      verify(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: longPassword,
          data: {'username': 'testuser'},
        ),
      ).called(1);
    });

    test('should handle unicode characters in username', () async {
      // Arrange
      final mockResponse = MockAuthResponse();

      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'utente_àéìòù',
      );

      // Assert
      verify(
        () => mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          data: {'username': 'utente_àéìòù'},
        ),
      ).called(1);
    });
  });
}
