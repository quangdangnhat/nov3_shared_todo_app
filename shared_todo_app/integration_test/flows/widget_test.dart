import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart'; // Import corretto
import 'package:shared_todo_app/app/my_app.dart';
import 'package:shared_todo_app/theme_provider.dart'; // Import corretto
import 'package:shared_todo_app/core/widgets/app_drawer.dart';
import 'package:shared_todo_app/core/widgets/confirmation_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
    );
  });

  // ============================================================
  // GROUP 1: MyApp Tests (Original)
  // ============================================================

  group('MyApp - Launch App (Unauthenticated User)', () {
    setUp(() async {
      await Supabase.instance.client.auth.signOut();
    });

    testWidgets('The app shows the login screen on startup', (
      WidgetTester tester,
    ) async {
      // 1. Run: Launch the app WITH THE PROVIDER
      // --- HERE'S THE MISSING FIX ---
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const MyApp(),
        ),
      );

      // 2. Wait: Wait for the redirection
      await tester.pumpAndSettle();

      // 3. Verifica:
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.text('My To-Do Lists'), findsNothing);
    });
  });

  // ============================================================
  // GROUP 2: AppDrawer Tests
  // ============================================================

/*
  group('Avvio App (Utente Autenticato)', () {
    setUpAll(() async {
      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: 'test@example.com',
          password: 'test-password-123',
        );
        if (response.user == null) {
          throw Exception('Login fallito: utente nullo o credenziali errate');
        }
      } catch (e) {
        print('--- ERRORE SETUP TEST (GRUPPO 2) ---');
        print(
            'Impossibile loggare l\'utente di test (test@example.com / test-password-123).');
        print('Assicurati che questo utente esista nel tuo Supabase Auth.');
        print('Errore originale: $e');
        print('-------------------------------------');
        rethrow;
      }
    });

    tearDownAll(() async {
      await Supabase.instance.client.auth.signOut();
    });

    testWidgets('L\'app mostra la schermata Home se l\'utente è loggato', (
      WidgetTester tester,
    ) async {
      // 1. Esegui: Avvia l'app CON IL PROVIDER (questo era già corretto)
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const MyApp(),
        ),
      );

      // 2. Attendi:
      await tester.pumpAndSettle();

      // 3. Verifica:
      expect(find.text('My To-Do Lists'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsNothing);
    });
  });*/
}
