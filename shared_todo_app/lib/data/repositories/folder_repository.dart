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
      .map((data) {
        return data.map((json) => Folder.fromJson(json)).toList();
      });
}


  // --- CREATE: Nuovo folder ---
  // verificare che il title del folder non sia già presente.-->altrimenti si genera una "infinite recursion"
  Future<Folder> createFolder({
    required String todoListId,
    required String title,
    String? parentId,
  }) async {
    try {
      final response = await _supabase
          .from('folders')
          .insert({
            'created_at': DateTime.now().toIso8601String(),
            'todo_list_id': todoListId,
            'title': title,
            'parent_id': parentId,
          })
          .select()
          .single();
      return Folder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create folder: $e');
    }
  }

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
          .select() // in modo che verifico che i dati siano stati aggiornati    ( si può togliere )
          .single(); // voglio ritornato solo quell'elemento

      return Folder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update folder: $e');
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _supabase.from('folders').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }
}
