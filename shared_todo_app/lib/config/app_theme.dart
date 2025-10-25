import 'package:flutter/material.dart';

/// Definisce il tema visivo dell'applicazione.
class AppTheme {
  /// Restituisce il tema scuro per l'app.
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.blue, // Colore primario
      scaffoldBackgroundColor: const Color(0xFF121212), // Sfondo leggermente più scuro
      appBarTheme: const AppBarTheme(
        elevation: 0, // Nessuna ombra sotto l'AppBar
        backgroundColor: Color(0xFF1F1F1F), // Colore AppBar
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
       // Aggiungi qui altre personalizzazioni (colori, font, ecc.)
    );
  }

  // Potresti aggiungere anche un lightTheme se necessario
  // static ThemeData get lightTheme { ... }
}
