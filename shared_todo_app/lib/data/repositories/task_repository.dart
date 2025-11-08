import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  // final SupabaseClient _supabase = Supabase.instance.client;
  // --- UPDATED: Injectable Client ---
  final SupabaseClient _supabase;
  // Constructor with optional client for testing.
  TaskRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

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

      final response =
          await _supabase.from('tasks').insert(payload).select().single();

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
        'updated_at':
            DateTime.now().toIso8601String(), // Aggiorna sempre 'updated_at'
      };
      if (title != null) updates['title'] = title;
      if (desc != null)
        updates['desc'] =
            desc; // Permetti di impostare a null? Serve 'desc': desc ?? null?
      if (priority != null) updates['priority'] = priority;
      if (status != null) updates['status'] = status;
      if (startDate != null)
        updates['start_date'] = startDate.toIso8601String();
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();

      // Se non ci sono campi da aggiornare (a parte updated_at), potremmo voler uscire prima
      if (updates.length <= 1) {
        // Potresti lanciare un errore o restituire il task non modificato
        // Per ora, procediamo comunque per aggiornare 'updated_at'
        debugPrint(
          "Nessun campo da aggiornare per il task $taskId (solo updated_at)",
        );
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
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      debugPrint('Errore durante l\'eliminazione del task $taskId: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  // Nel tuo TaskRepository:

  // --- Task per periodo (griglia mensile del calendario) ---
  // Calendar: task che "cadono" (anche solo in parte) dentro [from, to)
  // Nel tuo TaskRepository:

  // --- Task per periodo (griglia mensile del calendario) ---
  // Recupera i task che si sovrappongono all'intervallo di date [from, to).
  Future<List<Task>> getTasksForCalendar_Future(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final fromIso = from.toUtc().toIso8601String();
      final toIso = to.toUtc().toIso8601String();

      // La query al database recupera tutti i task che hanno un intervallo
      // di esistenza (da start_date a due_date) che si sovrappone
      // con l'intervallo del calendario [from, to).
      // (start_date < to) AND (due_date >= from)
      final response = await _supabase
          .from('tasks')
          .select()
          .lt('start_date', toIso)
          .gte('due_date', fromIso)
          // Ordiniamo primariamente per data di scadenza direttamente in query,
          // che è più efficiente.
          .order('due_date', ascending: true);

      // Trasforma i dati grezzi in una lista di oggetti Task.
      final tasks = (response as List)
          .map((json) => Task.fromMap(json as Map<String, dynamic>))
          .toList();

      // Applica un ordinamento secondario avanzato in Dart.
      // Questa è la logica che dà priorità alla scadenza, poi alla priorità del task,
      // e infine al titolo.
      tasks.sort((taskA, taskB) {
        // 1. Ordina per data di scadenza (crescente)
        int comparison = taskA.dueDate.compareTo(taskB.dueDate);
        if (comparison != 0) {
          return comparison;
        }

        // 2. Se la scadenza è la stessa, ordina per priorità (da Alta a Bassa)
        comparison = _rankPriority(
          taskA.priority,
        ).compareTo(_rankPriority(taskB.priority));
        if (comparison != 0) {
          return comparison;
        }

        // 3. Se anche la priorità è la stessa, ordina per titolo (alfabetico)
        return taskA.title.toLowerCase().compareTo(taskB.title.toLowerCase());
      });

      return tasks;
    } catch (e) {
      debugPrint('Errore durante il recupero dei task per il calendario: $e');
      // Rilancia l'eccezione per permettere al chiamante (UI) di gestirla.
      rethrow;
    }
  }

  /// Funzione helper per assegnare un peso numerico alla priorità.
  /// Un valore più basso significa una priorità più alta.
  int _rankPriority(String priority) {
    final p = priority.toLowerCase();
    if (p.contains('alta') || p.contains('high')) return 0;
    if (p.contains('media') || p.contains('medium')) return 1;
    return 2; // Bassa, low, o qualsiasi altro valore
  }

  // --- Task per il giorno selezionato ---

  // --- Task per il giorno selezionato ---
  Future<List<Task>> getTasksForDay_Future(
    DateTime dayStartInclusive,
    DateTime dayEndExclusive,
  ) async {
    try {
      final res = await _supabase
          .from('tasks')
          .select('*')
          .gte('due_date', dayStartInclusive.toUtc().toIso8601String())
          .lt('due_date', dayEndExclusive.toUtc().toIso8601String())
          .order('due_date', ascending: true);

      final list = (res as List)
          .cast<Map<String, dynamic>>()
          .map((m) => Task.fromMap(m))
          .toList();

      return list;
    } catch (e) {
      debugPrint('Errore getTasksForDay_Future: $e');
      rethrow;
    }
  }
}
