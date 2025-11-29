import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/task_list_tile.dart';
import 'package:shared_todo_app/data/models/task.dart';
import 'package:shared_todo_app/data/repositories/task_repository.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/task_dialog.dart';

import '../controllers/history_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryController>().loadHistory();
    });
  }

  Future<void> _handleStatusChange(Task task, String newStatus) async {
    final repo = TaskRepository();
    await repo.updateTask(taskId: task.id, status: newStatus);
    if (mounted) {
      context.read<HistoryController>().loadHistory();
    }
  }

  Future<void> _openEditDialog(Task task) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => TaskDialog(
        folderId: task.folderId,
        taskToEdit: task,
      ),
    );

    if (result == true && mounted) {
      context.read<HistoryController>().loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HistoryController>();
    final isLoading = controller.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // AppBar pulita che usa il colore del tema (coerente con le altre pagine)
        appBar: AppBar(
          title: const Text("History"),
          centerTitle: true,
          bottom: TabBar(
            // Colori indicatori e testo che si adattano al tema
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            // Rimuoviamo il divider per un look più pulito
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(
                icon: Icon(Icons.check_circle_outline_rounded),
                text: "Completed",
              ),
              Tab(
                icon: Icon(Icons
                    .history_rounded), // Icona più adatta per scaduti/storia
                text: "Expired",
              ),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // TAB 1: Task Completati
                  _buildTaskList(
                    context,
                    controller.completedTasks,
                    emptyIcon: Icons.task_alt,
                    emptyMessage: "No completed tasks yet.",
                  ),

                  // TAB 2: Task Scaduti
                  _buildTaskList(
                    context,
                    controller.expiredTasks,
                    emptyIcon: Icons.event_busy,
                    emptyMessage: "No expired tasks.",
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Task> tasks, {
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<HistoryController>().loadHistory();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskListTile(
            key: ValueKey(task.id),
            task: task,
            currentUserRole: 'admin',
            onTap: () {},
            onEdit: () => _openEditDialog(task),
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: Text('Delete "${task.title}" permanently?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                final repo = TaskRepository();
                await repo.deleteTask(task.id);
                if (mounted) {
                  context.read<HistoryController>().loadHistory();
                }
              }
            },
            onStatusChanged: (newStatus) {
              _handleStatusChange(task, newStatus);
            },
          );
        },
      ),
    );
  }
}
