import 'package:flutter/foundation.dart';
import '../../main.dart'; // Per l'istanza 'supabase'
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

    // 2. Trasforma lo stream di "partecipazioni" in uno stream di "liste"
    return participationStream.asyncMap((participationMaps) async {
      debugPrint("Participation stream updated with ${participationMaps.length} items");

      if (participationMaps.isEmpty) {
        return <TodoList>[];
      }

      // 3. Estrai gli ID delle liste (codice di sicurezza per i null)
      // Questa logica funziona anche se riceviamo più colonne (come 'id', 'user_id', ecc.)
      final listIds = participationMaps
          // Controlla sia 'todoList_id' (snake_case) che 'todoListId' (camelCase)
          .map((map) => map['todo_list_id'] ?? map['todoListId'])
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
          // Usiamo il metodo .filter() che non ha conflitti di keyword
          .filter('id', 'in', listIds)
          .order('created_at', ascending: false);

      debugPrint("Got ${todoListsData.length} list details");

      // 5. Trasforma i dati grezzi in oggetti TodoList
      // Assicurati che anche 'TodoList.fromMap' sia robusto (vedi file successivo)
      return todoListsData.map((map) => TodoList.fromMap(map)).toList();
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
}

