// coverage:ignore-file

// consider testing later

import 'package:flutter/material.dart';
import '../../../../core/enums/task_filter_type.dart';

/// Reusable widget to select multiple filters for Task list
class TaskFilterDropdown extends StatelessWidget {
  final Set<TaskFilterType> selectedFilters;
  final ValueChanged<Set<TaskFilterType>> onFiltersChanged;

  const TaskFilterDropdown({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskFilterType>(
      icon: Badge(
        isLabelVisible: selectedFilters.isNotEmpty,
        label: Text('${selectedFilters.length}'),
        child: const Icon(Icons.filter_list),
      ),
      tooltip: 'Filter Tasks',
      // Don't close on selection - allow multiple selections
      onSelected: (TaskFilterType filterType) {
        final newFilters = Set<TaskFilterType>.from(selectedFilters);

        if (newFilters.contains(filterType)) {
          // Uncheck: remove the filter
          newFilters.remove(filterType);
        } else {
          // Check: add the filter
          // Handle mutually exclusive sorting options
          if (_isSortingFilter(filterType)) {
            // Remove other sorting filters (keep only filtering options)
            newFilters.removeWhere((f) => _isSortingFilter(f));
          }
          newFilters.add(filterType);
        }

        onFiltersChanged(newFilters);
      },
      itemBuilder: (BuildContext context) {
        return TaskFilterType.values.map((TaskFilterType filterType) {
          final isSelected = selectedFilters.contains(filterType);
          return PopupMenuItem<TaskFilterType>(
            value: filterType,
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filterType.displayName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        filterType.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  /// Check if filter is a sorting filter (mutually exclusive)
  bool _isSortingFilter(TaskFilterType filter) {
    return filter != TaskFilterType.highPriorityOnly;
  }
}
