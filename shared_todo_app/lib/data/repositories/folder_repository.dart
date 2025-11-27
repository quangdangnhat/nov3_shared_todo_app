// coverage:ignore-file

// consider testing later

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder.dart';

class FolderRepository {
  final SupabaseClient _supabase;

  // Constructor with optional client for testing.
  FolderRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  // --- NUOVO: Stream globale di TUTTI i folder ---
  /// Stream che emette TUTTI i folder del database in tempo reale.
  /// Usalo per monitorare creazioni, modifiche ed eliminazioni.
  Stream<List<Folder>> getAllFoldersStream() {
    final stream = _supabase.from('folders').stream(primaryKey: ['id']);
    return stream
        .map((data) => data.map((json) => Folder.fromMap(json)).toList());
  }

  // --- GET: Stream di folder DENTRO una cartella ---
  Stream<List<Folder>> getFoldersStream(String todoListId, {String? parentId}) {
    // Stream filtrato lato client
    final stream = _supabase
        .from('folders')
        .stream(primaryKey: ['id'])
        .eq('todo_list_id', todoListId)
        .order('created_at', ascending: false);

    return stream.map((data) {
      final allFolders = data.map((json) => Folder.fromMap(json));

      if (parentId == null) {
        return allFolders.where((folder) => folder.parentId == null).toList();
      } else {
        return allFolders
            .where((folder) => folder.parentId == parentId)
            .toList();
      }
    });
  }

  // --- TROVA ROOT FOLDER ---
  Future<Folder> getRootFolder(String todoListId) async {
    try {
      final response = await _supabase
          .from('folders')
          .select()
          .eq('todo_list_id', todoListId)
          .filter('parent_id', 'is', null)
          .single();

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

  Future<void> moveFolder({
    required String folderId,
    required String newParentFolderId,
  }) async {
    try {
      await _supabase
          .from('folders') //  nome tabella cartelle
          .update({
        'parent_id': newParentFolderId, // usa la colonna giusta del DB
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', folderId);
    } catch (e) {
      debugPrint('Errore durante lo spostamento della cartella $folderId: $e');
      throw Exception('Failed to move folder: $e');
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

  // --- GET: Singolo folder ---
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
