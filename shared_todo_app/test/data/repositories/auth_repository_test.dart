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
    test('should call signInWithPassword with correct email and password', () async {
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

    test('should throw AuthException with correct message on auth error', () async {
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
}