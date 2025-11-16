import 'dart:async';

import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter/foundation.dart';
import '../../../../data/repositories/folder_repository.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../../data/models/todo_list.dart';
import '../../../../data/models/folder.dart';
import '../../../../data/models/task.dart';
import '../../models/tree/tree_data_cache_service.dart';
import '../../models/tree/tree_node_data.dart';
import '../../models/tree/node_type.dart';

/// Service per la costruzione dell'albero delle TodoList/Folders/Tasks
/// con aggiornamenti in tempo reale dei task E dei folder.
class TreeBuilderService {
  final FolderRepository _folderRepository;
  final TaskRepository _taskRepository;
  final TreeDataCacheService _cache;

  /// Sottoscrizione unica per TUTTI i task
  StreamSubscription<List<Task>>? _allTasksSub;

  /// Sottoscrizione per TUTTI i folder (PER OGNI TodoList)
  final Map<String, StreamSubscription<List<Folder>>> _folderStreamsByList = {};

  /// Registro per mappare [folderId] al suo [TreeNode] corrispondente
  final Map<String, TreeNode<TreeNodeData>> _folderNodeRegistry = {};

  /// Registro per mappare [todoListId] al suo [TreeNode] root corrispondente
  final Map<String, TreeNode<TreeNodeData>> _todoListNodeRegistry = {};

  /// Cache locale per lo stato corrente dei task per ogni cartella.
  final Map<String, List<Task>> _tasksByFolder = {};

  /// Cache locale per lo stato corrente dei folder per ogni TodoList.
  final Map<String, List<Folder>> _foldersByTodoList = {};

  TreeBuilderService({
    required FolderRepository folderRepository,
    required TaskRepository taskRepository,
    required TreeDataCacheService cache,
  })  : _folderRepository = folderRepository,
        _taskRepository = taskRepository,
        _cache = cache;

  /// Costruisce l'albero completo dalle TodoList
  Future<TreeNode<TreeNodeData>> buildTreeFromLists(
    List<TodoList> todoLists,
  ) async {
    // 1. Pulisce tutto lo stato precedente
    _cache.clear();
    _clearSubscriptions();
    _folderNodeRegistry.clear();
    _todoListNodeRegistry.clear();
    _tasksByFolder.clear();
    _foldersByTodoList.clear();

    // 2. Carica lo stato INIZIALE di tutti i task
    final List<Task> allInitialTasks =
        await _taskRepository.getAllTasksStream().first;
    final Map<String, List<Task>> initialGroupedTasks =
        _groupTasksByFolder(allInitialTasks);

    // 3. Avvia lo stream per gli aggiornamenti FUTURI dei task
    _initializeAllTasksStream();

    // Costruisce il nodo root
    final rootNode = TreeNode<TreeNodeData>(
      key: "root",
      data: const TreeNodeData(
        id: "root",
        name: "Root",
        type: NodeType.todoList,
      ),
    );

    // 4. Costruisce l'albero passando i task iniziali
    for (final todoList in todoLists) {
      try {
        final todoListNode = await buildTodoListNode(
          todoList,
          initialGroupedTasks,
        );
        rootNode.add(todoListNode);
      } catch (e) {
        debugPrint('Errore costruzione nodo TodoList ${todoList.id}: $e');
      }
    }

    return rootNode;
  }

  /// Costruisce il nodo di una TodoList
  Future<TreeNode<TreeNodeData>> buildTodoListNode(
    TodoList todoList,
    Map<String, List<Task>> initialGroupedTasks,
  ) async {
    final todoListNode = TreeNode<TreeNodeData>(
      key: "list_${todoList.id}",
      data: TreeNodeData.fromTodoList(todoList),
    );

    // Registra il nodo della TodoList
    _todoListNodeRegistry[todoList.id] = todoListNode;

    try {
      // Carica stato iniziale dei folder per questa TodoList
      /*final initialFolders = await _folderRepository
          .getFoldersStream(todoList.id, parentId: null)
          .first;*/
      
      // Carica TUTTI i folder di questa lista (per il confronto)
      final allInitialFolders = await _loadAllFoldersForList(todoList.id);
      _foldersByTodoList[todoList.id] = allInitialFolders;

      // Avvia lo stream per i folder di questa TodoList
      _initializeFoldersStream(todoList.id);

      final rootFolder = await _getRootFolder(todoList.id);
      final rootFolderNode = await buildFolderNode(
        rootFolder,
        todoList.id,
        todoList,
        initialGroupedTasks,
      );
      todoListNode.add(rootFolderNode);
    } catch (e) {
      debugPrint('Errore caricamento root folder per ${todoList.title}: $e');
      rethrow;
    }

    return todoListNode;
  }

  /// Carica tutti i folder di una TodoList (non in stream)
  Future<List<Folder>> _loadAllFoldersForList(String todoListId) async {
    // Usa il primo valore dello stream per ottenere tutti i folder
    final stream = _folderRepository.getFoldersStream(todoListId);
    return await stream.first;
  }

