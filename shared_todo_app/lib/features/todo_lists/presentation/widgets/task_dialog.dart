import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/task.dart'; // Assicurati che il modello Task sia importato
import '../../../../data/repositories/task_repository.dart';
import '../../../../core/utils/snackbar_utils.dart';

/// Un dialog per creare (e in futuro modificare) un Task.
class TaskDialog extends StatefulWidget {
  final String folderId;
  // Aggiungeremo taskToEdit quando implementeremo la modifica
  // final Task? taskToEdit;

  const TaskDialog({
    super.key,
    required this.folderId,
    // this.taskToEdit,
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

  // bool get _isEditing => widget.taskToEdit != null; // Per il futuro

  @override
  void initState() {
    super.initState();
    // Inizializza i controller e i valori predefiniti
    // TODO: Pre-compilare se _isEditing è true
    _titleController = TextEditingController(/* text: widget.taskToEdit?.title */);
    _descController = TextEditingController(/* text: widget.taskToEdit?.desc */);
    _selectedPriority = /* widget.taskToEdit?.priority ?? */ _priorities[0];
    _selectedStatus = /* widget.taskToEdit?.status ?? */ _statuses[0];
    _selectedStartDate = /* widget.taskToEdit?.startDate */ null;
    _selectedDueDate = /* widget.taskToEdit?.dueDate */ null;
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
    // Validazione aggiuntiva per la data
    if (!_formKey.currentState!.validate() || _selectedDueDate == null) {
       // Se la form non è valida o manca la data, forza l'aggiornamento
       // dello stato del dialog per mostrare eventuali errori
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Per ora solo logica di Creazione
      await _taskRepo.createTask(
        folderId: widget.folderId,
        title: _titleController.text.trim(),
        desc: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        priority: _selectedPriority,
        status: _selectedStatus,
        startDate: _selectedStartDate,
        dueDate: _selectedDueDate!,
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Chiudi e indica successo
      }
    } catch (e) {
      // Mostra l'errore qui, perché l'utente è ancora nel dialog
      if (mounted) {
         showErrorSnackBar(context, message: 'Failed to create task: $e');
      }
    } finally {
      // Assicurati che il loading venga disattivato anche in caso di errore
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Task'),
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
                value: _selectedPriority,
                items: _priorities.map((priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 8),
              // --- LISTTILE START DATE RIPRISTINATO ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedStartDate == null
                    ? 'Select Start Date (Optional)'
                    : 'Start: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await _selectDate(context, _selectedStartDate);
                  if (date != null) {
                    setState(() => _selectedStartDate = date); // Usa setState qui
                  }
                },
              ),
              // --- LISTTILE DUE DATE RIPRISTINATO ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedDueDate == null
                    ? 'Select Due Date *'
                    : 'Due: ${DateFormat('dd/MM/yyyy').format(_selectedDueDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await _selectDate(context, _selectedDueDate);
                  if (date != null) {
                    setState(() => _selectedDueDate = date); // Usa setState qui
                  }
                },
              ),
              // Mostra errore se DueDate è obbligatoria e non selezionata
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
              : const Text('Create Task'),
        ),
      ],
    );
  }
}

