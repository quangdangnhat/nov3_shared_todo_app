import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder.dart';

class FolderRepository {
  // final SupabaseClient _supabase = Supabase.instance.client; // OLD
  // --- UPDATED: Injectable Client ---
  final SupabaseClient _supabase;

  // Constructor with optional client for testing.
  FolderRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  // --- GET: Stream di folder DENTRO una cartella ---
  Stream<List<Folder>> getFoldersStream(String todoListId, {String? parentId}) {
    // --- MODIFICA CON FILTRO LATO CLIENT ---

    // 1. Crea lo stream filtrando SOLO per todo_list_id (che è supportato)
    final stream = _supabase
        .from('folders')
        .stream(primaryKey: ['id'])
        .eq('todo_list_id', todoListId)
        .order('created_at', ascending: false);

    // 2. Mappa i risultati e filtra in Dart
    return stream.map((data) {
      // 'data' contiene TUTTE le cartelle della lista
      final allFolders = data.map((json) => Folder.fromMap(json));

      // 3. Applica il filtro parentId in Dart
      if (parentId == null) {
        // Cerca le cartelle root
        return allFolders.where((folder) => folder.parentId == null).toList();
      } else {
        // Cerca le sottocartelle
        return allFolders
            .where((folder) => folder.parentId == parentId)
            .toList();
      }
    });
    // --- FINE MODIFICA ---
  }

  // --- NUOVO METODO: Trova la cartella "Root" ---
  // (Questo metodo era già corretto, .filter() funziona qui
  // perché non stiamo usando .stream())
  Future<Folder> getRootFolder(String todoListId) async {
    try {
      final response = await _supabase
          .from('folders')
          .select()
          .eq('todo_list_id', todoListId)
          .filter('parent_id', 'is', null) // Cerca la cartella root
          .single(); // Ci aspettiamo che ce ne sia solo UNA

      return Folder.fromMap(response);
    } catch (e) {
      debugPrint("Errore in getRootFolder: $e");
      throw Exception('Could not find Root folder for list $todoListId');
    }
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
            // 'created_at' rimosso (il DB lo imposta)
            'todo_list_id': todoListId,
            'title': title,
            'parent_id': parentId,
          })
          .select()
          .single();
      return Folder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create folder: $e');
    }
  }

  // --- UPDATE: Aggiorna folder ---
  Future<Folder> updateFolder({
    required String id,
    String? title,
    String? parentId,
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
          .select()
          .single();

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

  Future<Folder> getFolder(String folderId) async {
    try {
      final response =
          await _supabase.from('folders').select().eq('id', folderId).single();
      return Folder.fromMap(response);
    } catch (e) {
      debugPrint("Errore in getFolder: $e");
      throw Exception('Could not find folder with id $folderId');
    }
  }
}
