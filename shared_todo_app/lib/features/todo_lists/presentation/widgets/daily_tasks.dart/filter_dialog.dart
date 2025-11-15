// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import '../../../../../data/models/daily_tasks/task_category.dart';

/// Dialog per filtrare le categorie di task
class FilterDialog extends StatefulWidget {
  final Set<TaskCategory> activeFilters;
  final Map<TaskCategory, int> taskCounts;

  const FilterDialog({
    Key? key,
    required this.activeFilters,
    required this.taskCounts,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();

  /// Mostra il dialog e restituisce i filtri selezionati
  static Future<Set<TaskCategory>?> show(
    BuildContext context, {
    required Set<TaskCategory> activeFilters,
    required Map<TaskCategory, int> taskCounts,
  }) {
    return showDialog<Set<TaskCategory>>(
      context: context,
      builder: (context) => FilterDialog(
        activeFilters: Set.from(activeFilters),
        taskCounts: taskCounts,
      ),
    );
  }
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<TaskCategory> _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = Set.from(widget.activeFilters);
  }

  void _toggleFilter(TaskCategory category, bool? value) {
    setState(() {
      if (value == true) {
        _localFilters.add(category);
      } else {
        _localFilters.remove(category);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _localFilters.addAll(TaskCategory.values);
    });
  }

  void _apply() {
    Navigator.pop(context, _localFilters);
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tasks Filter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: TaskCategory.values.map((category) {
          return CheckboxListTile(
            title: Text(category.filterLabel),
            subtitle: Text('${widget.taskCounts[category] ?? 0} task'),
            value: _localFilters.contains(category),
            onChanged: (value) => _toggleFilter(category, value),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: _selectAll,
          child: const Text('Show All'),
        ),
        TextButton(
          onPressed: _cancel,
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
