import '../../../../data/models/folder.dart';
import '../../../../data/models/task.dart';

/// Service per la gestione della cache dei dati dell'albero
class TreeDataCacheService {
  final Map<String, Folder> _rootFolders = {};
  final Map<String, List<Folder>> _subFolders = {};
  final Map<String, List<Task>> _tasks = {};

  // Root Folders
  Folder? getRootFolder(String todoListId) => _rootFolders[todoListId];

  void setRootFolder(String todoListId, Folder folder) =>
      _rootFolders[todoListId] = folder;

  bool hasRootFolder(String todoListId) => _rootFolders.containsKey(todoListId);

  // Sub Folders
  List<Folder>? getSubFolders(String parentId) => _subFolders[parentId];

  void setSubFolders(String parentId, List<Folder> folders) =>
      _subFolders[parentId] = folders;

  bool hasSubFolders(String parentId) => _subFolders.containsKey(parentId);

  // Tasks
  List<Task>? getTasks(String folderId) => _tasks[folderId];

  void setTasks(String folderId, List<Task> tasks) => _tasks[folderId] = tasks;

  bool hasTasks(String folderId) => _tasks.containsKey(folderId);

  // Cache management
  void clear() {
    _rootFolders.clear();
    _subFolders.clear();
    _tasks.clear();
  }

  void clearRootFolders() => _rootFolders.clear();
  void clearSubFolders() => _subFolders.clear();
  void clearTasks() => _tasks.clear();

  // Debug info
  int get cacheSize =>
      _rootFolders.length + _subFolders.length + _tasks.length;

  Map<String, int> get cacheStats => {
        'rootFolders': _rootFolders.length,
        'subFolders': _subFolders.length,
        'tasks': _tasks.length,
      };
}