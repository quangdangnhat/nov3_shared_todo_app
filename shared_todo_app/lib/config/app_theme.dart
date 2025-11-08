import 'package:flutter/material.dart';

/// Definisce i temi visivi dell'applicazione con colori bilanciati e contrasti ottimali.
class AppTheme {
  // --- TEMA CHIARO (Light) ---
  /// Restituisce il tema chiaro con bianco dominante e celeste per contenitori complessi.
  static ThemeData get lightTheme {
    // Palette colori: bianco dominante, celeste per contenitori con molti elementi, grigio chiaro per contrasto delicato
    const Color primaryBlue = Color(0xFF0288D1); // Celeste principale
    const Color containerBlue = Color(
        0xFFE1F5FE); // Celeste molto chiaro per contenitori complessi (liste, gruppi)
    const Color white =
        Color(0xFFFFFFFF); // Bianco dominante per sfondo e card singole
    const Color lightGrey =
        Color(0xFFF5F5F5); // Grigio chiarissimo per separazione delicata
    const Color accentOrange =
        Color(0xFFFF6F00); // Arancione intenso per contrasto
    const Color textDark = Color(0xFF212121); // Grigio scurissimo per testo
    const Color textSecondary =
        Color(0xFF616161); // Grigio medio per testi secondari

    return ThemeData.light().copyWith(
      // Colori principali
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: white, // Sfondo bianco

      // Tema AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: white, // AppBar bianca e pulita
        foregroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: primaryBlue),
        titleTextStyle: const TextStyle(
          color: primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Tema Bottoni
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange, // Bottoni arancioni per contrasto
          foregroundColor: white,
          elevation: 2,
          shadowColor: accentOrange.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
        ),
      ),

      // Tema Bottoni di testo
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentOrange,
        ),
      ),

      // Tema Campi di Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white, // Input bianchi
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: accentOrange, width: 2.5),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
      ),

      // ColorScheme
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentOrange,
        background: white,
        surface: white, // Superficie bianca come default
        onPrimary: white,
        onBackground: textDark,
        onSurface: textDark,
        error: const Color(0xFFD32F2F),
        surfaceVariant:
            containerBlue, // Celeste chiaro per contenitori complessi
      ),

      // Tema per le Card
      cardTheme: CardThemeData(
        elevation: 1,
        color: white, // Card bianche di default (per elementi singoli)
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: lightGrey, width: 1), // Bordo grigio delicato
        ),
      ),

      // Tema per il testo
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textDark, fontSize: 16),
        bodyMedium: TextStyle(color: textDark, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        titleLarge: TextStyle(
            color: textDark, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: textDark, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      // Tema FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentOrange,
        foregroundColor: white,
        elevation: 4,
      ),

      // Tema Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: white, // Dialog bianchi
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // Tema BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: white, // BottomSheet bianchi
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
      ),

      // Tema ListTile (per contenitori con molti elementi)
      listTileTheme: ListTileThemeData(
        tileColor: containerBlue, // Celeste chiaro per liste
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // Tema Divider
      dividerTheme: DividerThemeData(
        color: lightGrey,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // --- TEMA SCURO (Dark) ---
  /// Restituisce il tema scuro con nero dominante negli elementi grandi e testo bianco.
  static ThemeData get darkTheme {
    // Palette colori scura: nero/grigio per aree grandi, bianco per testo, turchese accento
    const Color background =
        Color(0xFF121212); // Nero molto scuro per sfondo (area grande)
    const Color surface =
        Color(0xFF1E1E1E); // Superficie grigio scurissimo (aree grandi)
    const Color cardColor =
        Color(0xFF252525); // Card grigio scuro (aree grandi)
    const Color accentCyan =
        Color(0xFF00E5FF); // Turchese brillante per contrasto
    const Color primaryCyan = Color(0xFF00BCD4); // Turchese principale
    const Color white = Color(0xFFFFFFFF); // Bianco per tutto il testo
    const Color textSecondary =
        Color(0xFFE0E0E0); // Bianco leggermente più soft

    return ThemeData.dark().copyWith(
      primaryColor: primaryCyan,
      scaffoldBackgroundColor: background, // Sfondo nero (area grande)

      // Tema AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surface, // AppBar grigio scuro (area grande)
        foregroundColor: white, // Testo bianco
        iconTheme: const IconThemeData(color: white),
        titleTextStyle: const TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Tema Bottoni
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan, // Bottoni turchesi per contrasto
          foregroundColor: background, // Testo nero scuro su turchese
          elevation: 2,
          shadowColor: accentCyan.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
        ),
      ),

      // Tema Bottoni di testo
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentCyan, // Testo turchese
        ),
      ),

      // Tema Campi di Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor, // Input grigio scuro
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: accentCyan, width: 2.5),
        ),
        labelStyle: const TextStyle(color: white), // Label bianco
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
      ),

      // ColorScheme
      colorScheme: ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentCyan,
        background: background,
        surface: surface,
        onPrimary: white, // Testo su primary: bianco
        onBackground: white, // Testo su background: bianco
        onSurface: white, // Testo su surface: bianco
        error: const Color(0xFFFF5252),
      ),

      // Tema per le Card
      cardTheme: CardThemeData(
        elevation: 3,
        color: cardColor, // Card grigio scuro (aree grandi)
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // Tema per il testo - TUTTO BIANCO
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: white, fontSize: 16),
        bodyMedium: const TextStyle(color: white, fontSize: 14),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
        titleLarge: const TextStyle(
            color: white, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(
            color: white, fontSize: 18, fontWeight: FontWeight.w600),
        headlineLarge: const TextStyle(
            color: white, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: const TextStyle(
            color: white, fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: const TextStyle(
            color: white, fontSize: 24, fontWeight: FontWeight.bold),
      ),

      // Tema FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentCyan,
        foregroundColor: background, // Icona nera su turchese
        elevation: 4,
      ),

      // Tema Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface, // Dialog grigio scuro (area grande)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // Tema BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface, // BottomSheet grigio scuro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
      ),
      
      listTileTheme: ListTileThemeData(
        // Usiamo 'cardColor' che hai già definito per i contenitori
        tileColor: cardColor, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      dividerTheme: DividerThemeData(
        // Usiamo un grigio scuro visibile sullo sfondo 'surface'
        color: Colors.grey[800], // o un altro colore a tua scelta
        thickness: 1,
        space: 1,
      ),

    );
    
  }
}
