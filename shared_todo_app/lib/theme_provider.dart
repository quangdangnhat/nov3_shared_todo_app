// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Chiave univoca per salvare il dato nella memoria del telefono
  static const String _themeKey = 'theme_preference';

  // Iniziamo con un valore di default (Sistema o Light) finché non carichiamo le preferenze
  ThemeMode _themeMode = ThemeMode.system;

  // Getter pubblico per leggere lo stato
  ThemeMode get currentThemeMode => _themeMode;

  // Helper per lo switch (true se dark, false se light o system)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Se è impostato su "Sistema", non possiamo sapere qui se è dark o light
      // senza il context, ma per lo switch di solito si assume false.
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Costruttore: Appena il Provider viene creato, proviamo a caricare la preferenza salvata
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Carica il tema salvato nelle SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeKey);

    // Se non c'è nulla salvato (prima volta che apre l'app), usiamo System
    if (savedTheme == null) {
      _themeMode = ThemeMode.system;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Aggiorniamo la UI con il tema caricato
    notifyListeners();
  }

  /// Cambia il tema e salva la preferenza
  Future<void> toggleTheme(bool isDark) async {
    // 1. Aggiorniamo subito la variabile locale per dare feedback immediato all'utente
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // 2. Notifichiamo i widget (la UI cambia colore istantaneamente)
    notifyListeners();

    // 3. Salviamo la scelta in memoria in background
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }
}