  /// Avvia lo stream per monitorare i folder di una specifica TodoList
  void _initializeFoldersStream(String todoListId) {
    // Cancella eventuale sottoscrizione precedente
    _folderStreamsByList[todoListId]?.cancel();

    final stream = _folderRepository.getFoldersStream(todoListId);
    
    _folderStreamsByList[todoListId] = stream.listen(
      (allFolders) {
        _handleFoldersUpdate(todoListId, allFolders);
      },
      onError: (e) {
        debugPrint('Errore nello stream dei folder per $todoListId: $e');
      },
    );
  }

  /// Gestisce gli aggiornamenti dei folder
  void _handleFoldersUpdate(String todoListId, List<Folder> newFolders) {
    final currentFolders = _foldersByTodoList[todoListId] ?? [];

    // Se non ci sono cambiamenti rilevanti, esci
    if (!_haveFoldersChanged(currentFolders, newFolders)) {
      return;
    }

    // Aggiorna la cache
    _foldersByTodoList[todoListId] = List.from(newFolders);

    // Ricostruisci la struttura dei folder per questa TodoList
    _rebuildFolderStructure(todoListId, newFolders);
  }

  /// Verifica se ci sono stati cambiamenti rilevanti nei folder
  bool _haveFoldersChanged(List<Folder> oldList, List<Folder> newList) {
    // Controllo sulla lunghezza
    if (oldList.length != newList.length) {
      return true;
    }

    if (oldList.isEmpty) {
      return false;
    }

    // Crea una mappa per confronto efficiente
    final newFoldersMap = {
      for (var folder in newList)
        folder.id: {'title': folder.title, 'parentId': folder.parentId}
    };

    // Controlla ogni folder della vecchia lista
    for (final oldFolder in oldList) {
      final newFolderData = newFoldersMap[oldFolder.id];

      // Folder rimosso o aggiunto
      if (newFolderData == null) {
        return true;
      }

      // Titolo cambiato
      if (oldFolder.title != newFolderData['title']) {
        return true;
      }

      // Parent cambiato (spostamento nella gerarchia)
      if (oldFolder.parentId != newFolderData['parentId']) {
        return true;
      }
    }

    return false;
  }

  /// Ricostruisce la struttura dei folder per una TodoList
  Future<void> _rebuildFolderStructure(
    String todoListId,
    List<Folder> folders,
  ) async {
    final todoListNode = _todoListNodeRegistry[todoListId];
    if (todoListNode == null) {
      debugPrint('TodoList node non trovato per $todoListId');
      return;
    }

    // Rimuovi tutti i nodi folder esistenti (mantieni eventuali altri tipi)
    todoListNode.removeWhere((node) {
      final typedNode = node as TreeNode<TreeNodeData>;
      return typedNode.data?.type == NodeType.folder;
    });

    // Pulisci il registro dei folder per questa lista
    _folderNodeRegistry.removeWhere((key, value) {
      return value.data?.todoListId == todoListId;
    });

    try {
      // Trova e ricostruisci il root folder
      final rootFolder = folders.firstWhere(
        (f) => f.parentId == null,
        orElse: () => throw Exception('Root folder not found'),
      );

      final todoList = todoListNode.data?.todoList;
      if (todoList == null) return;

      // Ottieni i task correnti (per popolare i nuovi nodi)
      final allTasks = await _taskRepository.getAllTasksStream().first;
      final groupedTasks = _groupTasksByFolder(allTasks);

      // Ricostruisci il nodo root
      final rootFolderNode = await buildFolderNode(
        rootFolder,
        todoListId,
        todoList,
        groupedTasks,
      );

      todoListNode.add(rootFolderNode);
    } catch (e) {
      debugPrint('Errore nella ricostruzione dei folder per $todoListId: $e');
    }
  }

  /// Costruisce ricorsivamente un nodo cartella
  Future<TreeNode<TreeNodeData>> buildFolderNode(
    Folder folder,
    String todoListId,
    TodoList todoList,
    Map<String, List<Task>> initialGroupedTasks,
  ) async {
    final folderNode = TreeNode<TreeNodeData>(
      key: "folder_${folder.id}",
      data: TreeNodeData.fromFolder(folder, todoListId, todoList),
    );

    // Registra questo nodo
    _folderNodeRegistry[folder.id] = folderNode;

    // Prende i task iniziali
    final initialTasks = initialGroupedTasks[folder.id] ?? [];
    _tasksByFolder[folder.id] = List.from(initialTasks);

    // Popola il nodo con i task iniziali
    _updateNodeWithTasks(folderNode, initialTasks);

    // Carica le sottocartelle
    await _addSubFoldersToNode(
      folderNode,
      todoListId,
      todoList,
      folder.id,
      initialGroupedTasks,
    );

    return folderNode;
  }

