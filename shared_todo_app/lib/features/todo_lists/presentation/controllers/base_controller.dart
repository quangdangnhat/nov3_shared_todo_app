// lib/presentation/controllers/base/base_folder_selection_controller.dart

import 'package:flutter/foundation.dart';

import '../../../../data/models/folder.dart';
import '../../../../data/models/todo_list.dart';


/// Interfaccia base per i controller che gestiscono la selezione di TodoList e Folder
abstract class BaseFolderSelectionController extends ChangeNotifier {
  // Getters che devono essere implementati
  Stream<List<TodoList>>? get listsStream;
  Stream<List<Folder>>? get folderStream;
  TodoList? get selectedTodoList;
  Folder? get selectedFolder;
  Folder? get rootFolder;
  String get searchQuery;
  bool get isLoading;

  // Metodi che devono essere implementati
  void initialize();
  List<TodoList> filterLists(List<TodoList> lists);
  void updateSearchQuery(String query);
  Future<void> selectTodoList(TodoList list);
  Future<void> selectFolder(Folder folder);
}