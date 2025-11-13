import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/utils/tree_style_util.dart';
import 'package:shared_todo_app/data/models/tree/node_type.dart';

void main() {
  group('TreeStyleUtils Tests', () {
    late ThemeData lightTheme;
    late ThemeData darkTheme;

    setUp(() {
      lightTheme = ThemeData.light();
      darkTheme = ThemeData.dark();
    });

    group('getIconForType', () {
      test('should return list icon for todoList type', () {
        final icon = TreeStyleUtils.getIconForType(NodeType.todoList);
        expect(icon, Icons.list_alt);
      });

      test('should return folder icon for folder type', () {
        final icon = TreeStyleUtils.getIconForType(NodeType.folder);
        expect(icon, Icons.folder);
      });

      test('should return task icon for task type', () {
        final icon = TreeStyleUtils.getIconForType(NodeType.task);
        expect(icon, Icons.task_alt);
      });

      test('should return valid IconData for all node types', () {
        for (final type in NodeType.values) {
          final icon = TreeStyleUtils.getIconForType(type);
          expect(icon, isA<IconData>());
        }
      });
    });

    group('getIconColor', () {
      test('should return primary color for todoList in light theme', () {
        final color = TreeStyleUtils.getIconColor(NodeType.todoList, lightTheme);
        expect(color, lightTheme.colorScheme.primary);
      });

      test('should return primary color for todoList in dark theme', () {
        final color = TreeStyleUtils.getIconColor(NodeType.todoList, darkTheme);
        expect(color, darkTheme.colorScheme.primary);
      });

      test('should return orange color for folder in light theme', () {
        final color = TreeStyleUtils.getIconColor(NodeType.folder, lightTheme);
        expect(color, const Color(0xFFFFA000));
      });

      test('should return lighter orange color for folder in dark theme', () {
        final color = TreeStyleUtils.getIconColor(NodeType.folder, darkTheme);
        expect(color, const Color(0xFFFFB74D));
      });

      test('should return green color for task in light theme', () {
        final color = TreeStyleUtils.getIconColor(NodeType.task, lightTheme);
        expect(color, const Color(0xFF43A047));
      });

      test('should return lighter green color for task in dark theme', () {
        final color = TreeStyleUtils.getIconColor(NodeType.task, darkTheme);
        expect(color, const Color(0xFF66BB6A));
      });

      test('should return different colors for folder in light vs dark theme', () {
        final lightColor = TreeStyleUtils.getIconColor(NodeType.folder, lightTheme);
        final darkColor = TreeStyleUtils.getIconColor(NodeType.folder, darkTheme);
        expect(lightColor, isNot(darkColor));
      });

      test('should return different colors for task in light vs dark theme', () {
        final lightColor = TreeStyleUtils.getIconColor(NodeType.task, lightTheme);
        final darkColor = TreeStyleUtils.getIconColor(NodeType.task, darkTheme);
        expect(lightColor, isNot(darkColor));
      });
    });

    group('getBackgroundColor', () {
      test('should return surface variant for todoList in light theme', () {
        final color = TreeStyleUtils.getBackgroundColor(NodeType.todoList, lightTheme);
        expect(color, lightTheme.colorScheme.surfaceVariant);
      });

      test('should return surface with opacity for todoList in dark theme', () {
        final color = TreeStyleUtils.getBackgroundColor(NodeType.todoList, darkTheme);
        expect(color, darkTheme.colorScheme.surface.withOpacity(0.8));
      });

      test('should return surface color for folder', () {
        final lightColor = TreeStyleUtils.getBackgroundColor(NodeType.folder, lightTheme);
        final darkColor = TreeStyleUtils.getBackgroundColor(NodeType.folder, darkTheme);

        expect(lightColor, lightTheme.colorScheme.surface);
        expect(darkColor, darkTheme.colorScheme.surface);
      });

      test('should return surface color for task', () {
        final lightColor = TreeStyleUtils.getBackgroundColor(NodeType.task, lightTheme);
        final darkColor = TreeStyleUtils.getBackgroundColor(NodeType.task, darkTheme);

        expect(lightColor, lightTheme.colorScheme.surface);
        expect(darkColor, darkTheme.colorScheme.surface);
      });

      test('should return same color for folder and task', () {
        final folderColor = TreeStyleUtils.getBackgroundColor(NodeType.folder, lightTheme);
        final taskColor = TreeStyleUtils.getBackgroundColor(NodeType.task, lightTheme);

        expect(folderColor, taskColor);
      });
    });

    group('getTitleFontSize', () {
      test('should return 18.0 for todoList', () {
        final fontSize = TreeStyleUtils.getTitleFontSize(NodeType.todoList);
        expect(fontSize, 18.0);
      });

      test('should return 16.0 for folder', () {
        final fontSize = TreeStyleUtils.getTitleFontSize(NodeType.folder);
        expect(fontSize, 16.0);
      });

      test('should return 16.0 for task', () {
        final fontSize = TreeStyleUtils.getTitleFontSize(NodeType.task);
        expect(fontSize, 16.0);
      });

      test('todoList should have larger font size than folder', () {
        final todoListSize = TreeStyleUtils.getTitleFontSize(NodeType.todoList);
        final folderSize = TreeStyleUtils.getTitleFontSize(NodeType.folder);

        expect(todoListSize, greaterThan(folderSize));
      });

      test('todoList should have larger font size than task', () {
        final todoListSize = TreeStyleUtils.getTitleFontSize(NodeType.todoList);
        final taskSize = TreeStyleUtils.getTitleFontSize(NodeType.task);

        expect(todoListSize, greaterThan(taskSize));
      });
    });

    group('getTitleFontWeight', () {
      test('should return bold for todoList', () {
        final weight = TreeStyleUtils.getTitleFontWeight(NodeType.todoList);
        expect(weight, FontWeight.bold);
      });

      test('should return w500 for folder', () {
        final weight = TreeStyleUtils.getTitleFontWeight(NodeType.folder);
        expect(weight, FontWeight.w500);
      });

      test('should return w500 for task', () {
        final weight = TreeStyleUtils.getTitleFontWeight(NodeType.task);
        expect(weight, FontWeight.w500);
      });

      test('todoList should have heavier weight than folder', () {
        final todoListWeight = TreeStyleUtils.getTitleFontWeight(NodeType.todoList);
        final folderWeight = TreeStyleUtils.getTitleFontWeight(NodeType.folder);

        expect(todoListWeight.index, greaterThan(folderWeight.index));
      });

      test('folder and task should have same weight', () {
        final folderWeight = TreeStyleUtils.getTitleFontWeight(NodeType.folder);
        final taskWeight = TreeStyleUtils.getTitleFontWeight(NodeType.task);

        expect(folderWeight, taskWeight);
      });
    });

    group('getCardElevation', () {
      test('should return 2.0 for todoList', () {
        final elevation = TreeStyleUtils.getCardElevation(NodeType.todoList);
        expect(elevation, 2.0);
      });

      test('should return 1.0 for folder', () {
        final elevation = TreeStyleUtils.getCardElevation(NodeType.folder);
        expect(elevation, 1.0);
      });

      test('should return 1.0 for task', () {
        final elevation = TreeStyleUtils.getCardElevation(NodeType.task);
        expect(elevation, 1.0);
      });

      test('todoList should have higher elevation than folder', () {
        final todoListElevation = TreeStyleUtils.getCardElevation(NodeType.todoList);
        final folderElevation = TreeStyleUtils.getCardElevation(NodeType.folder);

        expect(todoListElevation, greaterThan(folderElevation));
      });

      test('folder and task should have same elevation', () {
        final folderElevation = TreeStyleUtils.getCardElevation(NodeType.folder);
        final taskElevation = TreeStyleUtils.getCardElevation(NodeType.task);

        expect(folderElevation, taskElevation);
      });
    });

    group('Consistency', () {
      test('todoList should have distinctive styling compared to others', () {
        // TodoList should have larger font, heavier weight, higher elevation
        expect(
          TreeStyleUtils.getTitleFontSize(NodeType.todoList),
          greaterThan(TreeStyleUtils.getTitleFontSize(NodeType.folder)),
        );
        expect(
          TreeStyleUtils.getTitleFontWeight(NodeType.todoList).index,
          greaterThan(TreeStyleUtils.getTitleFontWeight(NodeType.folder).index),
        );
        expect(
          TreeStyleUtils.getCardElevation(NodeType.todoList),
          greaterThan(TreeStyleUtils.getCardElevation(NodeType.folder)),
        );
      });

      test('folder and task should have similar styling', () {
        expect(
          TreeStyleUtils.getTitleFontSize(NodeType.folder),
          TreeStyleUtils.getTitleFontSize(NodeType.task),
        );
        expect(
          TreeStyleUtils.getTitleFontWeight(NodeType.folder),
          TreeStyleUtils.getTitleFontWeight(NodeType.task),
        );
        expect(
          TreeStyleUtils.getCardElevation(NodeType.folder),
          TreeStyleUtils.getCardElevation(NodeType.task),
        );
      });

      test('all methods should handle all NodeType values', () {
        for (final type in NodeType.values) {
          expect(() => TreeStyleUtils.getIconForType(type), returnsNormally);
          expect(() => TreeStyleUtils.getIconColor(type, lightTheme), returnsNormally);
          expect(() => TreeStyleUtils.getBackgroundColor(type, lightTheme), returnsNormally);
          expect(() => TreeStyleUtils.getTitleFontSize(type), returnsNormally);
          expect(() => TreeStyleUtils.getTitleFontWeight(type), returnsNormally);
          expect(() => TreeStyleUtils.getCardElevation(type), returnsNormally);
        }
      });
    });
  });
}
