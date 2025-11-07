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
      // La policy RLS ci permette di eseguire questa query se siamo membri.
      final response = await supabase
          .from('participations')
          // Seleziona tutte le colonne da 'participations' (*)
          // e le colonne 'username' ed 'email' dalla tabella 'users' collegata
          .select('*, users(username, email)')
          .eq('todo_list_id', todoListId);

      // Trasforma la lista di mappe JSON in una lista di oggetti Participant
      final List<Participant> participants = response
          .map((map) => Participant.fromMap(map as Map<String, dynamic>))
          .toList();

      return participants;
    } catch (e) {
      debugPrint('Errore durante il recupero dei partecipanti: $e');
      throw Exception('Failed to load participants: $e');
    }
  }

  /// Recupera uno stream di partecipanti per una data todo_list_id.
  /// Si aggiorna automaticamente quando i dati cambiano.
  Stream<List<Participant>> getParticipantsStream(String todoListId) {
    try {
      // Definiamo la query, identica a getParticipants
      final query = supabase
          .from('participations')
          .select('*, users(username, email)')
          .eq('todo_list_id', todoListId);

      // Creiamo uno stream da questa query.
      // Specifichiamo la chiave primaria composita della tabella 'participations'
      // in modo che Supabase possa identificare univocamente le righe
      // per gli aggiornamenti in tempo reale.
      return supabase
          .from('participations')
          .stream(primaryKey: ['todo_list_id', 'user_id'])
          .eq('todo_list_id', todoListId)
          .map(
            (listOfMaps) {
              // Trasformiamo la lista di mappe in una lista di oggetti Participant
              final participants = listOfMaps
                  .map(
                      (map) => Participant.fromMap(map as Map<String, dynamic>))
                  .toList();
              return participants;
            },
          );
    } catch (e) {
      debugPrint(
          'Errore durante la creazione dello stream dei partecipanti: $e');
      // Rilancia l'eccezione per farla gestire dal chiamante (es. StreamBuilder)
      throw Exception('Failed to create participants stream: $e');
    }
  }

  // --- METODO PER RIMUOVERE UN PARTECIPANTE ---
  /// Rimuove un partecipante (diverso dall'utente corrente) da una lista.
  /// L'esecuzione riuscirà solo se l'utente corrente è un 'admin'
  /// e il target non è un altro 'admin', come definito dalle Policy RLS.
  Future<void> removeParticipant(
      {required String todoListId, required String userIdToRemove}) async {
    try {
      // Le policy RLS "Allow admins to remove..." E "Allow users to delete (leave)..."
      // controlleranno i permessi.
      await supabase
          .from('participations')
          .delete()
          .eq('todo_list_id', todoListId)
          .eq('user_id', userIdToRemove); // Specifica chi rimuovere
    } catch (e) {
      debugPrint('Errore durante la rimozione del partecipante: $e');
      // Controlla se è un errore di RLS (permesso negato)
      if (e is PostgrestException && e.code == '42501') {
        throw Exception(
            'Permission denied. You may not have the rights to remove this participant.');
      }
      throw Exception('Failed to remove participant: $e');
    }
  }
}
