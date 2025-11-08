import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_todo_app/data/repositories/auth_repository.dart';

// Import centralized mocks
import '../../mocks/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthRepository authRepository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    authRepository = AuthRepository(client: mockSupabase);
  });

  // ============================================================
  // GROUP 1: signIn Tests
  // ============================================================
  group('signIn', () {
    test('calls signInWithPassword with correct credentials', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockResponse);

      // Act
      await authRepository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      verify(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('throws AuthException on invalid credentials', () {
      // Arrange
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid credentials'));

      // Act & Assert
      expect(
        () => authRepository.signIn(
          email: 'wrong@example.com',
          password: 'wrongpass',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException with specific message', () {
      // Arrange
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Email not confirmed'));

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

    test('rethrows generic exceptions', () {
      // Arrange
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
  });

  // ============================================================
  // GROUP 2: signUp Tests
  // ============================================================
  group('signUp', () {
    test('calls signUp with correct data including username', () async {
      // Arrange
      final mockResponse = MockAuthResponse();
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

      // Assert
      verify(() => mockAuth.signUp(
            email: 'newuser@example.com',
            password: 'password123',
            data: {'username': 'testuser'},
          )).called(1);
    });

    test('throws custom exception when username already exists', () {
      // Arrange
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

    test('rethrows other AuthExceptions', () {
      // Arrange
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

    test('rethrows generic exceptions', () {
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
  });

  // ============================================================
  // GROUP 3: signOut Tests
  // ============================================================
  group('signOut', () {
    test('calls signOut successfully', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await authRepository.signOut();

      // Assert
      verify(() => mockAuth.signOut()).called(1);
    });

    test('throws exception on signOut failure', () {
      // Arrange
      when(() => mockAuth.signOut()).thenThrow(
        AuthException('SignOut failed'),
      );

      // Act & Assert
      expect(() => authRepository.signOut(), throwsA(isA<AuthException>()));
    });
  });

  // ============================================================
  // GROUP 4: currentUser Tests
  // ============================================================
  group('currentUser', () {
    test('returns user when logged in', () {
      // Arrange
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      // Act
      final user = authRepository.currentUser;

      // Assert
      expect(user, mockUser);
      verify(() => mockAuth.currentUser).called(1);
    });

    test('returns null when not logged in', () {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      final user = authRepository.currentUser;

      // Assert
      expect(user, null);
      verify(() => mockAuth.currentUser).called(1);
    });
  });

  // ============================================================
  // GROUP 5: authStateChanges Stream Tests
  // ============================================================
  group('authStateChanges', () {
    test('returns auth state change stream', () {
      // Arrange
      final mockStream = Stream<AuthState>.empty();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => mockStream);

      // Act
      final stream = authRepository.authStateChanges;

      // Assert
      expect(stream, mockStream);
      verify(() => mockAuth.onAuthStateChange).called(1);
    });

    test('emits auth state changes', () async {
      // Arrange
      final mockSession = MockSession();
      final authState = AuthState(AuthChangeEvent.signedIn, mockSession);
      final streamController = StreamController<AuthState>();
      when(() => mockAuth.onAuthStateChange)
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = authRepository.authStateChanges;
      streamController.add(authState);

      // Assert
      await expectLater(stream, emits(authState));

      // Cleanup
      await streamController.close();
    });
  });

  // ============================================================
  // GROUP 6: Integration Scenarios
  // ============================================================
  group('Integration Scenarios', () {
    test('handles signup → login flow', () async {
      // Arrange
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => MockAuthResponse());

      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockAuthResponse());

      // Act
      await authRepository.signUp(
        email: 'newuser@example.com',
        password: 'password123',
        username: 'newuser',
      );
      await authRepository.signIn(
        email: 'newuser@example.com',
        password: 'password123',
      );

      // Assert
      verify(() => mockAuth.signUp(
            email: 'newuser@example.com',
            password: 'password123',
            data: {'username': 'newuser'},
          )).called(1);
      verify(() => mockAuth.signInWithPassword(
            email: 'newuser@example.com',
            password: 'password123',
          )).called(1);
    });

    test('handles login → logout flow', () async {
      // Arrange
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockAuthResponse());
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await authRepository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );
      await authRepository.signOut();

      // Assert
      verify(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
