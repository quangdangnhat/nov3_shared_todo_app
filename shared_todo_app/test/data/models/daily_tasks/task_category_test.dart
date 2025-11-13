import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/daily_tasks/task_category.dart';

void main() {
  group('TaskCategory Tests', () {
    group('Enum Values', () {
      test('should have exactly 4 categories', () {
        expect(TaskCategory.values.length, 4);
      });

      test('should contain all expected categories', () {
        expect(TaskCategory.values, contains(TaskCategory.overdue));
        expect(TaskCategory.values, contains(TaskCategory.dueToday));
        expect(TaskCategory.values, contains(TaskCategory.ongoing));
        expect(TaskCategory.values, contains(TaskCategory.startingToday));
      });
    });

    group('title getter', () {
      test('overdue should return "Expired"', () {
        expect(TaskCategory.overdue.title, 'Expired');
      });

      test('dueToday should return "Expires Today"', () {
        expect(TaskCategory.dueToday.title, 'Expires Today');
      });

      test('ongoing should return "In Progress"', () {
        expect(TaskCategory.ongoing.title, 'In Progress');
      });

      test('startingToday should return "They start today"', () {
        expect(TaskCategory.startingToday.title, 'They start today');
      });

      test('all categories should have non-empty titles', () {
        for (final category in TaskCategory.values) {
          expect(category.title, isNotEmpty);
        }
      });
    });

    group('subtitle getter', () {
      test('overdue should return "Requires immediate attention"', () {
        expect(TaskCategory.overdue.subtitle, 'Requires immediate attention');
      });

      test('dueToday should return "To be completed by today"', () {
        expect(TaskCategory.dueToday.subtitle, 'To be completed by today');
      });

      test('ongoing should return "Already started, future deadline"', () {
        expect(TaskCategory.ongoing.subtitle, 'Already started, future deadline');
      });

      test('startingToday should return "New tasks to start"', () {
        expect(TaskCategory.startingToday.subtitle, 'New tasks to start');
      });

      test('all categories should have non-empty subtitles', () {
        for (final category in TaskCategory.values) {
          expect(category.subtitle, isNotEmpty);
        }
      });
    });

    group('icon getter', () {
      test('overdue should return warning icon', () {
        expect(TaskCategory.overdue.icon, Icons.warning_amber_rounded);
      });

      test('dueToday should return event available icon', () {
        expect(TaskCategory.dueToday.icon, Icons.event_available);
      });

      test('ongoing should return pending actions icon', () {
        expect(TaskCategory.ongoing.icon, Icons.pending_actions);
      });

      test('startingToday should return play circle outline icon', () {
        expect(TaskCategory.startingToday.icon, Icons.play_circle_outline);
      });

      test('all categories should return valid IconData', () {
        for (final category in TaskCategory.values) {
          expect(category.icon, isA<IconData>());
        }
      });

      test('all categories should have unique icons', () {
        final icons = TaskCategory.values.map((c) => c.icon).toSet();
        expect(icons.length, TaskCategory.values.length);
      });
    });

    group('filterLabel getter', () {
      test('overdue should return "Expired"', () {
        expect(TaskCategory.overdue.filterLabel, 'Expired');
      });

      test('dueToday should return "Expire Today"', () {
        expect(TaskCategory.dueToday.filterLabel, 'Expire Today');
      });

      test('ongoing should return "In Progress"', () {
        expect(TaskCategory.ongoing.filterLabel, 'In Progress');
      });

      test('startingToday should return "Start today"', () {
        expect(TaskCategory.startingToday.filterLabel, 'Start today');
      });

      test('all categories should have non-empty filter labels', () {
        for (final category in TaskCategory.values) {
          expect(category.filterLabel, isNotEmpty);
        }
      });
    });

    group('Enum Comparison', () {
      test('should be able to compare enum values', () {
        expect(TaskCategory.overdue == TaskCategory.overdue, isTrue);
        expect(TaskCategory.overdue == TaskCategory.dueToday, isFalse);
      });

      test('should work in switch statements', () {
        String getCategoryName(TaskCategory category) {
          switch (category) {
            case TaskCategory.overdue:
              return 'overdue';
            case TaskCategory.dueToday:
              return 'due_today';
            case TaskCategory.ongoing:
              return 'ongoing';
            case TaskCategory.startingToday:
              return 'starting_today';
          }
        }

        expect(getCategoryName(TaskCategory.overdue), 'overdue');
        expect(getCategoryName(TaskCategory.dueToday), 'due_today');
      });

      test('should be usable in collections', () {
        final categories = [
          TaskCategory.overdue,
          TaskCategory.ongoing,
        ];

        expect(categories.length, 2);
        expect(categories, contains(TaskCategory.overdue));
      });

      test('should be usable as map keys', () {
        final categoryMap = {
          TaskCategory.overdue: 'red',
          TaskCategory.dueToday: 'orange',
        };

        expect(categoryMap[TaskCategory.overdue], 'red');
        expect(categoryMap[TaskCategory.dueToday], 'orange');
      });
    });

    group('Category Properties', () {
      test('overdue category should have urgent properties', () {
        final category = TaskCategory.overdue;

        expect(category.title, 'Expired');
        expect(category.subtitle, contains('immediate attention'));
        expect(category.icon, Icons.warning_amber_rounded);
      });

      test('dueToday category should have today-related properties', () {
        final category = TaskCategory.dueToday;

        expect(category.title, contains('Today'));
        expect(category.subtitle, contains('today'));
        expect(category.icon, Icons.event_available);
      });

      test('ongoing category should have progress-related properties', () {
        final category = TaskCategory.ongoing;

        expect(category.title, 'In Progress');
        expect(category.subtitle, contains('started'));
        expect(category.icon, Icons.pending_actions);
      });

      test('startingToday category should have start-related properties', () {
        final category = TaskCategory.startingToday;

        expect(category.title, contains('start'));
        expect(category.subtitle, contains('start'));
        expect(category.icon, Icons.play_circle_outline);
      });
    });

    group('Consistency', () {
      test('all titles should be unique', () {
        final titles = TaskCategory.values.map((c) => c.title).toSet();
        expect(titles.length, TaskCategory.values.length);
      });

      test('all subtitles should be unique', () {
        final subtitles = TaskCategory.values.map((c) => c.subtitle).toSet();
        expect(subtitles.length, TaskCategory.values.length);
      });

      test('all filter labels should be unique', () {
        final labels = TaskCategory.values.map((c) => c.filterLabel).toSet();
        expect(labels.length, TaskCategory.values.length);
      });

      test('should maintain consistent properties across calls', () {
        final category = TaskCategory.overdue;

        expect(category.title, category.title);
        expect(category.subtitle, category.subtitle);
        expect(category.icon, category.icon);
        expect(category.filterLabel, category.filterLabel);
      });
    });

    group('Edge Cases', () {
      test('should be able to iterate over all values', () {
        int count = 0;
        for (final category in TaskCategory.values) {
          count++;
          expect(category.title, isNotEmpty);
          expect(category.subtitle, isNotEmpty);
          expect(category.icon, isA<IconData>());
          expect(category.filterLabel, isNotEmpty);
        }

        expect(count, 4);
      });

      test('should be able to filter categories', () {
        final todayCategories = TaskCategory.values
            .where((c) => c.title.toLowerCase().contains('today'))
            .toList();

        expect(todayCategories.length, 2); // dueToday and startingToday
        expect(todayCategories, contains(TaskCategory.dueToday));
        expect(todayCategories, contains(TaskCategory.startingToday));
      });

      test('should be able to map categories', () {
        final titles = TaskCategory.values.map((c) => c.title).toList();

        expect(titles.length, 4);
        expect(titles, contains('Expired'));
        expect(titles, contains('In Progress'));
      });
    });

    group('Text Content', () {
      test('title should be shorter than subtitle', () {
        for (final category in TaskCategory.values) {
          expect(
            category.title.length,
            lessThanOrEqualTo(category.subtitle.length),
          );
        }
      });

      test('filter labels should be concise', () {
        for (final category in TaskCategory.values) {
          expect(category.filterLabel.length, lessThan(30));
        }
      });

      test('overdue should use warning-related terms', () {
        expect(TaskCategory.overdue.title.toLowerCase(), contains('expir'));
        expect(TaskCategory.overdue.subtitle.toLowerCase(), contains('attention'));
      });
    });

    group('Priority Ordering', () {
      test('overdue should be the first category', () {
        expect(TaskCategory.values.first, TaskCategory.overdue);
      });

      test('categories should be in logical priority order', () {
        final categories = TaskCategory.values;

        // Overdue should come first (highest priority)
        expect(categories[0], TaskCategory.overdue);
        // DueToday should come second
        expect(categories[1], TaskCategory.dueToday);
        // Then ongoing and startingToday
        expect(categories.sublist(2), containsAll([
          TaskCategory.ongoing,
          TaskCategory.startingToday,
        ]));
      });
    });
  });
}
