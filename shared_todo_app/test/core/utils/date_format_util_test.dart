import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/utils/date_format_util.dart';

void main() {
  group('formatDate Tests', () {
    test('should return "Just now" for time less than 2 minutes ago', () {
      final date = DateTime.now().subtract(const Duration(minutes: 1));
      final result = formatDate(date);

      expect(result, 'Just now');
    });

    test('should return minutes ago for time less than 1 hour ago', () {
      final date = DateTime.now().subtract(const Duration(minutes: 30));
      final result = formatDate(date);

      expect(result, '30m ago');
    });

    test('should return hours ago for time less than 1 day ago', () {
      final date = DateTime.now().subtract(const Duration(hours: 5));
      final result = formatDate(date);

      expect(result, '5h ago');
    });

    test('should return "Yesterday" for 1 day ago', () {
      final date = DateTime.now().subtract(const Duration(days: 1));
      final result = formatDate(date);

      expect(result, 'Yesterday');
    });

    test('should return "X days ago" for less than 7 days', () {
      final date = DateTime.now().subtract(const Duration(days: 3));
      final result = formatDate(date);

      expect(result, '3 days ago');
    });

    test('should return formatted date for 7+ days ago', () {
      final date = DateTime(2025, 11, 1); // More than 7 days ago
      final result = formatDate(date);

      expect(result, matches(r'\d{2}/\d{2}/\d{4}'));
      expect(result, '01/11/2025');
    });

    test('should handle exact 2 minutes threshold', () {
      final date = DateTime.now().subtract(const Duration(minutes: 2));
      final result = formatDate(date);

      expect(result, '2m ago');
    });

    test('should handle exact 1 hour threshold', () {
      final date = DateTime.now().subtract(const Duration(hours: 1));
      final result = formatDate(date);

      expect(result, '1h ago');
    });

    test('should handle exact 7 days threshold', () {
      final date = DateTime.now().subtract(const Duration(days: 7));
      final result = formatDate(date);

      // Should be formatted date, not "7 days ago"
      expect(result, matches(r'\d{2}/\d{2}/\d{4}'));
    });

    test('should convert to local time', () {
      final utcDate = DateTime.utc(2025, 11, 1, 12, 0);
      final result = formatDate(utcDate);

      // Should work regardless of timezone
      expect(result, isNotEmpty);
    });

    test('should pad single digits with zero', () {
      final date = DateTime(2025, 1, 5); // January 5
      final result = formatDate(date);

      expect(result, '05/01/2025');
    });

    test('should handle different months correctly', () {
      final dateJan = DateTime(2025, 1, 15);
      final resultJan = formatDate(dateJan);
      expect(resultJan, '15/01/2025');

      final dateDec = DateTime(2025, 12, 25);
      final resultDec = formatDate(dateDec);
      expect(resultDec, '25/12/2025');
    });

    test('should handle leap year dates', () {
      final date = DateTime(2024, 2, 29); // Leap year
      final result = formatDate(date);

      expect(result, '29/02/2024');
    });

    test('should handle very old dates', () {
      final date = DateTime(2020, 1, 1);
      final result = formatDate(date);

      expect(result, '01/01/2020');
    });

    test('should handle dates at midnight', () {
      final date = DateTime(2025, 11, 10, 0, 0, 0);
      final result = formatDate(date);

      expect(result, isNotEmpty);
    });

    test('should handle dates at end of day', () {
      final date = DateTime(2025, 11, 10, 23, 59, 59);
      final result = formatDate(date);

      expect(result, isNotEmpty);
    });
  });
}
