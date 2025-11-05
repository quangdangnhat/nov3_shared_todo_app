// lib/presentation/controllers/folder/folder_create_controller.dart

import '../../../../../data/models/folder.dart';
import '../../../../../data/models/todo_list.dart';
import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import '../base_controller.dart';

class FolderCreateController extends BaseFolderSelectionController {
  final TodoListRepository _todoListRepo;
  final FolderRepository _folderRepo;

  FolderCreateController({
    required TodoListRepository todoListRepo,
    required FolderRepository folderRepo,
  })  : _todoListRepo = todoListRepo,
        _folderRepo = folderRepo;

  // Streams
  Stream<List<TodoList>>? _listsStream;
  Stream<List<Folder>>? _folderStream;

  // State
  TodoList? _selectedTodoList;
  Folder? _selectedFolder;
  Folder? _rootFolder;
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  @override
  Stream<List<TodoList>>? get listsStream => _listsStream;
  @override
  Stream<List<Folder>>? get folderStream => _folderStream;
  @override
  TodoList? get selectedTodoList => _selectedTodoList;
  @override
  Folder? get selectedFolder => _selectedFolder;
  @override
  Folder? get rootFolder => _rootFolder;
  @override
  String get searchQuery => _searchQuery;
  @override
  bool get isLoading => _isLoading;

  // Initialization
  @override
  void initialize() {
    _listsStream = _todoListRepo.getTodoListsStream();
  }

  // Filter lists based on search query
  @override
  List<TodoList> filterLists(List<TodoList> lists) {
    if (_searchQuery.isEmpty) return lists;
    return lists.where((list) {
      return list.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Update search query
  @override
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Select TodoList and load its root folder
  @override
  Future<void> selectTodoList(TodoList list) async {
    _selectedTodoList = list;
    _selectedFolder = null;
    _folderStream = null;
    _rootFolder = null;
    _isLoading = true;
    notifyListeners();

    try {
      final root = await _folderRepo.getRootFolder(list.id);
      _rootFolder = root;
      _selectedFolder = root;
      _folderStream = _folderRepo.getFoldersStream(
        list.id,
        parentId: root.id,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Select a folder and load its subfolders
  @override
  Future<void> selectFolder(Folder folder) async {
    if (folder.id != _selectedFolder?.id && _selectedTodoList != null) {
      _selectedFolder = folder;
      _folderStream = _folderRepo.getFoldersStream(
        _selectedTodoList!.id,
        parentId: folder.id,
      );
      notifyListeners();
    }
  }

  // Create a new folder
  Future<void> createFolder(String title) async {
    if (_selectedTodoList == null) {
      throw Exception('No todo list selected');
    }

    if (title.trim().isEmpty) {
      throw Exception('Folder name cannot be empty');
    }

    await _folderRepo.createFolder(
      todoListId: _selectedTodoList!.id,
      title: title.trim(),
      parentId: _selectedFolder?.id,
    );
  }

  // Check if can create folder
  bool canCreateFolder(String folderName) {
    return _selectedTodoList != null && folderName.trim().isNotEmpty;
  }

  // Reset form to initial state
  void resetForm() {
    _selectedTodoList = null;
    _selectedFolder = null;
    _rootFolder = null;
    _folderStream = null;
    _searchQuery = '';
    notifyListeners();
  }
}
