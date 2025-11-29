import 'package:flutter/material.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';

class HistoryController extends ChangeNotifier {
  final TaskRepository taskRepository;

  HistoryController({required this.taskRepository});

  bool isLoading = false;
  List<Task> completedTasks = [];
  List<Task> expiredTasks = [];

  Future<void> loadHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      final allTasks = await taskRepository.getHistoryTasks(); //
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // FILTRO 1: Completati (Status è "Done")
      completedTasks = allTasks
          .where((t) => t.status == 'Done')
          .toList();

      // FILTRO 2: Scaduti (Non Done E data < oggi)
      expiredTasks = allTasks
          .where((t) => t.status != 'Done' && t.dueDate.isBefore(today))
          .toList();

    } catch (e) {
      debugPrint("Errore history: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}