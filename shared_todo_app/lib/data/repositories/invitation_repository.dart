import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Per l'istanza 'supabase'
import '../models/invitation.dart'; // Importa il nuovo modello

/// Repository per gestire inviti e partecipazioni.
class InvitationRepository {
  
  /// Chiama la Supabase Edge Function 'create-invitation' per creare
  /// un invito "pending" per un utente esistente.
  Future<void> inviteUserToList({
    required String todoListId,
    required String email,
    required String role,
  }) async {
    try {
      // Invoca la funzione serverless corretta ('create-invitation')
      final response = await supabase.functions.invoke(
        'create-invitation',
        body: {
          'todo_list_id': todoListId,
          'invited_email': email,
          'assigned_role': role,
        },
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Failed to send invitation.';
        throw Exception(errorMessage);
      }
      
      debugPrint('Invitation created successfully: ${response.data}');

    } on FunctionException catch (e) {
      debugPrint('FunctionException: ${e.toString()}');
      throw Exception('Function error: ${e.toString()}');
    } catch (e) {
      debugPrint('Generic error in inviteUserToList: $e');
      rethrow;
    }
  }

  /// Recupera tutti gli inviti in sospeso ('pending') per l'utente corrente.
  Stream<List<Invitation>> getPendingInvitationsStream() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]); 
    }
    
    final stream = supabase
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return stream.map((data) {
      return data.map((map) => Invitation.fromMap(map)).toList();
    });
  }

  // --- METODO MANCANTE ---
  /// Chiama la Edge Function 'respond-to-invitation' per accettare o rifiutare.
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    try {
      final response = await supabase.functions.invoke(
        'respond-to-invitation', // Nome della nuova funzione
        body: {
          'invitation_id': invitationId,
          'accept': accept, // Invia true (accetta) o false (rifiuta)
        },
      );

       if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Failed to respond to invitation.';
        throw Exception(errorMessage);
      }
      
      debugPrint('Response recorded successfully: ${response.data}');

    } on FunctionException catch (e) {
      debugPrint('FunctionException: ${e.toString()}');
      throw Exception('Function error: ${e.toString()}');
    } catch (e) {
      debugPrint('Generic error in respondToInvitation: $e');
      rethrow;
    }
  }
  // --- FINE METODO MANCANTE ---
}

