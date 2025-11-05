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
      // La policy RLS "Allow members to see other participants..."
      // ci permette di eseguire questa query se siamo membri.
      final response = await supabase
          .from('participations')
          // Seleziona tutte le colonne da 'participations' (*)
          // e le colonne 'username' ed 'email' dalla tabella 'users' collegata
          .select('*, users(username, email)')
          .eq('todo_list_id', todoListId);
      // Non serve ordinare qui, possiamo farlo nella UI se necessario

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

  // TODO: Aggiungere logica per rimuovere/modificare ruolo partecipante (solo admin)
}
