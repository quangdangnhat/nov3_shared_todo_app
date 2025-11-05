// ============================================================
// UNIT TEST - Mock Supabase
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_todo_app/data/repositories/auth_repository.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthRepository authRepository;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    
    // Setup mock: When calling supabase.auth, return mockAuth
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    
    // Inject mock into repository
    authRepository = AuthRepository(client: mockSupabase);
  });

  group('AuthRepository Unit Tests (MOCKED)', () {
    test('signIn should call supabase.auth.signInWithPassword', () async {
      // Arrange: Prepare fake data
      final mockResponse = MockAuthResponse();
      final mockUser = MockUser();
      
      when(() => mockResponse.user).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('test@example.com');
      
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

    test('signIn should throw exception on wrong credentials', () async {
      // Arrange: Simulate error
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

    test('signOut should call supabase.auth.signOut', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await authRepository.signOut();

      // Assert
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}