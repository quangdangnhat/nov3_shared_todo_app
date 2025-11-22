// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // Assicurati di avere questo pacchetto

import 'app/my_app.dart'; // Assicurati che il percorso sia corretto
import 'theme_provider.dart'; // Il file che abbiamo appena creato/modificato

Future<void> main() async {
  // 1. Necessario per i plugin (Supabase, SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inizializza Supabase
  await Supabase.initialize(
    url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
  );

  // 3. Avvia l'app avvolta nel Provider
  runApp(
    ChangeNotifierProvider(
      // Quando viene creato qui, il costruttore di ThemeProvider()
      // parte subito a leggere la memoria del telefono.
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// Helper globale per accedere al client Supabase
final supabase = Supabase.instance.client;
