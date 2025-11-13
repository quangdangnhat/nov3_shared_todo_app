import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/data/models/daily_tasks/task_category.dart';
import 'package:shared_todo_app/core/utils/tasks_color.dart';

void main() {
  group('TaskColors Tests', () {
    late ThemeData lightTheme;
    late ThemeData darkTheme;

    setUp(() {
      lightTheme = ThemeData.light();
      darkTheme = ThemeData.dark();
    });

    group('getCategoryColor', () {
      test('should return error color for overdue category', () {
        final color = TaskColors.getCategoryColor(
          TaskCategory.overdue,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.error);
      });

      test('should return secondary color for dueToday category', () {
        final color = TaskColors.getCategoryColor(
          TaskCategory.dueToday,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return primary color for ongoing category', () {
        final color = TaskColors.getCategoryColor(
          TaskCategory.ongoing,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for startingToday category', () {
        final color = TaskColors.getCategoryColor(
          TaskCategory.startingToday,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.primary);
      });

      test('should work with dark theme', () {
        final overdueColor = TaskColors.getCategoryColor(
          TaskCategory.overdue,
          darkTheme,
        );
        final dueTodayColor = TaskColors.getCategoryColor(
          TaskCategory.dueToday,
          darkTheme,
        );

        expect(overdueColor, darkTheme.colorScheme.error);
        expect(dueTodayColor, darkTheme.colorScheme.secondary);
      });

      test('should return different colors for different categories', () {
        final overdueColor = TaskColors.getCategoryColor(
          TaskCategory.overdue,
          lightTheme,
        );
        final dueTodayColor = TaskColors.getCategoryColor(
          TaskCategory.dueToday,
          lightTheme,
        );
        final ongoingColor = TaskColors.getCategoryColor(
          TaskCategory.ongoing,
          lightTheme,
        );

        expect(overdueColor, isNot(dueTodayColor));
        expect(dueTodayColor, isNot(ongoingColor));
      });
    });

    group('getPriorityColor', () {
      test('should return error color for High priority', () {
        final color = TaskColors.getPriorityColor('High', lightTheme);
        expect(color, lightTheme.colorScheme.error);
      });

      test('should return error color for high priority (lowercase)', () {
        final color = TaskColors.getPriorityColor('high', lightTheme);
        expect(color, lightTheme.colorScheme.error);
      });

      test('should return error color for alta priority (Italian)', () {
        final color = TaskColors.getPriorityColor('alta', lightTheme);
        expect(color, lightTheme.colorScheme.error);
      });

      test('should return secondary color for Medium priority', () {
        final color = TaskColors.getPriorityColor('Medium', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return secondary color for medium priority (lowercase)', () {
        final color = TaskColors.getPriorityColor('medium', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return secondary color for media priority (Italian)', () {
        final color = TaskColors.getPriorityColor('media', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return primary color for Low priority', () {
        final color = TaskColors.getPriorityColor('Low', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for low priority (lowercase)', () {
        final color = TaskColors.getPriorityColor('low', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should be case insensitive', () {
        final colorUpper = TaskColors.getPriorityColor('HIGH', lightTheme);
        final colorLower = TaskColors.getPriorityColor('high', lightTheme);
        final colorMixed = TaskColors.getPriorityColor('HiGh', lightTheme);

        expect(colorUpper, lightTheme.colorScheme.error);
        expect(colorLower, lightTheme.colorScheme.error);
        expect(colorMixed, lightTheme.colorScheme.error);
      });

      test('should handle unknown priority as low priority', () {
        final color = TaskColors.getPriorityColor('Unknown', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should work with dark theme', () {
        final highColor = TaskColors.getPriorityColor('High', darkTheme);
        final mediumColor = TaskColors.getPriorityColor('Medium', darkTheme);
        final lowColor = TaskColors.getPriorityColor('Low', darkTheme);

        expect(highColor, darkTheme.colorScheme.error);
        expect(mediumColor, darkTheme.colorScheme.secondary);
        expect(lowColor, darkTheme.colorScheme.primary);
      });

      test('should handle empty string', () {
        final color = TaskColors.getPriorityColor('', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });
    });

    group('getStatusColor', () {
      test('should return primary color for done status', () {
        final color = TaskColors.getStatusColor('done', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for DONE status (uppercase)', () {
        final color = TaskColors.getStatusColor('DONE', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for completato status (Italian)', () {
        final color = TaskColors.getStatusColor('completato', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return secondary color for progress status', () {
        final color = TaskColors.getStatusColor('progress', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return secondary color for in progress status', () {
        final color = TaskColors.getStatusColor('in progress', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return secondary color for progresso status (Italian)', () {
        final color = TaskColors.getStatusColor('progresso', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return faded onSurface color for pending status', () {
        final color = TaskColors.getStatusColor('pending', lightTheme);
        expect(color.opacity, 0.6);
      });

      test('should return faded onSurface color for unknown status', () {
        final color = TaskColors.getStatusColor('unknown', lightTheme);
        expect(color.opacity, 0.6);
      });

      test('should be case insensitive', () {
        final colorUpper = TaskColors.getStatusColor('DONE', lightTheme);
        final colorLower = TaskColors.getStatusColor('done', lightTheme);
        final colorMixed = TaskColors.getStatusColor('DoNe', lightTheme);

        expect(colorUpper, lightTheme.colorScheme.primary);
        expect(colorLower, lightTheme.colorScheme.primary);
        expect(colorMixed, lightTheme.colorScheme.primary);
      });

      test('should work with dark theme', () {
        final doneColor = TaskColors.getStatusColor('done', darkTheme);
        final progressColor = TaskColors.getStatusColor('progress', darkTheme);

        expect(doneColor, darkTheme.colorScheme.primary);
        expect(progressColor, darkTheme.colorScheme.secondary);
      });

      test('should handle empty string', () {
        final color = TaskColors.getStatusColor('', lightTheme);
        expect(color.opacity, 0.6);
      });

      test('should handle partial matches', () {
        // These should match because they contain the keywords
        final todoColor = TaskColors.getStatusColor('Todo', lightTheme);
        final startedColor = TaskColors.getStatusColor('Started', lightTheme);

        expect(todoColor.opacity, 0.6);
        expect(startedColor.opacity, 0.6);
      });
    });

    group('Consistency', () {
      test('should maintain color consistency across calls', () {
        final color1 = TaskColors.getCategoryColor(
          TaskCategory.overdue,
          lightTheme,
        );
        final color2 = TaskColors.getCategoryColor(
          TaskCategory.overdue,
          lightTheme,
        );

        expect(color1, equals(color2));
      });

      test('should provide consistent colors for same priority', () {
        final color1 = TaskColors.getPriorityColor('High', lightTheme);
        final color2 = TaskColors.getPriorityColor('HIGH', lightTheme);
        final color3 = TaskColors.getPriorityColor('high', lightTheme);

        expect(color1, equals(color2));
        expect(color2, equals(color3));
      });
    });
  });
}
