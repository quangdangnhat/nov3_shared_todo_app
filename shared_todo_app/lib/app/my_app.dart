// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. IMPORTA PROVIDER
import '../theme_provider.dart'; // 1. IMPORTA IL TUO THEME PROVIDER
import '../config/app_theme.dart';
import '../config/router/app_router.dart'; // Importa la configurazione del router

/// Il widget radice dell'applicazione.
///
/// Configura MaterialApp per usare GoRouter per la navigazione.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. AVVOLGI IL TUO MATERIALAPP CON UN CONSUMER
    //    Questo "ascolta" il ThemeProvider per i cambiamenti.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Ora restituiamo MaterialApp.router dall'interno del builder
        return MaterialApp.router(
          // Passa la configurazione del router definita in app_router.dart
          routerConfig: AppRouter.router,

          title: 'Shared To-Do',

          // 3. IMPOSTA I TEMI IN MODO DINAMICO
          theme: AppTheme.lightTheme, // Il tuo tema chiaro
          darkTheme: AppTheme.darkTheme, // Il tuo tema scuro
          themeMode:
              themeProvider.currentThemeMode, // Prende lo stato dal provider!

          debugShowCheckedModeBanner: false,

          // IMPORTANTE: NON ci devono essere 'home:' né 'StreamBuilder<AuthState>' qui
        );
      },
    );
  }
}
