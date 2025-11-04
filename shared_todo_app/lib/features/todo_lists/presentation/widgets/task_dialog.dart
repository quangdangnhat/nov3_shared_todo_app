import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/task.dart';
import '../../../../data/repositories/task_repository.dart';
import '../../../../core/utils/snackbar_utils.dart'; // Importato ma non usato qui

/// Un dialog per creare o modificare un Task.
class TaskDialog extends StatefulWidget {
  final String folderId;
  final Task? taskToEdit; // Se non nullo, siamo in modalità modifica

  const TaskDialog({
    super.key,
    required this.folderId,
    this.taskToEdit,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final TaskRepository _taskRepo = TaskRepository();
  bool _isLoading = false;

  final _priorities = ['Low', 'Medium', 'High'];
  final _statuses = ['To Do', 'In Progress', 'Done'];
  late String _selectedPriority;
  late String _selectedStatus;
  DateTime? _selectedStartDate;
  DateTime? _selectedDueDate;

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    // Pre-compila i campi se stiamo modificando
    _titleController = TextEditingController(text: widget.taskToEdit?.title);
    _descController = TextEditingController(text: widget.taskToEdit?.desc);
    _selectedPriority = widget.taskToEdit?.priority ?? _priorities[0];
    _selectedStatus = widget.taskToEdit?.status ?? _statuses[0];
    _selectedStartDate = widget.taskToEdit?.startDate;
    _selectedDueDate = widget.taskToEdit?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Funzione helper per mostrare il date picker
  Future<DateTime?> _selectDate(BuildContext context, DateTime? initialDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    return picked;
  }

  Future<void> _submit() async {
    // Validazione
    if (!_formKey.currentState!.validate() || _selectedDueDate == null) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Logica di Modifica
        await _taskRepo.updateTask(
          taskId: widget.taskToEdit!.id,
          title: _titleController.text.trim(),
          desc: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: _selectedStartDate,
          dueDate: _selectedDueDate,
        );
      } else {
        // Logica di Creazione
        await _taskRepo.createTask(
          folderId: widget.folderId,
          title: _titleController.text.trim(),
          desc: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: _selectedStartDate,
          dueDate: _selectedDueDate!,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Chiudi e indica successo
      }
    } catch (e) {
      // --- CORREZIONE: RIMOSSA SnackBar DA QUI ---
      // if (mounted) {
      //    showErrorSnackBar(context, message: 'Failed to ${_isEditing ? 'update' : 'create'} task: $e');
      // }
      // --- FINE CORREZIONE ---
      rethrow; // Propaga l'errore al chiamante
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Task' : 'Create New Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                //initialValue: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: _priorities.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedPriority = newValue!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                //initialValue: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedStatus = newValue!);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: Text(_selectedStartDate == null
                     ? 'Start Date (Defaults to Today)'
                     : 'Start: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)}'),
                 trailing: const Icon(Icons.calendar_today),
                 onTap: () async {
                   final date = await _selectDate(context, _selectedStartDate ?? DateTime.now());
                   if (date != null) {
                     setState(() => _selectedStartDate = date);
                   }
                 },
               ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                 title: Text(_selectedDueDate == null
                     ? 'Select Due Date *'
                     : 'Due: ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                   final date = await _selectDate(context, _selectedDueDate ?? DateTime.now());
                   if (date != null) {
                     setState(() => _selectedDueDate = date);
                   }
                 },
              ),
              if (_selectedDueDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Due date is required',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEditing ? 'Save Task' : 'Create Task'),
        ),
      ],
    );
  }
}