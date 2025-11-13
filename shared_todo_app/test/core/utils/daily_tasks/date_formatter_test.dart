import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/utils/daily_tasks/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 11, 13, 14, 30);
    });

    test('should format full date correctly', () {
      // Act
      final formatted = DateFormatter.formatFull(testDate);

      // Assert
      expect(formatted, '13/11/2025 14:30');
    });

    test('should handle null date in formatFull', () {
      // Act
      final formatted = DateFormatter.formatFull(null);

      // Assert
      expect(formatted, 'Data non impostata');
    });

    test('should format short date correctly', () {
      // Act
      final formatted = DateFormatter.formatShort(testDate);

      // Assert
      expect(formatted, '13/11');
    });

    test('should calculate days until future date', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 5));

      // Act
      final days = DateFormatter.daysUntil(futureDate);

      // Assert
      expect(days, 5);
    });

    test('should calculate days until past date (negative)', () {
      // Arrange
      final pastDate = DateTime.now().subtract(const Duration(days: 3));

      // Act
      final days = DateFormatter.daysUntil(pastDate);

      // Assert
      expect(days, -3);
    });

    test('should calculate days until today as 0', () {
      // Arrange
      final today = DateTime.now();

      // Act
      final days = DateFormatter.daysUntil(today);

      // Assert
      expect(days, 0);
    });

    test('should calculate days between two dates', () {
      // Arrange
      final startDate = DateTime(2025, 11, 1);
      final endDate = DateTime(2025, 11, 10);

      // Act
      final days = DateFormatter.daysBetween(startDate, endDate);

      // Assert
      expect(days, 9);
    });

    test('should calculate negative days when start is after end', () {
      // Arrange
      final startDate = DateTime(2025, 11, 10);
      final endDate = DateTime(2025, 11, 1);

      // Act
      final days = DateFormatter.daysBetween(startDate, endDate);

      // Assert
      expect(days, -9);
    });

    test('should ignore time when calculating days between', () {
      // Arrange
      final startDate = DateTime(2025, 11, 1, 23, 59);
      final endDate = DateTime(2025, 11, 2, 0, 1);

      // Act
      final days = DateFormatter.daysBetween(startDate, endDate);

      // Assert
      expect(days, 1);
    });

    test('should identify overdue date', () {
      // Arrange
      final overdueDate = DateTime.now().subtract(const Duration(days: 1));

      // Act
      final isOverdue = DateFormatter.isOverdue(overdueDate);

      // Assert
      expect(isOverdue, isTrue);
    });

    test('should identify non-overdue date', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 1));

      // Act
      final isOverdue = DateFormatter.isOverdue(futureDate);

      // Assert
      expect(isOverdue, isFalse);
    });

    test('should not consider today as overdue', () {
      // Arrange
      final today = DateTime.now();

      // Act
      final isOverdue = DateFormatter.isOverdue(today);

      // Assert
      expect(isOverdue, isFalse);
    });

    test('should format days remaining for overdue task (single day)', () {
      // Arrange
      final overdueDate = DateTime.now().subtract(const Duration(days: 1));

      // Act
      final formatted = DateFormatter.formatDaysRemaining(overdueDate);

      // Assert
      expect(formatted, 'Expired  1 day ago');
    });

    test('should format days remaining for overdue task (multiple days)', () {
      // Arrange
      final overdueDate = DateTime.now().subtract(const Duration(days: 5));

      // Act
      final formatted = DateFormatter.formatDaysRemaining(overdueDate);

      // Assert
      expect(formatted, 'Expired  5 days ago');
    });

    test('should format days remaining for task due today', () {
      // Arrange
      final today = DateTime.now();

      // Act
      final formatted = DateFormatter.formatDaysRemaining(today);

      // Assert
      expect(formatted, 'Expire Today');
    });

    test('should format days remaining for task due tomorrow', () {
      // Arrange
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Act
      final formatted = DateFormatter.formatDaysRemaining(tomorrow);

      // Assert
      expect(formatted, 'Expire tomorrow');
    });

    test('should format days remaining for future task', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 7));

      // Act
      final formatted = DateFormatter.formatDaysRemaining(futureDate);

      // Assert
      expect(formatted, 'Days Left: 7');
    });

    test('should handle date with different time components correctly', () {
      // Arrange
      final date1 = DateTime(2025, 11, 13, 8, 0);
      final date2 = DateTime(2025, 11, 13, 23, 59);

      // Act
      final days = DateFormatter.daysBetween(date1, date2);

      // Assert
      expect(days, 0); // Same day, should be 0
    });

    test('should format month with leading zero', () {
      // Arrange
      final date = DateTime(2025, 1, 5); // January

      // Act
      final formatted = DateFormatter.formatShort(date);

      // Assert
      expect(formatted, '05/01');
    });

    test('should format day with leading zero', () {
      // Arrange
      final date = DateTime(2025, 11, 3);

      // Act
      final formatted = DateFormatter.formatShort(date);

      // Assert
      expect(formatted, '03/11');
    });

    test('should handle leap year dates', () {
      // Arrange
      final leapYearDate = DateTime(2024, 2, 29); // Leap year
      final nextDay = DateTime(2024, 3, 1);

      // Act
      final days = DateFormatter.daysBetween(leapYearDate, nextDay);

      // Assert
      expect(days, 1);
    });

    test('should handle year boundaries', () {
      // Arrange
      final endOfYear = DateTime(2025, 12, 31);
      final startOfYear = DateTime(2026, 1, 1);

      // Act
      final days = DateFormatter.daysBetween(endOfYear, startOfYear);

      // Assert
      expect(days, 1);
    });
  });
}
