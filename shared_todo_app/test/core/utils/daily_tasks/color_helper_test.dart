import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/enums/task_category.dart';
import 'package:shared_todo_app/core/utils/daily_tasks/color_helper.dart';

void main() {
  group('ColorHelper Tests', () {
    late ThemeData lightTheme;
    late ThemeData darkTheme;

    setUp(() {
      lightTheme = ThemeData.light();
      darkTheme = ThemeData.dark();
    });

    group('getCategoryColor', () {
      test('should return error color for overdue category', () {
        final color = ColorHelper.getCategoryColor(
          TaskCategory.overdue,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.error);
      });

      test('should return secondary color for dueToday category', () {
        final color = ColorHelper.getCategoryColor(
          TaskCategory.dueToday,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return primary color for ongoing category', () {
        final color = ColorHelper.getCategoryColor(
          TaskCategory.ongoing,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for startingToday category', () {
        final color = ColorHelper.getCategoryColor(
          TaskCategory.startingToday,
          lightTheme,
        );

        expect(color, lightTheme.colorScheme.primary);
      });

      test('should work with dark theme', () {
        final color = ColorHelper.getCategoryColor(
          TaskCategory.overdue,
          darkTheme,
        );

        expect(color, darkTheme.colorScheme.error);
      });
    });

    group('getPriorityColor', () {
      test('should return error color for High priority', () {
        final color = ColorHelper.getPriorityColor('High', lightTheme);
        expect(color, lightTheme.colorScheme.error);
      });

      test('should return error color for alta priority (Italian)', () {
        final color = ColorHelper.getPriorityColor('alta', lightTheme);
        expect(color, lightTheme.colorScheme.error);
      });

      test('should return secondary color for Medium priority', () {
        final color = ColorHelper.getPriorityColor('Medium', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return secondary color for media priority (Italian)', () {
        final color = ColorHelper.getPriorityColor('media', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return primary color for Low priority', () {
        final color = ColorHelper.getPriorityColor('Low', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should be case insensitive', () {
        final colorUpper = ColorHelper.getPriorityColor('HIGH', lightTheme);
        final colorLower = ColorHelper.getPriorityColor('high', lightTheme);
        final colorMixed = ColorHelper.getPriorityColor('HiGh', lightTheme);

        expect(colorUpper, lightTheme.colorScheme.error);
        expect(colorLower, lightTheme.colorScheme.error);
        expect(colorMixed, lightTheme.colorScheme.error);
      });

      test('should handle unknown priority as low priority', () {
        final color = ColorHelper.getPriorityColor('Unknown', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });
    });

    group('getStatusColor', () {
      test('should return primary color for done status', () {
        final color = ColorHelper.getStatusColor('done', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for completato status (Italian)', () {
        final color = ColorHelper.getStatusColor('completato', lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return secondary color for progress status', () {
        final color = ColorHelper.getStatusColor('progress', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return secondary color for progresso status (Italian)', () {
        final color = ColorHelper.getStatusColor('progresso', lightTheme);
        expect(color, lightTheme.colorScheme.secondary);
      });

      test('should return faded onSurface color for pending status', () {
        final color = ColorHelper.getStatusColor('pending', lightTheme);
        expect(color.opacity, 0.6);
      });

      test('should be case insensitive', () {
        final colorUpper = ColorHelper.getStatusColor('DONE', lightTheme);
        final colorLower = ColorHelper.getStatusColor('done', lightTheme);
        final colorMixed = ColorHelper.getStatusColor('DoNe', lightTheme);

        expect(colorUpper, lightTheme.colorScheme.primary);
        expect(colorLower, lightTheme.colorScheme.primary);
        expect(colorMixed, lightTheme.colorScheme.primary);
      });
    });

    group('getBadgeBackgroundColor', () {
      test('should return color with default opacity', () {
        final baseColor = Colors.red;
        final backgroundColor = ColorHelper.getBadgeBackgroundColor(baseColor);

        expect(backgroundColor.opacity, 0.2);
      });

      test('should return color with custom opacity', () {
        final baseColor = Colors.blue;
        final backgroundColor =
            ColorHelper.getBadgeBackgroundColor(baseColor, opacity: 0.5);

        expect(backgroundColor.opacity, 0.5);
      });

      test('should preserve base color', () {
        final baseColor = Colors.green;
        final backgroundColor = ColorHelper.getBadgeBackgroundColor(baseColor);

        expect(backgroundColor.red, baseColor.red);
        expect(backgroundColor.green, baseColor.green);
        expect(backgroundColor.blue, baseColor.blue);
      });
    });

    group('getOverdueBorderColor', () {
      test('should return error color with reduced opacity', () {
        final borderColor = ColorHelper.getOverdueBorderColor(lightTheme);

        expect(borderColor.opacity, 0.3);
      });

      test('should use theme error color', () {
        final borderColor = ColorHelper.getOverdueBorderColor(lightTheme);
        final errorColor = lightTheme.colorScheme.error;

        expect(borderColor.red, errorColor.red);
        expect(borderColor.green, errorColor.green);
        expect(borderColor.blue, errorColor.blue);
      });

      test('should work with dark theme', () {
        final borderColor = ColorHelper.getOverdueBorderColor(darkTheme);

        expect(borderColor.opacity, 0.3);
      });
    });
  });
}
