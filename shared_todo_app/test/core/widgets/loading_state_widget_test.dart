import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/widgets/loading_state_widget.dart';

void main() {
  group('LoadingStateWidget Tests', () {
    testWidgets('should display CircularProgressIndicator', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display message when provided', (tester) async {
      // Arrange
      const testMessage = 'Loading data...';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('should not display message when not provided', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('should use custom color when provided', (tester) async {
      // Arrange
      const customColor = Colors.red;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(color: customColor),
          ),
        ),
      );

      // Assert
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, customColor);
    });

    testWidgets('should use theme primary color when color not provided', (tester) async {
      // Arrange
      const primaryColor = Colors.blue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          home: const Scaffold(
            body: LoadingStateWidget(),
          ),
        ),
      );

      // Assert
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, primaryColor);
    });

    testWidgets('should center content', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('should display message below indicator', (tester) async {
      // Arrange
      const testMessage = 'Please wait...';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, greaterThanOrEqualTo(2));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('should have proper spacing between indicator and message', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: 'Loading'),
          ),
        ),
      );

      // Assert
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should handle null message', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: null),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('should handle empty message', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: ''),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Empty text still renders
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('should work in different screen sizes', (tester) async {
      // Small screen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: 'Loading'),
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(300, 500));
      await tester.pump();

      expect(find.byType(LoadingStateWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Large screen
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pump();

      expect(find.byType(LoadingStateWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be accessible', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateWidget(message: 'Loading content'),
          ),
        ),
      );

      // Assert - Widget should be findable and have text
      expect(find.byType(LoadingStateWidget), findsOneWidget);
      expect(find.text('Loading content'), findsOneWidget);
    });
  });
}
