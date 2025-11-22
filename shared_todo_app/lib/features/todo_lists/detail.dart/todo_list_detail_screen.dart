// coverage:ignore-file
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/responsive.dart';
import '../../../config/router/app_router.dart';
import '../../../data/models/todo_list.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/folder_repository.dart';
import '../presentation/controllers/todo_list_detail_viewmodel.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../presentation/widgets/folder_dialog.dart';
import '../presentation/widgets/task_dialog.dart';
import '../presentation/widgets/task_list_tile.dart';
import '../../../main.dart';
import '../presentation/widgets/todo_list_detail_header.dart';
import '../presentation/widgets/folder_list_section.dart';
import '../presentation/widgets/detail_action_buttons.dart';
import '../presentation/widgets/participants_dialog.dart';
import '../presentation/widgets/manage_members_dialog.dart';

import '../../../../core/enums/task_filter_type.dart';
import '../../../../core/utils/task_sorter.dart';
import '../presentation/widgets/task_filter_dropdown.dart';

/// Schermata di dettaglio di una TodoList con le sue cartelle e task.
class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;
  final Folder parentFolder;

  const TodoListDetailScreen({
    super.key,
    required this.todoList,
    required this.parentFolder,
  });

  @override
  State<TodoListDetailScreen> createState() => _TodoListDetailScreenState();
}

class _TodoListDetailScreenState extends State<TodoListDetailScreen> {
  late final TodoListDetailViewModel _viewModel;
  TaskFilterType _selectedTaskFilter = TaskFilterType.createdAtNewest;

