// coverage:ignore-file

// consider testing later

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

  // CRITICO: Manteniamo una cache locale dei task per evitare rebuild
  List<Task> _cachedTasks = [];
  
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
                    showSuccessSnackBar(
                      context,
                      message: 'Folder deleted successfully',
                    );
                    _refreshStreams();
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(
                      context,
                      message: 'Failed to delete folder: $error',
                    );
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
                    showSuccessSnackBar(
                      context,
                      message: 'Task deleted successfully',
                    );
                  }
                } catch (error) {
                  if (mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    showErrorSnackBar(
                      context,
                      message: 'Failed to delete task: $error',
                    );
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
        showErrorSnackBar(
          context,
          message: 'Failed to update task status: $error',
        );
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
        final Folder parentOfCurrentFolder = await folderRepository.getFolder(
          parentFolderId,
        );

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
          showErrorSnackBar(
            context,
            message: 'Failed to navigate back: $error',
          );
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
                    // CRITICO: Key per mantenere lo stato dello scroll
                    key: PageStorageKey('tasks_scroll_${widget.parentFolder.id}'),
                    slivers: [
                      FolderListSection(
                        isCollapsed: isFoldersCollapsed,
                        stream: foldersStream,
                        currentUserRole: _viewModel.currentUserRole,
                        onToggleCollapse: _viewModel.toggleFoldersCollapse,
                        onFolderTap: (folder) {
                          context.go(
                            '/list/${widget.todoList.id}/folder/${folder.id}',
                            extra: {
                              'todoList': widget.todoList,
                              'parentFolder': folder
                            },
                          );
                        },
                        onEdit: (folder) => _openFolderDialog(
                          folderToEdit: folder,
                        ),
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
                                        color: Colors.grey),
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

                      // === SOLUZIONE DEFINITIVA: STREAMBUILDER CON LISTA STATICA ===
                      StreamBuilder<List<Task>>(
                        stream: tasksStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Center(
                                      child: CircularProgressIndicator())),
                            );
                          }
                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                                child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Error: ${snapshot.error}'),
                            ));
                          }

                          final tasks = snapshot.data ?? [];
                          final sortedTasks =
                              TaskSorter.sortTasks(tasks, _selectedTaskFilter);

                          // CRITICO: Aggiorna la cache solo se i dati sono diversi
                          if (!_areTaskListsEqual(_cachedTasks, sortedTasks)) {
                            // Usa addPostFrameCallback per evitare setState durante build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _cachedTasks = sortedTasks;
                                });
                              }
                            });
                          }

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

                          // SOLUZIONE: SliverFixedExtentList invece di SliverList
                          // Questo forza Flutter a sapere esattamente l'altezza di ogni item
                          return SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            sliver: SliverFixedExtentList(
                              itemExtent: 202, // Altezza card (190) + margin (12)
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  // Usa la cache invece dei dati diretti per stabilità
                                  final task = _cachedTasks.isNotEmpty 
                                      ? _cachedTasks[index] 
                                      : sortedTasks[index];

                                  return _TaskListTileWrapper(
                                    key: ValueKey('task_${task.id}'),
                                    task: task,
                                    currentUserRole: _viewModel.currentUserRole,
                                    onEdit: () =>
                                        _openTaskDialog(taskToEdit: task),
                                    onDelete: () => _showDeleteTaskDialog(task),
                                    onStatusChanged: (newStatus) {
                                      _handleTaskStatusChange(task, newStatus);
                                    },
                                  );
                                },
                                childCount: _cachedTasks.isNotEmpty 
                                    ? _cachedTasks.length 
                                    : sortedTasks.length,
                                // RIMOSSO findChildIndexCallback - causa il glitch!
                              ),
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
                  child: DetailActionButtons(
                    onNewFolder: () => _openFolderDialog(),
                    onNewTask: () => _openTaskDialog(),
                    isMobile: isMobile,
                    currentUserRole: _viewModel.currentUserRole,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper per confrontare liste di task
  bool _areTaskListsEqual(List<Task> list1, List<Task> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || list1[i].status != list2[i].status) {
        return false;
      }
    }
    return true;
  }
}

/// Wrapper per TaskListTile con KeepAlive
class _TaskListTileWrapper extends StatefulWidget {
  final Task task;
  final String? currentUserRole;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;

  const _TaskListTileWrapper({
    super.key,
    required this.task,
    required this.currentUserRole,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  State<_TaskListTileWrapper> createState() => _TaskListTileWrapperState();
}

class _TaskListTileWrapperState extends State<_TaskListTileWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return TaskListTile(
      key: ValueKey(widget.task.id),
      task: widget.task,
      currentUserRole: widget.currentUserRole,
      onTap: () {},
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      onStatusChanged: widget.onStatusChanged,
    );
  }
}