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
    test('should call signInWithPassword with correct email and password',
        () async {
      // Arrange: Setup mock response (Prepare fake data)
      final mockResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn(null);

      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockResponse);

      // Act: Run the function
      await authRepository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert: Verify that Supabase has been called correctly
      verify(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('should throw AuthException when credentials are invalid', () async {
      // Arrange: Simulate Mock supabase error
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid credentials'));

      // Act & Assert: Make sure it throws an exception
      expect(
        () => authRepository.signIn(
          email: 'wrong@example.com',
          password: 'wrongpass',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('should throw AuthException with correct message on auth error',
        () async {
      // Arrange
      final authException = AuthException('Email not confirmed');

      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(authException);

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
    });

    test('should rethrow generic exceptions', () async {
      // Arrange: Mock non-AuthException error
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Network error'));

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
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signIn(
        email: '',
        password: 'password123',
      );

      // Assert: Verify it was called (Supabase will validate)
      verify(() => mockAuth.signInWithPassword(
            email: '',
            password: 'password123',
          )).called(1);
    });
  });

  // ============================================================
  // GROUP 2: signUp Tests
  // ============================================================
  group('signUp Method Tests', () {
    test('should call signUp with correct email, password, and username',
        () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockResponse.user).thenReturn(mockUser);

      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signUp(
        email: 'newuser@example.com',
        password: 'password123',
        username: 'testuser',
      );

      // Assert: Verify username is passed in data object
      verify(() => mockAuth.signUp(
            email: 'newuser@example.com',
            password: 'password123',
            data: {'username': 'testuser'},
          )).called(1);
    });

    test('should throw custom exception when username is already in use',
        () async {
      // Arrange: Mock database error for duplicate username
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenThrow(AuthException('Database error saving new user'));

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
    });

    test('should rethrow AuthException if not username duplicate error',
        () async {
      // Arrange: Mock different auth error
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenThrow(AuthException('Email already registered'));

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
    });

    test('should rethrow generic exceptions during signup', () async {
      // Arrange
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenThrow(Exception('Network error'));

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

      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signUp(
        email: 'test@example.com',
        password: 'password123',
        username: 'user_name-123',
      );

      // Assert
      verify(() => mockAuth.signUp(
            email: 'test@example.com',
            password: 'password123',
            data: {'username': 'user_name-123'},
          )).called(1);
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
      expect(
        () => authRepository.signOut(),
        throwsException,
      );
    });

    test('should handle AuthException during signOut', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenThrow(
        AuthException('Session expired'),
      );

      // Act & Assert
      expect(
        () => authRepository.signOut(),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
