import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/features/auth/presentation/domain/validators/auth_validators.dart';

void main() {
  group('AuthValidators Tests', () {
    group('validateEmail', () {
      test('should return null for valid email', () {
        // Arrange
        const validEmail = 'test@example.com';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return null for valid email with subdomain', () {
        // Arrange
        const validEmail = 'user@mail.example.com';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return null for valid email with dots', () {
        // Arrange
        const validEmail = 'first.last@example.com';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return null for valid email with numbers', () {
        // Arrange
        const validEmail = 'user123@example456.com';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return null for valid email with hyphens', () {
        // Arrange
        const validEmail = 'user-name@example-domain.com';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return null for valid email with underscores', () {
        // Arrange
        const validEmail = 'user_name@example.com';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return null for email with multiple dots in domain', () {
        // Arrange
        const validEmail = 'user@mail.example.co.uk';

        // Act
        final result = AuthValidators.validateEmail(validEmail);

        // Assert
        expect(result, isNull);
      });

      test('should return error for null email', () {
        // Act
        final result = AuthValidators.validateEmail(null);

        // Assert
        expect(result, 'Please, insert your email');
      });

      test('should return error for empty email', () {
        // Act
        final result = AuthValidators.validateEmail('');

        // Assert
        expect(result, 'Please, insert your email');
      });

      test('should return error for whitespace only email', () {
        // Act
        final result = AuthValidators.validateEmail('   ');

        // Assert
        expect(result, 'Please, insert your email');
      });

      test('should return error for email without @', () {
        // Arrange
        const invalidEmail = 'testexample.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email without domain', () {
        // Arrange
        const invalidEmail = 'test@';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email without username', () {
        // Arrange
        const invalidEmail = '@example.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email without TLD', () {
        // Arrange
        const invalidEmail = 'test@example';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email with spaces', () {
        // Arrange
        const invalidEmail = 'test user@example.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email with multiple @', () {
        // Arrange
        const invalidEmail = 'test@@example.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email with invalid characters', () {
        // Arrange
        const invalidEmail = 'test#user@example.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email with TLD too short', () {
        // Arrange
        const invalidEmail = 'test@example.c';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for email with TLD too long', () {
        // Arrange
        const invalidEmail = 'test@example.commmm';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should trim whitespace before validation', () {
        // Arrange
        const emailWithSpaces = '  test@example.com  ';

        // Act
        final result = AuthValidators.validateEmail(emailWithSpaces);

        // Assert
        expect(result, isNull);
      });

      test('should return error for domain starting with dot', () {
        // Arrange
        const invalidEmail = 'test@.example.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for domain ending with dot', () {
        // Arrange
        const invalidEmail = 'test@example.com.';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should return error for consecutive dots in username', () {
        // Arrange
        const invalidEmail = 'test..user@example.com';

        // Act
        final result = AuthValidators.validateEmail(invalidEmail);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('should handle very long valid email', () {
        // Arrange
        final longEmail = '${'a' * 50}@${'example' * 5}.com';

        // Act
        final result = AuthValidators.validateEmail(longEmail);

        // Assert
        expect(result, isNull);
      });
    });

    group('validatePassword', () {
      test('should return null for password with exactly 6 characters', () {
        // Arrange
        const validPassword = '123456';

        // Act
        final result = AuthValidators.validatePassword(validPassword);

        // Assert
        expect(result, isNull);
      });

      test('should return null for password with more than 6 characters', () {
        // Arrange
        const validPassword = '12345678';

        // Act
        final result = AuthValidators.validatePassword(validPassword);

        // Assert
        expect(result, isNull);
      });

      test('should return null for password with letters and numbers', () {
        // Arrange
        const validPassword = 'Pass123';

        // Act
        final result = AuthValidators.validatePassword(validPassword);

        // Assert
        expect(result, isNull);
      });

      test('should return null for password with special characters', () {
        // Arrange
        const validPassword = 'P@ss!123';

        // Act
        final result = AuthValidators.validatePassword(validPassword);

        // Assert
        expect(result, isNull);
      });

      test('should return null for password with spaces', () {
        // Arrange
        const validPassword = 'Pass 123';

        // Act
        final result = AuthValidators.validatePassword(validPassword);

        // Assert
        expect(result, isNull);
      });

      test('should return null for very long password', () {
        // Arrange
        final longPassword = 'a' * 100;

        // Act
        final result = AuthValidators.validatePassword(longPassword);

        // Assert
        expect(result, isNull);
      });

      test('should return error for null password', () {
        // Act
        final result = AuthValidators.validatePassword(null);

        // Assert
        expect(result, 'The password has to contain at least 6 characters');
      });

      test('should return error for password with less than 6 characters', () {
        // Arrange
        const shortPassword = '12345';

        // Act
        final result = AuthValidators.validatePassword(shortPassword);

        // Assert
        expect(result, 'The password has to contain at least 6 characters');
      });

      test('should return error for empty password', () {
        // Act
        final result = AuthValidators.validatePassword('');

        // Assert
        expect(result, 'The password has to contain at least 6 characters');
      });

      test('should return error for password with 1 character', () {
        // Arrange
        const shortPassword = 'a';

        // Act
        final result = AuthValidators.validatePassword(shortPassword);

        // Assert
        expect(result, 'The password has to contain at least 6 characters');
      });

      test('should return error for password with 5 characters', () {
        // Arrange
        const shortPassword = 'abcde';

        // Act
        final result = AuthValidators.validatePassword(shortPassword);

        // Assert
        expect(result, 'The password has to contain at least 6 characters');
      });

      test('should accept password with only spaces if length >= 6', () {
        // Arrange
        const spacesPassword = '      ';

        // Act
        final result = AuthValidators.validatePassword(spacesPassword);

        // Assert
        expect(result, isNull);
      });

      test('should accept password with unicode characters', () {
        // Arrange
        const unicodePassword = 'пароль123';

        // Act
        final result = AuthValidators.validatePassword(unicodePassword);

        // Assert
        expect(result, isNull);
      });

      test('should accept password with emoji', () {
        // Arrange
        const emojiPassword = 'pass🔒123';

        // Act
        final result = AuthValidators.validatePassword(emojiPassword);

        // Assert
        expect(result, isNull);
      });
    });

    group('validatePasswordConfirmation', () {
      test('should return null when passwords match', () {
        // Arrange
        const password = 'password123';
        const confirmation = 'password123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return null when both passwords are identical long strings',
          () {
        // Arrange
        final password = 'a' * 100;
        final confirmation = 'a' * 100;

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return null when both passwords have special characters',
          () {
        // Arrange
        const password = 'P@ss!w0rd#123';
        const confirmation = 'P@ss!w0rd#123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return null when both passwords have spaces', () {
        // Arrange
        const password = 'pass word 123';
        const confirmation = 'pass word 123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return null when both passwords have unicode', () {
        // Arrange
        const password = 'пароль123';
        const confirmation = 'пароль123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, isNull);
      });

      test('should return error for null confirmation', () {
        // Arrange
        const password = 'password123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          null,
          password,
        );

        // Assert
        expect(result, 'Please, confirm your password');
      });

      test('should return error for empty confirmation', () {
        // Arrange
        const password = 'password123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          '',
          password,
        );

        // Assert
        expect(result, 'Please, confirm your password');
      });

      test('should return error when passwords do not match', () {
        // Arrange
        const password = 'password123';
        const confirmation = 'password456';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should return error when confirmation is longer', () {
        // Arrange
        const password = 'password';
        const confirmation = 'password123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should return error when confirmation is shorter', () {
        // Arrange
        const password = 'password123';
        const confirmation = 'password';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should return error for case mismatch', () {
        // Arrange
        const password = 'Password123';
        const confirmation = 'password123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should return error when confirmation has extra space', () {
        // Arrange
        const password = 'password123';
        const confirmation = 'password123 ';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should return error when password is null but confirmation is not',
          () {
        // Arrange
        const confirmation = 'password123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          null,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should handle both being empty strings differently', () {
        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          '',
          '',
        );

        // Assert
        // Empty confirmation should trigger the empty check first
        expect(result, 'Please, confirm your password');
      });

      test('should be case-sensitive for matching', () {
        // Arrange
        const password = 'ABC123';
        const confirmation = 'abc123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should not trim whitespace before comparison', () {
        // Arrange
        const password = 'password123';
        const confirmation = '  password123  ';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should handle unicode mismatch', () {
        // Arrange
        const password = 'пароль123';
        const confirmation = 'пароль456';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });

      test('should handle special character mismatch', () {
        // Arrange
        const password = 'Pass!123';
        const confirmation = 'Pass@123';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, 'Passwords do not match');
      });
    });

    group('Edge Cases', () {
      test('email validator should handle tab characters', () {
        // Arrange
        const emailWithTab = 'test\t@example.com';

        // Act
        final result = AuthValidators.validateEmail(emailWithTab);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('email validator should handle newline characters', () {
        // Arrange
        const emailWithNewline = 'test\n@example.com';

        // Act
        final result = AuthValidators.validateEmail(emailWithNewline);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('password validator should handle tab characters', () {
        // Arrange
        const passwordWithTab = 'pass\tword';

        // Act
        final result = AuthValidators.validatePassword(passwordWithTab);

        // Assert
        expect(result, isNull); // 8 characters total
      });

      test('password confirmation should match with emoji', () {
        // Arrange
        const password = '🔒secure🔑pass';
        const confirmation = '🔒secure🔑pass';

        // Act
        final result = AuthValidators.validatePasswordConfirmation(
          confirmation,
          password,
        );

        // Assert
        expect(result, isNull);
      });

      test('email validator should accept valid international domain', () {
        // Arrange
        const email = 'test@example.co.uk';

        // Act
        final result = AuthValidators.validateEmail(email);

        // Assert
        expect(result, isNull);
      });

      test('email validator should reject email starting with dot', () {
        // Arrange
        const email = '.test@example.com';

        // Act
        final result = AuthValidators.validateEmail(email);

        // Assert
        expect(result, 'Please, insert a valid email');
      });

      test('email validator should reject email ending with dot before @', () {
        // Arrange
        const email = 'test.@example.com';

        // Act
        final result = AuthValidators.validateEmail(email);

        // Assert
        expect(result, 'Please, insert a valid email');
      });
    });
  });
}
