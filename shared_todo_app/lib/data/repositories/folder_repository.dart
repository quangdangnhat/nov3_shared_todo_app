import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder.dart';

class FolderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- GET: Stream di tutti i folder di una TodoList ---
  Stream<List<Folder>> getFoldersStream(String todoListId) {
    return _supabase
        .from('folders')
        .stream(primaryKey: ['id'])
        .eq('todo_list_id', todoListId)
        .order('created_at', ascending: false) // Aggiungiamo un ordine
        .map((data) {
      // Usa .fromMap come abbiamo corretto
      return data.map((json) => Folder.fromMap(json)).toList();
    });
  }

  // --- CREATE: Nuovo folder ---
  Future<Folder> createFolder({
    required String todoListId,
    required String title,
    String? parentId,
  }) async {
    try {
      final response = await _supabase
          .from('folders')
          .insert({
            // --- CORREZIONE ---
            // 'created_at' rimosso. Lasciamo che il DB lo imposti.
            // --- FINE CORREZIONE ---
            'todo_list_id': todoListId,
            'title': title,
            'parent_id': parentId,
          })
          .select()
          .single();
      
      // Usa .fromMap come abbiamo corretto
      return Folder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create folder: $e');
    }
  }

  // --- UPDATE: Aggiorna folder ---
  Future<Folder> updateFolder({
    required String id,
    String? title,
    String? parentId, // se vogliamo spostare la cartella in una diversa
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title == null && parentId == null) {
        throw Exception('Nothing to update');
      }
      if (title != null) updates['title'] = title;
      if (parentId != null) updates['parent_id'] = parentId;
      

      final response = await _supabase
          .from('folders')
          .update(updates)
          .eq('id', id)
          .select() // in modo che verifico che i dati siano stati aggiornati
          .single(); // voglio ritornato solo quell'elemento

      // Usa .fromMap come abbiamo corretto
      return Folder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update folder: $e');
    }
  }

  // --- DELETE: Elimina folder ---
  Future<void> deleteFolder(String id) async {
    try {
      await _supabase.from('folders').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }
}
