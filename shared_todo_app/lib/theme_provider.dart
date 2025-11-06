import 'package:flutter/material.dart';

// 1. Usiamo 'ChangeNotifier' per permettere a questa classe
//    di inviare "notifiche" ai widget quando lo stato cambia.
class ThemeProvider extends ChangeNotifier {

  // 2. Questa è la variabile privata che memorizza lo stato attuale.
  //    Iniziamo con il tema chiaro (light) come default.
  ThemeMode _themeMode = ThemeMode.light;

  // 3. Questo è un "getter" pubblico.
  //    I widget (come MaterialApp) lo useranno per LEGGERE lo stato attuale.
  ThemeMode get currentThemeMode => _themeMode;

  // 4. Questo è un helper comodo per il tuo Switch.
  //    Restituisce 'true' se il tema scuro è attivo.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // 5. Questa è la FUNZIONE che il tuo Switch chiamerà.
  //    Riceve un valore booleano (true = è scuro, false = è chiaro)
  //    e aggiorna lo stato.
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // 6. FONDAMENTALE: Questo comando "notifica" a tutti i widget 
    //    in ascolto (principalmente il tuo MaterialApp in my_app.dart)
    //    che devono ricostruirsi perché lo stato è cambiato.
    notifyListeners();
  }
}