import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/my_app.dart'; // Importa il widget MyApp

// Punto di ingresso principale dell'applicazione Flutter.
Future<void> main() async {
  // Necessario per assicurarsi che i binding di Flutter siano pronti prima di chiamare metodi nativi o plugin come Supabase.
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il client Supabase con le credenziali del tuo progetto.
  await Supabase.initialize(
    url: 'https://xpcqhvgkzajaoegtxiih.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwY3FodmdremFqYW9lZ3R4aWloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5ODIwMDksImV4cCI6MjA3NjU1ODAwOX0.6Laq17RKctTPjhal-t9D1LIJBtHbK-riu2k93I6oL8s',
  );

  // Avvia l'applicazione Flutter usando il widget MyApp come radice.
  runApp(const MyApp());
}

// Helper globale per accedere facilmente al client Supabase ovunque nell'app.
// Usalo con cautela, potrebbe essere preferibile usare dependency injection in progetti più grandi.
final supabase = Supabase.instance.client;
