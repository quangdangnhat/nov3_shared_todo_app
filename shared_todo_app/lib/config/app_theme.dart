import 'package:flutter/material.dart';

/// Definisce i temi visivi dell'applicazione.
class AppTheme {
  // --- TEMA CHIARO ---
  /// Restituisce il tema chiaro per l'app.
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      primaryColor: Colors.blue, // Colore primario
      scaffoldBackgroundColor:
          Colors.grey[100], // Sfondo per il tema chiaro (quasi bianco)
      appBarTheme: const AppBarTheme(
        elevation: 2, // Una leggera ombra per il tema chiaro
        backgroundColor: Colors.blue, // Colore AppBar (primario)
        foregroundColor: Colors.white, // Colore del testo e icone sull'AppBar
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Colore bottoni
          foregroundColor: Colors.white, // Colore testo bottoni
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      // Aggiungi qui altre personalizzazioni
    );
  }

  // --- TEMA SCURO ---
  /// Restituisce il tema scuro per l'app.
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.blue, // Colore primario
      scaffoldBackgroundColor: const Color(
        0xFF121212,
      ), // Sfondo leggermente più scuro
      appBarTheme: const AppBarTheme(
        elevation: 0, // Nessuna ombra sotto l'AppBar
        backgroundColor: Color(0xFF1F1F1F), // Colore AppBar
        foregroundColor: Colors.white, // Colore del testo e icone sull'AppBar
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Colore bottoni
          foregroundColor: Colors.white, // Colore testo bottoni
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[800],
      ),
      // Aggiungi qui altre personalizzazioni
    );
  }
}
