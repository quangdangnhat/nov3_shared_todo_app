import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; // Per l'istanza 'supabase'
import '../models/participant.dart';

/// Repository per gestire le operazioni sui partecipanti.
class ParticipantRepository {
  /// Recupera la lista di tutti i partecipanti per una data todo_list_id.
  /// Fa un join con la tabella 'users' per ottenere username ed email.
  Future<List<Participant>> getParticipants(String todoListId) async {
    try {
      final response = await supabase
          .from('participations')
          .select('*, users(username, email)') // Il JOIN automatico funziona con i Future
          .eq('todo_list_id', todoListId);

      final List<Participant> participants = response
          .map((map) => Participant.fromMap(map as Map<String, dynamic>))
          .toList();

      return participants;
    } catch (e) {
      debugPrint('Errore durante il recupero dei partecipanti: $e');
      throw Exception('Failed to load participants: $e');
    }
  }

  // --- SOLUZIONE AL PROBLEMA "UNKNOWN USER" E "CARICAMENTO INFINITO" ---

  /// Recupera uno stream di partecipanti per una data todo_list_id.
  /// Si aggiorna automaticamente quando i dati cambiano.
  Stream<List<Participant>> getParticipantsStream(String todoListId) {
    try {
      final participationStream = supabase
          .from('participations')
          .stream(primaryKey: ['todo_list_id', 'user_id'])
          .eq('todo_list_id', todoListId);

      return participationStream.asyncMap((listOfMaps) async {
        
        if (listOfMaps.isEmpty) {
          return <Participant>[];
        }

        final userIds =
            listOfMaps.map((map) => map['user_id'] as String).toList();

        // 5. Facciamo una SECONDA query (un Future) per caricare i profili
        final profileResponse = await supabase
            .from('users')
            .select('id, username, email') // La tabella users ha l'id
            .inFilter('id', userIds); // <-- FIX: Corretto in .inFilter e colonna 'id'

        // 6. Creiamo una Mappa per un "JOIN manuale" veloce.
        //    (La chiave della mappa è 'id' della tabella users)
        final profileMap = <String, Map<String, dynamic>>{};
        for (final profile in profileResponse) {
          // Usiamo l'ID della tabella users come chiave
          profileMap[profile['id']] = profile; 
        }

        // 7. "Iniettiamo" i dati del profilo in ogni mappa di partecipazione.
        final enrichedMaps = listOfMaps.map((participationMap) {
          // participationMap ha 'user_id', che corrisponde a users.id
          final userIdInParticipation = participationMap['user_id'];
          final userProfile = profileMap[userIdInParticipation]; 

          // Aggiungiamo la mappa "users" che il modello si aspetta.
          participationMap['users'] = userProfile;
          
          return participationMap;
        }).toList();

        final participants = enrichedMaps
            .map((map) => Participant.fromMap(map as Map<String, dynamic>))
            .toList();

        return participants;

      }); // Fine asyncMap

    } catch (e) {
      debugPrint('Errore durante la creazione dello stream dei partecipanti: $e');
      throw Exception('Failed to create participants stream: $e');
    }
  }
  // --- FINE SOLUZIONE ---


  // --- METODO PER RIMUOVERE UN PARTECIPANTE ---
  Future<void> removeParticipant(
      {required String todoListId, required String userIdToRemove}) async {
    try {
      await supabase
          .from('participations')
          .delete()
          .eq('todo_list_id', todoListId)
          .eq('user_id', userIdToRemove); 
    } catch (e) {
      debugPrint('Errore during la rimozione del partecipante: $e');
      if (e is PostgrestException && e.code == '42501') {
        throw Exception(
            'Permission denied. You may not have the rights to remove this participant.');
      }
      throw Exception('Failed to remove participant: $e');
    }
  }
}
