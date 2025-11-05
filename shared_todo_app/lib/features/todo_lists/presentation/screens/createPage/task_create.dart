import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/create/task/status_picker.dart';

// lib/presentation/pages/task/task_create_page.dart

import '../../../../../data/repositories/folder_repository.dart';
import '../../../../../data/repositories/task_repository.dart';
import '../../../../../data/repositories/todo_list_repository.dart';
import '../../controllers/task/task_create_controller.dart';
import '../../widgets/create/task/Date_picker.dart';
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

    // Inizializza il controller
    _controller = TaskCreateController(
      todoListRepo: TodoListRepository(),
      folderRepo: FolderRepository(),
      taskRepo: TaskRepository(),
    );
    _controller.initialize();

    // Ascolta i cambiamenti del campo titolo per aggiornare il pulsante
    _titleController.addListener(() {
      setState(() {
        // Forza il rebuild per aggiornare lo stato del pulsante
      });
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
      builder: (context) => FolderSelectionDialog(
        controller: _controller,
      ),
    );
    setState(() {
      // Aggiorna l'UI dopo la selezione
    });
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

          // Pulisci i campi dopo la creazione
          _titleController.clear();
          _descriptionController.clear();
          _controller.resetForm();

          // Opzionale: torna indietro
          // Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo e descrizione della pagina
                const Text(
                  'Create a new task',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a task in your todo list',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Titolo task
                TaskTitleField(controller: _titleController),
                const SizedBox(height: 16),

                // Descrizione
                TaskDescriptionField(controller: _descriptionController),
                const SizedBox(height: 16),

                // Cartella di destinazione
                FolderDisplayCard(
                  selectedTodoList: _controller.selectedTodoList,
                  selectedFolder: _controller.selectedFolder,
                  onTap: _showFolderSelectionDialog,
                ),
                const SizedBox(height: 16),

                //Start Date (optional)
                DatePickerCard(
                  key: const ValueKey('start_date picker'),
                  type: DatePickerType.startDate,
                  selectedDate: _controller.selectedStartDate ?? DateTime.now(),
                  onDateSelected: (date) {
                    _controller.setStartDate(date);
                  },
                ),

                const SizedBox(height: 16),
                // End Date
                DatePickerCard(
                  key: const ValueKey('due_date_picker'),
                  type: DatePickerType.dueDate,
                  selectedDate: _controller.selectedDueDate,
                  onDateSelected: (date) {
                    _controller.setDueDate(date);
                  },
                ),
                const SizedBox(height: 16),

                // error date handler
                if (_controller.dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[700], size: 20),
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
                  ),

                const SizedBox(height: 16),

                StatusSelector(
                    selectedStatus: _controller.selectedStatus,
                    onStatusChanged: (status) {
                      _controller.setStatus(status);
                    }),
                const SizedBox(height: 16),
                // priority
                PrioritySelector(
                  selectedPriority: _controller.selectedPriority,
                  onPriorityChanged: (priority) {
                    _controller.setPriority(priority);
                  },
                ),
                const SizedBox(height: 32),

                // Bottone Crea
                CreateTaskButton(
                  isEnabled: _controller.canCreateTask(_titleController.text),
                  onPressed: _handleCreateTask,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
