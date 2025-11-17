// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/create/task/status_picker.dart';
// lib/presentation/pages/task/task_create_page.dart
import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/task_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import '../../controllers/task/task_create_controller.dart';
import '../../widgets/create/task/date_picker.dart';
import '../../widgets/create/task/folder_dialog.dart';
import '../../widgets/create/task/folder_display.dart';
import '../../widgets/create/task/priority.dart';
import '../../widgets/create/task/task_button.dart';
import '../../widgets/create/task/task_description.dart';
import '../../widgets/create/task/task_title.dart';

class TaskCreatePage extends StatefulWidget {
  const TaskCreatePage({super.key});

  @override
  State<TaskCreatePage> createState() => _TaskCreatePageState();
}

class _TaskCreatePageState extends State<TaskCreatePage> {
  late final TaskCreateController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = TaskCreateController(
      todoListRepo: TodoListRepository(),
      folderRepo: FolderRepository(),
      taskRepo: TaskRepository(),
    );

    _controller.initialize();

    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showFolderSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => FolderSelectionDialog(controller: _controller),
    );
    setState(() {});
  }

  Future<void> _handleCreateTask() async {
    try {
      if (_controller.dateError == null) {
        await _controller.createTask(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully!')),
          );

          _titleController.clear();
          _descriptionController.clear();
          _controller.resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Collaborators can\'t create tasks')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a new task',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a task in your todo list',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TaskTitleField(controller: _titleController),
                const SizedBox(height: 16),
                TaskDescriptionField(controller: _descriptionController),
                const SizedBox(height: 16),
                FolderDisplayCard(
                  selectedTodoList: _controller.selectedTodoList,
                  selectedFolder: _controller.selectedFolder,
                  onTap: _showFolderSelectionDialog,
                ),
                const SizedBox(height: 16),
                DatePickerCard(
                  key: const ValueKey('start_date_picker'),
                  type: DatePickerType.startDate,
                  selectedDate: _controller.selectedStartDate ?? DateTime.now(),
                  onDateSelected: (date) => _controller.setStartDate(date),
                ),
                const SizedBox(height: 16),
                DatePickerCard(
                  key: const ValueKey('due_date_picker'),
                  type: DatePickerType.dueDate,
                  selectedDate: _controller.selectedDueDate,
                  onDateSelected: (date) => _controller.setDueDate(date),
                ),
                if (_controller.dateError != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.dateError!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                StatusSelector(
                  selectedStatus: _controller.selectedStatus,
                  onStatusChanged: (status) => _controller.setStatus(status),
                ),
                const SizedBox(height: 16),
                PrioritySelector(
                  selectedPriority: _controller.selectedPriority,
                  onPriorityChanged: (priority) =>
                      _controller.setPriority(priority),
                ),
                const SizedBox(height: 32),
                CreateTaskButton(
                  isEnabled: _controller.canCreateTask(_titleController.text),
                  onPressed: _handleCreateTask,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
