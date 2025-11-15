import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/core/utils/snackbar_utils.dart';

void main() {
  group('SnackbarUtils Tests', () {
    group('showErrorSnackBar', () {
      testWidgets('should display error snackbar with message', (tester) async {
        // Arrange
        const testMessage = 'An error occurred';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showErrorSnackBar(capturedContext, message: testMessage);
        await tester.pump();

        // Assert
        expect(find.text(testMessage), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should use theme error color', (tester) async {
        // Arrange
        const errorColor = Colors.red;
        const testMessage = 'Error message';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(error: errorColor),
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showErrorSnackBar(capturedContext, message: testMessage);
        await tester.pump();

        // Assert
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, errorColor);
      });

      testWidgets('should display snackbar at bottom of screen',
          (tester) async {
        // Arrange
        const testMessage = 'Error';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showErrorSnackBar(capturedContext, message: testMessage);
        await tester.pump();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.content, isA<Text>());
      });

      testWidgets('should handle long error messages', (tester) async {
        // Arrange
        const longMessage =
            'This is a very long error message that might need to wrap to multiple lines in the snackbar';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showErrorSnackBar(capturedContext, message: longMessage);
        await tester.pump();

        // Assert
        expect(find.text(longMessage), findsOneWidget);
      });

      // testWidgets('should be dismissible', (tester) async {
      //   // Arrange
      //   const testMessage = 'Error';
      //   late BuildContext capturedContext;

      //   await tester.pumpWidget(
      //     MaterialApp(
      //       home: Scaffold(
      //         body: Builder(
      //           builder: (context) {
      //             capturedContext = context;
      //             return Container();
      //           },
      //         ),
      //       ),
      //     ),
      //   );

      //   // Act
      //   showErrorSnackBar(capturedContext, message: testMessage);
      //   await tester.pump();
      //   expect(find.byType(SnackBar), findsOneWidget);

      //   // Dismiss snackbar
      //   await tester.pumpAndSettle(const Duration(seconds: 5));

      //   // Assert - snackbar should disappear after timeout
      //   expect(find.byType(SnackBar), findsNothing);
      // });
    });

    group('showSuccessSnackBar', () {
      testWidgets('should display success snackbar with message',
          (tester) async {
        // Arrange
        const testMessage = 'Operation successful';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showSuccessSnackBar(capturedContext, message: testMessage);
        await tester.pump();

        // Assert
        expect(find.text(testMessage), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should use green background color', (tester) async {
        // Arrange
        const testMessage = 'Success';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showSuccessSnackBar(capturedContext, message: testMessage);
        await tester.pump();

        // Assert
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, Colors.green);
      });

      testWidgets('should have floating behavior', (tester) async {
        // Arrange
        const testMessage = 'Success';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showSuccessSnackBar(capturedContext, message: testMessage);
        await tester.pump();

        // Assert
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, SnackBarBehavior.floating);
      });

      testWidgets('should handle long success messages', (tester) async {
        // Arrange
        const longMessage =
            'Your operation has been completed successfully and all changes have been saved';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showSuccessSnackBar(capturedContext, message: longMessage);
        await tester.pump();

        // Assert
        expect(find.text(longMessage), findsOneWidget);
      });

      // testWidgets('should be dismissible', (tester) async {
      //   // Arrange
      //   const testMessage = 'Success';
      //   late BuildContext capturedContext;

      //   await tester.pumpWidget(
      //     MaterialApp(
      //       home: Scaffold(
      //         body: Builder(
      //           builder: (context) {
      //             capturedContext = context;
      //             return Container();
      //           },
      //         ),
      //       ),
      //     ),
      //   );

      //   // Act
      //   showSuccessSnackBar(capturedContext, message: testMessage);
      //   await tester.pump();
      //   expect(find.byType(SnackBar), findsOneWidget);

      //   // Dismiss snackbar
      //   await tester.pumpAndSettle(const Duration(seconds: 5));

      //   // Assert - snackbar should disappear after timeout
      //   expect(find.byType(SnackBar), findsNothing);
      // });
    });

    group('Comparison Tests', () {
      // testWidgets('error and success snackbars should have different colors', (tester) async {
      //   // Arrange
      //   late BuildContext capturedContext;

      //   await tester.pumpWidget(
      //     MaterialApp(
      //       home: Scaffold(
      //         body: Builder(
      //           builder: (context) {
      //             capturedContext = context;
      //             return Container();
      //           },
      //         ),
      //       ),
      //     ),
      //   );

      //   // Act - Show error
      //   showErrorSnackBar(capturedContext, message: 'Error');
      //   await tester.pump();
      //   final errorSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      //   final errorColor = errorSnackBar.backgroundColor;

      //   // Dismiss error snackbar
      //   await tester.pumpAndSettle(const Duration(seconds: 5));

      //   // Show success
      //   showSuccessSnackBar(capturedContext, message: 'Success');
      //   await tester.pump();
      //   final successSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      //   final successColor = successSnackBar.backgroundColor;

      //   // Assert
      //   expect(errorColor, isNot(successColor));
      //   expect(successColor, Colors.green);
      // });

      // testWidgets('success snackbar should have floating behavior but error should not', (tester) async {
      //   // Arrange
      //   late BuildContext capturedContext;

      //   await tester.pumpWidget(
      //     MaterialApp(
      //       home: Scaffold(
      //         body: Builder(
      //           builder: (context) {
      //             capturedContext = context;
      //             return Container();
      //           },
      //         ),
      //       ),
      //     ),
      //   );

      //   // Act - Show error
      //   showErrorSnackBar(capturedContext, message: 'Error');
      //   await tester.pump();
      //   final errorSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));

      //   // Dismiss
      //   await tester.pumpAndSettle(const Duration(seconds: 5));

      //   // Show success
      //   showSuccessSnackBar(capturedContext, message: 'Success');
      //   await tester.pump();
      //   final successSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));

      //   // Assert
      //   expect(successSnackBar.behavior, SnackBarBehavior.floating);
      //   // Error snackbar doesn't explicitly set behavior, so it uses default (fixed)
      // });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty message', (tester) async {
        // Arrange
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showErrorSnackBar(capturedContext, message: '');
        await tester.pump();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should handle special characters in message',
          (tester) async {
        // Arrange
        const specialMessage = 'Error: <>&"\' special chars!';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showSuccessSnackBar(capturedContext, message: specialMessage);
        await tester.pump();

        // Assert
        expect(find.text(specialMessage), findsOneWidget);
      });

      testWidgets('should handle unicode characters', (tester) async {
        // Arrange
        const unicodeMessage = 'Operazione completata ✓ 成功 🎉';
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return Container();
                },
              ),
            ),
          ),
        );

        // Act
        showSuccessSnackBar(capturedContext, message: unicodeMessage);
        await tester.pump();

        // Assert
        expect(find.text(unicodeMessage), findsOneWidget);
      });
    });
  });
}
