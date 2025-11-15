import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/theme_provider.dart';

void main() {
  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    group('Initial State', () {
      test('should start with light theme mode', () {
        expect(themeProvider.currentThemeMode, ThemeMode.light);
      });

      test('should have isDarkMode as false initially', () {
        expect(themeProvider.isDarkMode, isFalse);
      });
    });

    group('toggleTheme', () {
      test('should switch to dark mode when toggled with true', () {
        // Act
        themeProvider.toggleTheme(true);

        // Assert
        expect(themeProvider.currentThemeMode, ThemeMode.dark);
        expect(themeProvider.isDarkMode, isTrue);
      });

      test('should switch to light mode when toggled with false', () {
        // Arrange
        themeProvider.toggleTheme(true); // First set to dark

        // Act
        themeProvider.toggleTheme(false);

        // Assert
        expect(themeProvider.currentThemeMode, ThemeMode.light);
        expect(themeProvider.isDarkMode, isFalse);
      });

      test('should stay in light mode when toggled with false multiple times',
          () {
        // Act
        themeProvider.toggleTheme(false);
        themeProvider.toggleTheme(false);
        themeProvider.toggleTheme(false);

        // Assert
        expect(themeProvider.currentThemeMode, ThemeMode.light);
        expect(themeProvider.isDarkMode, isFalse);
      });

      test('should stay in dark mode when toggled with true multiple times',
          () {
        // Act
        themeProvider.toggleTheme(true);
        themeProvider.toggleTheme(true);
        themeProvider.toggleTheme(true);

        // Assert
        expect(themeProvider.currentThemeMode, ThemeMode.dark);
        expect(themeProvider.isDarkMode, isTrue);
      });

      test('should toggle between dark and light modes', () {
        // Initial state
        expect(themeProvider.isDarkMode, isFalse);

        // Toggle to dark
        themeProvider.toggleTheme(true);
        expect(themeProvider.isDarkMode, isTrue);

        // Toggle to light
        themeProvider.toggleTheme(false);
        expect(themeProvider.isDarkMode, isFalse);

        // Toggle to dark again
        themeProvider.toggleTheme(true);
        expect(themeProvider.isDarkMode, isTrue);
      });
    });

    group('notifyListeners', () {
      test('should notify listeners when theme is toggled', () {
        // Arrange
        int listenerCallCount = 0;
        themeProvider.addListener(() {
          listenerCallCount++;
        });

        // Act
        themeProvider.toggleTheme(true);

        // Assert
        expect(listenerCallCount, 1);
      });

      test('should notify listeners multiple times for multiple toggles', () {
        // Arrange
        int listenerCallCount = 0;
        themeProvider.addListener(() {
          listenerCallCount++;
        });

        // Act
        themeProvider.toggleTheme(true);
        themeProvider.toggleTheme(false);
        themeProvider.toggleTheme(true);

        // Assert
        expect(listenerCallCount, 3);
      });

      test('should notify all registered listeners', () {
        // Arrange
        int listener1CallCount = 0;
        int listener2CallCount = 0;

        themeProvider.addListener(() {
          listener1CallCount++;
        });
        themeProvider.addListener(() {
          listener2CallCount++;
        });

        // Act
        themeProvider.toggleTheme(true);

        // Assert
        expect(listener1CallCount, 1);
        expect(listener2CallCount, 1);
      });

      test('should not notify removed listeners', () {
        // Arrange
        int listenerCallCount = 0;
        void listener() {
          listenerCallCount++;
        }

        themeProvider.addListener(listener);
        themeProvider.toggleTheme(true);
        expect(listenerCallCount, 1);

        // Remove listener
        themeProvider.removeListener(listener);

        // Act
        themeProvider.toggleTheme(false);

        // Assert - Count should still be 1
        expect(listenerCallCount, 1);
      });
    });

    group('Getters', () {
      test('currentThemeMode should return correct value', () {
        expect(themeProvider.currentThemeMode, ThemeMode.light);

        themeProvider.toggleTheme(true);
        expect(themeProvider.currentThemeMode, ThemeMode.dark);
      });

      test('isDarkMode should be consistent with currentThemeMode', () {
        // Light mode
        themeProvider.toggleTheme(false);
        expect(themeProvider.isDarkMode,
            themeProvider.currentThemeMode == ThemeMode.dark);

        // Dark mode
        themeProvider.toggleTheme(true);
        expect(themeProvider.isDarkMode,
            themeProvider.currentThemeMode == ThemeMode.dark);
      });
    });

    // group('Edge Cases', () {
    //   test('should handle rapid theme toggles', () {
    //     for (int i = 0; i < 100; i++) {
    //       themeProvider.toggleTheme(i % 2 == 0);
    //     }

    //     // Should end up in light mode (100 is even)
    //     expect(themeProvider.isDarkMode, isFalse);
    //   });

    //   test('should work correctly after dispose', () {
    //     themeProvider.dispose();

    //     // After dispose, toggling shouldn't throw errors
    //     expect(() => themeProvider.toggleTheme(true), returnsNormally);
    //   });
    // });
  });
}
