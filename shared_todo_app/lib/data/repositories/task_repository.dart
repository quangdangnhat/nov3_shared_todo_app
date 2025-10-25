import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ottiene uno stream dei task all'interno di una specifica cartella.
  Stream<List<Task>> getTasksStream(String folderId) {
    // Ascolta la tabella 'tasks' filtrando per 'folder_id'
    final stream = _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('folder_id', folderId)
        .order('created_at', ascending: false); // O ordina per 'due_date', ecc.

    // Mappa i dati JSON in oggetti Task
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
    DateTime? startDate,
    required DateTime dueDate,
  }) async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert({
            'folder_id': folderId,
            'title': title,
            'desc': desc,
            'priority': priority,
            'status': status,
            // Converti le date in stringhe ISO 8601, gestendo il null
            'start_date': startDate?.toIso8601String(),
            'due_date': dueDate.toIso8601String(),
            // 'created_at' e 'updated_at' sono gestiti dal DB (DEFAULT)
          })
          .select() // Restituisce il record appena creato
          .single(); // Ci aspettiamo un solo risultato

      return Task.fromMap(response);
    } catch (e) {
      debugPrint('Errore creazione task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // TODO: Aggiungere metodi per updateTask e deleteTask
}