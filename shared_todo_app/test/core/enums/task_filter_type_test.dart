import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/enums/task_filter_type.dart';

void main() {
  group('TaskFilterType Extended Tests', () {
    group('Display Names', () {
      test('createdAtNewest should have correct display name', () {
        expect(TaskFilterType.createdAtNewest.displayName, 'Newest First');
      });

      test('createdAtOldest should have correct display name', () {
        expect(TaskFilterType.createdAtOldest.displayName, 'Oldest First');
      });

      test('priorityHighToLow should have correct display name', () {
        expect(TaskFilterType.priorityHighToLow.displayName,
            'Priority: High → Low');
      });

      test('priorityLowToHigh should have correct display name', () {
        expect(TaskFilterType.priorityLowToHigh.displayName,
            'Priority: Low → High');
      });

      test('alphabeticalAZ should have correct display name', () {
        expect(TaskFilterType.alphabeticalAZ.displayName, 'Title: A → Z');
      });

      test('alphabeticalZA should have correct display name', () {
        expect(TaskFilterType.alphabeticalZA.displayName, 'Title: Z → A');
      });
    });

    group('Descriptions', () {
      test('createdAtNewest should have correct description', () {
        expect(TaskFilterType.createdAtNewest.description,
            'Sort by creation date (newest first)');
      });

      test('createdAtOldest should have correct description', () {
        expect(TaskFilterType.createdAtOldest.description,
            'Sort by creation date (oldest first)');
      });

      test('priorityHighToLow should have correct description', () {
        expect(TaskFilterType.priorityHighToLow.description,
            'Sort by priority (High, Medium, Low)');
      });

      test('priorityLowToHigh should have correct description', () {
        expect(TaskFilterType.priorityLowToHigh.description,
            'Sort by priority (Low, Medium, High)');
      });

      test('alphabeticalAZ should have correct description', () {
        expect(TaskFilterType.alphabeticalAZ.description,
            'Sort alphabetically (A to Z)');
      });

      test('alphabeticalZA should have correct description', () {
        expect(TaskFilterType.alphabeticalZA.description,
            'Sort alphabetically (Z to A)');
      });
    });

    group('Enum Values', () {
      test('should have exactly 6 filter types', () {
        expect(TaskFilterType.values.length, 6);
      });

      test('should contain all filter types', () {
        expect(TaskFilterType.values, contains(TaskFilterType.createdAtNewest));
        expect(TaskFilterType.values, contains(TaskFilterType.createdAtOldest));
        expect(
            TaskFilterType.values, contains(TaskFilterType.priorityHighToLow));
        expect(
            TaskFilterType.values, contains(TaskFilterType.priorityLowToHigh));
        expect(TaskFilterType.values, contains(TaskFilterType.alphabeticalAZ));
        expect(TaskFilterType.values, contains(TaskFilterType.alphabeticalZA));
      });
    });
  });
}
