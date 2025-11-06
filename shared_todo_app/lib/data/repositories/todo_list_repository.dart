import 'package:flutter/foundation.dart';
import '../../main.dart'; // Per l'istanza 'supabase'
import '../models/todo_list.dart';
import 'dart:async'; // Per Completer e Future.wait

/// Repository per gestire le operazioni sulle TodoList.
class TodoListRepository {
  /// Ottiene uno stream delle liste a cui l'utente partecipa,
  /// includendo il ruolo dell'utente per ciascuna lista.
  Stream<List<TodoList>> getTodoListsStream() {
    final userId = supabase.auth.currentUser!.id;

    // 1. Ascolta la tabella 'participations' per l'utente corrente
    final participationStream = supabase
        .from('participations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // 2. Trasforma lo stream di partecipazioni in uno stream di liste
    return participationStream.asyncMap((participationMaps) async {
      if (participationMaps.isEmpty) {
        return <TodoList>[];
      }

      // 3. Estrai gli ID delle liste e mappa il ruolo per ogni ID
      final Map<String, String> listIdToRoleMap = {};
      for (var map in participationMaps) {
        final listId = (map['todo_list_id'] ?? map['todoListId']) as String?;
        final role = map['role'] as String?;
        if (listId != null && role != null) {
          listIdToRoleMap[listId] = role;
        }
      }

      final listIds = listIdToRoleMap.keys.toList();
      if (listIds.isEmpty) {
        return <TodoList>[];
      }

      // 4. Fai una query per ottenere i *dettagli* delle liste
      final todoListsData = await supabase
          .from('todo_lists')
          .select()
          .filter('id', 'in', listIds)
          .order('created_at', ascending: false);

      // 5. Combina i dati: aggiungi il ruolo salvato a ogni oggetto TodoList
      return todoListsData.map((listMap) {
        final listId = listMap['id'] as String;
        final role = listIdToRoleMap[listId] ?? 'Unknown'; // Fallback

        // --- CORREZIONE ---
        // Aggiungi il ruolo alla mappa prima di passarla al costruttore.
        // Il modello TodoList.fromMap si aspetta di trovarlo lì.
        final enrichedMap = {
          ...listMap, // Copia i dati della lista (id, title, desc, ecc.)
          'role': role, // Aggiungi il ruolo
        };

        // Ora fromMap(map) funzionerà
        return TodoList.fromMap(enrichedMap);
        // --- FINE CORREZIONE ---
      }).toList();
    });
  }

  /// Crea una nuova todo_list.
  /// (Il trigger 'on_todolist_created_add_admin_participation'
  /// aggiungerà automaticamente il creatore come 'admin' in 'participations')
  Future<void> createTodoList({required String title, String? desc}) async {
    final newRow = {'title': title, 'desc': desc};
    try {
      await supabase.from('todo_lists').insert(newRow);
    } catch (error) {
      debugPrint('Errore creazione lista: $error');
      rethrow;
    }
  }

  /// Aggiorna una todo_list (titolo/descrizione).
  /// (La policy RLS assicura che solo gli 'admin' possano farlo).
  Future<void> updateTodoList({
    required String listId,
    required String title,
    String? desc,
  }) async {
    try {
      await supabase.from('todo_lists').update({
        'title': title,
        'desc': desc,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', listId);
    } catch (error) {
      debugPrint('Errore aggiornamento lista: $error');
      rethrow;
    }
  }

  /// Rimuove la partecipazione dell'utente corrente da una lista.
  /// La policy RLS ('Allow users to delete (leave) their own participation')
  /// assicura che l'utente possa solo eliminare se stesso.
  /// Il trigger ('on_participation_deleted_check_orphans')
  /// pulirà la lista se era l'ultimo partecipante.
  Future<void> leaveTodoList(String todoListId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("Utente non autenticato.");
    }

    try {
      // Elimina la riga dalla tabella 'participations'
      await supabase
          .from('participations')
          .delete()
          .eq('todo_list_id', todoListId)
          .eq('user_id', userId); // Filtro esplicito
    } catch (error) {
      debugPrint('Errore abbandonando la lista: $error');
      rethrow;
    }
  }
}
