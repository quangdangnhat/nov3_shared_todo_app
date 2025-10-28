import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ottiene uno stream dei task all'interno di una specifica cartella.
  Stream<List<Task>> getTasksStream(String folderId) {
     final stream = _supabase
        .from('tasks')
        .stream(primaryKey: ['id']) // Chiama stream() prima
        .eq('folder_id', folderId) // Applica filtro DOPO stream()
        .order('created_at', ascending: false); // Applica ordine DOPO stream()

     // Mappa i dati JSON ricevuti in oggetti Task
     return stream.map((data) {
          return data.map((json) => Task.fromMap(json)).toList();
        });
  }

  /// Crea un nuovo task nel database.
  Future<Task> createTask({
    required String folderId,
    required String title,
    String? desc,
    required String priority,
    required String status,
    DateTime? startDate, // Opzionale, usa default DB
    required DateTime dueDate,
  }) async {
    try {
      final Map<String, dynamic> payload = {
            'folder_id': folderId,
            'title': title,
            'desc': desc,
            'priority': priority,
            'status': status,
            'due_date': dueDate.toIso8601String(),
      };
      // Aggiungi start_date solo se fornita (altrimenti usa DEFAULT now())
      if (startDate != null) {
         payload['start_date'] = startDate.toIso8601String();
      }

      final response = await _supabase
          .from('tasks')
          .insert(payload)
          .select()
          .single();

      return Task.fromMap(response);
    } catch (e) {
      debugPrint('Errore durante la creazione del task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // --- Aggiorna un task esistente ---
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
       // Costruisci dinamicamente il payload con solo i campi da aggiornare
       final updates = <String, dynamic>{
         'updated_at': DateTime.now().toIso8601String(), // Aggiorna sempre 'updated_at'
       };
       if (title != null) updates['title'] = title;
       if (desc != null) updates['desc'] = desc; // Permetti di impostare a null? Serve 'desc': desc ?? null?
       if (priority != null) updates['priority'] = priority;
       if (status != null) updates['status'] = status;
       if (startDate != null) updates['start_date'] = startDate.toIso8601String();
       if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();

       // Se non ci sono campi da aggiornare (a parte updated_at), potremmo voler uscire prima
       if (updates.length <= 1) {
          // Potresti lanciare un errore o restituire il task non modificato
          // Per ora, procediamo comunque per aggiornare 'updated_at'
          debugPrint("Nessun campo da aggiornare per il task $taskId (solo updated_at)");
       }

       final response = await _supabase
           .from('tasks')
           .update(updates)
           .eq('id', taskId)
           .select() // Restituisce il record aggiornato
           .single(); // Ci aspettiamo un solo risultato

       return Task.fromMap(response);
     } catch (e) {
       debugPrint('Errore durante l\'aggiornamento del task $taskId: $e');
       throw Exception('Failed to update task: $e');
     }
  }

  // --- Elimina un task ---
  Future<void> deleteTask(String taskId) async {
     try {
       await _supabase
           .from('tasks')
           .delete()
           .eq('id', taskId);
     } catch (e) {
       debugPrint('Errore durante l\'eliminazione del task $taskId: $e');
       throw Exception('Failed to delete task: $e');
     }
  }
}

