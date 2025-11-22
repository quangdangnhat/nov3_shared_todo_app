import 'package:shared_todo_app/features/todo_lists/presentation/widgets/maps/map_dialog.dart';
import '../../../../../data/models/folder.dart';
import '../../../../../data/models/task.dart';
import '../../../../../data/models/todo_list.dart';
import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/task_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import '../../widgets/create/task/status_picker.dart';
import '../base_controller.dart';

class TaskCreateController extends BaseFolderSelectionController {
  final TodoListRepository _todoListRepo;
  final FolderRepository _folderRepo;
  final TaskRepository _taskRepo;

  TaskCreateController({
    required TodoListRepository todoListRepo,
    required FolderRepository folderRepo,
    required TaskRepository taskRepo,
  })  : _todoListRepo = todoListRepo,
        _folderRepo = folderRepo,
        _taskRepo = taskRepo;

  // Streams
  Stream<List<TodoList>>? _listsStream;
  Stream<List<Folder>>? _folderStream;

  // State
  TodoList? _selectedTodoList;
  Folder? _selectedFolder;
  Folder? _rootFolder;
  String _searchQuery = '';
  bool _isLoading = false;
  String _selectedPriority = 'low';
  DateTime _selectedDueDate = DateTime.now();
  DateTime? _selectedStartDate = DateTime.now();
  TaskStatus _selectedStatus = TaskStatus.toDo;
  String? _dateError;

  // Location state
  LocationData? _selectedLocation;

  bool get hasValidDates => _dateError == null;

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
  String get selectedPriority => _selectedPriority;
  DateTime get selectedDueDate => _selectedDueDate;
  DateTime? get selectedStartDate => _selectedStartDate;
  TaskStatus get selectedStatus => _selectedStatus;
  String? get dateError => _dateError;
  LocationData? get selectedLocation => _selectedLocation;
  bool get hasLocation => _selectedLocation != null;

  // Initialization
  @override
  void initialize() {
    _listsStream = _todoListRepo.getTodoListsStream();
  }

  @override
  List<TodoList> filterLists(List<TodoList> lists) {
    if (_searchQuery.isEmpty) return lists;
    return lists.where((list) {
      return list.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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
      _folderStream = _folderRepo.getFoldersStream(list.id, parentId: root.id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

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

  void setPriority(String priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setStatus(TaskStatus status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setDueDate(DateTime date) {
    _selectedDueDate = date;
    _validateDates();
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    _selectedStartDate = date;
    _validateDates();
    notifyListeners();
  }

  void _validateDates() {
    if (_selectedStartDate != null &&
        _selectedStartDate!.isAfter(_selectedDueDate)) {
      _dateError = 'Start date cannot be after end date';
    } else {
      _dateError = null;
    }
  }

  // Location methods
  void setLocation(LocationData location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void clearLocation() {
    _selectedLocation = null;
    notifyListeners();
  }

  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? startDate,
  }) async {
    if (_selectedFolder == null) {
      throw Exception('No folder selected');
    }

    if (title.trim().isEmpty) {
      throw Exception('Task title cannot be empty');
    }

    String status = "To Do";
    if (_selectedStatus.toString().split('.').last == 'inProgress') {
      status = "In Progress";
    }
    if (_selectedStatus.toString().split('.').last == 'done') {
      status = "Done";
    }

    return await _taskRepo.createTask(
      folderId: _selectedFolder!.id,
      title: title.trim(),
      desc: description?.trim(),
      priority: _selectedPriority,
      status: status,
      startDate: startDate,
      dueDate: _selectedDueDate,
      // Aggiungi i dati di localizzazione se presenti
      latitude: _selectedLocation?.latitude,
      longitude: _selectedLocation?.longitude,
      placeName: _selectedLocation?.placeName,
    );
  }

  bool canCreateTask(String taskTitle) {
    return _selectedFolder != null && taskTitle.trim().isNotEmpty;
  }

  void resetForm() {
    _selectedTodoList = null;
    _selectedFolder = null;
    _rootFolder = null;
    _folderStream = null;
    _selectedPriority = 'low';
    _selectedDueDate = DateTime.now();
    _searchQuery = '';
    _selectedStatus = TaskStatus.toDo;
    _selectedLocation = null; // Reset anche la location
    notifyListeners();
  }
}