  /// Aggiunge ricorsivamente le sottocartelle
  Future<void> _addSubFoldersToNode(
    TreeNode<TreeNodeData> parentNode,
    String todoListId,
    TodoList todoList,
    String? parentFolderId,
    Map<String, List<Task>> initialGroupedTasks,
  ) async {
    final folders = await _getSubFolders(todoListId, parentFolderId);

    for (final folder in folders) {
      try {
        final folderNode = await buildFolderNode(
          folder,
          todoListId,
          todoList,
          initialGroupedTasks,
        );
        parentNode.add(folderNode);
      } catch (e) {
        debugPrint('Errore costruzione sottocartella ${folder.id}: $e');
      }
    }
  }

  /// Avvia l'UNICA sottoscrizione che ascolta TUTTI i task
  void _initializeAllTasksStream() {
    _allTasksSub?.cancel();

    _allTasksSub = _taskRepository.getAllTasksStream().listen(
      (allTasks) {
        final groupedTasks = _groupTasksByFolder(allTasks);

        for (final folderId in _folderNodeRegistry.keys) {
          final node = _folderNodeRegistry[folderId];
          if (node == null) continue;

          final newTasks = groupedTasks[folderId] ?? [];
          final currentTasks = _tasksByFolder[folderId] ?? [];

          if (!_haveRelevantTaskFieldsChanged(currentTasks, newTasks)) {
            continue;
          }

          _tasksByFolder[folderId] = List.from(newTasks);
          _updateNodeWithTasks(node, newTasks);
        }
      },
      onError: (e) {
        debugPrint('Errore nello stream principale dei task: $e');
      },
    );
  }

  /// Confronta due liste di task
  bool _haveRelevantTaskFieldsChanged(List<Task> oldList, List<Task> newList) {
    if (oldList.length != newList.length) {
      return true;
    }

    if (oldList.isEmpty) {
      return false;
    }

    final newTasksMap = {for (var task in newList) task.id: task.title};

    for (final oldTask in oldList) {
      final newTitle = newTasksMap[oldTask.id];

      if (newTitle == null) {
        return true;
      }

      if (oldTask.title != newTitle) {
        return true;
      }
    }

    return false;
  }

  /// Raggruppa una lista di task in una mappa per folderId
  Map<String, List<Task>> _groupTasksByFolder(List<Task> allTasks) {
    final Map<String, List<Task>> grouped = {};
    for (final task in allTasks) {
      (grouped[task.folderId] ??= []).add(task);
    }
    return grouped;
  }

  /// Aggiorna i figli di un nodo (solo i task)
  void _updateNodeWithTasks(
    TreeNode<TreeNodeData> folderNode,
    List<Task> tasks,
  ) {
    final todoList = folderNode.data?.todoList;

    if (todoList == null) {
      debugPrint("Attenzione: folderNode ${folderNode.key} non ha todoList.");
      return;
    }

    final taskNodes = tasks.map((task) {
      return TreeNode<TreeNodeData>(
        key: "task_${task.id}",
        data: TreeNodeData.fromTask(
          task.id,
          task.title,
          todoList.id,
          todoList,
        ),
      );
    }).toList();

    // Rimuove solo i figli che sono di tipo TASK
    folderNode.removeWhere(
      (node) {
        final typedNode = node as TreeNode<TreeNodeData>;
        return typedNode.data?.type == NodeType.task;
      },
    );

    folderNode.addAll(taskNodes);
  }

  /// Cancella tutte le sottoscrizioni attive
  void _clearSubscriptions() {
    _allTasksSub?.cancel();
    _allTasksSub = null;

    for (final sub in _folderStreamsByList.values) {
      sub.cancel();
    }
    _folderStreamsByList.clear();
  }

  /// Metodo pubblico per la pulizia
  void dispose() {
    _clearSubscriptions();
    _folderNodeRegistry.clear();
    _todoListNodeRegistry.clear();
    _tasksByFolder.clear();
    _foldersByTodoList.clear();
  }

  // --- METODI HELPER PER LA CACHE ---

  Future<Folder> _getRootFolder(String todoListId) async {
    if (_cache.hasRootFolder(todoListId)) {
      return _cache.getRootFolder(todoListId)!;
    }
    final rootFolder = await _folderRepository.getRootFolder(todoListId);
    _cache.setRootFolder(todoListId, rootFolder);
    return rootFolder;
  }

  Future<List<Folder>> _getSubFolders(
    String todoListId,
    String? parentFolderId,
  ) async {
    final cacheKey = parentFolderId ?? 'null';
    if (_cache.hasSubFolders(cacheKey)) {
      return _cache.getSubFolders(cacheKey)!;
    }
    final foldersStream = _folderRepository.getFoldersStream(
      todoListId,
      parentId: parentFolderId,
    );
    final folders = await foldersStream.first;
    _cache.setSubFolders(cacheKey, folders);
    return folders;
  }
}