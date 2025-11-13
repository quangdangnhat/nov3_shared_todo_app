import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/enums/task_filter_type.dart';

void main() {
  group('TaskFilterType Tests', () {
    group('Enum Values', () {
      test('should have exactly 6 filter types', () {
        expect(TaskFilterType.values.length, 6);
      });

      test('should contain all expected filter types', () {
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

      test('all filter types should have non-empty display names', () {
        for (final filterType in TaskFilterType.values) {
          expect(filterType.displayName, isNotEmpty);
        }
      });
    });

    group('Descriptions', () {
      test('createdAtNewest should have correct description', () {
        expect(
          TaskFilterType.createdAtNewest.description,
          'Sort by creation date (newest first)',
        );
      });

      test('createdAtOldest should have correct description', () {
        expect(
          TaskFilterType.createdAtOldest.description,
          'Sort by creation date (oldest first)',
        );
      });

      test('priorityHighToLow should have correct description', () {
        expect(
          TaskFilterType.priorityHighToLow.description,
          'Sort by priority (High, Medium, Low)',
        );
      });

      test('priorityLowToHigh should have correct description', () {
        expect(
          TaskFilterType.priorityLowToHigh.description,
          'Sort by priority (Low, Medium, High)',
        );
      });

      test('alphabeticalAZ should have correct description', () {
        expect(
          TaskFilterType.alphabeticalAZ.description,
          'Sort alphabetically (A to Z)',
        );
      });

      test('alphabeticalZA should have correct description', () {
        expect(
          TaskFilterType.alphabeticalZA.description,
          'Sort alphabetically (Z to A)',
        );
      });

      test('all filter types should have non-empty descriptions', () {
        for (final filterType in TaskFilterType.values) {
          expect(filterType.description, isNotEmpty);
        }
      });
    });

    group('Enum Comparison', () {
      test('should be able to compare enum values', () {
        expect(
          TaskFilterType.createdAtNewest == TaskFilterType.createdAtNewest,
          isTrue,
        );
        expect(
          TaskFilterType.createdAtNewest == TaskFilterType.createdAtOldest,
          isFalse,
        );
      });

      test('should work in switch statements', () {
        String getFilterName(TaskFilterType type) {
          switch (type) {
            case TaskFilterType.createdAtNewest:
              return 'newest';
            case TaskFilterType.createdAtOldest:
              return 'oldest';
            case TaskFilterType.priorityHighToLow:
              return 'priority_high_low';
            case TaskFilterType.priorityLowToHigh:
              return 'priority_low_high';
            case TaskFilterType.alphabeticalAZ:
              return 'alpha_az';
            case TaskFilterType.alphabeticalZA:
              return 'alpha_za';
          }
        }

        expect(getFilterName(TaskFilterType.createdAtNewest), 'newest');
        expect(getFilterName(TaskFilterType.alphabeticalAZ), 'alpha_az');
      });

      test('should be usable in collections', () {
        final filters = [
          TaskFilterType.createdAtNewest,
          TaskFilterType.priorityHighToLow,
          TaskFilterType.alphabeticalAZ,
        ];

        expect(filters.length, 3);
        expect(filters, contains(TaskFilterType.createdAtNewest));
      });

      test('should be usable as map keys', () {
        final filterMap = {
          TaskFilterType.createdAtNewest: 'Newest',
          TaskFilterType.createdAtOldest: 'Oldest',
        };

        expect(filterMap[TaskFilterType.createdAtNewest], 'Newest');
        expect(filterMap[TaskFilterType.createdAtOldest], 'Oldest');
      });
    });

    group('Filter Type Pairs', () {
      test('createdAt filters should be opposites', () {
        expect(
          TaskFilterType.createdAtNewest.displayName,
          contains('Newest'),
        );
        expect(
          TaskFilterType.createdAtOldest.displayName,
          contains('Oldest'),
        );
      });

      test('priority filters should be opposites', () {
        expect(
          TaskFilterType.priorityHighToLow.displayName,
          contains('High → Low'),
        );
        expect(
          TaskFilterType.priorityLowToHigh.displayName,
          contains('Low → High'),
        );
      });

      test('alphabetical filters should be opposites', () {
        expect(
          TaskFilterType.alphabeticalAZ.displayName,
          contains('A → Z'),
        );
        expect(
          TaskFilterType.alphabeticalZA.displayName,
          contains('Z → A'),
        );
      });
    });

    group('Edge Cases', () {
      test('should maintain consistent properties across multiple calls', () {
        final filter = TaskFilterType.createdAtNewest;

        expect(filter.displayName, filter.displayName);
        expect(filter.description, filter.description);
      });

      test('should be able to iterate over all values', () {
        int count = 0;
        for (final filter in TaskFilterType.values) {
          count++;
          expect(filter.displayName, isNotEmpty);
          expect(filter.description, isNotEmpty);
        }

        expect(count, 6);
      });

      test('should be able to filter values', () {
        final priorityFilters = TaskFilterType.values
            .where((f) => f.displayName.contains('Priority'))
            .toList();

        expect(priorityFilters.length, 2);
        expect(priorityFilters, contains(TaskFilterType.priorityHighToLow));
        expect(priorityFilters, contains(TaskFilterType.priorityLowToHigh));
      });

      test('should be able to map values', () {
        final displayNames =
            TaskFilterType.values.map((f) => f.displayName).toList();

        expect(displayNames.length, 6);
        expect(displayNames, contains('Newest First'));
        expect(displayNames, contains('Title: A → Z'));
      });
    });

    group('Consistency', () {
      test('all display names should be unique', () {
        final displayNames =
            TaskFilterType.values.map((f) => f.displayName).toSet();

        expect(displayNames.length, TaskFilterType.values.length);
      });

      test('all descriptions should be unique', () {
        final descriptions =
            TaskFilterType.values.map((f) => f.description).toSet();

        expect(descriptions.length, TaskFilterType.values.length);
      });

      test('display names should be shorter than descriptions', () {
        for (final filter in TaskFilterType.values) {
          expect(
            filter.displayName.length,
            lessThanOrEqualTo(filter.description.length),
          );
        }
      });
    });
  });
}
