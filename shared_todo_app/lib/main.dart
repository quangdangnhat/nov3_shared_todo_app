// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/my_app.dart'; // Importa il widget MyApp
import 'theme_provider.dart'; // 2. IMPORTA IL NOSTRO NUOVO PROVIDER
import 'package:provider/provider.dart';

// Punto di ingresso principale dell'applicazione Flutter.
Future<void> main() async {
  // Necessario per assicurarsi che i binding di Flutter siano pronti
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il client Supabase (invariato)
  await Supabase.initialize(
    url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
  );

  // 3. AVVIA L'APP AVVOLTA NEL PROVIDER
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(), // Il tuo widget MyApp originale
    ),
  );
}

// Helper globale per accedere facilmente al client Supabase (invariato)
final supabase = Supabase.instance.client;
