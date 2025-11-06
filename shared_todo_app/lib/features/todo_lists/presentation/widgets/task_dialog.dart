import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/task.dart';
import '../../../../data/repositories/task_repository.dart';

/// Un dialog per creare o modificare un Task.
class TaskDialog extends StatefulWidget {
  final String folderId;
  // --- MODIFICA: Aggiunto taskToEdit ---
  final Task? taskToEdit; // Se non nullo, siamo in modalità modifica
  // --- FINE MODIFICA ---

  const TaskDialog({
    super.key,
    required this.folderId,
    this.taskToEdit, // Aggiunto al costruttore
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

  // Stato per i campi specifici del Task
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
    // --- MODIFICA: Pre-compila i campi se stiamo modificando ---
    _titleController = TextEditingController(text: widget.taskToEdit?.title);
    _descController = TextEditingController(text: widget.taskToEdit?.desc);
    _selectedPriority = widget.taskToEdit?.priority ?? _priorities[0];
    _selectedStatus = widget.taskToEdit?.status ?? _statuses[0];
    _selectedStartDate = widget.taskToEdit?.startDate;
    _selectedDueDate = widget.taskToEdit?.dueDate; // Carica la data esistente
    // --- FINE MODIFICA ---
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Funzione helper per mostrare il date picker
  Future<DateTime?> _selectDate(
    BuildContext context,
    DateTime? initialDate,
  ) async {
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
      // --- MODIFICA: Logica differenziata per Creazione/Modifica ---
      if (_isEditing) {
        // Logica di Modifica
        await _taskRepo.updateTask(
          taskId: widget.taskToEdit!.id, // ID del task da modificare
          title: _titleController.text.trim(),
          desc: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: _selectedStartDate,
          dueDate: _selectedDueDate, // _selectedDueDate non può essere null qui
        );
      } else {
        // Logica di Creazione
        await _taskRepo.createTask(
          folderId: widget.folderId,
          title: _titleController.text.trim(),
          desc: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: _selectedStartDate, // Può essere null (usa default DB)
          dueDate: _selectedDueDate!,
        );
      }
      // --- FINE MODIFICA ---

      if (mounted) {
        Navigator.of(context).pop(true); // Chiudi e indica successo
      }
    } catch (e) {
      // Propaga l'errore al chiamante
      rethrow;
    } finally {
      // Assicurati che il loading venga disattivato
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Titolo dinamico
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: _priorities.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedPriority = newValue!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedStatus = newValue!);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedStartDate == null
                      ? 'Start Date (Defaults to Today)'
                      : 'Start: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await _selectDate(
                    context,
                    _selectedStartDate ?? DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedStartDate = date);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDueDate == null
                      ? 'Select Due Date *'
                      // Ora _selectedDueDate non è mai null qui se _isEditing è true
                      : 'Due: ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await _selectDate(
                    context,
                    _selectedDueDate ?? DateTime.now(),
                  );
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
                      fontSize: 12,
                    ),
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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              // Testo dinamico
              : Text(_isEditing ? 'Save Task' : 'Create Task'),
        ),
      ],
    );
  }
}
