// coverage:ignore-file

// consider testing later

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/models/task.dart';
import '../../../../data/models/participant.dart';
import '../../../../data/repositories/folder_repository.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../../data/repositories/invitation_repository.dart';
import '../../../../data/repositories/participant_repository.dart';
import '../../../../main.dart'; // per accedere a supabase

class TodoListDetailViewModel extends ChangeNotifier {
  // Repositories
  final _folderRepo = FolderRepository();
  final _taskRepo = TaskRepository();
  final _invitationRepo = InvitationRepository();
  final _participantRepo = ParticipantRepository();

  // Stato UI
  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;
  String _currentUserRole = 'collaborator';

  bool get isFoldersCollapsed => _isFoldersCollapsed;
  bool get isTasksCollapsed => _isTasksCollapsed;
  String get currentUserRole => _currentUserRole;

  // Streams e cache
  Stream<List<Folder>> _foldersStream = Stream.empty();
  final Map<String, StreamController<List<Task>>> _tasksControllers = {};
  final Map<String, List<Task>> _tasksByFolder = {};
  Stream<List<Participant>> _rawParticipantsStream = Stream.empty();
  final StreamController<List<Participant>> _participantsStreamController =
      StreamController.broadcast();
  List<Participant> _latestParticipants = const [];

  StreamSubscription<List<Task>>? _allTasksSub;
  StreamSubscription? _participantsSubscription;

  bool _isInitialized = false;

  // --- Stream getter ---
  Stream<List<Task>> tasksStream(String folderId) {
    _initTasksStream(folderId);
    return _tasksControllers[folderId]!.stream;
  }

  Stream<List<Folder>> get foldersStream => _foldersStream;

  Stream<List<Participant>> get participantsStream async* {
    yield _latestParticipants;
    yield* _participantsStreamController.stream;
  }

  // --- Inizializzazione tasks stream per folder ---
  void _initTasksStream(String folderId) {
    if (_tasksControllers.containsKey(folderId)) return;

    final controller = StreamController<List<Task>>.broadcast();
    _tasksControllers[folderId] = controller;
    _tasksByFolder.putIfAbsent(folderId, () => []);

    _allTasksSub ??= _taskRepo.getAllTasksStream().listen((allTasks) {
      for (final folder in _tasksByFolder.keys) {
        final tasksInFolder =
            allTasks.where((t) => t.folderId == folder).toList();
        _tasksByFolder[folder] = tasksInFolder;
        _tasksControllers[folder]?.add(List.from(tasksInFolder));
      }
    });
  }