  @override
  void initState() {
    super.initState();
    _viewModel = TodoListDetailViewModel();
    _viewModel.init(widget.todoList.id, widget.parentFolder.id);
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _refreshStreams() {
    if (!mounted) return;
    _viewModel.resetInitialization();
    _viewModel.init(widget.todoList.id, widget.parentFolder.id);
  }

  Future<void> _openFolderDialog({Folder? folderToEdit}) async {
    if (!mounted) return;
    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return FolderDialog(
            todoListId: widget.todoList.id,
            parentId: widget.parentFolder.id,
            folderToEdit: folderToEdit,
          );
        },
      );
      if (result == true && mounted) {
        showSuccessSnackBar(
          context,
          message:
              'Folder ${folderToEdit == null ? 'created' : 'updated'} successfully',
        );
        _refreshStreams();
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message:
              'Failed to ${folderToEdit == null ? 'create' : 'update'} folder: $error',
        );
      }
    }
  }

  void _showDeleteFolderDialog(Folder folder) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: Text('Are you sure you want to delete "${folder.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _viewModel.deleteFolder(folder.id);
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(context,
                        message: 'Folder deleted successfully');
                    _refreshStreams();
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(context,
                        message: 'Failed to delete folder: $error');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openTaskDialog({Task? taskToEdit}) async {
    if (!mounted) return;
    try {
      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => TaskDialog(
          folderId: widget.parentFolder.id,
          taskToEdit: taskToEdit,
        ),
      );
      if (result == true && mounted) {
        showSuccessSnackBar(
          context,
          message:
              'Task ${taskToEdit == null ? 'created' : 'updated'} successfully',
        );
        _refreshStreams();
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          message:
              'Failed to ${taskToEdit == null ? 'create' : 'update'} task: $error',
        );
      }
    }
  }

  void _showDeleteTaskDialog(Task task) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _viewModel.deleteTask(widget.parentFolder.id, task.id);
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showSuccessSnackBar(context,
                        message: 'Task deleted successfully');
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(context,
                        message: 'Failed to delete task: $error');
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTaskStatusChange(Task task, String newStatus) async {
    try {
      await _viewModel.handleTaskStatusChange(task, newStatus);
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context,
            message: 'Failed to update task status: $error');
      }
    }
  }

  void _showInviteFormDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return ManageMembersDialog(
          todoListId: widget.todoList.id,
          viewModel: _viewModel,
        );
      },
    );
  }

  void _showManageMembersDialog() {
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ParticipantsDialog(
          viewModel: _viewModel,
          todoListId: widget.todoList.id,
          todoListTitle: widget.todoList.title,
          currentUserId: currentUserId,
          currentUserRole: _viewModel.currentUserRole,
          onInvitationSent: () {
            showSuccessSnackBar(context, message: 'Invitation Sent!');
          },
          onParticipantsChanged: () {},
        );
      },
    );
  }

  Future<void> _navigateToParent() async {
    final bool isRootFolder = widget.parentFolder.parentId == null;
    if (!mounted) return;

    if (isRootFolder) {
      context.go(AppRouter.home);
    } else {
      final String parentFolderId = widget.parentFolder.parentId!;
      try {
        final folderRepository = FolderRepository();
        final Folder parentOfCurrentFolder =
            await folderRepository.getFolder(parentFolderId);

        if (!mounted) return;
        final bool isParentTheRoot = parentOfCurrentFolder.parentId == null;

        if (isParentTheRoot) {
          context.goNamed(
            AppRouter.listDetail,
            pathParameters: {'listId': widget.todoList.id},
            extra: {
              'todoList': widget.todoList,
              'parentFolder': parentOfCurrentFolder,
            },
          );
        } else {
          context.goNamed(
            AppRouter.folderDetail,
            pathParameters: {
              'listId': widget.todoList.id,
              'folderId': parentOfCurrentFolder.id,
            },
            extra: {
              'todoList': widget.todoList,
              'parentFolder': parentOfCurrentFolder,
            },
          );
        }
      } catch (error) {
        if (mounted) {
          showErrorSnackBar(context,
              message: 'Failed to navigate back: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRootFolder = widget.parentFolder.parentId == null;
    final bool isMobile = ResponsiveLayout.isMobile(context);

    final bool isFoldersCollapsed = _viewModel.isFoldersCollapsed;
    final bool isTasksCollapsed = _viewModel.isTasksCollapsed;
    final Stream<List<Folder>> foldersStream = _viewModel.foldersStream;
    final Stream<List<Task>> tasksStream =
        _viewModel.tasksStream(widget.parentFolder.id);

    return Container(
      key: ValueKey('folder_screen_${widget.parentFolder.id}'),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          TodoListDetailHeader(
            isMobile: isMobile,
            isRootFolder: isRootFolder,
            title: widget.parentFolder.title,
            onBackTap: _navigateToParent,
            onManageTap: _showManageMembersDialog,
            onInviteTap: _showInviteFormDialog,
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async => _refreshStreams(),
                  child: CustomScrollView(
                    key: PageStorageKey(
                        'tasks_scroll_${widget.parentFolder.id}'),
                    slivers: [
                      FolderListSection(
                        isCollapsed: isFoldersCollapsed,
                        stream: foldersStream,
                        currentUserRole: _viewModel.currentUserRole,
                        onToggleCollapse: _viewModel.toggleFoldersCollapse,
                        onFolderTap: (folder) {
                          // CORREZIONE: Usa goNamed invece di go per navigazione corretta
                          context.goNamed(
                            AppRouter.folderDetail,
                            pathParameters: {
                              'listId': widget.todoList.id,
                              'folderId': folder.id,
                            },
                            extra: {
                              'todoList': widget.todoList,
                              'parentFolder': folder,
                            },
                          );
                        },
                        onEdit: (folder) =>
                            _openFolderDialog(folderToEdit: folder),
                        onDelete: (folder) => _showDeleteFolderDialog(folder),
                      ),

                      // TASK HEADER
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0)
                              .copyWith(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tasks',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey)),
                              Row(
                                children: [
                                  TaskFilterDropdown(
                                    selectedFilter: _selectedTaskFilter,
                                    onFilterChanged: (newFilter) {
                                      setState(() {
                                        _selectedTaskFilter = newFilter;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isTasksCollapsed
                                          ? Icons.expand_more
                                          : Icons.expand_less,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _viewModel.toggleTasksCollapse,
                                    tooltip: isTasksCollapsed
                                        ? 'Expand Tasks'
                                        : 'Collapse Tasks',
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      // SOLUZIONE: StreamBuilder con SliverList.builder
                      StreamBuilder<List<Task>>(
                        stream: tasksStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(30),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('Error: ${snapshot.error}'),
                              ),
                            );
                          }

                          final tasks = snapshot.data ?? [];
                          final sortedTasks =
                              TaskSorter.sortTasks(tasks, _selectedTaskFilter);

                          if (sortedTasks.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: Text("No tasks found.")),
                              ),
                            );
                          }

                          if (isTasksCollapsed) {
                            return const SliverToBoxAdapter(
                                child: SizedBox.shrink());
                          }

                          // SOLUZIONE: SliverList.builder con key UNICA e STABILE
                          return SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            sliver: SliverList.builder(
                              itemCount: sortedTasks.length,
                              itemBuilder: (context, index) {
                                final task = sortedTasks[index];

                                // KEY UNICA basata solo sull'ID del task
                                return Padding(
                                  key: ValueKey('task_tile_${task.id}'),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskListTile(
                                    task: task,
                                    currentUserRole: _viewModel.currentUserRole,
                                    onTap: () {},
                                    onEdit: () =>
                                        _openTaskDialog(taskToEdit: task),
                                    onDelete: () => _showDeleteTaskDialog(task),
                                    onStatusChanged: (newStatus) {
                                      _handleTaskStatusChange(task, newStatus);
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 160)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // FAB Chat
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: FloatingActionButton(
                          heroTag: 'chat_fab', // Serve se ci sono più FAB
                          onPressed: () {
                            // Naviga alla chat della todo list corrente
                            context.go('/list/${widget.todoList.id}/chat');
                          },
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.chat),
                          tooltip: 'Open Chat',
                        ),
                      ),
                      // FAB esistenti (DetailActionButtons)
                      DetailActionButtons(
                        onNewFolder: () => _openFolderDialog(),
                        onNewTask: () => _openTaskDialog(),
                        isMobile: isMobile,
                        currentUserRole: _viewModel.currentUserRole,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
