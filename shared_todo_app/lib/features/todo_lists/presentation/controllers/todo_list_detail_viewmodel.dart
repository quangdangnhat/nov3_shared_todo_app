import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/models/task.dart';
import '../../../../data/repositories/folder_repository.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../../data/repositories/invitation_repository.dart';
import '../../../../main.dart'; // per accedere a supabase

/// ViewModel per la TodoListDetailScreen.
/// Gestisce tutto lo stato e la logica di business,
/// notificando i listener (la View) quando i dati cambiano.
class TodoListDetailViewModel extends ChangeNotifier {
  // --- DIPENDENZE ---
  final FolderRepository _folderRepo = FolderRepository();
  final TaskRepository _taskRepo = TaskRepository();
  final InvitationRepository _invitationRepo = InvitationRepository();

  // --- STATO PRIVATO ---
  Stream<List<Folder>> _foldersStream = Stream.empty();
  Stream<List<Task>> _tasksStream = Stream.empty();
  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;

  // --- STATO PUBBLICO (Getters) ---
  Stream<List<Folder>> get foldersStream => _foldersStream;
  Stream<List<Task>> get tasksStream => _tasksStream;
  bool get isFoldersCollapsed => _isFoldersCollapsed;
  bool get isTasksCollapsed => _isTasksCollapsed;

  // --- METODI PUBBLICI ---

  /// Inizializza il ViewModel e carica i dati iniziali.
  void init(String todoListId, String parentFolderId) {
    _refreshStreams(todoListId, parentFolderId);
  }

  /// Aggiorna gli stream di dati.
  void _refreshStreams(String todoListId, String parentFolderId) {
    _foldersStream = _folderRepo.getFoldersStream(
      todoListId,
      parentId: parentFolderId,
    );
    _tasksStream = _taskRepo.getTasksStream(parentFolderId);
    // Notifica la UI che gli stream sono stati aggiornati
    notifyListeners();
  }

  /// Inverte lo stato di collasso della sezione cartelle.
  void toggleFoldersCollapse() {
    _isFoldersCollapsed = !_isFoldersCollapsed;
    notifyListeners();
  }

  /// Inverte lo stato di collasso della sezione task.
  void toggleTasksCollapse() {
    _isTasksCollapsed = !_isTasksCollapsed;
    notifyListeners();
  }

  /// Logica per aggiornare lo stato di un task.
  Future<void> handleTaskStatusChange(Task task, String newStatus) async {
    if (task.status == newStatus) return;
    // L'errore verrà gestito dal chiamante (la View)
    await _taskRepo.updateTask(taskId: task.id, status: newStatus);
  }

  /// Logica per eliminare una cartella.
  Future<void> deleteFolder(String folderId) async {
    await _folderRepo.deleteFolder(folderId);
  }

  /// Logica per eliminare un task.
  Future<void> deleteTask(String taskId) async {
    await _taskRepo.deleteTask(taskId);
  }

  /// Logica per invitare un utente.
  Future<void> inviteUser(
      String todoListId, String email, String role) async {
    await _invitationRepo.inviteUserToList(
      todoListId: todoListId,
      email: email,
      role: role,
    );
  }

  /// Logica per recuperare la cartella genitore per la navigazione.
  Future<Folder> getParentFolderForNavigation(String parentId) async {
    final response =
        await supabase.from('folders').select().eq('id', parentId).single();
    return Folder.fromMap(response);
  }
}