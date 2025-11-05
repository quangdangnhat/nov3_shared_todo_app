import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Per accedere a 'supabase'

class AuthRepository {
  // --- ADDITION: Injectable Client ---
  final SupabaseClient _client;

  // Constructor with optional client for testing.
  //
  // In production: Use the global client from main.dart
  // In test: Inject a mock client
  AuthRepository({SupabaseClient? client}) 
      : _client = client ?? supabase;

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
      await _client.auth.signUp( // USE _client instead of global supabase
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
      await _client.auth.signInWithPassword( // USE _client instead of global supabase
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
      await _client.auth.signOut();
    } catch (error) {
      debugPrint('Errore signOut: $error');
      rethrow;
    }
  }

  // Get the current user (if logged in)
  User? get currentUser => _client.auth.currentUser;

  /// Auth event stream (for reactive UI).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}  