  // --- Gestione cache tasks ---
  void _updateTaskCache(String folderId, Task updatedTask) {
    final tasks = _tasksByFolder[folderId];
    if (tasks == null) return;

    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
    } else {
      tasks.insert(0, updatedTask);
    }
    _tasksControllers[folderId]?.add(List.from(tasks));
  }

  void _removeTaskFromCache(String folderId, String taskId) {
    final tasks = _tasksByFolder[folderId];
    if (tasks == null) return;

    tasks.removeWhere((t) => t.id == taskId);
    _tasksControllers[folderId]?.add(List.from(tasks));
  }

  void _addTaskToCache(String folderId, Task newTask) {
    final tasks = _tasksByFolder[folderId] ?? [];
    tasks.insert(0, newTask);
    _tasksByFolder[folderId] = tasks;
    _tasksControllers[folderId]?.add(List.from(tasks));
  }

  // --- CRUD tasks con aggiornamento cache ---
  Future<Task> createTask(String folderId, Task task) async {
    try {
      final newTask = await _taskRepo.createTask(
        folderId: task.folderId,
        title: task.title,
        desc: task.desc,
        priority: task.priority,
        status: task.status,
        startDate: task.startDate,
        dueDate: task.dueDate,
      );
      _addTaskToCache(folderId, newTask);
      return newTask;
    } catch (e) {
      debugPrint('Errore nella creazione del task: $e');
      rethrow;
    }
  }

  Future<Task> updateTask(String folderId, Task task) async {
    try {
      final updatedTask = await _taskRepo.updateTask(
        taskId: task.id,
        title: task.title,
        desc: task.desc,
        priority: task.priority,
        status: task.status,
        startDate: task.startDate,
        dueDate: task.dueDate,
      );
      _updateTaskCache(folderId, updatedTask);
      return updatedTask;
    } catch (e) {
      debugPrint('Errore nell\'aggiornamento del task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String folderId, String taskId) async {
    try {
      await _taskRepo
          .deleteTask(taskId); // Assicurati che il repo usi .select()
      _removeTaskFromCache(folderId, taskId);
    } catch (e) {
      debugPrint('Errore nella cancellazione del task $taskId: $e');
      rethrow;
    }
  }

  Future<void> handleTaskStatusChange(Task task, String newStatus) async {
    try {
      final updatedTask =
          await _taskRepo.updateTask(taskId: task.id, status: newStatus);
      _updateTaskCache(task.folderId, updatedTask);
    } catch (e) {
      debugPrint('Errore nell\'update dello status del task: $e');
      rethrow;
    }
  }

  // --- Metodi UI ---
  void toggleFoldersCollapse() {
    _isFoldersCollapsed = !_isFoldersCollapsed;
    notifyListeners();
  }

  void toggleTasksCollapse() {
    _isTasksCollapsed = !_isTasksCollapsed;
    notifyListeners();
  }

  // --- Participants stream & management ---
  void _addParticipantsToStream(List<Participant> data) {
    _latestParticipants = data;
    if (!_participantsStreamController.isClosed) {
      _participantsStreamController.add(data);
    }
  }

  void _addErrorToStream(Object error) {
    if (!_participantsStreamController.isClosed) {
      _participantsStreamController.addError(error);
    }
  }

  Future<void> _loadAndListenToParticipants(String todoListId) async {
    try {
      final initialData = await _participantRepo.getParticipants(todoListId);
      _addParticipantsToStream(initialData);
    } catch (e) {
      _addErrorToStream(e);
    }

    _participantsSubscription?.cancel();
    _rawParticipantsStream = _participantRepo.getParticipantsStream(todoListId);
    _participantsSubscription =
        _rawParticipantsStream.listen((participantList) async {
      try {
        final participantsWithData =
            await _participantRepo.getParticipants(todoListId);
        _addParticipantsToStream(participantsWithData);
      } catch (e) {
        _addErrorToStream(e);
      }
    });
  }

  Future<void> _fetchCurrentUserRole(String todoListId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _currentUserRole = 'collaborator';
        return;
      }
      final participants = await _participantRepo.getParticipants(todoListId);
      final myParticipation = participants.firstWhere((p) => p.userId == userId,
          orElse: () => Participant.empty());
      _currentUserRole = myParticipation.role;
    } catch (e) {
      debugPrint("Errore nel fetch del ruolo utente: $e");
      _currentUserRole = 'collaborator';
    }
  }

  /// Inizializzazione generale
  Future<void> init(String todoListId, String parentFolderId) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _foldersStream =
          _folderRepo.getFoldersStream(todoListId, parentId: parentFolderId);

      // RIMUOVERE: _tasksStream = tasksStream(parentFolderId);

      await _loadAndListenToParticipants(todoListId);
      await _fetchCurrentUserRole(todoListId);
    } catch (e) {
      debugPrint("Errore in init ViewModel: $e");
    } finally {
      notifyListeners();
    }
  }

  /// Reset inizializzazione
  void resetInitialization() {
    _participantsSubscription?.cancel();
    _latestParticipants = const [];
    _isInitialized = false;
  }

  /// Altri metodi business logic
  Future<void> deleteFolder(String folderId) async {
    await _folderRepo.deleteFolder(folderId);
  }

  Future<void> inviteUser(String todoListId, String email, String role) async {
    await _invitationRepo.inviteUserToList(
        todoListId: todoListId, email: email, role: role);
  }

  Future<Folder> getParentFolderForNavigation(String parentFolderId) async {
    return await _folderRepo.getFolder(parentFolderId);
  }

  Future<void> removeParticipant({
    required String participantId,
    required String todoListId,
  }) async {
    await _participantRepo.removeParticipant(
        userIdToRemove: participantId, todoListId: todoListId);
  }

  Future<void> forceParticipantsReload(String todoListId) async {
    try {
      final participantsWithData =
          await _participantRepo.getParticipants(todoListId);
      _addParticipantsToStream(participantsWithData);
    } catch (e) {
      _addErrorToStream(e);
      throw Exception("Failed to force reload participants: $e");
    }
  }

  @override
  void dispose() {
    _participantsSubscription?.cancel();
    _allTasksSub?.cancel();
    for (final controller in _tasksControllers.values) {
      controller.close();
    }
    _participantsStreamController.close();
    super.dispose();
  }
}
