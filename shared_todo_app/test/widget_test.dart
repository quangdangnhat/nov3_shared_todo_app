import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_todo_app/app/my_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Ensure Flutter test bindings are initialized for mocking platform channels.
  TestWidgetsFlutterBinding.ensureInitialized();

  // 'setUpAll' runs once before all tests in this file.
  // Used here to initialize Supabase.
  setUpAll(() async {
    // Mock the SharedPreferences implementation.
    // This is required because Supabase (via supabase_flutter) tries to
    // access native SharedPreferences to load a saved session.
    // 'MissingPluginException' occurs in a pure Dart test environment otherwise.
    //
    // An empty map simulates no saved user session (logged out state).
    SharedPreferences.setMockInitialValues({});

    // Initialize the Supabase client.
    // This will now use the mocked SharedPreferences.
    await Supabase.initialize(
      url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
    );
  });

  // Test case: Verify the app shows the Login screen on initial startup.
  // The test name is still in Italian.
  testWidgets('L\'app mostra la schermata di Login all\'avvio', (
    WidgetTester tester,
  ) async {
    // Build the root widget 'MyApp'.
    await tester.pumpWidget(const MyApp());

    // 'pumpAndSettle' waits for all animations and async operations (like
    // GoRouter's initial navigation and auth redirects) to complete.
    await tester.pumpAndSettle();

    // Expectation: The app should have redirected to the Login screen.

    // Find a specific widget (ElevatedButton) that contains the text 'Login'.
    // This is more specific than find.text('Login') to avoid ambiguity.
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    // Negative Expectation: Text from the authenticated home screen
    // should not be present.
    expect(find.text('Le tue To-Do'), findsNothing);
  });
}
