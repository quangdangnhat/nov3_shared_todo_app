// Purpose: Utility functions and extensions to simplify widget testing (pumpApp, tapAndSettle, etc.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extension on WidgetTester for common operations
extension WidgetTesterX on WidgetTester {
  /// Pumps a widget wrapped in MaterialApp
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    Locale? locale,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        home: widget,
      ),
    );
  }

  /// Pumps a widget and waits for animations
  Future<void> pumpAppAndSettle(
    Widget widget, {
    ThemeData? theme,
    Duration? duration,
  }) async {
    await pumpApp(widget, theme: theme);
    if (duration != null) {
      await pumpAndSettle(duration);
    } else {
      await pumpAndSettle();
    }
  }

  /// Finds a widget by key
  Finder findByKey(String key) => find.byKey(Key(key));

  /// Taps a widget and waits for animations
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Enters text and waits for animations
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Scrolls until a widget is visible
  Future<void> scrollUntilVisibleWidget(
    Finder finder,
    double delta, {
    Finder? scrollable,
  }) async {
    await scrollUntilVisible(
      finder,
      delta,
      scrollable: scrollable ?? find.byType(Scrollable),
    );
  }
}

/// Test widget wrapper with common providers
class TestWrapper extends StatelessWidget {
  final Widget child;
  final ThemeData? theme;

  const TestWrapper({
    Key? key,
    required this.child,
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: child,
      ),
    );
  }
}

/// Common test data and utilities
class WidgetTestHelpers {
  /// Standard test theme
  static ThemeData get testTheme => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      );

  /// Find text containing substring
  static Finder findTextContaining(String text) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && widget.data?.contains(text) == true,
    );
  }

  /// Find icon by icon data
  static Finder findIcon(IconData icon) {
    return find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == icon,
    );
  }

  /// Verify widget is visible
  static void expectVisible(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify widget is not visible
  static void expectNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify multiple widgets visible
  static void expectMultiple(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }
}

/// Mock navigation observer for testing navigation
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> routes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routes.remove(route);
    super.didPop(route, previousRoute);
  }
}

/// Delays for animations in tests
class TestDelays {
  static const Duration short = Duration(milliseconds: 100);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}
