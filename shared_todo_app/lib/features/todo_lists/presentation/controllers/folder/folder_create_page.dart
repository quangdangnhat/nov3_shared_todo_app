import 'package:flutter/material.dart';
import '../../../../../data/models/folder.dart';
import '../../../../../data/models/todo_list.dart';
import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import 'package:flutter/foundation.dart';

class FolderCreateController extends ChangeNotifier {
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
  Stream<List<TodoList>>? get listsStream => _listsStream;
  Stream<List<Folder>>? get folderStream => _folderStream;
  TodoList? get selectedTodoList => _selectedTodoList;
  Folder? get selectedFolder => _selectedFolder;
  Folder? get rootFolder => _rootFolder;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  // Initialization
  void initialize() {
    _listsStream = _todoListRepo.getTodoListsStream();
  }

  // Filter lists based on search query
  List<TodoList> filterLists(List<TodoList> lists) {
    if (_searchQuery.isEmpty) return lists;
    return lists.where((list) {
      return list.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Select TodoList and load its root folder
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

  @override
  void dispose() {
    super.dispose();
  }
}