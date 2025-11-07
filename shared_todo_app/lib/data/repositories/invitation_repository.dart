import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation.dart';

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
        final errorMessage =
            errorData?['error'] ?? 'Failed to send invitation.';
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
      return Stream.value([]);
    }

    // 1. Definiamo la query FILTRATA
    final baseQuery = _supabase
        .from('invitations')
        .select() // Inizia la query con select()
        .eq('status', 'pending')
        .eq('invited_user_id', userId);

    // 2. Chiamiamo .select().asStream() su un oggetto che supporta i filtri
    final stream =
        baseQuery.order('created_at', ascending: false).select().asStream();

    // 3. Usiamo asyncMap per "arricchire" i dati e filtrare con certezza.
    return stream.asyncMap((invitationDataList) async {
      // Filtriamo la lista grezza anche per lo stato 'pending' per robustezza.
      final pendingInvitations = invitationDataList
          .where((map) => map['status'] == 'pending')
          .toList();

      if (pendingInvitations.isEmpty) {
        return <Invitation>[];
      }

      // Estrai gli ID necessari per le query successive
      final listIds = pendingInvitations
          .map((map) => map['todo_list_id'] as String)
          .toSet()
          .toList();
      final inviterIds = pendingInvitations
          .map((map) => map['invited_by_user_id'] as String)
          .toSet()
          .toList();

      if (listIds.isEmpty || inviterIds.isEmpty) {
        return <Invitation>[];
      }

      // 3. Fai query separate per i dati aggiuntivi (JOIN manuale)
      final listTitlesFuture = _supabase
          .from('todo_lists')
          .select('id, title')
          .filter('id', 'in', listIds);

      final inviterEmailsFuture = _supabase
          .from('users')
          .select('id, email')
          .filter('id', 'in', inviterIds);

      final [listTitlesResponse, inviterEmailsResponse] = await Future.wait([
        listTitlesFuture,
        inviterEmailsFuture,
      ]);

      // 4. Mappa i risultati in lookup map per efficienza
      final listTitles = {
        for (var item in listTitlesResponse)
          item['id'] as String: item['title'] as String,
      };
      final inviterEmails = {
        for (var item in inviterEmailsResponse)
          item['id'] as String: item['email'] as String,
      };

      // 5. Combina i dati e costruisci i modelli Invitation
      return pendingInvitations.map((invitationMap) {
        final todoListId = invitationMap['todo_list_id'] as String;
        final inviterId = invitationMap['invited_by_user_id'] as String;

        // Aggiunto cast esplicito per risolvere il problema dei tipi
        final Map<String, dynamic> enrichedMap = {
          ...invitationMap.cast<String, dynamic>(),
          'todo_lists': {'title': listTitles[todoListId] ?? '[Unknown List]'},
          'users': {'email': inviterEmails[inviterId] ?? '[Unknown User]'},
        };
        return Invitation.fromMap(enrichedMap);
      }).toList();
    });
  }

  /// Chiama la Edge Function 'respond-to-invitation' per accettare o rifiutare.
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    try {
      final response = await _supabase.functions.invoke(
        'respond-to-invitation',
        body: {'invitation_id': invitationId, 'accept': accept},
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] ?? 'Failed to respond to invitation.';
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
