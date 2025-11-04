import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Rimosso import '../../main.dart';
import '../models/invitation.dart'; // Importa il modello aggiornato

/// Repository per gestire inviti e partecipazioni.
class InvitationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Chiama la Supabase Edge Function 'create-invitation'.
  Future<void> inviteUserToList({
    required String todoListId,
    required String email,
    required String role,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
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

  /// Recupera tutti gli inviti in sospeso per l'utente corrente,
  /// includendo il titolo della lista E l'email di chi ha invitato.
  Stream<List<Invitation>> getPendingInvitationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]); // Ritorna uno stream vuoto se l'utente non è loggato
    }
    
    // --- CORREZIONE: Usa asyncMap ---
    // 1. Crea uno stream SEMPLICE solo per lo stato 'pending'
    //    La RLS (Policy) si occupa già di filtrare per l'utente loggato.
    final stream = _supabase
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending') // Filtra solo per inviti in sospeso
        .order('created_at', ascending: false);
    // --- FINE ---

    // 2. Usa asyncMap per "arricchire" i dati
    return stream.asyncMap((invitationDataList) async {
      
      // Filtra ulteriormente lato client per sicurezza (se RLS dovesse fallire)
      final myInvitations = invitationDataList
          .where((map) => map['invited_user_id'] == userId)
          .toList();

      if (myInvitations.isEmpty) {
        return <Invitation>[]; // Ritorna lista vuota se non ci sono inviti
      }

      // Estrai gli ID necessari per le query successive
      final listIds = myInvitations
          .map((map) => map['todo_list_id'] as String)
          .toSet()
          .toList();
      final inviterIds = myInvitations
          .map((map) => map['invited_by_user_id'] as String)
          .toSet()
          .toList();
          
      if (listIds.isEmpty || inviterIds.isEmpty) {
         return <Invitation>[];
      }

      // 3. Fai query separate per i dati aggiuntivi
      // --- CORREZIONE: Usa .filter() invece di .in_() ---
      final listTitlesFuture = _supabase
          .from('todo_lists')
          .select('id, title')
          .filter('id', 'in', listIds); // Corretto
          
      final inviterEmailsFuture = _supabase
          .from('users')
          .select('id, email')
          .filter('id', 'in', inviterIds); // Corretto
      // --- FINE CORREZIONE ---

      // Esegui le query in parallelo
      final [listTitlesResponse, inviterEmailsResponse] = await Future.wait([
          listTitlesFuture,
          inviterEmailsFuture
      ]);

      // 4. Mappa i risultati in lookup map per efficienza
      final listTitles = {
        for (var item in listTitlesResponse) 
          item['id'] as String: item['title'] as String
      };
      final inviterEmails = {
        for (var item in inviterEmailsResponse) 
          item['id'] as String: item['email'] as String
      };

      // 5. Combina i dati e costruisci i modelli Invitation
      return myInvitations.map((invitationMap) {
         final todoListId = invitationMap['todo_list_id'] as String;
         final inviterId = invitationMap['invited_by_user_id'] as String;
         
         final enrichedMap = {
           ...invitationMap,
           'todo_lists': { 
             'title': listTitles[todoListId] ?? '[Unknown List]'
           },
           'users': { 
             'email': inviterEmails[inviterId] ?? '[Unknown User]'
           }
         };
         return Invitation.fromMap(enrichedMap as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Chiama la Edge Function 'respond-to-invitation' per accettare o rifiutare.
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    try {
      final response = await _supabase.functions.invoke(
        'respond-to-invitation', 
        body: {
          'invitation_id': invitationId,
          'accept': accept, 
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
}

