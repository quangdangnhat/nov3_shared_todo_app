import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './config/app_theme.dart'; // Importa il tema
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/todo_lists/presentation/screens/todo_lists_screen.dart';
import '../main.dart'; // Importa l'helper 'supabase'

/// Il widget radice dell'applicazione.
/// 
/// Contiene MaterialApp e la logica per mostrare la schermata 
/// di login o la home in base allo stato di autenticazione.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared To-Do',
      theme: AppTheme.darkTheme, // Usa il tema definito esternamente
      debugShowCheckedModeBanner: false,
      
      // Usa uno StreamBuilder per reindirizzare l'utente
      // in base allo stato di autenticazione di Supabase.
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // Mostra un caricamento mentre si verifica lo stato della sessione.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          
          // Se c'è una sessione attiva, l'utente è loggato.
          if (session != null) {
            return const TodoListsScreen(); // Mostra la schermata principale delle liste.
          }

          // Altrimenti, l'utente non è loggato.
          return const LoginScreen(); // Mostra la schermata di login.
        },
      ),
    );
  }
}
