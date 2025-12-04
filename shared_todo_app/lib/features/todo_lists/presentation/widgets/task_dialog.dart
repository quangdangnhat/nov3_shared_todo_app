// coverage:ignore-file

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/maps/map_dialog.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/create/task/recurrence_selector.dart';
import 'package:shared_todo_app/core/enums/recurrence_type.dart';
import '../../../../data/models/task.dart';
import '../../../../data/repositories/task_repository.dart';

/// Un dialog per creare o modificare un Task.
class TaskDialog extends StatefulWidget {
  final String folderId;
  final Task? taskToEdit;

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

  final _priorities = ['low', 'medium', 'high'];
  final _priorityLabels = ['Low', 'Medium', 'High'];
  final _statuses = ['To Do', 'In Progress', 'Done'];
  late String _selectedPriority;
  late String _selectedStatus;
  DateTime? _selectedStartDate;
  DateTime? _selectedDueDate;

  // Location state
  LocationData? _selectedLocation;

  // Recurring state
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;

  bool get _isEditing => widget.taskToEdit != null;
  bool get _hasLocation => _selectedLocation != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskToEdit?.title);
    _descController = TextEditingController(text: widget.taskToEdit?.desc);
    _selectedPriority = widget.taskToEdit?.priority ?? _priorities[0];
    _selectedStatus = widget.taskToEdit?.status ?? _statuses[0];
    _selectedStartDate = widget.taskToEdit?.startDate;
    _selectedDueDate = widget.taskToEdit?.dueDate;

    // Carica location esistente se in modifica
    if (widget.taskToEdit != null &&
        widget.taskToEdit!.latitude != null &&
        widget.taskToEdit!.longitude != null) {
      _selectedLocation = LocationData(
        latitude: widget.taskToEdit!.latitude!,
        longitude: widget.taskToEdit!.longitude!,
        placeName: widget.taskToEdit!.placeName ?? 'Posizione salvata',
      );
    }

    // Carica recurring state se in modifica
    if (widget.taskToEdit != null) {
      _isRecurring = widget.taskToEdit!.isRecurring;
      _recurrenceType = RecurrenceType.fromString(widget.taskToEdit!.recurrenceType);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

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

  Future<void> _showLocationDialog() async {
    final result = await showDialog<LocationData>(
      context: context,
      builder: (context) => const MapDialog.forCreate(),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  void _clearLocation() {
    setState(() => _selectedLocation = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDueDate == null) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _taskRepo.updateTask(
          taskId: widget.taskToEdit!.id,
          title: _titleController.text.trim(),
          desc: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: _selectedStartDate,
          dueDate: _selectedDueDate,
          // Location data
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          placeName: _selectedLocation?.placeName,
          // Recurring data
          isRecurring: _isRecurring,
          recurrenceType: _isRecurring ? _recurrenceType.value : 'none',
        );
      } else {
        await _taskRepo.createTask(
          folderId: widget.folderId,
          title: _titleController.text.trim(),
          desc: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: _selectedStartDate,
          dueDate: _selectedDueDate!,
          // Location data
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          placeName: _selectedLocation?.placeName,
          // Recurring data
          isRecurring: _isRecurring,
          recurrenceType: _isRecurring ? _recurrenceType.value : 'none',
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // Log error for debugging
      debugPrint('❌ Error creating/updating task: $e');
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
                items: List.generate(_priorities.length, (index) {
                  return DropdownMenuItem<String>(
                    value: _priorities[index],
                    child: Text(_priorityLabels[index]),
                  );
                }),
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

              // LOCATION TILE
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.location_on,
                  color: _hasLocation ? Colors.blue : Colors.grey,
                ),
                title: Text(
                  _hasLocation
                      ? _selectedLocation!.placeName
                      : 'Add a place (Optional)',
                  style: TextStyle(
                    color: _hasLocation ? Colors.black87 : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _hasLocation
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clearLocation,
                        tooltip: 'Remove place',
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _showLocationDialog,
              ),

              const Divider(height: 1),

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
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              RecurrenceSelector(
                isRecurring: _isRecurring,
                recurrenceType: _recurrenceType,
                onRecurringChanged: (value) {
                  setState(() => _isRecurring = value);
                },
                onRecurrenceTypeChanged: (type) {
                  setState(() => _recurrenceType = type);
                },
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
              : Text(_isEditing ? 'Save Task' : 'Create Task'),
        ),
      ],
    );
  }
}
