import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget Tests', () {
    testWidgets('should display default inbox icon', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: 'No items'),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('should display custom icon when provided', (tester) async {
      // Arrange
      const customIcon = Icons.folder_open;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: customIcon,
              title: 'No folders',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(customIcon), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsNothing);
    });

    testWidgets('should display title', (tester) async {
      // Arrange
      const testTitle = 'No items found';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: testTitle),
          ),
        ),
      );

      // Assert
      expect(find.text(testTitle), findsOneWidget);
    });

    testWidgets('should display subtitle when provided', (tester) async {
      // Arrange
      const testSubtitle = 'Try adding some items';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              subtitle: testSubtitle,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testSubtitle), findsOneWidget);
    });

    testWidgets('should not display subtitle when not provided', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: 'Empty'),
          ),
        ),
      );

      // Assert
      // Should only find title text
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('should display action widget when provided', (tester) async {
      // Arrange
      const actionButton = ElevatedButton(
        onPressed: null,
        child: Text('Add Item'),
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              action: actionButton,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('should not display action when not provided', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: 'Empty'),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should handle action button press', (tester) async {
      // Arrange
      bool actionPressed = false;
      final actionButton = ElevatedButton(
        onPressed: () => actionPressed = true,
        child: const Text('Add'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              action: actionButton,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(actionPressed, isTrue);
    });

    testWidgets('should center content', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: 'Empty'),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should have proper padding', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: 'Empty'),
          ),
        ),
      );

      // Assert
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(Center),
          matching: find.byType(Padding),
        ).first,
      );
      expect(padding.padding, const EdgeInsets.all(24.0));
    });

    testWidgets('should use theme colors with opacity for icon', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(onSurface: Colors.black),
          ),
          home: const Scaffold(
            body: EmptyStateWidget(title: 'Empty'),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox));
      expect(icon.color, isNotNull);
      // Icon should have reduced opacity
      expect(icon.color?.opacity, lessThan(1.0));
    });

    testWidgets('should display all elements together', (tester) async {
      // Arrange
      const actionButton = TextButton(
        onPressed: null,
        child: Text('Create New'),
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.task,
              title: 'No Tasks',
              subtitle: 'Get started by creating your first task',
              action: actionButton,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.task), findsOneWidget);
      expect(find.text('No Tasks'), findsOneWidget);
      expect(find.text('Get started by creating your first task'), findsOneWidget);
      expect(find.text('Create New'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should have proper spacing between elements', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SizedBox), findsNWidgets(2)); // spacing after icon and title
    });

    testWidgets('should handle long title text', (tester) async {
      // Arrange
      const longTitle = 'This is a very long title that might need to wrap to multiple lines';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(title: longTitle),
          ),
        ),
      );

      // Assert
      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('should handle long subtitle text', (tester) async {
      // Arrange
      const longSubtitle = 'This is a very long subtitle with lots of text that explains what the user should do';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              subtitle: longSubtitle,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longSubtitle), findsOneWidget);
    });

    testWidgets('should work in different screen sizes', (tester) async {
      // Small screen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              subtitle: 'No items',
            ),
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(300, 500));
      await tester.pump();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);

      // Large screen
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pump();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('subtitle should have center alignment', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'Empty',
              subtitle: 'Test subtitle',
            ),
          ),
        ),
      );

      // Assert
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final subtitleText = textWidgets.lastWhere(
        (text) => (text.data ?? '') == 'Test subtitle',
      );
      expect(subtitleText.textAlign, TextAlign.center);
    });
  });
}
