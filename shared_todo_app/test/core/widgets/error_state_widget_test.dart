import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/widgets/error_state_widget.dart';

void main() {
  group('ErrorStateWidget Tests', () {
    testWidgets('should display error icon', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display default title when not provided',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(),
          ),
        ),
      );

      // Assert
      expect(find.text('Errore'), findsOneWidget);
    });

    testWidgets('should display custom title when provided', (tester) async {
      // Arrange
      const customTitle = 'Custom Error Title';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(title: customTitle),
          ),
        ),
      );

      // Assert
      expect(find.text(customTitle), findsOneWidget);
    });

    testWidgets('should display message when provided', (tester) async {
      // Arrange
      const testMessage = 'Something went wrong';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(message: testMessage),
          ),
        ),
      );

      // Assert
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('should display error object when provided', (tester) async {
      // Arrange
      final testError = Exception('Test exception');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(error: testError),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Exception: Test exception'), findsOneWidget);
    });

    testWidgets('should prioritize message over error when both provided',
        (tester) async {
      // Arrange
      const testMessage = 'Custom message';
      final testError = Exception('Test exception');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: testMessage,
              error: testError,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testMessage), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    // testWidgets('should display retry button when onRetry provided',
    //     (tester) async {
    //   // Arrange
    //   bool retryPressed = false;

    //   // Act
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: Scaffold(
    //         body: ErrorStateWidget(
    //           onRetry: () => retryPressed = true,
    //         ),
    //       ),
    //     ),
    //   );

    //   // Assert
    //   expect(find.byType(ElevatedButton), findsOneWidget);
    //   expect(find.text('Riprova'), findsOneWidget);
    // });

    testWidgets('should not display retry button when onRetry not provided',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNothing);
    });

    // testWidgets('should call onRetry when retry button pressed',
    //     (tester) async {
    //   // Arrange
    //   bool retryPressed = false;

    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: Scaffold(
    //         body: ErrorStateWidget(
    //           onRetry: () => retryPressed = true,
    //         ),
    //       ),
    //     ),
    //   );

    //   // Act
    //   await tester.tap(find.byType(ElevatedButton));
    //   await tester.pump();

    //   // Assert
    //   expect(retryPressed, isTrue);
    // });

    testWidgets('should display custom retry label when provided',
        (tester) async {
      // Arrange
      const customLabel = 'Try Again';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              onRetry: () {},
              retryLabel: customLabel,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(customLabel), findsOneWidget);
      expect(find.text('Riprova'), findsNothing);
    });

    testWidgets('should use theme error color for icon', (tester) async {
      // Arrange
      const errorColor = Colors.red;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(error: errorColor),
          ),
          home: const Scaffold(
            body: ErrorStateWidget(),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, errorColor);
    });

    // testWidgets('should center content', (tester) async {
    //   // Act
    //   await tester.pumpWidget(
    //     const MaterialApp(
    //       home: Scaffold(
    //         body: ErrorStateWidget(),
    //       ),
    //     ),
    //   );

    //   // Assert
    //   expect(find.byType(Center), findsOneWidget);
    // });

    testWidgets('should have proper padding', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(),
          ),
        ),
      );

      // Assert
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(Center),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(24.0));
    });

    // testWidgets('should handle all parameters together', (tester) async {
    //   // Arrange
    //   bool retryPressed = false;

    //   // Act
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: Scaffold(
    //         body: ErrorStateWidget(
    //           title: 'Network Error',
    //           message: 'Failed to connect to server',
    //           onRetry: () => retryPressed = true,
    //           retryLabel: 'Retry Connection',
    //         ),
    //       ),
    //     ),
    //   );

    //   // Assert
    //   expect(find.text('Network Error'), findsOneWidget);
    //   expect(find.text('Failed to connect to server'), findsOneWidget);
    //   expect(find.text('Retry Connection'), findsOneWidget);
    //   expect(find.byIcon(Icons.error_outline), findsOneWidget);

    //   // Test retry
    //   await tester.tap(find.byType(ElevatedButton));
    //   expect(retryPressed, isTrue);
    // });

    testWidgets('should display refresh icon on retry button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should work in different screen sizes', (tester) async {
      // Small screen
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error occurred',
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(300, 500));
      await tester.pump();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('Error occurred'), findsOneWidget);

      // Large screen
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      await tester.pump();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('Error occurred'), findsOneWidget);
    });
  });
}
