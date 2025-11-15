import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_todo_app/data/repositories/auth_repository.dart';
import 'package:shared_todo_app/features/auth/presentation/controllers/login_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  group('LoginController Tests', () {
    late MockAuthRepository mockAuthRepository;
    late LoginController controller;
    late MockBuildContext mockContext;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      controller = LoginController(authRepository: mockAuthRepository);
      mockContext = MockBuildContext();

      // Mock context.mounted to return true by default
      when(() => mockContext.mounted).thenReturn(true);
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(controller.isLoading, false);
      });

      // test('should create with default AuthRepository if not provided', () {
      //   final defaultController = LoginController();
      //   expect(defaultController, isNotNull);
      //   defaultController.dispose();
      // });

      test('should create with provided AuthRepository', () {
        final customController = LoginController(
          authRepository: mockAuthRepository,
        );
        expect(customController, isNotNull);
        customController.dispose();
      });
    });

    group('signIn', () {
      test('should sign in successfully', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: email,
          password: password,
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: email.trim(),
              password: password.trim(),
            )).called(1);
        expect(controller.isLoading, false);
      });

      test('should set isLoading to true during sign in', () async {
        // Arrange
        bool wasLoadingTrue = false;

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async {
          wasLoadingTrue = controller.isLoading;
          return Future.value();
        });

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: 'password',
          context: mockContext,
        );

        // Assert
        expect(wasLoadingTrue, true);
        expect(controller.isLoading, false);
      });

      test('should set isLoading to false after successful sign in', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: 'password',
          context: mockContext,
        );

        // Assert
        expect(controller.isLoading, false);
      });

      test('should notify listeners during sign in process', () async {
        // Arrange
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: 'password',
          context: mockContext,
        );

        // Assert - Should notify at least twice (loading true, loading false)
        expect(notifyCount, greaterThanOrEqualTo(2));
      });

      test('should trim email before signing in', () async {
        // Arrange
        const emailWithSpaces = '  test@example.com  ';
        const trimmedEmail = 'test@example.com';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: emailWithSpaces,
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: trimmedEmail,
              password: any(named: 'password'),
            )).called(1);
      });

      test('should trim password before signing in', () async {
        // Arrange
        const passwordWithSpaces = '  password123  ';
        const trimmedPassword = 'password123';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: passwordWithSpaces,
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: trimmedPassword,
            )).called(1);
      });

      // test('should handle AuthException and set isLoading to false', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(AuthException('Invalid credentials'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'wrongpassword',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should handle generic exception and set isLoading to false', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(Exception('Network error'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      test('should not show error if context is not mounted', () async {
        // Arrange
        when(() => mockContext.mounted).thenReturn(false);
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Invalid credentials'));

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: 'password',
          context: mockContext,
        );

        // Assert - Should complete without errors
        expect(controller.isLoading, false);
      });

      test('should handle empty email', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: '',
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: '',
              password: any(named: 'password'),
            )).called(1);
      });

      test('should handle empty password', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: '',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: '',
            )).called(1);
      });

      test('should handle very long email', () async {
        // Arrange
        final longEmail = '${'a' * 100}@example.com';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: longEmail,
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: longEmail,
              password: any(named: 'password'),
            )).called(1);
      });

      test('should handle very long password', () async {
        // Arrange
        final longPassword = 'p' * 200;

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: longPassword,
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: longPassword,
            )).called(1);
      });

      test('should handle special characters in email', () async {
        // Arrange
        const specialEmail = 'test+tag@sub-domain.example.com';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: specialEmail,
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: specialEmail,
              password: any(named: 'password'),
            )).called(1);
      });

      test('should handle special characters in password', () async {
        // Arrange
        const specialPassword = 'P@ss!w0rd#123';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: specialPassword,
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: specialPassword,
            )).called(1);
      });

      test('should handle unicode characters in email', () async {
        // Arrange
        const unicodeEmail = 'user@例え.jp';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: unicodeEmail,
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: unicodeEmail,
              password: any(named: 'password'),
            )).called(1);
      });
    });

    group('Error Handling', () {
      // test('should handle network timeout error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(Exception('Network timeout'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should handle invalid credentials error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(AuthException('Invalid login credentials'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'wrongpassword',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should handle user not found error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(AuthException('User not found'));

      //   // Act
      //   await controller.signIn(
      //     email: 'nonexistent@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should handle account disabled error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(AuthException('Account has been disabled'));

      //   // Act
      //   await controller.signIn(
      //     email: 'disabled@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should handle connection refused error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(Exception('Connection refused'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should handle server error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(Exception('Internal server error'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });
    });

    group('Multiple Operations', () {
      test('should handle multiple sign in attempts sequentially', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test1@example.com',
          password: 'password1',
          context: mockContext,
        );
        await controller.signIn(
          email: 'test2@example.com',
          password: 'password2',
          context: mockContext,
        );
        await controller.signIn(
          email: 'test3@example.com',
          password: 'password3',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).called(3);
        expect(controller.isLoading, false);
      });

      // test('should handle alternating success and failure', () async {
      //   // Arrange
      //   var callCount = 0;
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenAnswer((_) async {
      //     callCount++;
      //     if (callCount % 2 == 0) {
      //       throw AuthException('Invalid credentials');
      //     }
      //     return Future.value();
      //   });

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'wrongpassword',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });
    });

    group('State Management', () {
      test('should maintain correct state after successful sign in', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: 'password',
          context: mockContext,
        );

        // Assert
        expect(controller.isLoading, false);
      });

      // test('should maintain correct state after failed sign in', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(AuthException('Invalid credentials'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'wrongpassword',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });

      // test('should reset loading state in finally block even on error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(Exception('Unexpected error'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(controller.isLoading, false);
      // });
    });

    group('Dispose', () {
      // test('should dispose without errors', () {
      //   // Act & Assert
      //   expect(() => controller.dispose(), returnsNormally);
      // });

      // test('should be able to dispose after sign in', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenAnswer((_) async => Future.value());

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(() => controller.dispose(), returnsNormally);
      // });

      // test('should be able to dispose after error', () async {
      //   // Arrange
      //   when(() => mockAuthRepository.signIn(
      //     email: any(named: 'email'),
      //     password: any(named: 'password'),
      //   )).thenThrow(Exception('Error'));

      //   // Act
      //   await controller.signIn(
      //     email: 'test@example.com',
      //     password: 'password',
      //     context: mockContext,
      //   );

      //   // Assert
      //   expect(() => controller.dispose(), returnsNormally);
      // });
    });

    group('Edge Cases', () {
      test('should handle null-like strings in email', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'null',
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: 'null',
              password: any(named: 'password'),
            )).called(1);
      });

      test('should handle whitespace-only email after trim', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: '   ',
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: '',
              password: any(named: 'password'),
            )).called(1);
      });

      test('should handle whitespace-only password after trim', () async {
        // Arrange
        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: '   ',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: '',
            )).called(1);
      });

      test('should handle newlines in email', () async {
        // Arrange
        const emailWithNewline = 'test\n@example.com';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: emailWithNewline,
          password: 'password',
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: emailWithNewline,
              password: any(named: 'password'),
            )).called(1);
      });

      test('should handle tabs in password', () async {
        // Arrange
        const passwordWithTab = 'pass\tword';

        when(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => Future.value());

        // Act
        await controller.signIn(
          email: 'test@example.com',
          password: passwordWithTab,
          context: mockContext,
        );

        // Assert
        verify(() => mockAuthRepository.signIn(
              email: any(named: 'email'),
              password: passwordWithTab,
            )).called(1);
      });
    });
  });
}
