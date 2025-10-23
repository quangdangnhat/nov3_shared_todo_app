import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Per accedere a 'supabase'

class AuthRepository {
  // Metodo per registrarsi
  // Nota come gestiamo il campo 'username' nella tua tabella 'users'
  // usando il parametro 'data' di signUp.
  // ... (signIn e signOut restano uguali) ...

  // Metodo per registrarsi
  Future<void> signUp({
    required String email,
    required String password,
    required String username, // MANTENIAMO QUESTO per passarlo nei metadata
  }) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        // Il Trigger che abbiamo creato in Supabase leggerà
        // questo campo 'data' per popolare public.users
        data: {
          'username': username,
        },
      );
    } on AuthException catch (error) {
      if (error.message.contains('Database error saving new user')) {
        throw AuthException(
          'Username già in uso. Prova con un altro.'
        );
      }

      
      rethrow;
    } catch (error) {
      debugPrint('Generic sign up error: $error');
      rethrow;
    }
  }

  // Metodo per accedere
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      debugPrint('Errore signIn: ${error.message}');
      rethrow; // Rilancia l'errore per mostrarlo nella UI
    } catch (error) {
      debugPrint('Errore generico in signIn: $error');
      rethrow;
    }
  }

  // Metodo per uscire
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      debugPrint('Errore signOut: $error');
      rethrow;
    }
  }
}
