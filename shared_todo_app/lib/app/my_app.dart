import 'package:flutter/material.dart';
// Rimuovi import non necessari qui (supabase, schermate, main)
import '../config/app_theme.dart'; 
import '../config/router/app_router.dart'; // Importa la configurazione del router

/// Il widget radice dell'applicazione.
/// 
/// Configura MaterialApp per usare GoRouter per la navigazione.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usa MaterialApp.router per integrare GoRouter
    return MaterialApp.router(
      // Passa la configurazione del router definita in app_router.dart
      routerConfig: AppRouter.router, 
      
      title: 'Shared To-Do',
      theme: AppTheme.darkTheme, 
      debugShowCheckedModeBanner: false,

      // IMPORTANTE: NON ci devono essere 'home:' né 'StreamBuilder<AuthState>' qui
    );
  }
}

