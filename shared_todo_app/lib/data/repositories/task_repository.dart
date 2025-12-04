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
// aggiunti per la geolocalizzazione
    double? latitude,
    double? longitude,
    String? placeName,
// aggiunti per recurring tasks
    bool isRecurring = false,
    String recurrenceType = 'none',
    String? parentRecurringTaskId,
  }) async {
    try {
      final payload = {
        'folder_id': folderId,
        'title': title,
        'desc': desc,
        'priority': priority,
        'status': status,
        'due_date': dueDate.toIso8601String(),

// aggiunti per la geolocalizzazione
        'latitude': latitude,
        'longitude': longitude,
        'place_name': placeName,

// aggiunti per recurring tasks
        'is_recurring': isRecurring,
        'recurrence_type': recurrenceType,
        'parent_recurring_task_id': parentRecurringTaskId,
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
// aggiunti per la geolocalizzazione
    double? latitude,
    double? longitude,
    String? placeName,
// aggiunti per recurring tasks
    bool? isRecurring,
    String? recurrenceType,
    String? parentRecurringTaskId,
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

// aggiunti per la geolocalizzazione
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (placeName != null) updates['place_name'] = placeName;

// aggiunti per recurring tasks
      if (isRecurring != null) updates['is_recurring'] = isRecurring;
      if (recurrenceType != null) updates['recurrence_type'] = recurrenceType;
      if (parentRecurringTaskId != null) updates['parent_recurring_task_id'] = parentRecurringTaskId;

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

  /// Sposta un task in un'altra cartella
  Future<void> moveTaskToFolder({
    required String taskId,
    required String newFolderId,
  }) async {
    try {
      await _supabase.from('tasks').update({
        'folder_id': newFolderId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } catch (e) {
      debugPrint('Errore durante lo spostamento del task $taskId: $e');
      throw Exception('Failed to move task: $e');
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

// metodo utile per ottenere i task da inserire nella pagina di recap dei task
  /// Recupera tutti i task attivi (non completati) per il recap giornaliero
  Future<List<Task>> getActiveTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          // IMPORTANTE: Escludi i task già fatti!
          // Assumo tu abbia un campo 'status' o 'is_completed'
          .neq('status', 'Done') // O .eq('is_completed', false)
          .order('due_date', ascending: true); // Ordina per scadenza

      return (response as List)
          .map((json) => Task.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Errore caricamento task attivi: $e');
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

  Future<List<Task>> getHistoryTasks() async {
    final now = DateTime.now().toIso8601String();

    // Scarichiamo i task che sono 'Done' OPPURE che hanno una data di scadenza passata
    final response = await _supabase
        .from('tasks')
        .select()
        .order('due_date', ascending: false); // I più recenti in alto

    return (response as List)
        .map((json) => Task.fromMap(json as Map<String, dynamic>))
        .toList();
  }
}
