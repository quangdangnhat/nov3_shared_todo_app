// coverage:ignore-file

// consider testing later

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation.dart';

/// Repository per gestire inviti e partecipazioni.
class InvitationRepository {
  final SupabaseClient _supabase;

  InvitationRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

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
  /// includendo il titolo della lista e l'email di chi ha invitato.
  ///
  /// Nota sulla compatibilità: per evitare problemi con versioni diverse di
  /// supabase_flutter (dove `.stream()` talvolta non supporta `.eq()`/.order()),
  /// qui creiamo lo stream raw su 'invitations' e poi **filtriamo/ordiniamo client-side**
  /// prima di fare le query aggiuntive.
  Stream<List<Invitation>> getPendingInvitationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(<Invitation>[]);
    }

    // 1) Creiamo lo stream realtime "raw" sulla tabella invitations.
    //    Evitiamo di concatenare .eq()/.order() dopo .stream() per compatibilità.
    final rawStream = _supabase.from('invitations').stream(primaryKey: ['id']);

    // 2) Trasformiamo i rows -> List<Invitation> con asyncMap
    return rawStream.asyncMap((rows) async {
      if (rows == null || rows.isEmpty) return <Invitation>[];

      // 3) Converti e filtra localmente in modo sicuro
      final pendingMaps = <Map<String, dynamic>>[];

      for (final raw in rows) {
        if (raw == null) continue;
        if (raw is! Map) continue;

        // Convertiamo in Map<String, dynamic> in modo esplicito
        final Map<String, dynamic> map = Map<String, dynamic>.from(raw as Map);

        // Applica il filtro desiderato client-side:
        if ((map['status'] ?? '') != 'pending') continue;
        if ((map['invited_user_id'] ?? '') != userId) continue;

        pendingMaps.add(map);
      }

      if (pendingMaps.isEmpty) return <Invitation>[];

      // 4) Ordina client-side per created_at desc (se presente)
      pendingMaps.sort((a, b) {
        final aTs = a['created_at'];
        final bTs = b['created_at'];
        DateTime? ad;
        DateTime? bd;
        try {
          ad = aTs is DateTime ? aTs : DateTime.tryParse(aTs?.toString() ?? '');
        } catch (_) {}
        try {
          bd = bTs is DateTime ? bTs : DateTime.tryParse(bTs?.toString() ?? '');
        } catch (_) {}
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad); // desc
      });

      // 5) Raccogli gli id per le query aggiuntive (join manuale)
      final listIds = pendingMaps
          .map((m) => m['todo_list_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final inviterIds = pendingMaps
          .map((m) => m['invited_by_user_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      // Se non ci sono id validi, restituiamo map trasformate senza titoli/email.
      if (listIds.isEmpty || inviterIds.isEmpty) {
        return pendingMaps.map((map) {
          final enriched = Map<String, dynamic>.from(map);
          enriched['todo_lists'] = {'title': '[Unknown List]'};
          enriched['users'] = {'email': '[Unknown User]'};
          return Invitation.fromMap(enriched);
        }).toList();
      }

      // 6) Query parallele per ottenere titoli e email.
      //    Uso 'inFilter' che è presente in supabase_flutter moderne; se la tua versione
      //    lo chiama 'filter(..., "in", ...)' sostituiscilo.
      final listTitlesFuture = _supabase
          .from('todo_lists')
          .select('id, title')
          .inFilter('id', listIds);

      final inviterEmailsFuture = _supabase
          .from('users')
          .select('id, email')
          .inFilter('id', inviterIds);

      final results =
          await Future.wait([listTitlesFuture, inviterEmailsFuture]);

      final listTitlesResponse = results[0] as List;
      final inviterEmailsResponse = results[1] as List;

      // 7) Costruisci mappe di lookup (con cast sicuro)
      final Map<String, String> listTitles = {};
      for (final item in listTitlesResponse) {
        if (item is Map) {
          final Map<String, dynamic> im = Map<String, dynamic>.from(item);
          final id = im['id']?.toString();
          final title = im['title']?.toString();
          if (id != null && title != null) listTitles[id] = title;
        }
      }

      final Map<String, String> inviterEmails = {};
      for (final item in inviterEmailsResponse) {
        if (item is Map) {
          final Map<String, dynamic> im = Map<String, dynamic>.from(item);
          final id = im['id']?.toString();
          final email = im['email']?.toString();
          if (id != null && email != null) inviterEmails[id] = email;
        }
      }

      // 8) Arricchisci e costruisci i modelli Invitation (cast sicuro)
      final List<Invitation> finalList = [];

      for (final map in pendingMaps) {
        // crea una copia sicura
        final Map<String, dynamic> enrichedMap = Map<String, dynamic>.from(map);

        final todoListId = enrichedMap['todo_list_id']?.toString() ?? '';
        final inviterId = enrichedMap['invited_by_user_id']?.toString() ?? '';

        enrichedMap['todo_lists'] = {
          'title': listTitles[todoListId] ?? '[Unknown List]'
        };
        enrichedMap['users'] = {
          'email': inviterEmails[inviterId] ?? '[Unknown User]'
        };

        try {
          finalList.add(Invitation.fromMap(enrichedMap));
        } catch (e) {
          debugPrint(
              'Warning: failed to parse Invitation.fromMap: $e — map: $enrichedMap');
        }
      }

      return finalList;
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
