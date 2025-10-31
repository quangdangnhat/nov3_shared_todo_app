import 'package:flutter/material.dart';
import '../../../../core/enums/task_filter_type.dart';

/// Reusable widget to select filter for Task list
class TaskFilterDropdown extends StatelessWidget {
  final TaskFilterType selectedFilter;
  final ValueChanged<TaskFilterType> onFilterChanged;

  const TaskFilterDropdown({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskFilterType>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Filter Tasks',
      initialValue: selectedFilter,
      onSelected: onFilterChanged,
      itemBuilder: (BuildContext context) {
        return TaskFilterType.values.map((TaskFilterType filterType) {
          return PopupMenuItem<TaskFilterType>(
            value: filterType,
            child: Row(
              children: [
                // Show checkmark if selected
                Icon(
                  selectedFilter == filterType
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selectedFilter == filterType
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
                          fontWeight: selectedFilter == filterType
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
}