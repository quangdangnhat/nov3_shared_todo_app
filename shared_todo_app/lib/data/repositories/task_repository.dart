// coverage:ignore-file

// consider testing later

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  final SupabaseClient _supabase;

  TaskRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  /// Stream globale di tutti i task
  Stream<List<Task>> getAllTasksStream() {
    final stream = _supabase.from('tasks').stream(primaryKey: ['id']);
    return stream
        .map((data) => data.map((json) => Task.fromMap(json)).toList());
  }

  /// Stream dei task di una cartella specifica
  Stream<List<Task>> getTasksStream(String folderId) {
    final stream = _supabase
        .from('tasks')
        .stream(primaryKey: ['id']).eq('folder_id', folderId);
    return stream
        .map((data) => data.map((json) => Task.fromMap(json)).toList());
  }

  /// Crea un nuovo task
  Future<Task> createTask({
    required String folderId,
    required String title,
    String? desc,
    required String priority,
    required String status,
    DateTime? startDate,
    required DateTime dueDate,
  }) async {
    try {
      final payload = {
        'folder_id': folderId,
        'title': title,
        'desc': desc,
        'priority': priority,
        'status': status,
        'due_date': dueDate.toIso8601String(),
      };
      if (startDate != null)
        payload['start_date'] = startDate.toIso8601String();

      final response =
          await _supabase.from('tasks').insert(payload).select().single();

      return Task.fromMap(response);
    } catch (e) {
      debugPrint('Errore durante la creazione del task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  /// Aggiorna un task esistente
  Future<Task> updateTask({
    required String taskId,
    String? title,
    String? desc,
    String? priority,
    String? status,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String()
      };
      if (title != null) updates['title'] = title;
      if (desc != null) updates['desc'] = desc;
      if (priority != null) updates['priority'] = priority;
      if (status != null) updates['status'] = status;
      if (startDate != null)
        updates['start_date'] = startDate.toIso8601String();
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      return Task.fromMap(response);
    } catch (e) {
      debugPrint('Errore durante l\'aggiornamento del task $taskId: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  /// Elimina un task
  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .select(); // <- forza Supabase a restituire i record cancellati

      if ((response as List).isEmpty) {
        debugPrint('Task $taskId non trovato o già cancellato.');
      } else {
        debugPrint('Task $taskId cancellato correttamente.');
      }
    } catch (e) {
      debugPrint('Errore durante l\'eliminazione del task $taskId: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Recupera i task che hanno 'dueDate' tra start e end
  Future<List<Task>> getTasksForCalendar(DateTime start, DateTime end) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .gte('due_date', start.toIso8601String())
        .lt('due_date', end.toIso8601String());

    return (response as List)
        .map((json) => Task.fromMap(json as Map<String, dynamic>))
        .toList();
  }
}
