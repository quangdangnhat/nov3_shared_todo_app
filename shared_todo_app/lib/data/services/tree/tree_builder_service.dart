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
class TreeBuilderService {
  final FolderRepository _folderRepository;
  final TaskRepository _taskRepository;
  final TreeDataCacheService _cache;

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
    _cache.clear();

    final rootNode = TreeNode<TreeNodeData>(
      key: "root",
      data: const TreeNodeData(
        id: "root",
        name: "Root",
        type: NodeType.todoList,
      ),
    );

    for (final todoList in todoLists) {
      try {
        final todoListNode = await buildTodoListNode(todoList);
        rootNode.add(todoListNode);
      } catch (e) {
        debugPrint('Errore costruzione nodo TodoList ${todoList.id}: $e');
      }
    }

    return rootNode;
  }

  /// Costruisce il nodo di una TodoList
  Future<TreeNode<TreeNodeData>> buildTodoListNode(TodoList todoList) async {
    final todoListNode = TreeNode<TreeNodeData>(
      key: "list_${todoList.id}",
      data: TreeNodeData.fromTodoList(todoList),
    );

    try {
      final rootFolder = await _getRootFolder(todoList.id);
      final rootFolderNode = await buildFolderNode(
        rootFolder,
        todoList.id,
        todoList,
      );
      todoListNode.add(rootFolderNode);
    } catch (e) {
      debugPrint('Errore caricamento root folder per ${todoList.title}: $e');
      rethrow;
    }

    return todoListNode;
  }

  /// Costruisce ricorsivamente un nodo cartella
  Future<TreeNode<TreeNodeData>> buildFolderNode(
    Folder folder,
    String todoListId,
    TodoList todoList,
  ) async {
    final folderNode = TreeNode<TreeNodeData>(
      key: "folder_${folder.id}",
      data: TreeNodeData.fromFolder(folder, todoListId, todoList),
    );

    await _addTasksToNode(folderNode, folder.id, todoList);
    await _addSubFoldersToNode(folderNode, todoListId, todoList, folder.id);

    return folderNode;
  }

  /// Aggiunge ricorsivamente le sottocartelle
  Future<void> _addSubFoldersToNode(
    TreeNode<TreeNodeData> parentNode,
    String todoListId,
    TodoList todoList,
    String? parentFolderId,
  ) async {
    final folders = await _getSubFolders(todoListId, parentFolderId);

    for (final folder in folders) {
      try {
        final folderNode = await buildFolderNode(folder, todoListId, todoList);
        parentNode.add(folderNode);
      } catch (e) {
        debugPrint('Errore costruzione sottocartella ${folder.id}: $e');
      }
    }
  }

  /// Aggiunge i task a un nodo cartella
  Future<void> _addTasksToNode(
    TreeNode<TreeNodeData> folderNode,
    String folderId,
    TodoList todoList,
  ) async {
    try {
      final tasks = await _getTasks(folderId);

      for (final task in tasks) {
        final taskNode = TreeNode<TreeNodeData>(
          key: "task_${task.id}",
          data: TreeNodeData.fromTask(
            task.id,
            task.title,
            todoList.id,
            todoList,
          ),
        );
        folderNode.add(taskNode);
      }
    } catch (e) {
      debugPrint('Errore caricamento task per folder $folderId: $e');
    }
  }

  // Cache helpers
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

  Future<List<Task>> _getTasks(String folderId) async {
    if (_cache.hasTasks(folderId)) {
      return _cache.getTasks(folderId)!;
    }

    final tasksStream = _taskRepository.getTasksStream(folderId);
    final tasks = await tasksStream.first;
    _cache.setTasks(folderId, tasks);
    return tasks;
  }
}