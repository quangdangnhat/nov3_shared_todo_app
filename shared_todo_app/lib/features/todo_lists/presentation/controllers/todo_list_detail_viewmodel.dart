import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _taskRepo = TaskRepository(); // FIX 1: Corretto il tipo
  final _invitationRepo = InvitationRepository();
  final _participantRepo = ParticipantRepository();

  // Stato UI
  bool _isFoldersCollapsed = false;
  bool _isTasksCollapsed = false;
  String _currentUserRole = 'collaborator';

  bool get isFoldersCollapsed => _isFoldersCollapsed;
  bool get isTasksCollapsed => _isTasksCollapsed;
  String get currentUserRole => _currentUserRole;

  // Streams
  Stream<List<Folder>> _foldersStream = Stream.empty();
  Stream<List<Task>> _tasksStream = Stream.empty();
  
  // 1. Lo stream grezzo (trigger)
  Stream<List<Participant>> _rawParticipantsStream = Stream.empty();

  // 2. StreamController per gli aggiornamenti futuri
  final StreamController<List<Participant>> _participantsStreamController =
      StreamController.broadcast();
  
  // 3. Variabile per cacheare l'ultimo valore (il nostro "Behavior")
  List<Participant> _latestParticipants = const [];
  
  // 4. Getter che garantisce che il dato cachato venga emesso subito (FIX 2)
  Stream<List<Participant>> get participantsStream async* {
    // FIX 2: Emitto l'ultimo dato cachato per primo,
    // seguito dagli aggiornamenti del controller (il Behavior Subject manuale).
    yield _latestParticipants;
    yield* _participantsStreamController.stream;
  }
  
  // Metodi helper per aggiungere dati e salvare l'ultimo valore
  void _addParticipantsToStream(List<Participant> data) {
    _latestParticipants = data; // Salva l'ultimo valore
    if (!_participantsStreamController.isClosed) {
      _participantsStreamController.add(data);
    }
  }

  void _addErrorToStream(Object error) {
    if (!_participantsStreamController.isClosed) {
      _participantsStreamController.addError(error);
    }
  }

  StreamSubscription? _participantsSubscription;

  Stream<List<Folder>> get foldersStream => _foldersStream;
  Stream<List<Task>> get tasksStream => _tasksStream;

  // Traccia se l'init è stato chiamato
  bool _isInitialized = false;

  /// Resetta il flag di inizializzazione per permettere il refresh
  void resetInitialization() {
    _participantsSubscription?.cancel();
    _latestParticipants = const []; // Resetta la cache
    _isInitialized = false;
  }

  /// Inizializza il ViewModel, carica gli stream e il ruolo utente
  @override
  Future<void> init(String todoListId, String parentFolderId) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _foldersStream = _folderRepo.getFoldersStream(
        todoListId, 
        parentId: parentFolderId,
      );
      _tasksStream = _taskRepo.getTasksStream(parentFolderId);
      _rawParticipantsStream = _participantRepo.getParticipantsStream(todoListId);
      
      // Carica i dati iniziali e avvia l'ascolto (Behavior Subject logic)
      await _loadAndListenToParticipants(todoListId);

      await _fetchCurrentUserRole(todoListId);
    } catch (e) {
      debugPrint("Errore in init ViewModel: $e");
    } finally {
      notifyListeners();
    }
  }

  /// Carica i dati iniziali e avvia la sottoscrizione
  Future<void> _loadAndListenToParticipants(String todoListId) async {
    // 1. Carica i dati INIZIALI immediatamente e li invia
    try {
      final initialData = await _participantRepo.getParticipants(todoListId);
      _addParticipantsToStream(initialData); // Invia il dato iniziale (Behavior)
    } catch (e) {
      _addErrorToStream(e);
    }

    // 2. Avvia l'ascolto degli AGGIORNAMENTI futuri
    _participantsSubscription?.cancel();
    _participantsSubscription =
        _rawParticipantsStream.listen((participantList) async {
      try {
        // Ricarica il JOIN in caso di trigger
        final participantsWithData =
            await _participantRepo.getParticipants(todoListId);

        _addParticipantsToStream(participantsWithData); 
      } catch (e) {
        _addErrorToStream(e);
      }
    });
  }


  /// Carica il ruolo dell'utente corrente per questa todo list
  Future<void> _fetchCurrentUserRole(String todoListId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        _currentUserRole = 'collaborator';
        return;
      }
      final participants = await _participantRepo.getParticipants(todoListId);

      try {
        final myParticipation = participants.firstWhere(
          (p) => p.userId == userId,
        );
        _currentUserRole = myParticipation.role;
      } catch (e) {
        _currentUserRole = 'collaborator';
      }
    } catch (e) {
      debugPrint("Errore nel fetch del ruolo utente: $e");
      _currentUserRole = 'collaborator'; 
    }
  }

  // --- Metodi di Stato UI ---
  void toggleFoldersCollapse() {
    _isFoldersCollapsed = !_isFoldersCollapsed;
    notifyListeners();
  }

  void toggleTasksCollapse() {
    _isTasksCollapsed = !_isTasksCollapsed;
    notifyListeners();
  }

  // --- Metodi di Business Logic ---
  Future<void> deleteFolder(String folderId) async {
    await _folderRepo.deleteFolder(folderId);
  }

  Future<void> deleteTask(String taskId) async {
    // Assumo che deleteTask usi solo taskId per l'eliminazione
    await _taskRepo.deleteTask(taskId); 
  }

  Future<void> handleTaskStatusChange(Task task, String newStatus) async {
    await _taskRepo.updateTask(
      taskId: task.id,
      status: newStatus,
    );
  }

  /// Invia un invito a un nuovo utente
  Future<void> inviteUser(
      String todoListId, String email, String role) async {
    await _invitationRepo.inviteUserToList(
      todoListId: todoListId,
      email: email,
      role: role,
    );
  }

  /// Recupera la cartella genitore per la navigazione "indietro"
  Future<Folder> getParentFolderForNavigation(String parentFolderId) async {
    return await _folderRepo.getFolder(parentFolderId);
  }

  /// Rimuove un partecipante dalla todo list
  Future<void> removeParticipant({
    required String participantId,
    required String todoListId,
  }) async {
    await _participantRepo.removeParticipant(
      userIdToRemove: participantId,
      todoListId: todoListId,
    );
  }

  /// Forza un ricaricamento manuale dei partecipanti (per DELETE)
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
    _participantsStreamController.close();
    super.dispose();
  }
}