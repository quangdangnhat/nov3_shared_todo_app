import 'package:flutter/foundation.dart';
import '../../main.dart';
import '../models/todo_list.dart';

class TodoListRepository {
  // Ottiene uno "Stream" di liste
  Stream<List<TodoList>> getTodoListsStream() {
    final userId = supabase.auth.currentUser!.id;

    // 1. Ascolta in tempo reale la tabella 'participations'
    final participationStream = supabase
        .from('participations')
        .stream(
          primaryKey: ['id'],
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Mappa per tenere traccia dei ruoli
    final roleMap = <String, String>{};

    // 2. Trasforma lo stream di "partecipazioni" in uno stream di "liste"
    return participationStream.asyncMap((participationMaps) async {
      debugPrint("Participation stream updated with ${participationMaps.length} items");

      if (participationMaps.isEmpty) {
        return <TodoList>[];
      }

      // 3. Estrai gli ID delle liste e salva i ruoli
      final listIds = participationMaps
          .map((map) {
            final listId = map['todo_list_id'] ?? map['todoListId'];
            final role = map['role'] as String? ?? 'unknown';
            if (listId != null) {
              roleMap[listId] = role;
            }
            return listId;
          })
          .whereType<String>()
          .toSet()
          .toList();

      if (listIds.isEmpty) {
        debugPrint("No valid list IDs found after filtering");
        return <TodoList>[];
      }

      debugPrint("Fetching details for list IDs: $listIds");

      // 4. Fai una query per ottenere i *dettagli* delle liste
      final todoListsData = await supabase
          .from('todo_lists')
          .select()
          .filter('id', 'in', listIds)
          .order('created_at', ascending: false);

      debugPrint("Got ${todoListsData.length} list details");

      // 5. Trasforma i dati grezzi in oggetti TodoList, FONDENDO il ruolo
      return todoListsData.map((map) {
        final listId = map['id'] as String;
        // Aggiungi il ruolo salvato alla mappa prima di creare l'oggetto
        final mapWithRole = {
          ...map,
          'role': roleMap[listId] ?? 'unknown',
        };
        return TodoList.fromMap(mapWithRole);
      }).toList();
    });
  }

  // Metodo per creare una nuova lista
  Future<void> createTodoList({
    required String title,
    String? desc,
  }) async {
    final newRow = {
      'title': title,
      'desc': desc,
    };

    try {
      await supabase.from('todo_lists').insert(newRow);
    } catch (error) {
      debugPrint('Errore creazione lista: $error');
      rethrow;
    }
  }

  // Metodo per eliminare una lista
  Future<void> deleteTodoList(String listId) async {
    try {
      await supabase.from('todo_lists').delete().eq('id', listId);
    } catch (error) {
      debugPrint('Errore eliminazione lista: $error');
      rethrow;
    }
  }

  // --- NUOVO METODO PER MODIFICARE UNA LISTA ---
  Future<void> updateTodoList({
    required String listId,
    required String title,
    String? desc,
  }) async {
    final updates = {
      'title': title,
      'desc': desc,
      'updated_at': DateTime.now().toIso8601String(), // Aggiorna 'updated_at'
    };

    try {
      await supabase
          .from('todo_lists')
          .update(updates)
          .eq('id', listId);
    } catch (error) {
      debugPrint('Errore aggiornamento lista: $error');
      rethrow;
    }
  }
}

