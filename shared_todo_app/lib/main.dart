import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/todo_lists/presentation/screens/todo_lists_screen.dart';

Future<void> main() async {
  // 1. Assicurati che Flutter sia inizializzato
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inizializza Supabase
  await Supabase.initialize(
    url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
  );
  
  runApp(const MyApp());
}

// Helper per accedere rapidamente al client Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared To-Do',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        // ... altri stili
      ),
      // 3. Usa uno StreamBuilder per reindirizzare l'utente
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Se sta ancora caricando la sessione
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          
          // Se l'utente è loggato (ha una sessione)
          if (session != null) {
            return const TodoListsScreen(); // Vai alla home (che creeremo)
          }

          // Se l'utente non è loggato
          return const LoginScreen(); // Vai alla pagina di login
        },
      ),
    );
  }
}