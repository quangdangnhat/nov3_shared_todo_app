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

    // 2. Trasforma lo stream di "partecipazioni" in uno stream di "liste"
    return participationStream.asyncMap((participationMaps) async {
      debugPrint("Participation stream updated with ${participationMaps.length} items");

      if (participationMaps.isEmpty) {
        return <TodoList>[];
      }

      // --- MODIFICA: Crea una mappa per cercare i ruoli velocemente ---
      // (Es: {'listId_1': 'admin', 'listId_2': 'collaborator'})
      final roleMap = <String, String>{};
      for (final map in participationMaps) {
        // Usa la logica robusta per trovare l'ID
        final listId = map['todo_list_id'] ?? map['todoListId'];
        final role = map['role'] as String?; // Il ruolo
        if (listId != null && role != null) {
          roleMap[listId] = role;
        }
      }
      
      final listIds = roleMap.keys.toList();
      // --- FINE MODIFICA ---

      if (listIds.isEmpty) {
        debugPrint("No valid list IDs found after filtering");
        return <TodoList>[];
      }

      debugPrint("Fetching details for list IDs: $listIds");

      // 4. Fai una query per ottenere i *dettagli* delle liste
      final todoListsData = await supabase
          .from('todo_lists')
          .select()
          .filter('id', 'in', listIds);
          // Rimuoviamo l'ordine qui, lo applicheremo dopo il merge

      debugPrint("Got ${todoListsData.length} list details");

      // --- MODIFICA: Fondi i dati della lista con i dati del ruolo ---
      final mergedData = todoListsData.map((listMap) {
        final listId = listMap['id'] as String;
        final role = roleMap[listId] ?? 'Unknown'; // Recupera il ruolo

        // Ritorna una nuova mappa con *tutti* i dati
        return {
          ...listMap, // Dati della lista (id, title, desc, created_at)
          'role': role,  // Aggiungi il ruolo
        };
      }).toList();

      // Ordina la lista finale in Dart per data di creazione
      mergedData.sort((a, b) {
         // Usa la logica robusta per la data
         final dateA = DateTime.parse(a['created_at'] ?? a['createdAt']);
         final dateB = DateTime.parse(b['created_at'] ?? b['createdAt']);
         return dateB.compareTo(dateA); // Decrescente (più recenti prima)
      });
      // --- FINE MODIFICA ---

      // 5. Trasforma le mappe unite in oggetti TodoList
      return mergedData.map((map) => TodoList.fromMap(map)).toList();
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
}

