import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Ottiene uno stream dei task all'interno di una specifica cartella.
  Stream<List<Task>> getTasksStream(String folderId) {
     // --- CORREZIONE ORDINE STREAM ---
     // Chiama prima .stream() e poi applica i filtri
     final stream = _supabase
        .from('tasks')
        .stream(primaryKey: ['id']) // Chiama stream() prima
        .eq('folder_id', folderId) // Applica filtro DOPO stream()
        .order('created_at', ascending: false); // Applica ordine DOPO stream()
     // --- FINE CORREZIONE ---

     // Mappa i dati JSON ricevuti in oggetti Task
     return stream.map((data) {
          // Task.fromMap gestirà tutte le colonne ricevute dallo stream (*)
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
    // startDate ora è opzionale
    DateTime? startDate,
    required DateTime dueDate,
  }) async {
    try {
      // Costruisci il payload base
      final Map<String, dynamic> payload = {
            'folder_id': folderId,
            'title': title,
            'desc': desc,
            'priority': priority,
            'status': status,
            'due_date': dueDate.toIso8601String(),
      };

      // Aggiungi start_date solo se fornita dall'utente.
      if (startDate != null) {
         payload['start_date'] = startDate.toIso8601String();
      }

      // Esegui l'inserimento nel database
      final response = await _supabase
          .from('tasks')
          .insert(payload) // Inserisci il payload costruito
          .select() // Restituisce il record appena creato
          .single(); // Ci aspettiamo un solo risultato

      // Converte la risposta del database in un oggetto Task
      return Task.fromMap(response);
    } catch (e) {
      // Stampa l'errore per il debug e rilancia un'eccezione più specifica
      debugPrint('Errore durante la creazione del task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  // TODO: Aggiungere metodi per updateTask e deleteTask
}

