import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_list.dart';

class TodoListRepository {
  final SupabaseClient _supabase;

  TodoListRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  Stream<List<TodoList>> getTodoListsStream() {
    final userId = _supabase.auth.currentUser!.id;

    final participationStream = _supabase
        .from('participations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return participationStream.asyncMap((participationMaps) async {
      if (participationMaps.isEmpty) {
        return <TodoList>[];
      }

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

      // FIXED: Query 'todo_lists' and get member count via select.
      final todoListsData = await _supabase
          .from('todo_lists')
          .select('*, participations(count)')
          .filter('id', 'in', listIds)
          .order('created_at', ascending: false);

      final lists = List<Map<String, dynamic>>.from(todoListsData as List);

      return lists.map((listMap) {
        final listId = listMap['id'] as String;
        final role = listIdToRoleMap[listId] ?? 'Unknown';

        // FIXED: Extract member count from nested 'participations' list.
        final participations = listMap['participations'] as List;
        final memberCount =
            participations.isNotEmpty ? participations[0]['count'] as int : 0;

        final enrichedMap = Map<String, dynamic>.from(listMap);
        enrichedMap['role'] = role;
        enrichedMap['member_count'] = memberCount;
        enrichedMap.remove('participations'); // Clean up before passing to fromMap

        return TodoList.fromMap(enrichedMap);
      }).toList();
    });
  }

  Future<TodoList> getTodoListById(String listId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // FIXED: Query 'todo_lists' and get member count via select.
      final listFuture = _supabase
          .from('todo_lists')
          .select('*, participations(count)')
          .eq('id', listId)
          .single();

      final participationFuture = _supabase
          .from('participations')
          .select('role')
          .eq('todo_list_id', listId)
          .eq('user_id', userId)
          .single();

      final results = await Future.wait([listFuture, participationFuture]);

      final listMap = results[0] as Map<String, dynamic>;
      final participationMap = results[1] as Map<String, dynamic>;

      // FIXED: Extract member count.
      final participations = listMap['participations'] as List;
      final memberCount =
          participations.isNotEmpty ? participations[0]['count'] as int : 0;

      final enrichedMap = {
        ...listMap,
        'role': participationMap['role'] ?? 'Unknown',
        'member_count': memberCount
      };
      enrichedMap.remove('participations'); // Clean up

      return TodoList.fromMap(enrichedMap);
    } catch (error) {
      debugPrint('Error fetching todo list by id: $error');
      throw Exception('Could not fetch list details: $error');
    }
  }

  Future<void> createTodoList({required String title, String? desc}) async {
    final newRow = {'title': title, 'desc': desc};
    try {
      await _supabase.from('todo_lists').insert(newRow);
    } catch (error) {
      debugPrint('Errore creazione lista: $error');
      rethrow;
    }
  }

  Future<void> updateTodoList({
    required String listId,
    required String title,
    String? desc,
  }) async {
    try {
      await _supabase.from('todo_lists').update({
        'title': title,
        'desc': desc,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', listId);
    } catch (error) {
      debugPrint('Errore aggiornamento lista: $error');
      rethrow;
    }
  }

  Future<void> leaveTodoList(String todoListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("Utente non autenticato.");
    }

    try {
      await _supabase
          .from('participations')
          .delete()
          .eq('todo_list_id', todoListId)
          .eq('user_id', userId);
    } catch (error) {
      debugPrint('Errore abbandonando la lista: $error');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchTasksAndGetPath(
      String searchTerm) async {
    try {
      final response = await _supabase.rpc(
        'search_tasks_with_path',
        params: {
          'search_term': searchTerm,
        },
      );

      if (response is List) {
        return List<Map<String, dynamic>>.from(response);
      } else {
        throw Exception('Invalid response format from RPC: expected a List');
      }
    } on PostgrestException catch (e) {
      debugPrint('Errore RPC search_tasks_with_path: ${e.message}');
      throw Exception('Database error while searching tasks: ${e.message}');
    } catch (e) {
      debugPrint('Errore imprevisto in searchTasksAndGetPath: $e');
      throw Exception('An unexpected error occurred while searching tasks: $e');
    }
  }
}
