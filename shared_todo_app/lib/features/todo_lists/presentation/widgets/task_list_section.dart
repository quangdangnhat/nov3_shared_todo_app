import 'package:flutter/material.dart';
import '../../../../data/models/task.dart';
import 'task_list_tile.dart';

/// Sezione che mostra il titolo e lo StreamBuilder per i task.
class TaskListSection extends StatelessWidget {
  final bool isCollapsed;
  final Stream<List<Task>> stream;
  final VoidCallback onToggleCollapse;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;
  final Function(Task, String) onStatusChanged;

  const TaskListSection({
    super.key,
    required this.isCollapsed,
    required this.stream,
    required this.onToggleCollapse,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ).copyWith(top: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey),
                ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.expand_more : Icons.expand_less,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleCollapse,
                  tooltip: isCollapsed ? 'Expand Tasks' : 'Collapse Tasks',
                ),
              ],
            ),
          ),
        ),
        if (!isCollapsed)
          StreamBuilder<List<Task>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                debugPrint(
                  'Errore StreamBuilder Tasks: ${snapshot.error}',
                );
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error loading tasks: ${snapshot.error}',
                    ),
                  ),
                );
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32.0,
                    ),
                    child: Center(
                      child: Text(
                        'No tasks in this folder yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((
                  context,
                  index,
                ) {
                  final task = tasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: TaskListTile(
                      task: task,
                      onTap: () {},
                      onEdit: () => onEdit(task),
                      onDelete: () => onDelete(task),
                      onStatusChanged: (newStatus) =>
                          onStatusChanged(task, newStatus),
                    ),
                  );
                }, childCount: tasks.length),
              );
            },
          ),
      ],
    );
  }
}
